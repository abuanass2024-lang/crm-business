import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CRMBusinessApp());
}

// ============================================================
// APP
// ============================================================

class CRMBusinessApp extends StatelessWidget {
  const CRMBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRM Business',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1565C0),
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const DemoHomePage(),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class Customer {
  String id;
  String name;
  String company;
  String phone;
  String email;
  String sector;
  String status;
  int healthScore;
  String notes;

  Customer({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.sector,
    required this.status,
    required this.healthScore,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'sector': sector,
      'status': status,
      'healthScore': healthScore,
      'notes': notes,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      company: json['company'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      sector: json['sector'] ?? '',
      status: json['status'] ?? 'Active',
      healthScore: json['healthScore'] ?? 70,
      notes: json['notes'] ?? '',
    );
  }
}

class Opportunity {
  String id;
  String title;
  String customer;
  double value;
  String stage;
  String owner;

  Opportunity({
    required this.id,
    required this.title,
    required this.customer,
    required this.value,
    required this.stage,
    required this.owner,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'customer': customer,
      'value': value,
      'stage': stage,
      'owner': owner,
    };
  }

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      customer: json['customer'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      stage: json['stage'] ?? 'Lead',
      owner: json['owner'] ?? '',
    );
  }
}

class CRMTask {
  String id;
  String title;
  String customer;
  String dueDate;
  String priority;
  String status;

  CRMTask({
    required this.id,
    required this.title,
    required this.customer,
    required this.dueDate,
    required this.priority,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'customer': customer,
      'dueDate': dueDate,
      'priority': priority,
      'status': status,
    };
  }

  factory CRMTask.fromJson(Map<String, dynamic> json) {
    return CRMTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      customer: json['customer'] ?? '',
      dueDate: json['dueDate'] ?? '',
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Open',
    );
  }
}

class Activity {
  String id;
  String customer;
  String type;
  String description;
  String date;

  Activity({
    required this.id,
    required this.customer,
    required this.type,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer,
      'type': type,
      'description': description,
      'date': date,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',
      customer: json['customer'] ?? '',
      type: json['type'] ?? 'Note',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

// ============================================================
// LOCAL STORE
// ============================================================

class DemoStore extends ChangeNotifier {
  static const String storageKey = 'crm_business_demo_data';

  List<Customer> customers = [];
  List<Opportunity> opportunities = [];
  List<CRMTask> tasks = [];
  List<Activity> activities = [];

  bool initialized = false;

  Future<void> initialize() async {
    if (initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw == null) {
      _seed();
      await save();
    } else {
      try {
        final data = jsonDecode(raw);

        customers = (data['customers'] as List? ?? [])
            .map((e) => Customer.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        opportunities = (data['opportunities'] as List? ?? [])
            .map(
              (e) => Opportunity.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();

        tasks = (data['tasks'] as List? ?? [])
            .map(
              (e) => CRMTask.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();

        activities = (data['activities'] as List? ?? [])
            .map(
              (e) => Activity.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList();
      } catch (_) {
        _seed();
        await save();
      }
    }

    initialized = true;
    notifyListeners();
  }

  void _seed() {
    customers = [
      Customer(
        id: 'c1',
        name: 'محمد أحمد',
        company: 'شركة النور التجارية',
        phone: '777123456',
        email: 'info@alnoor.example',
        sector: 'تجارة',
        status: 'Active',
        healthScore: 88,
        notes: 'عميل استراتيجي ومهتم بالتوسع.',
      ),
      Customer(
        id: 'c2',
        name: 'عبدالله صالح',
        company: 'مؤسسة المستقبل',
        phone: '733456789',
        email: 'contact@future.example',
        sector: 'مقاولات',
        status: 'Active',
        healthScore: 74,
        notes: 'فرصة لتمويل مشروع جديد.',
      ),
      Customer(
        id: 'c3',
        name: 'أحمد علي',
        company: 'شركة التقنية الحديثة',
        phone: '711987654',
        email: 'sales@tech.example',
        sector: 'تقنية',
        status: 'Prospect',
        healthScore: 61,
        notes: 'يحتاج متابعة من مسؤول العلاقة.',
      ),
      Customer(
        id: 'c4',
        name: 'سالم حسن',
        company: 'شركة الطاقة الشمسية',
        phone: '700112233',
        email: 'info@solar.example',
        sector: 'طاقة',
        status: 'Active',
        healthScore: 92,
        notes: 'عميل ذو قيمة عالية.',
      ),
    ];

    opportunities = [
      Opportunity(
        id: 'o1',
        title: 'تمويل توسعة',
        customer: 'شركة النور التجارية',
        value: 250000,
        stage: 'Proposal',
        owner: 'مسؤول العلاقة',
      ),
      Opportunity(
        id: 'o2',
        title: 'حلول طاقة شمسية',
        customer: 'شركة الطاقة الشمسية',
        value: 180000,
        stage: 'Negotiation',
        owner: 'مسؤول العلاقة',
      ),
      Opportunity(
        id: 'o3',
        title: 'خدمات شركات',
        customer: 'مؤسسة المستقبل',
        value: 95000,
        stage: 'Lead',
        owner: 'مسؤول العلاقة',
      ),
    ];

    tasks = [
      CRMTask(
        id: 't1',
        title: 'الاتصال بالعميل',
        customer: 'شركة النور التجارية',
        dueDate: '2026-10-04',
        priority: 'High',
        status: 'Open',
      ),
      CRMTask(
        id: 't2',
        title: 'إرسال العرض',
        customer: 'مؤسسة المستقبل',
        dueDate: '2026-10-05',
        priority: 'Medium',
        status: 'In Progress',
      ),
      CRMTask(
        id: 't3',
        title: 'مراجعة احتياجات العميل',
        customer: 'شركة التقنية الحديثة',
        dueDate: '2026-10-06',
        priority: 'High',
        status: 'Open',
      ),
    ];

    activities = [
      Activity(
        id: 'a1',
        customer: 'شركة النور التجارية',
        type: 'Call',
        description: 'تم الاتصال ومناقشة التوسع.',
        date: '2026-10-02',
      ),
      Activity(
        id: 'a2',
        customer: 'شركة الطاقة الشمسية',
        type: 'Meeting',
        description: 'اجتماع لمناقشة مشروع الطاقة.',
        date: '2026-10-01',
      ),
    ];
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'customers': customers.map((e) => e.toJson()).toList(),
      'opportunities': opportunities.map((e) => e.toJson()).toList(),
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'activities': activities.map((e) => e.toJson()).toList(),
    };

    await prefs.setString(storageKey, jsonEncode(data));
    notifyListeners();
  }

  Future<void> reset() async {
    _seed();
    await save();
  }

  double get pipelineValue {
    return opportunities.fold(
      0,
      (sum, item) => sum + item.value,
    );
  }

  int get openTasks {
    return tasks.where((e) => e.status != 'Completed').length;
  }

  double get weightedPipeline {
    double total = 0;

    for (final opportunity in opportunities) {
      double probability;

      switch (opportunity.stage) {
        case 'Lead':
          probability = 0.20;
          break;
        case 'Qualified':
          probability = 0.40;
          break;
        case 'Proposal':
          probability = 0.60;
          break;
        case 'Negotiation':
          probability = 0.80;
          break;
        case 'Won':
          probability = 1.00;
          break;
        default:
          probability = 0.20;
      }

      total += opportunity.value * probability;
    }

    return total;
  }
}

// ============================================================
// HOME
// ============================================================

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  final DemoStore store = DemoStore();

  int selectedIndex = 0;

  final List<String> titles = [
    'لوحة التحكم',
    'العملاء',
    'الفرص البيعية',
    'المهام',
    'التحليلات',
    'المساعد الذكي',
    'المزيد',
  ];

  @override
  void initState() {
    super.initState();
    store.initialize();
  }

  Widget currentPage() {
    switch (selectedIndex) {
      case 1:
        return CustomersPage(store: store);
      case 2:
        return OpportunitiesPage(store: store);
      case 3:
        return TasksPage(store: store);
      case 4:
        return AnalyticsPage(store: store);
      case 5:
        return AssistantPage(store: store);
      case 6:
        return MorePage(store: store);
      default:
        return DashboardPage(store: store);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.initialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Text(
              titles[selectedIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'الإشعارات',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('الإشعارات'),
                        content: const Text(
                          'لا توجد إشعارات جديدة حاليًا.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إغلاق'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.notifications_none),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: currentPage(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex > 4 ? 0 : selectedIndex,
            onDestinationSelected: (index) {
              if (index <= 4) {
                setState(() {
                  selectedIndex = index;
                });
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'العملاء',
              ),
              NavigationDestination(
                icon: Icon(Icons.trending_up),
                selectedIcon: Icon(Icons.trending_up),
                label: 'الفرص',
              ),
              NavigationDestination(
                icon: Icon(Icons.task_alt),
                selectedIcon: Icon(Icons.task_alt),
                label: 'المهام',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'التحليلات',
              ),
            ],
          ),
          floatingActionButton: selectedIndex == 1
              ? FloatingActionButton(
                  onPressed: () => showCustomerDialog(
                    context,
                    store,
                  ),
                  child: const Icon(Icons.add),
                )
              : selectedIndex == 2
                  ? FloatingActionButton(
                      onPressed: () => showOpportunityDialog(
                        context,
                        store,
                      ),
                      child: const Icon(Icons.add),
                    )
                  : selectedIndex == 3
                      ? FloatingActionButton(
                          onPressed: () => showTaskDialog(
                            context,
                            store,
                          ),
                          child: const Icon(Icons.add),
                        )
                      : null,
        );
      },
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatelessWidget {
  final DemoStore store;

  const DashboardPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: store.save,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'مرحبًا بك في CRM Business 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'نظرة تنفيذية سريعة على نشاط العملاء والمبيعات.',
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              StatCard(
                title: 'العملاء',
                value: '${store.customers.length}',
                icon: Icons.people,
              ),
              StatCard(
                title: 'قيمة Pipeline',
                value: formatMoney(store.pipelineValue),
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'Forecast',
                value: formatMoney(store.weightedPipeline),
                icon: Icons.auto_graph,
              ),
              StatCard(
                title: 'المهام المفتوحة',
                value: '${store.openTasks}',
                icon: Icons.task_alt,
              ),
            ],
          ),

          const SizedBox(height: 20),

          const SectionTitle(
            title: 'Executive Brief',
            icon: Icons.insights,
          ),

          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InsightRow(
                    icon: Icons.trending_up,
                    title: 'قوة المبيعات',
                    value:
                        '${store.opportunities.length} فرص نشطة',
                  ),
                  const Divider(height: 24),
                  InsightRow(
                    icon: Icons.favorite,
                    title: 'Customer Health',
                    value: averageHealth(store),
                  ),
                  const Divider(height: 24),
                  InsightRow(
                    icon: Icons.warning_amber,
                    title: 'Next Best Action',
                    value: nextBestAction(store),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const SectionTitle(
            title: 'أحدث الأنشطة',
            icon: Icons.history,
          ),

          const SizedBox(height: 10),

          ...store.activities.reversed.take(5).map(
                (activity) => ActivityCard(
                  activity: activity,
                ),
              ),
        ],
      ),
    );
  }
}

// ============================================================
// CUSTOMERS
// ============================================================

class CustomersPage extends StatefulWidget {
  final DemoStore store;

  const CustomersPage({
    super.key,
    required this.store,
  });

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.store.customers.where((customer) {
      final query = search.toLowerCase();

      return customer.name.toLowerCase().contains(query) ||
          customer.company.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.sector.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث عن عميل أو شركة...',
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('لا توجد نتائج'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final customer = filtered[index];

                    return CustomerCard(
                      customer: customer,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Customer360Page(
                              store: widget.store,
                              customer: customer,
                            ),
                          ),
                        );
                      },
                      onEdit: () {
                        showCustomerDialog(
                          context,
                          widget.store,
                          existing: customer,
                        );
                      },
                      onDelete: () async {
                        final confirmed =
                            await confirmDelete(context);

                        if (confirmed) {
                          widget.store.customers.removeWhere(
                            (e) => e.id == customer.id,
                          );

                          await widget.store.save();
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                child: Text(
                  customer.name.isEmpty
                      ? '?'
                      : customer.name.substring(0, 1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(customer.company),
                    const SizedBox(height: 4),
                    Text(
                      '${customer.sector} • ${customer.phone}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('تعديل'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOMER 360
// ============================================================

class Customer360Page extends StatelessWidget {
  final DemoStore store;
  final Customer customer;

  const Customer360Page({
    super.key,
    required this.store,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final customerActivities = store.activities
        .where((e) => e.customer == customer.company)
        .toList();

    final customerOpportunities = store.opportunities
        .where((e) => e.customer == customer.company)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer 360'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    child: Text(
                      customer.name.substring(0, 1),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(customer.company),
                  const SizedBox(height: 16),
                  HealthScore(score: customer.healthScore),
                  const SizedBox(height: 16),
                  Text(customer.notes),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const SectionTitle(
            title: 'بيانات العميل',
            icon: Icons.person_outline,
          ),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DetailRow(
                    label: 'الهاتف',
                    value: customer.phone,
                  ),
                  DetailRow(
                    label: 'البريد',
                    value: customer.email,
                  ),
                  DetailRow(
                    label: 'القطاع',
                    value: customer.sector,
                  ),
                  DetailRow(
                    label: 'الحالة',
                    value: customer.status,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const SectionTitle(
            title: 'الفرص',
            icon: Icons.trending_up,
          ),

          ...customerOpportunities.map(
            (opportunity) => OpportunityCard(
              opportunity: opportunity,
              compact: true,
              onStageChanged: (_) {},
            ),
          ),

          const SizedBox(height: 16),

          const SectionTitle(
            title: 'الأنشطة',
            icon: Icons.history,
          ),

          ...customerActivities.map(
            (activity) => ActivityCard(
              activity: activity,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showActivityDialog(
            context,
            store,
            customer,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('نشاط'),
      ),
    );
  }
}

// ============================================================
// OPPORTUNITIES
// ============================================================

class OpportunitiesPage extends StatelessWidget {
  final DemoStore store;

  const OpportunitiesPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      'Lead',
      'Qualified',
      'Proposal',
      'Negotiation',
      'Won',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sales Pipeline',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'إدارة الفرص ومتابعة تقدمها حتى الإغلاق.',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 18),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'إجمالي Pipeline',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatMoney(store.pipelineValue),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Forecast: ${formatMoney(store.weightedPipeline)}',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        ...stages.map(
          (stage) {
            final items = store.opportunities
                .where((e) => e.stage == stage)
                .toList();

            final value = items.fold<double>(
              0,
              (sum, e) => sum + e.value,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: ExpansionTile(
                title: Text(
                  stageName(stage),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${items.length} فرص • ${formatMoney(value)}',
                ),
                children: items.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('لا توجد فرص'),
                        ),
                      ]
                    : items.map(
                        (opportunity) {
                          return OpportunityCard(
                            opportunity: opportunity,
                            onStageChanged: (newStage) async {
                              opportunity.stage = newStage;
                              await store.save();
                            },
                          );
                        },
                      ).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool compact;
  final ValueChanged<String> onStageChanged;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onStageChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final stages = [
      'Lead',
      'Qualified',
      'Proposal',
      'Negotiation',
      'Won',
    ];

    return Card(
      margin: compact
          ? const EdgeInsets.only(bottom: 8)
          : const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              opportunity.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(opportunity.customer),
            const SizedBox(height: 5),
            Text(
              formatMoney(opportunity.value),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: opportunity.stage,
              decoration: const InputDecoration(
                labelText: 'المرحلة',
              ),
              items: stages
                  .map(
                    (stage) => DropdownMenuItem(
                      value: stage,
                      child: Text(stageName(stage)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onStageChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TASKS
// ============================================================

class TasksPage extends StatelessWidget {
  final DemoStore store;

  const TasksPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Tasks & Workflows',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'حوّل المتابعة اليومية إلى سير عمل واضح.',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 18),
        ...store.tasks.map(
          (task) => TaskCard(
            task: task,
            onStatusChanged: (status) async {
              task.status = status;
              await store.save();
            },
          ),
        ),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  final CRMTask task;
  final ValueChanged<String> onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'Open',
      'In Progress',
      'Completed',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.status == 'Completed'
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                PriorityBadge(
                  priority: task.priority,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(task.customer),
            const SizedBox(height: 5),
            Text('الاستحقاق: ${task.dueDate}'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: task.status,
              decoration: const InputDecoration(
                labelText: 'الحالة',
              ),
              items: statuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(taskStatusName(status)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onStatusChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ANALYTICS
// ============================================================

class AnalyticsPage extends StatelessWidget {
  final DemoStore store;

  const AnalyticsPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final activeCustomers = store.customers
        .where((e) => e.status == 'Active')
        .length;

    final completedTasks = store.tasks
        .where((e) => e.status == 'Completed')
        .length;

    final won = store.opportunities
        .where((e) => e.stage == 'Won')
        .fold<double>(
          0,
          (sum, e) => sum + e.value,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 18),

        AnalyticsCard(
          title: 'العملاء النشطون',
          value: '$activeCustomers',
          subtitle:
              'من إجمالي ${store.customers.length} عميل',
          icon: Icons.people,
        ),

        AnalyticsCard(
          title: 'Pipeline',
          value: formatMoney(store.pipelineValue),
          subtitle:
              '${store.opportunities.length} فرص',
          icon: Icons.trending_up,
        ),

        AnalyticsCard(
          title: 'Forecast',
          value: formatMoney(store.weightedPipeline),
          subtitle: 'القيمة المرجحة حسب المرحلة',
          icon: Icons.auto_graph,
        ),

        AnalyticsCard(
          title: 'المبيعات المغلقة',
          value: formatMoney(won),
          subtitle: 'الفرص في مرحلة Won',
          icon: Icons.check_circle,
        ),

        AnalyticsCard(
          title: 'المهام المكتملة',
          value: '$completedTasks',
          subtitle:
              'من إجمالي ${store.tasks.length} مهام',
          icon: Icons.task_alt,
        ),

        const SizedBox(height: 16),

        const SectionTitle(
          title: 'Customer Health',
          icon: Icons.favorite,
        ),

        const SizedBox(height: 10),

        ...store.customers.map(
          (customer) => Card(
            child: ListTile(
              leading: HealthScore(
                score: customer.healthScore,
                compact: true,
              ),
              title: Text(customer.company),
              subtitle: Text(customer.name),
              trailing: Text(
                '${customer.healthScore}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AI ASSISTANT
// ============================================================

class AssistantPage extends StatelessWidget {
  final DemoStore store;

  const AssistantPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final action = nextBestAction(store);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'مساعد CRM Business',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تحليل سريع للبيانات الحالية واقتراح الخطوة التالية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        const SectionTitle(
          title: 'Next Best Action',
          icon: Icons.lightbulb,
        ),

        const SizedBox(height: 10),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.arrow_forward,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        const SectionTitle(
          title: 'Smart Insights',
          icon: Icons.insights,
        ),

        const SizedBox(height: 10),

        InsightCard(
          title: 'Pipeline',
          text:
              'إجمالي قيمة الفرص الحالية ${formatMoney(store.pipelineValue)}.',
          icon: Icons.trending_up,
        ),

        InsightCard(
          title: 'Forecast',
          text:
              'القيمة المرجحة للفرص ${formatMoney(store.weightedPipeline)}.',
          icon: Icons.auto_graph,
        ),

        InsightCard(
          title: 'Customer Health',
          text:
              'متوسط صحة العملاء ${averageHealth(store)}.',
          icon: Icons.favorite,
        ),

        InsightCard(
          title: 'Tasks',
          text:
              'لديك ${store.openTasks} مهام تحتاج إلى متابعة.',
          icon: Icons.task_alt,
        ),
      ],
    );
  }
}

class InsightCard extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;

  const InsightCard({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(text),
        ),
      ),
    );
  }
}

// ============================================================
// MORE
// ============================================================

class MorePage extends StatelessWidget {
  final DemoStore store;

  const MorePage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.business),
            ),
            title: const Text(
              'CRM Business Demo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'بيئة تجريبية محلية',
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text(
                  'إعادة بيانات Demo',
                ),
                subtitle: const Text(
                  'إرجاع البيانات إلى الحالة الأصلية',
                ),
                onTap: () async {
                  final confirmed =
                      await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          'إعادة البيانات؟',
                        ),
                        content: const Text(
                          'سيتم حذف التعديلات المحلية وإرجاع بيانات Demo.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(
                              context,
                              false,
                            ),
                            child: const Text('إلغاء'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(
                              context,
                              true,
                            ),
                            child: const Text('إعادة'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await store.reset();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تمت إعادة بيانات Demo.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('عن النظام'),
                subtitle: const Text(
                  'CRM Business • Demo Edition',
                ),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'CRM Business',
                    applicationVersion: '1.6.0',
                    applicationLegalese:
                        'Demo Edition',
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'خارطة التطوير',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text('✓ Customer 360'),
                Text('✓ Sales Pipeline'),
                Text('✓ Forecasting'),
                Text('✓ Customer Health Score'),
                Text('✓ Smart Assistant'),
                Text('✓ Tasks & Workflows'),
                Text('→ Backend API'),
                Text('→ PostgreSQL Multi-Tenant'),
                Text('→ Authentication & RBAC'),
                Text('→ Audit Trail'),
                Text('→ Automation Engine'),
                Text('→ AI Copilot'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DIALOGS
// ============================================================

Future<void> showCustomerDialog(
  BuildContext context,
  DemoStore store, {
  Customer? existing,
}) async {
  final nameController = TextEditingController(
    text: existing?.name ?? '',
  );

  final companyController = TextEditingController(
    text: existing?.company ?? '',
  );

  final phoneController = TextEditingController(
    text: existing?.phone ?? '',
  );

  final emailController = TextEditingController(
    text: existing?.email ?? '',
  );

  final sectorController = TextEditingController(
    text: existing?.sector ?? '',
  );

  final notesController = TextEditingController(
    text: existing?.notes ?? '',
  );

  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          existing == null
              ? 'إضافة عميل'
              : 'تعديل العميل',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الشخص',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  labelText: 'اسم الشركة',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'الهاتف',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sectorController,
                decoration: const InputDecoration(
                  labelText: 'القطاع',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  companyController.text.trim().isEmpty) {
                return;
              }

              if (existing == null) {
                store.customers.add(
                  Customer(
                    id: DateTime.now()
                        .microsecondsSinceEpoch
                        .toString(),
                    name: nameController.text.trim(),
                    company:
                        companyController.text.trim(),
                    phone: phoneController.text.trim(),
                    email: emailController.text.trim(),
                    sector: sectorController.text.trim(),
                    status: 'Prospect',
                    healthScore: 70,
                    notes: notesController.text.trim(),
                  ),
                );
              } else {
                existing.name =
                    nameController.text.trim();
                existing.company =
                    companyController.text.trim();
                existing.phone =
                    phoneController.text.trim();
                existing.email =
                    emailController.text.trim();
                existing.sector =
                    sectorController.text.trim();
                existing.notes =
                    notesController.text.trim();
              }

              await store.save();

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              existing == null ? 'إضافة' : 'حفظ',
            ),
          ),
        ],
      );
    },
  );

  nameController.dispose();
  companyController.dispose();
  phoneController.dispose();
  emailController.dispose();
  sectorController.dispose();
  notesController.dispose();
}

Future<void> showOpportunityDialog(
  BuildContext context,
  DemoStore store,
) async {
  final titleController = TextEditingController();
  final valueController = TextEditingController();

  String? customer;

  if (store.customers.isNotEmpty) {
    customer = store.customers.first.company;
  }

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إضافة فرصة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الفرصة',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: valueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'القيمة',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: customer,
                    decoration: const InputDecoration(
                      labelText: 'العميل',
                    ),
                    items: store.customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.company,
                            child: Text(c.company),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        customer = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(
                    valueController.text.trim(),
                  );

                  if (titleController.text
                          .trim()
                          .isEmpty ||
                      value == null ||
                      customer == null) {
                    return;
                  }

                  store.opportunities.add(
                    Opportunity(
                      id: DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                      title:
                          titleController.text.trim(),
                      customer: customer!,
                      value: value,
                      stage: 'Lead',
                      owner: 'مسؤول العلاقة',
                    ),
                  );

                  await store.save();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      );
    },
  );

  titleController.dispose();
  valueController.dispose();
}

Future<void> showTaskDialog(
  BuildContext context,
  DemoStore store,
) async {
  final titleController = TextEditingController();
  final dateController = TextEditingController();

  String? customer;

  if (store.customers.isNotEmpty) {
    customer = store.customers.first.company;
  }

  String priority = 'Medium';

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إضافة مهمة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان المهمة',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: customer,
                    decoration: const InputDecoration(
                      labelText: 'العميل',
                    ),
                    items: store.customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.company,
                            child: Text(c.company),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        customer = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الاستحقاق',
                      hintText: '2026-10-10',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'الأولوية',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Low',
                        child: Text('منخفضة'),
                      ),
                      DropdownMenuItem(
                        value: 'Medium',
                        child: Text('متوسطة'),
                      ),
                      DropdownMenuItem(
                        value: 'High',
                        child: Text('عالية'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          priority = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleController.text
                          .trim()
                          .isEmpty ||
                      customer == null) {
                    return;
                  }

                  store.tasks.add(
                    CRMTask(
                      id: DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                      title:
                          titleController.text.trim(),
                      customer: customer!,
                      dueDate:
                          dateController.text.trim().isEmpty
                              ? 'غير محدد'
                              : dateController.text
                                  .trim(),
                      priority: priority,
                      status: 'Open',
                    ),
                  );

                  await store.save();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      );
    },
  );

  titleController.dispose();
  dateController.dispose();
}

Future<void> showActivityDialog(
  BuildContext context,
  DemoStore store,
  Customer customer,
) async {
  final descriptionController =
      TextEditingController();

  String type = 'Call';

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إضافة نشاط'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'نوع النشاط',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Call',
                      child: Text('مكالمة'),
                    ),
                    DropdownMenuItem(
                      value: 'Meeting',
                      child: Text('اجتماع'),
                    ),
                    DropdownMenuItem(
                      value: 'Email',
                      child: Text('بريد'),
                    ),
                    DropdownMenuItem(
                      value: 'Note',
                      child: Text('ملاحظة'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        type = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (descriptionController.text
                      .trim()
                      .isEmpty) {
                    return;
                  }

                  store.activities.add(
                    Activity(
                      id: DateTime.now()
                          .microsecondsSinceEpoch
                          .toString(),
                      customer: customer.company,
                      type: type,
                      description:
                          descriptionController.text
                              .trim(),
                      date: DateTime.now()
                          .toIso8601String()
                          .substring(0, 10),
                    ),
                  );

                  await store.save();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      );
    },
  );

  descriptionController.dispose();
}

// ============================================================
// UI COMPONENTS
// ============================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              child: Icon(icon),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class InsightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const InsightRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final Activity activity;

  const ActivityCard({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(activityIcon(activity.type)),
        ),
        title: Text(activity.description),
        subtitle: Text(
          '${activity.customer} • ${activity.date}',
        ),
      ),
    );
  }
}

class HealthScore extends StatelessWidget {
  final int score;
  final bool compact;

  const HealthScore({
    super.key,
    required this.score,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = score >= 80
        ? 'Healthy'
        : score >= 60
            ? 'Watch'
            : 'At Risk';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compact ? 36 : 70,
          height: compact ? 36 : 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: compact ? 4 : 7,
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: compact ? 11 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Text(label),
        ],
      ],
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: priority == 'High'
            ? Colors.red.shade50
            : priority == 'Medium'
                ? Colors.orange.shade50
                : Colors.green.shade50,
      ),
      child: Text(
        priorityName(priority),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String formatMoney(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }

  return value.toStringAsFixed(0);
}

String averageHealth(DemoStore store) {
  if (store.customers.isEmpty) {
    return '0';
  }

  final total = store.customers.fold<int>(
    0,
    (sum, customer) => sum + customer.healthScore,
  );

  return '${(total / store.customers.length).round()}/100';
}

String nextBestAction(DemoStore store) {
  final risky = store.customers
      .where((e) => e.healthScore < 60)
      .toList();

  if (risky.isNotEmpty) {
    return 'التواصل مع ${risky.first.company} لأن Customer Health Score منخفض ويحتاج متابعة.';
  }

  final openHighPriority = store.tasks
      .where(
        (e) =>
            e.priority == 'High' &&
            e.status != 'Completed',
      )
      .toList();

  if (openHighPriority.isNotEmpty) {
    return 'تنفيذ المهمة ذات الأولوية العالية: ${openHighPriority.first.title}.';
  }

  final negotiation = store.opportunities
      .where((e) => e.stage == 'Negotiation')
      .toList();

  if (negotiation.isNotEmpty) {
    return 'متابعة فرصة ${negotiation.first.title} مع ${negotiation.first.customer} لدفعها نحو الإغلاق.';
  }

  return 'مراجعة العملاء النشطين وتحديد فرص البيع المتقاطع والبيع الإضافي.';
}

String stageName(String stage) {
  switch (stage) {
    case 'Lead':
      return 'Lead — عميل محتمل';
    case 'Qualified':
      return 'Qualified — مؤهل';
    case 'Proposal':
      return 'Proposal — عرض';
    case 'Negotiation':
      return 'Negotiation — تفاوض';
    case 'Won':
      return 'Won — مغلق';
    default:
      return stage;
  }
}

String taskStatusName(String status) {
  switch (status) {
    case 'Open':
      return 'مفتوحة';
    case 'In Progress':
      return 'قيد التنفيذ';
    case 'Completed':
      return 'مكتملة';
    default:
      return status;
  }
}

String priorityName(String priority) {
  switch (priority) {
    case 'High':
      return 'عالية';
    case 'Medium':
      return 'متوسطة';
    case 'Low':
      return 'منخفضة';
    default:
      return priority;
  }
}

IconData activityIcon(String type) {
  switch (type) {
    case 'Call':
      return Icons.phone;
    case 'Meeting':
      return Icons.groups;
    case 'Email':
      return Icons.email;
    default:
      return Icons.note;
  }
}

Future<bool> confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('حذف العميل؟'),
        content: const Text(
          'سيتم حذف العميل من بيانات Demo المحلية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              false,
            ),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              true,
            ),
            child: const Text('حذف'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}