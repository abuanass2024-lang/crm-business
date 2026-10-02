import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CrmBusinessApp());
}

// ============================================================
// APP
// ============================================================

class CrmBusinessApp extends StatelessWidget {
  const CrmBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRM Business',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomePage(),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.sector,
    required this.status,
    required this.health,
    this.notes = '',
  });

  String id;
  String name;
  String company;
  String phone;
  String email;
  String sector;
  String status;
  int health;
  String notes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'sector': sector,
      'status': status,
      'health': health,
      'notes': notes,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      company: '${json['company'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      email: '${json['email'] ?? ''}',
      sector: '${json['sector'] ?? ''}',
      status: '${json['status'] ?? 'Prospect'}',
      health: (json['health'] as num?)?.toInt() ?? 70,
      notes: '${json['notes'] ?? ''}',
    );
  }
}

class Opportunity {
  Opportunity({
    required this.id,
    required this.title,
    required this.customer,
    required this.value,
    required this.stage,
    required this.owner,
  });

  String id;
  String title;
  String customer;
  double value;
  String stage;
  String owner;

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
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      customer: '${json['customer'] ?? ''}',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      stage: '${json['stage'] ?? 'Lead'}',
      owner: '${json['owner'] ?? 'مسؤول العلاقة'}',
    );
  }
}

class CrmTask {
  CrmTask({
    required this.id,
    required this.title,
    required this.customer,
    required this.dueDate,
    required this.priority,
    required this.status,
  });

  String id;
  String title;
  String customer;
  String dueDate;
  String priority;
  String status;

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

  factory CrmTask.fromJson(Map<String, dynamic> json) {
    return CrmTask(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      customer: '${json['customer'] ?? ''}',
      dueDate: '${json['dueDate'] ?? ''}',
      priority: '${json['priority'] ?? 'Medium'}',
      status: '${json['status'] ?? 'Open'}',
    );
  }
}

class Activity {
  Activity({
    required this.id,
    required this.customer,
    required this.type,
    required this.description,
    required this.date,
  });

  String id;
  String customer;
  String type;
  String description;
  String date;

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
      id: '${json['id'] ?? ''}',
      customer: '${json['customer'] ?? ''}',
      type: '${json['type'] ?? 'Note'}',
      description: '${json['description'] ?? ''}',
      date: '${json['date'] ?? ''}',
    );
  }
}

// ============================================================
// STORE
// ============================================================

class CrmStore extends ChangeNotifier {
  static const String storageKey = 'crm_business_demo_v3';

  final List<Customer> customers = [];
  final List<Opportunity> opportunities = [];
  final List<CrmTask> tasks = [];
  final List<Activity> activities = [];

  bool ready = false;

  Future<void> init() async {
    if (ready) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw == null) {
      seed();
      await save(notify: false);
    } else {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;

        customers
          ..clear()
          ..addAll(
            ((data['customers'] as List?) ?? []).map(
              (item) => Customer.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );

        opportunities
          ..clear()
          ..addAll(
            ((data['opportunities'] as List?) ?? []).map(
              (item) => Opportunity.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );

        tasks
          ..clear()
          ..addAll(
            ((data['tasks'] as List?) ?? []).map(
              (item) => CrmTask.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );

        activities
          ..clear()
          ..addAll(
            ((data['activities'] as List?) ?? []).map(
              (item) => Activity.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      } catch (_) {
        seed();
        await save(notify: false);
      }
    }

    ready = true;
    notifyListeners();
  }

  void seed() {
    customers
      ..clear()
      ..addAll([
        Customer(
          id: 'c1',
          name: 'محمد أحمد',
          company: 'شركة النور التجارية',
          phone: '777123456',
          email: 'info@alnoor.example',
          sector: 'تجارة',
          status: 'Active',
          health: 88,
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
          health: 74,
          notes: 'فرصة لمشروع جديد.',
        ),
        Customer(
          id: 'c3',
          name: 'أحمد علي',
          company: 'شركة التقنية الحديثة',
          phone: '711987654',
          email: 'sales@tech.example',
          sector: 'تقنية',
          status: 'Prospect',
          health: 61,
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
          health: 92,
          notes: 'عميل ذو قيمة عالية.',
        ),
      ]);

    opportunities
      ..clear()
      ..addAll([
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
      ]);

    tasks
      ..clear()
      ..addAll([
        CrmTask(
          id: 't1',
          title: 'الاتصال بالعميل',
          customer: 'شركة النور التجارية',
          dueDate: '2026-10-04',
          priority: 'High',
          status: 'Open',
        ),
        CrmTask(
          id: 't2',
          title: 'إرسال العرض',
          customer: 'مؤسسة المستقبل',
          dueDate: '2026-10-05',
          priority: 'Medium',
          status: 'In Progress',
        ),
        CrmTask(
          id: 't3',
          title: 'مراجعة احتياجات العميل',
          customer: 'شركة التقنية الحديثة',
          dueDate: '2026-10-06',
          priority: 'High',
          status: 'Open',
        ),
      ]);

    activities
      ..clear()
      ..addAll([
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
      ]);
  }

  Future<void> save({bool notify = true}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      storageKey,
      jsonEncode({
        'customers': customers.map((item) => item.toJson()).toList(),
        'opportunities':
            opportunities.map((item) => item.toJson()).toList(),
        'tasks': tasks.map((item) => item.toJson()).toList(),
        'activities': activities.map((item) => item.toJson()).toList(),
      }),
    );

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> reset() async {
    seed();
    await save();
  }

  double get pipeline {
    return opportunities.fold(
      0,
      (sum, item) => sum + item.value,
    );
  }

  double get forecast {
    return opportunities.fold(
      0,
      (sum, item) {
        const probabilities = {
          'Lead': 0.20,
          'Qualified': 0.40,
          'Proposal': 0.60,
          'Negotiation': 0.80,
          'Won': 1.00,
        };

        final probability = probabilities[item.stage] ?? 0.20;

        return sum + item.value * probability;
      },
    );
  }

  int get openTasks {
    return tasks.where((item) => item.status != 'Completed').length;
  }

  int get health {
    if (customers.isEmpty) {
      return 0;
    }

    final total = customers.fold(
      0,
      (sum, item) => sum + item.health,
    );

    return (total / customers.length).round();
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrmStore store = CrmStore();

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    store.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.ready) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final pages = [
          Dashboard(store: store),
          CustomersPage(store: store),
          OpportunitiesPage(store: store),
          TasksPage(store: store),
          AnalyticsPage(store: store),
        ];

        final titles = [
          'لوحة التحكم',
          'العملاء',
          'الفرص البيعية',
          'المهام',
          'التحليلات',
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                titles[selectedIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'المساعد الذكي',
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () {
                    showAssistant(context, store);
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'reset') {
                      await store.reset();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تمت إعادة البيانات التجريبية.'),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'reset',
                      child: Text('إعادة بيانات Demo'),
                    ),
                  ],
                ),
              ],
            ),
            body: pages[selectedIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
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
                  icon: Icon(Icons.task_alt_outlined),
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
            floatingActionButton: _buildFab(context),
          ),
        );
      },
    );
  }

  Widget? _buildFab(BuildContext context) {
    if (selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          customerDialog(context, store);
        },
        child: const Icon(Icons.add),
      );
    }

    if (selectedIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          opportunityDialog(context, store);
        },
        child: const Icon(Icons.add),
      );
    }

    if (selectedIndex == 3) {
      return FloatingActionButton(
        onPressed: () {
          taskDialog(context, store);
        },
        child: const Icon(Icons.add),
      );
    }

    return null;
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    required this.store,
  });

  final CrmStore store;

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
            'بيئة تجريبية محلية تعمل بدون Backend.',
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
                title: 'Pipeline',
                value: formatMoney(store.pipeline),
                icon: Icons.trending_up,
              ),
              StatCard(
                title: 'Forecast',
                value: formatMoney(store.forecast),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InfoRow(
                    title: 'Customer Health',
                    value: '${store.health}/100',
                    icon: Icons.favorite,
                  ),
                  const Divider(),
                  InfoRow(
                    title: 'الفرص النشطة',
                    value: '${store.opportunities.length}',
                    icon: Icons.trending_up,
                  ),
                  const Divider(),
                  InfoRow(
                    title: 'Next Best Action',
                    value: nextAction(store),
                    icon: Icons.lightbulb_outline,
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
          const SizedBox(height: 8),
          ...store.activities.reversed.take(5).map(
                (activity) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        activityIcon(activity.type),
                      ),
                    ),
                    title: Text(activity.description),
                    subtitle: Text(
                      '${activity.customer} • ${activity.date}',
                    ),
                  ),
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
  const CustomersPage({
    super.key,
    required this.store,
  });

  final CrmStore store;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.store.customers.where((customer) {
      final query = search.trim().toLowerCase();

      if (query.isEmpty) {
        return true;
      }

      return customer.company.toLowerCase().contains(query) ||
          customer.name.toLowerCase().contains(query) ||
          customer.phone.contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          onChanged: (value) {
            setState(() {
              search = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'بحث عن عميل أو شركة...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...filtered.map(
          (customer) => Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  customer.company.isEmpty
                      ? '?'
                      : customer.company.substring(0, 1),
                ),
              ),
              title: Text(
                customer.company,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${customer.name} • ${customer.sector} • ${customer.phone}',
              ),
              trailing: HealthIndicator(
                score: customer.health,
                compact: true,
              ),
              onTap: () {
                customer360(
                  context,
                  widget.store,
                  customer,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CUSTOMER 360
// ============================================================

void customer360(
  BuildContext context,
  CrmStore store,
  Customer customer,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                customer.company,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(customer.name),
              const SizedBox(height: 16),
              HealthIndicator(
                score: customer.health,
              ),
              const SizedBox(height: 16),
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
              DetailRow(
                label: 'ملاحظات',
                value: customer.notes,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);

                  activityDialog(
                    context,
                    store,
                    customer,
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة نشاط'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ============================================================
// OPPORTUNITIES
// ============================================================

class OpportunitiesPage extends StatelessWidget {
  const OpportunitiesPage({
    super.key,
    required this.store,
  });

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: store.opportunities
          .map(
            (opportunity) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.trending_up),
                ),
                title: Text(
                  opportunity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${opportunity.customer}\n'
                  '${stageName(opportunity.stage)} • '
                  '${opportunity.owner}',
                ),
                isThreeLine: true,
                trailing: Text(
                  formatMoney(opportunity.value),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ============================================================
// TASKS
// ============================================================

class TasksPage extends StatelessWidget {
  const TasksPage({
    super.key,
    required this.store,
  });

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: store.tasks
          .map(
            (task) => Card(
              child: ListTile(
                leading: IconButton(
                  icon: Icon(
                    task.status == 'Completed'
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  onPressed: () async {
                    task.status =
                        task.status == 'Completed'
                            ? 'Open'
                            : 'Completed';

                    await store.save();
                  },
                ),
                title: Text(task.title),
                subtitle: Text(
                  '${task.customer} • ${task.dueDate} • '
                  '${taskStatus(task.status)}',
                ),
                trailing: PriorityChip(
                  priority: task.priority,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ============================================================
// ANALYTICS
// ============================================================

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({
    super.key,
    required this.store,
  });

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final stages = <String, int>{};

    for (final opportunity in store.opportunities) {
      stages[opportunity.stage] =
          (stages[opportunity.stage] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle(
          title: 'Sales Analytics',
          icon: Icons.analytics,
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                MetricRow(
                  title: 'إجمالي Pipeline',
                  value: formatMoney(store.pipeline),
                ),
                MetricRow(
                  title: 'Weighted Forecast',
                  value: formatMoney(store.forecast),
                ),
                MetricRow(
                  title: 'Customer Health',
                  value: '${store.health}/100',
                ),
                MetricRow(
                  title: 'Open Tasks',
                  value: '${store.openTasks}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle(
          title: 'Pipeline by Stage',
          icon: Icons.account_tree,
        ),
        ...stages.entries.map(
          (entry) => Card(
            child: ListTile(
              title: Text(stageName(entry.key)),
              trailing: CircleAvatar(
                child: Text('${entry.value}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CUSTOMER DIALOG
// ============================================================

Future<void> customerDialog(
  BuildContext context,
  CrmStore store,
) async {
  final name = TextEditingController();
  final company = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final sector = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة عميل'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                formField(
                  name,
                  'اسم المسؤول',
                ),
                formField(
                  company,
                  'اسم الشركة',
                ),
                formField(
                  phone,
                  'الهاتف',
                ),
                formField(
                  email,
                  'البريد الإلكتروني',
                ),
                formField(
                  sector,
                  'القطاع',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (company.text.trim().isEmpty) {
                  return;
                }

                store.customers.add(
                  Customer(
                    id: generateId(),
                    name: name.text.trim(),
                    company: company.text.trim(),
                    phone: phone.text.trim(),
                    email: email.text.trim(),
                    sector: sector.text.trim().isEmpty
                        ? 'غير محدد'
                        : sector.text.trim(),
                    status: 'Prospect',
                    health: 70,
                  ),
                );

                await store.save();

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
    },
  );

  name.dispose();
  company.dispose();
  phone.dispose();
  email.dispose();
  sector.dispose();
}

// ============================================================
// OPPORTUNITY DIALOG
// ============================================================

Future<void> opportunityDialog(
  BuildContext context,
  CrmStore store,
) async {
  if (store.customers.isEmpty) {
    return;
  }

  final title = TextEditingController();
  final value = TextEditingController();

  String customer = store.customers.first.company;
  String stage = 'Lead';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('إضافة فرصة'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    formField(
                      title,
                      'اسم الفرصة',
                    ),
                    formField(
                      value,
                      'القيمة',
                      number: true,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: customer,
                      decoration: const InputDecoration(
                        labelText: 'العميل',
                      ),
                      items: store.customers
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.company,
                              child: Text(item.company),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          customer = newValue ?? customer;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: stage,
                      decoration: const InputDecoration(
                        labelText: 'المرحلة',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Lead',
                          child: Text('Lead'),
                        ),
                        DropdownMenuItem(
                          value: 'Qualified',
                          child: Text('Qualified'),
                        ),
                        DropdownMenuItem(
                          value: 'Proposal',
                          child: Text('Proposal'),
                        ),
                        DropdownMenuItem(
                          value: 'Negotiation',
                          child: Text('Negotiation'),
                        ),
                        DropdownMenuItem(
                          value: 'Won',
                          child: Text('Won'),
                        ),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          stage = newValue ?? stage;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(value.text.trim());

                    if (title.text.trim().isEmpty ||
                        amount == null) {
                      return;
                    }

                    store.opportunities.add(
                      Opportunity(
                        id: generateId(),
                        title: title.text.trim(),
                        customer: customer,
                        value: amount,
                        stage: stage,
                        owner: 'مسؤول العلاقة',
                      ),
                    );

                    await store.save();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  title.dispose();
  value.dispose();
}

// ============================================================
// TASK DIALOG
// ============================================================

Future<void> taskDialog(
  BuildContext context,
  CrmStore store,
) async {
  if (store.customers.isEmpty) {
    return;
  }

  final title = TextEditingController();
  final date = TextEditingController();

  String customer = store.customers.first.company;
  String priority = 'Medium';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('إضافة مهمة'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    formField(
                      title,
                      'عنوان المهمة',
                    ),
                    formField(
                      date,
                      'تاريخ الاستحقاق',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: customer,
                      decoration: const InputDecoration(
                        labelText: 'العميل',
                      ),
                      items: store.customers
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.company,
                              child: Text(item.company),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          customer = newValue ?? customer;
                        });
                      },
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
                      onChanged: (newValue) {
                        setState(() {
                          priority = newValue ?? priority;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (title.text.trim().isEmpty) {
                      return;
                    }

                    store.tasks.add(
                      CrmTask(
                        id: generateId(),
                        title: title.text.trim(),
                        customer: customer,
                        dueDate: date.text.trim().isEmpty
                            ? 'غير محدد'
                            : date.text.trim(),
                        priority: priority,
                        status: 'Open',
                      ),
                    );

                    await store.save();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  title.dispose();
  date.dispose();
}

// ============================================================
// ACTIVITY DIALOG
// ============================================================

Future<void> activityDialog(
  BuildContext context,
  CrmStore store,
  Customer customer,
) async {
  final description = TextEditingController();

  String type = 'Call';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
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
                    onChanged: (newValue) {
                      setState(() {
                        type = newValue ?? type;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  formField(
                    description,
                    'الوصف',
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (description.text.trim().isEmpty) {
                      return;
                    }

                    store.activities.add(
                      Activity(
                        id: generateId(),
                        customer: customer.company,
                        type: type,
                        description: description.text.trim(),
                        date: DateTime.now()
                            .toIso8601String()
                            .substring(0, 10),
                      ),
                    );

                    await store.save();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(context);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  description.dispose();
}

// ============================================================
// AI ASSISTANT
// ============================================================

void showAssistant(
  BuildContext context,
  CrmStore store,
) {
  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('المساعد الذكي ✨'),
          content: Text(
            nextAction(store),
            style: const TextStyle(
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    },
  );
}

// ============================================================
// COMPONENTS
// ============================================================

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              child: Icon(icon),
            ),
            Text(
              value,
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
  const SectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
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

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
        ),
      ),
    );
  }
}

class MetricRow extends StatelessWidget {
  const MetricRow({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value.isEmpty ? '-' : value,
      ),
    );
  }
}

class HealthIndicator extends StatelessWidget {
  const HealthIndicator({
    super.key,
    required this.score,
    this.compact = false,
  });

  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compact ? 40 : 72,
          height: compact ? 40 : 72,
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
          const SizedBox(width: 10),
          Text(
            score >= 80
                ? 'Healthy'
                : score >= 60
                    ? 'Watch'
                    : 'At Risk',
          ),
        ],
      ],
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({
    super.key,
    required this.priority,
  });

  final String priority;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        priorityName(priority),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String generateId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}

String formatMoney(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }

  return value.toStringAsFixed(0);
}

String nextAction(CrmStore store) {
  final riskyCustomers = store.customers.where(
    (customer) => customer.health < 60,
  );

  if (riskyCustomers.isNotEmpty) {
    return 'متابعة العميل ${riskyCustomers.first.company} '
        'لأن Customer Health منخفض ويحتاج إلى تدخل مسؤول العلاقة.';
  }

  final highPriorityTasks = store.tasks.where(
    (task) =>
        task.priority == 'High' &&
        task.status != 'Completed',
  );

  if (highPriorityTasks.isNotEmpty) {
    return 'تنفيذ المهمة ذات الأولوية العالية: '
        '${highPriorityTasks.first.title}.';
  }

  final negotiation = store.opportunities.where(
    (opportunity) => opportunity.stage == 'Negotiation',
  );

  if (negotiation.isNotEmpty) {
    return 'متابعة فرصة ${negotiation.first.title} '
        'مع ${negotiation.first.customer} لدفعها نحو الإغلاق.';
  }

  return 'مراجعة العملاء النشطين وتحديد فرص '
      'البيع المتقاطع والبيع الإضافي.';
}

String stageName(String stage) {
  const names = {
    'Lead': 'Lead — عميل محتمل',
    'Qualified': 'Qualified — مؤهل',
    'Proposal': 'Proposal — عرض',
    'Negotiation': 'Negotiation — تفاوض',
    'Won': 'Won — مغلق',
  };

  return names[stage] ?? stage;
}

String taskStatus(String status) {
  const names = {
    'Open': 'مفتوحة',
    'In Progress': 'قيد التنفيذ',
    'Completed': 'مكتملة',
  };

  return names[status] ?? status;
}

String priorityName(String priority) {
  const names = {
    'High': 'عالية',
    'Medium': 'متوسطة',
    'Low': 'منخفضة',
  };

  return names[priority] ?? priority;
}

IconData activityIcon(String type) {
  const icons = {
    'Call': Icons.phone,
    'Meeting': Icons.groups,
    'Email': Icons.email,
    'Note': Icons.note,
  };

  return icons[type] ?? Icons.note;
}

Widget formField(
  TextEditingController controller,
  String label, {
  bool number = false,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(
              decimal: true,
            )
          : null,
      decoration: InputDecoration(
        labelText: label,
      ),
    ),
  );
}