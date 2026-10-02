import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'CRM Business',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AppShell(),
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
    required this.industry,
    required this.value,
    required this.health,
    required this.lastActivityDays,
    required this.owner,
    required this.notes,
  });

  final int id;
  String name;
  String company;
  String phone;
  String email;
  String industry;
  double value;
  int health;
  int lastActivityDays;
  String owner;
  String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'company': company,
        'phone': phone,
        'email': email,
        'industry': industry,
        'value': value,
        'health': health,
        'lastActivityDays': lastActivityDays,
        'owner': owner,
        'notes': notes,
      };

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      company: json['company'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      industry: json['industry'] as String,
      value: (json['value'] as num).toDouble(),
      health: json['health'] as int,
      lastActivityDays: json['lastActivityDays'] as int,
      owner: json['owner'] as String,
      notes: json['notes'] as String,
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
    required this.probability,
    required this.owner,
    required this.daysSinceActivity,
    required this.nextAction,
  });

  final int id;
  String title;
  String customer;
  double value;
  String stage;
  int probability;
  String owner;
  int daysSinceActivity;
  String nextAction;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'customer': customer,
        'value': value,
        'stage': stage,
        'probability': probability,
        'owner': owner,
        'daysSinceActivity': daysSinceActivity,
        'nextAction': nextAction,
      };

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] as int,
      title: json['title'] as String,
      customer: json['customer'] as String,
      value: (json['value'] as num).toDouble(),
      stage: json['stage'] as String,
      probability: json['probability'] as int,
      owner: json['owner'] as String,
      daysSinceActivity: json['daysSinceActivity'] as int,
      nextAction: json['nextAction'] as String,
    );
  }
}

class CrmTask {
  CrmTask({
    required this.id,
    required this.title,
    required this.customer,
    required this.priority,
    required this.dueLabel,
    required this.completed,
  });

  final int id;
  String title;
  String customer;
  String priority;
  String dueLabel;
  bool completed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'customer': customer,
        'priority': priority,
        'dueLabel': dueLabel,
        'completed': completed,
      };

  factory CrmTask.fromJson(Map<String, dynamic> json) {
    return CrmTask(
      id: json['id'] as int,
      title: json['title'] as String,
      customer: json['customer'] as String,
      priority: json['priority'] as String,
      dueLabel: json['dueLabel'] as String,
      completed: json['completed'] as bool,
    );
  }
}

class Activity {
  Activity({
    required this.id,
    required this.customer,
    required this.type,
    required this.description,
    required this.dateLabel,
  });

  final int id;
  final String customer;
  final String type;
  final String description;
  final String dateLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer': customer,
        'type': type,
        'description': description,
        'dateLabel': dateLabel,
      };

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int,
      customer: json['customer'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      dateLabel: json['dateLabel'] as String,
    );
  }
}

// ============================================================
// STORE
// ============================================================

class CrmStore extends ChangeNotifier {
  static const String storageKey = 'crm_business_v17';

  List<Customer> customers = [];
  List<Opportunity> opportunities = [];
  List<CrmTask> tasks = [];
  List<Activity> activities = [];

  bool loaded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw == null) {
      seed();
    } else {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;

        customers = (data['customers'] as List)
            .map((e) => Customer.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        opportunities = (data['opportunities'] as List)
            .map((e) => Opportunity.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        tasks = (data['tasks'] as List)
            .map((e) => CrmTask.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        activities = (data['activities'] as List)
            .map((e) => Activity.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        seed();
      }
    }

    loaded = true;
    notifyListeners();
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
  }

  void seed() {
    customers = [
      Customer(
        id: 1,
        name: 'محمد العريقي',
        company: 'شركة النور للتجارة',
        phone: '+967 777 111 222',
        email: 'alnoor@example.com',
        industry: 'تجارة',
        value: 24500,
        health: 84,
        lastActivityDays: 2,
        owner: 'أحمد',
        notes: 'عميل رئيسي منذ 2023. مهتم بالتوسع.',
      ),
      Customer(
        id: 2,
        name: 'خالد القحطاني',
        company: 'مؤسسة الأمل',
        phone: '+967 777 222 333',
        email: 'alamal@example.com',
        industry: 'مقاولات',
        value: 18500,
        health: 61,
        lastActivityDays: 6,
        owner: 'محمد',
        notes: 'لديه عرض سعر مفتوح.',
      ),
      Customer(
        id: 3,
        name: 'عبدالله الحداد',
        company: 'شركة المستقبل',
        phone: '+967 777 333 444',
        email: 'future@example.com',
        industry: 'تقنية',
        value: 42000,
        health: 91,
        lastActivityDays: 1,
        owner: 'سارة',
        notes: 'عميل استراتيجي وفرصة توسع كبيرة.',
      ),
      Customer(
        id: 4,
        name: 'علي سالم',
        company: 'شركة البناء الحديث',
        phone: '+967 777 444 555',
        email: 'build@example.com',
        industry: 'مقاولات',
        value: 9700,
        health: 38,
        lastActivityDays: 12,
        owner: 'أحمد',
        notes: 'لم تتم متابعة العميل منذ فترة.',
      ),
      Customer(
        id: 5,
        name: 'ياسر أحمد',
        company: 'مؤسسة الرواد',
        phone: '+967 777 555 666',
        email: 'leaders@example.com',
        industry: 'خدمات',
        value: 15300,
        health: 55,
        lastActivityDays: 8,
        owner: 'محمد',
        notes: 'فرصة بيع إضافية محتملة.',
      ),
      Customer(
        id: 6,
        name: 'سامر حسن',
        company: 'شركة اليمن للطاقة',
        phone: '+967 777 666 777',
        email: 'energy@example.com',
        industry: 'طاقة',
        value: 56000,
        health: 73,
        lastActivityDays: 4,
        owner: 'سارة',
        notes: 'حساب ذو قيمة مرتفعة.',
      ),
      Customer(
        id: 7,
        name: 'فؤاد صالح',
        company: 'شركة الرؤية',
        phone: '+967 777 888 999',
        email: 'vision@example.com',
        industry: 'استشارات',
        value: 12500,
        health: 88,
        lastActivityDays: 2,
        owner: 'أحمد',
        notes: 'عميل نشط.',
      ),
    ];

    opportunities = [
      Opportunity(
        id: 1,
        title: 'توريد سنوي',
        customer: 'شركة النور للتجارة',
        value: 18000,
        stage: 'Negotiation',
        probability: 70,
        owner: 'أحمد',
        daysSinceActivity: 5,
        nextAction: 'الاتصال بالعميل',
      ),
      Opportunity(
        id: 2,
        title: 'مشروع مقاولات',
        customer: 'مؤسسة الأمل',
        value: 12500,
        stage: 'Proposal',
        probability: 55,
        owner: 'محمد',
        daysSinceActivity: 4,
        nextAction: 'متابعة العرض',
      ),
      Opportunity(
        id: 3,
        title: 'نظام إدارة',
        customer: 'شركة المستقبل',
        value: 32000,
        stage: 'Qualified',
        probability: 45,
        owner: 'سارة',
        daysSinceActivity: 2,
        nextAction: 'تحديد اجتماع',
      ),
      Opportunity(
        id: 4,
        title: 'حل الطاقة',
        customer: 'شركة اليمن للطاقة',
        value: 56000,
        stage: 'Proposal',
        probability: 65,
        owner: 'سارة',
        daysSinceActivity: 3,
        nextAction: 'مراجعة العرض',
      ),
      Opportunity(
        id: 5,
        title: 'توسعة الحساب',
        customer: 'مؤسسة الرواد',
        value: 9500,
        stage: 'Qualified',
        probability: 40,
        owner: 'محمد',
        daysSinceActivity: 8,
        nextAction: 'اكتشاف الاحتياج',
      ),
      Opportunity(
        id: 6,
        title: 'عقد خدمات',
        customer: 'شركة البناء الحديث',
        value: 15000,
        stage: 'Negotiation',
        probability: 60,
        owner: 'أحمد',
        daysSinceActivity: 11,
        nextAction: 'إنقاذ الفرصة',
      ),
      Opportunity(
        id: 7,
        title: 'استشارة',
        customer: 'شركة الرؤية',
        value: 7500,
        stage: 'Won',
        probability: 100,
        owner: 'أحمد',
        daysSinceActivity: 1,
        nextAction: 'بدء التنفيذ',
      ),
    ];

    tasks = [
      CrmTask(
        id: 1,
        title: 'الاتصال بعميل مهم',
        customer: 'شركة النور للتجارة',
        priority: 'عاجل',
        dueLabel: 'اليوم',
        completed: false,
      ),
      CrmTask(
        id: 2,
        title: 'متابعة عرض السعر',
        customer: 'مؤسسة الأمل',
        priority: 'مهم',
        dueLabel: 'اليوم',
        completed: false,
      ),
      CrmTask(
        id: 3,
        title: 'تحديد اجتماع',
        customer: 'شركة المستقبل',
        priority: 'مهم',
        dueLabel: 'غداً',
        completed: false,
      ),
      CrmTask(
        id: 4,
        title: 'متابعة الفرصة المتأخرة',
        customer: 'شركة البناء الحديث',
        priority: 'عاجل',
        dueLabel: 'متأخر',
        completed: false,
      ),
      CrmTask(
        id: 5,
        title: 'إرسال ملخص الاجتماع',
        customer: 'شركة اليمن للطاقة',
        priority: 'عادي',
        dueLabel: 'غداً',
        completed: false,
      ),
      CrmTask(
        id: 6,
        title: 'مراجعة العميل',
        customer: 'مؤسسة الرواد',
        priority: 'عادي',
        dueLabel: 'بعد يومين',
        completed: false,
      ),
      CrmTask(
        id: 7,
        title: 'إغلاق الصفقة',
        customer: 'شركة الرؤية',
        priority: 'مهم',
        dueLabel: 'اليوم',
        completed: true,
      ),
    ];

    activities = [
      Activity(
        id: 1,
        customer: 'شركة النور للتجارة',
        type: 'اتصال',
        description: 'مناقشة العرض الجديد',
        dateLabel: 'منذ يومين',
      ),
      Activity(
        id: 2,
        customer: 'شركة المستقبل',
        type: 'اجتماع',
        description: 'اجتماع استكشاف الاحتياج',
        dateLabel: 'أمس',
      ),
      Activity(
        id: 3,
        customer: 'شركة اليمن للطاقة',
        type: 'عرض',
        description: 'تم إرسال العرض التجاري',
        dateLabel: 'منذ 3 أيام',
      ),
      Activity(
        id: 4,
        customer: 'مؤسسة الأمل',
        type: 'اتصال',
        description: 'مناقشة الملاحظات',
        dateLabel: 'منذ 4 أيام',
      ),
      Activity(
        id: 5,
        customer: 'شركة الرؤية',
        type: 'صفقة',
        description: 'تم إغلاق الصفقة',
        dateLabel: 'أمس',
      ),
    ];
  }

  Future<void> resetDemo() async {
    seed();
    await save();
    notifyListeners();
  }

  Future<void> addCustomer(Customer customer) async {
    customers.add(customer);
    await save();
    notifyListeners();
  }

  Future<void> addOpportunity(Opportunity opportunity) async {
    opportunities.add(opportunity);
    await save();
    notifyListeners();
  }

  Future<void> addTask(CrmTask task) async {
    tasks.add(task);
    await save();
    notifyListeners();
  }

  Future<void> addActivity(Activity activity) async {
    activities.insert(0, activity);
    await save();
    notifyListeners();
  }

  Future<void> toggleTask(int id) async {
    final task = tasks.firstWhere((e) => e.id == id);
    task.completed = !task.completed;
    await save();
    notifyListeners();
  }

  double get pipelineValue => opportunities
      .where((o) => o.stage != 'Won')
      .fold(0, (sum, o) => sum + o.value);

  double get forecastValue =>
      opportunities.fold(0, (sum, o) => sum + (o.value * o.probability / 100));

  double get wonValue => opportunities
      .where((o) => o.stage == 'Won')
      .fold(0, (sum, o) => sum + o.value);

  int get openTasks => tasks.where((t) => !t.completed).length;

  int get urgentTasks =>
      tasks.where((t) => !t.completed && t.priority == 'عاجل').length;

  int get atRiskCustomers => customers.where((c) => c.health < 50).length;

  int get attentionCustomers =>
      customers.where((c) => c.health >= 50 && c.health < 70).length;

  int get activeCustomers =>
      customers.where((c) => c.lastActivityDays <= 7).length;

  int get overdueOpportunities =>
      opportunities.where((o) => o.daysSinceActivity >= 7).length;

  Customer? getCustomer(String company) {
    for (final customer in customers) {
      if (customer.company == company) return customer;
    }
    return null;
  }
}

// ============================================================
// APP SHELL
// ============================================================

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final CrmStore store = CrmStore();

  int index = 0;

  final List<String> titles = [
    'لوحة القيادة',
    'العملاء',
    'المبيعات',
    'المهام',
    'التحليلات',
  ];

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.loaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final pages = [
          DashboardPage(
            store: store,
            onNavigate: (value) => setState(() => index = value),
          ),
          CustomersPage(store: store),
          OpportunitiesPage(store: store),
          TasksPage(store: store),
          AnalyticsPage(store: store),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(
              titles[index],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: 'AI Assistant',
                onPressed: () => showAiAssistant(context, store),
                icon: const Icon(Icons.auto_awesome),
              ),
              IconButton(
                tooltip: 'إعادة البيانات التجريبية',
                onPressed: () => confirmReset(context),
                icon: const Icon(Icons.restart_alt),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: pages[index],
          floatingActionButton: _buildFab(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) {
              setState(() => index = value);
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
                icon: Icon(Icons.monetization_on_outlined),
                selectedIcon: Icon(Icons.monetization_on),
                label: 'المبيعات',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle),
                label: 'المهام',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'التحليلات',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildFab() {
    if (index == 1) {
      return FloatingActionButton.extended(
        onPressed: () => showAddCustomerDialog(context, store),
        icon: const Icon(Icons.person_add),
        label: const Text('عميل جديد'),
      );
    }

    if (index == 2) {
      return FloatingActionButton.extended(
        onPressed: () => showAddOpportunityDialog(context, store),
        icon: const Icon(Icons.add_business),
        label: const Text('فرصة جديدة'),
      );
    }

    if (index == 3) {
      return FloatingActionButton.extended(
        onPressed: () => showAddTaskDialog(context, store),
        icon: const Icon(Icons.add_task),
        label: const Text('مهمة جديدة'),
      );
    }

    return null;
  }

  Future<void> confirmReset(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة البيانات التجريبية'),
        content: const Text(
          'سيتم حذف التعديلات الحالية وإعادة بيانات Demo الأصلية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );

    if (result == true) {
      await store.resetDemo();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إعادة البيانات التجريبية'),
        ),
      );
    }
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.store,
    required this.onNavigate,
  });

  final CrmStore store;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final risky = store.customers.where((c) => c.health < 70).take(3).toList();

    final importantOpps = store.opportunities
        .where((o) => o.stage != 'Won')
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final actions = _buildActions();

    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _welcomeCard(context),
          const SizedBox(height: 16),
          _sectionTitle('📊 ملخص الأعمال'),
          const SizedBox(height: 10),
          _metricGrid(),
          const SizedBox(height: 20),
          _sectionTitle('⚡ ماذا أفعل الآن؟'),
          const SizedBox(height: 10),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _actionCard(context, action),
            ),
          ),
          const SizedBox(height: 10),
          _sectionTitle('❤️ صحة العملاء'),
          const SizedBox(height: 10),
          if (risky.isEmpty)
            _emptyCard('لا توجد عملاء يحتاجون انتباهاً حالياً.')
          else
            ...risky.map(
              (customer) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _customerHealthCard(context, customer),
              ),
            ),
          const SizedBox(height: 10),
          _sectionTitle('🔥 أهم الفرص'),
          const SizedBox(height: 10),
          ...importantOpps.take(4).map(
                (opportunity) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _opportunityCard(opportunity),
                ),
              ),
          const SizedBox(height: 10),
          _sectionTitle('🧠 Executive Brief'),
          const SizedBox(height: 10),
          _executiveBrief(),
          const SizedBox(height: 20),
          _demoTourButton(context),
        ],
      ),
    );
  }

  Widget _welcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 23,
                child: Icon(Icons.business),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'شركة النور للتجارة',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.verified),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'صباح الخير 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'إليك أهم ما يحتاج انتباهك اليوم.',
          ),
        ],
      ),
    );
  }

  Widget _metricGrid() {
    final metrics = [
      _MetricData(
        'Pipeline',
        money(store.pipelineValue),
        Icons.trending_up,
      ),
      _MetricData(
        'Forecast',
        money(store.forecastValue),
        Icons.auto_graph,
      ),
      _MetricData(
        'عملاء نشطون',
        '${store.activeCustomers}',
        Icons.people,
      ),
      _MetricData(
        'إجراءات اليوم',
        '${store.openTasks}',
        Icons.bolt,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final item = metrics[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon),
                const Spacer(),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_ActionData> _buildActions() {
    final result = <_ActionData>[];

    final urgent = store.tasks.where(
      (t) => !t.completed && t.priority == 'عاجل',
    );

    for (final task in urgent.take(2)) {
      result.add(
        _ActionData(
          level: 'عاجل',
          title: task.customer,
          description: task.title,
          action: 'فتح المهمة',
          icon: Icons.priority_high,
        ),
      );
    }

    final staleOpps = store.opportunities.where(
      (o) => o.stage != 'Won' && o.daysSinceActivity >= 7,
    );

    for (final opportunity in staleOpps.take(2)) {
      result.add(
        _ActionData(
          level: 'مهم',
          title: opportunity.customer,
          description: opportunity.nextAction,
          action: 'متابعة الفرصة',
          icon: Icons.warning_amber,
        ),
      );
    }

    if (result.isEmpty) {
      result.add(
        _ActionData(
          level: 'جيد',
          title: 'لا توجد إجراءات عاجلة',
          description: 'جميع المتابعات الأساسية تحت السيطرة.',
          action: 'استكشف العملاء',
          icon: Icons.check_circle,
        ),
      );
    }

    return result.take(4).toList();
  }

  Widget _actionCard(BuildContext context, _ActionData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(data.icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.level,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    data.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => onNavigate(3),
              child: Text(data.action),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customerHealthCard(
    BuildContext context,
    Customer customer,
  ) {
    final status = healthStatus(customer.health);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${customer.health}'),
        ),
        title: Text(
          customer.company,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${status.label} • آخر نشاط منذ ${customer.lastActivityDays} أيام',
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => showCustomer360(context, store, customer),
      ),
    );
  }

  Widget _opportunityCard(Opportunity opportunity) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(stageIcon(opportunity.stage)),
        ),
        title: Text(
          opportunity.customer,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${opportunity.title} • ${opportunity.stage}',
        ),
        trailing: Text(
          money(opportunity.value),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _executiveBrief() {
    final overdue = store.overdueOpportunities;
    final risk = store.atRiskCustomers;

    String message;

    if (overdue > 0 && risk > 0) {
      message =
          'يوجد $overdue فرص تحتاج متابعة، و$risk عملاء في مستوى خطر. ابدأ بالإجراءات العاجلة قبل التركيز على الفرص الجديدة.';
    } else if (overdue > 0) {
      message =
          'يوجد $overdue فرص متأخرة عن المتابعة. من الأفضل مراجعتها اليوم.';
    } else if (risk > 0) {
      message =
          'يوجد $risk عملاء يحتاجون تدخلاً. راجع صحة العملاء قبل فقدان فرص مستقبلية.';
    } else {
      message =
          'الوضع التشغيلي مستقر حالياً. ركّز على الفرص الأعلى قيمة وتحويلها إلى مبيعات.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.insights),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoTourButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => showDemoTour(context),
      icon: const Icon(Icons.play_circle_outline),
      label: const Text('ابدأ الجولة التجريبية'),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(text),
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}

class _ActionData {
  const _ActionData({
    required this.level,
    required this.title,
    required this.description,
    required this.action,
    required this.icon,
  });

  final String level;
  final String title;
  final String description;
  final String action;
  final IconData icon;
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
      final q = search.trim().toLowerCase();

      if (q.isEmpty) return true;

      return customer.company.toLowerCase().contains(q) ||
          customer.name.toLowerCase().contains(q) ||
          customer.industry.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'ابحث عن عميل أو شركة...',
          ),
          onChanged: (value) {
            setState(() => search = value);
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              '${filtered.length} عميل',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${widget.store.atRiskCustomers} في خطر',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...filtered.map(
          (customer) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _customerCard(context, customer),
          ),
        ),
      ],
    );
  }

  Widget _customerCard(
    BuildContext context,
    Customer customer,
  ) {
    final health = healthStatus(customer.health);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showCustomer360(
          context,
          widget.store,
          customer,
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                child: Text(
                  customer.company.substring(0, 1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.company,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${customer.name} • ${customer.industry}',
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'قيمة العميل: ${money(customer.value)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    child: Text(
                      '${customer.health}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    health.label,
                    style: const TextStyle(fontSize: 10),
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

Future<void> showCustomer360(
  BuildContext context,
  CrmStore store,
  Customer customer,
) async {
  final health = healthStatus(customer.health);

  final customerOpps = store.opportunities
      .where((o) => o.customer == customer.company)
      .toList();

  final customerActivities = store.activities
      .where((a) => a.customer == customer.company)
      .toList();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.55,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Text(
                        customer.company.substring(0, 1),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.company,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(customer.name),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _healthPanel(customer, health),
                const SizedBox(height: 16),
                _customerStats(customer, customerOpps),
                const SizedBox(height: 20),
                const Text(
                  '🔥 الإجراء التالي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.bolt),
                    ),
                    title: Text(
                      customer.lastActivityDays >= 7
                          ? 'الاتصال بالعميل خلال 24 ساعة'
                          : 'استكشاف فرصة إضافية',
                    ),
                    subtitle: Text(
                      customer.lastActivityDays >= 7
                          ? 'لم تتم متابعة العميل منذ ${customer.lastActivityDays} أيام.'
                          : 'العميل نشط ويمكن البحث عن فرصة توسع.',
                    ),
                    trailing: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showAddTaskDialog(
                          context,
                          store,
                          initialCustomer: customer.company,
                        );
                      },
                      child: const Text('مهمة'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '🎯 الفرص',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (customerOpps.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد فرص لهذا العميل.'),
                    ),
                  )
                else
                  ...customerOpps.map(
                    (o) => Card(
                      child: ListTile(
                        title: Text(o.title),
                        subtitle: Text(
                          '${o.stage} • ${o.probability}%',
                        ),
                        trailing: Text(
                          money(o.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  '📋 آخر الأنشطة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (customerActivities.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد أنشطة مسجلة.'),
                    ),
                  )
                else
                  ...customerActivities.map(
                    (activity) => ListTile(
                      leading: Icon(activityIcon(activity.type)),
                      title: Text(activity.description),
                      subtitle: Text(
                        '${activity.type} • ${activity.dateLabel}',
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                const Text(
                  '📝 ملاحظات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(customer.notes),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Widget _healthPanel(
  Customer customer,
  _HealthStatus health,
) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '❤️ Customer Health',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${customer.health}/100',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: customer.health / 100,
            minHeight: 9,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 10),
          Text(
            '${health.label}: ${health.explanation}',
          ),
        ],
      ),
    ),
  );
}

Widget _customerStats(
  Customer customer,
  List<Opportunity> opportunities,
) {
  return Row(
    children: [
      Expanded(
        child: _smallStat(
          'قيمة العميل',
          money(customer.value),
          Icons.attach_money,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _smallStat(
          'الفرص',
          '${opportunities.length}',
          Icons.track_changes,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _smallStat(
          'المسؤول',
          customer.owner,
          Icons.person,
        ),
      ),
    ],
  );
}

Widget _smallStat(
  String title,
  String value,
  IconData icon,
) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
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
    final stages = [
      'Lead',
      'Qualified',
      'Proposal',
      'Negotiation',
      'Won',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _pipelineSummary(),
        const SizedBox(height: 18),
        const Text(
          '💰 Sales Pipeline',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...stages.map(
          (stage) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _stageSection(stage),
          ),
        ),
      ],
    );
  }

  Widget _pipelineSummary() {
    return Row(
      children: [
        Expanded(
          child: _smallStat(
            'Pipeline',
            money(store.pipelineValue),
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _smallStat(
            'Forecast',
            money(store.forecastValue),
            Icons.auto_graph,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _smallStat(
            'Won',
            money(store.wonValue),
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _stageSection(String stage) {
    final list =
        store.opportunities.where((o) => o.stage == stage).toList();

    final total = list.fold<double>(
      0,
      (sum, opportunity) => sum + opportunity.value,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(stageIcon(stage)),
                const SizedBox(width: 8),
                Text(
                  stageName(stage),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  money(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (list.isEmpty)
              const Text('لا توجد فرص')
            else
              ...list.map(
                (opportunity) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      '${opportunity.probability}%',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  title: Text(opportunity.customer),
                  subtitle: Text(
                    '${opportunity.title} • ${opportunity.nextAction}',
                  ),
                  trailing: Text(
                    money(opportunity.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
  const TasksPage({
    super.key,
    required this.store,
  });

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final open = store.tasks.where((t) => !t.completed).toList();
    final completed = store.tasks.where((t) => t.completed).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: _smallStat(
                'مفتوحة',
                '${open.length}',
                Icons.pending_actions,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _smallStat(
                'عاجلة',
                '${store.urgentTasks}',
                Icons.priority_high,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _smallStat(
                'مكتملة',
                '${completed.length}',
                Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '⚡ مركز الإجراءات',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...open.map(
          (task) => _taskCard(context, task),
        ),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            '✓ مكتملة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...completed.map(
            (task) => _taskCard(context, task),
          ),
        ],
      ],
    );
  }

  Widget _taskCard(
    BuildContext context,
    CrmTask task,
  ) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (_) => store.toggleTask(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration:
                task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${task.customer} • ${task.dueLabel}',
        ),
        trailing: Chip(
          label: Text(task.priority),
        ),
      ),
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
    final totalCustomers = store.customers.length;
    final healthy =
        store.customers.where((c) => c.health >= 70).length;
    final attention = store.attentionCustomers;
    final risk = store.atRiskCustomers;

    final totalOpps = store.opportunities.length;
    final won = store.opportunities
        .where((o) => o.stage == 'Won')
        .length;

    final conversion =
        totalOpps == 0 ? 0 : (won / totalOpps * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        const Text(
          '📊 ذكاء الأعمال',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        _analyticsCard(
          '❤️ Customer Health',
          [
            _AnalyticsRow(
              'Healthy',
              '$healthy',
              totalCustomers == 0
                  ? 0
                  : healthy / totalCustomers,
            ),
            _AnalyticsRow(
              'Attention',
              '$attention',
              totalCustomers == 0
                  ? 0
                  : attention / totalCustomers,
            ),
            _AnalyticsRow(
              'Risk',
              '$risk',
              totalCustomers == 0
                  ? 0
                  : risk / totalCustomers,
            ),
          ],
        ),
        const SizedBox(height: 15),
        _analyticsCard(
          '💰 Sales Performance',
          [
            _AnalyticsRow(
              'Pipeline',
              money(store.pipelineValue),
              0.72,
            ),
            _AnalyticsRow(
              'Forecast',
              money(store.forecastValue),
              0.56,
            ),
            _AnalyticsRow(
              'Won',
              money(store.wonValue),
              0.31,
            ),
          ],
        ),
        const SizedBox(height: 15),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎯 Conversion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$conversion%',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نسبة الفرص المغلقة إلى إجمالي الفرص التجريبية.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ مؤشرات الانتباه',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• ${store.overdueOpportunities} فرص تحتاج متابعة.',
                ),
                Text(
                  '• ${store.atRiskCustomers} عملاء في مستوى خطر.',
                ),
                Text(
                  '• ${store.urgentTasks} مهام عاجلة مفتوحة.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _analyticsCard(
    String title,
    List<_AnalyticsRow> rows,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(row.label),
                        const Spacer(),
                        Text(
                          row.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: row.progress.clamp(0, 1),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRow {
  const _AnalyticsRow(
    this.label,
    this.value,
    this.progress,
  );

  final String label;
  final String value;
  final double progress;
}

// ============================================================
// ADD CUSTOMER
// ============================================================

Future<void> showAddCustomerDialog(
  BuildContext context,
  CrmStore store,
) async {
  final name = TextEditingController();
  final company = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final industry = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('إضافة عميل'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: company,
                decoration: const InputDecoration(
                  labelText: 'اسم الشركة',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'اسم جهة الاتصال',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                decoration: const InputDecoration(
                  labelText: 'الهاتف',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: industry,
                decoration: const InputDecoration(
                  labelText: 'القطاع',
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
              if (company.text.trim().isEmpty) return;

              final nextId = store.customers.isEmpty
                  ? 1
                  : store.customers
                          .map((e) => e.id)
                          .reduce((a, b) => a > b ? a : b) +
                      1;

              await store.addCustomer(
                Customer(
                  id: nextId,
                  name: name.text.trim().isEmpty
                      ? 'جهة اتصال جديدة'
                      : name.text.trim(),
                  company: company.text.trim(),
                  phone: phone.text.trim(),
                  email: email.text.trim(),
                  industry: industry.text.trim().isEmpty
                      ? 'عام'
                      : industry.text.trim(),
                  value: 0,
                  health: 70,
                  lastActivityDays: 0,
                  owner: 'أنا',
                  notes: 'عميل تمت إضافته من النسخة التجريبية.',
                ),
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      );
    },
  );
}

// ============================================================
// ADD OPPORTUNITY
// ============================================================

Future<void> showAddOpportunityDialog(
  BuildContext context,
  CrmStore store,
) async {
  final title = TextEditingController();
  final value = TextEditingController();

  String? selectedCustomer =
      store.customers.isEmpty ? null : store.customers.first.company;

  String stage = 'Qualified';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('فرصة بيع جديدة'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'اسم الفرصة',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'القيمة',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'العميل',
                    ),
                    items: store.customers
                        .map(
                          (customer) => DropdownMenuItem(
                            value: customer.company,
                            child: Text(customer.company),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedCustomer = value);
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
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => stage = value);
                      }
                    },
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
                  final amount =
                      double.tryParse(value.text.trim()) ?? 0;

                  if (title.text.trim().isEmpty ||
                      selectedCustomer == null) {
                    return;
                  }

                  final nextId = store.opportunities.isEmpty
                      ? 1
                      : store.opportunities
                              .map((e) => e.id)
                              .reduce((a, b) => a > b ? a : b) +
                          1;

                  final probability = stage == 'Won'
                      ? 100
                      : stage == 'Negotiation'
                          ? 70
                          : stage == 'Proposal'
                              ? 55
                              : stage == 'Qualified'
                                  ? 40
                                  : 20;

                  await store.addOpportunity(
                    Opportunity(
                      id: nextId,
                      title: title.text.trim(),
                      customer: selectedCustomer!,
                      value: amount,
                      stage: stage,
                      probability: probability,
                      owner: 'أنا',
                      daysSinceActivity: 0,
                      nextAction: 'تحديد الإجراء التالي',
                    ),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ============================================================
// ADD TASK
// ============================================================

Future<void> showAddTaskDialog(
  BuildContext context,
  CrmStore store, {
  String? initialCustomer,
}) async {
  final title = TextEditingController();

  String? selectedCustomer = initialCustomer ??
      (store.customers.isEmpty ? null : store.customers.first.company);

  String priority = 'مهم';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('مهمة جديدة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'المهمة',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedCustomer,
                  decoration: const InputDecoration(
                    labelText: 'العميل',
                  ),
                  items: store.customers
                      .map(
                        (customer) => DropdownMenuItem(
                          value: customer.company,
                          child: Text(customer.company),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedCustomer = value);
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
                      value: 'عاجل',
                      child: Text('عاجل'),
                    ),
                    DropdownMenuItem(
                      value: 'مهم',
                      child: Text('مهم'),
                    ),
                    DropdownMenuItem(
                      value: 'عادي',
                      child: Text('عادي'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => priority = value);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty ||
                      selectedCustomer == null) {
                    return;
                  }

                  final nextId = store.tasks.isEmpty
                      ? 1
                      : store.tasks
                              .map((e) => e.id)
                              .reduce((a, b) => a > b ? a : b) +
                          1;

                  await store.addTask(
                    CrmTask(
                      id: nextId,
                      title: title.text.trim(),
                      customer: selectedCustomer!,
                      priority: priority,
                      dueLabel: 'اليوم',
                      completed: false,
                    ),
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ============================================================
// AI ASSISTANT DEMO
// ============================================================

Future<void> showAiAssistant(
  BuildContext context,
  CrmStore store,
) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    child: Icon(Icons.auto_awesome),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AI Business Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _aiQuestion(
                context,
                'ما أهم شيء يجب أن أفعله اليوم؟',
                'ابدأ بالمهام العاجلة ثم راجع الفرص التي لم تتم متابعتها منذ 7 أيام أو أكثر.',
              ),
              _aiQuestion(
                context,
                'ما العملاء الذين يحتاجون انتباهاً؟',
                'يوجد حالياً ${store.atRiskCustomers} عملاء في مستوى خطر و${store.attentionCustomers} يحتاجون متابعة.',
              ),
              _aiQuestion(
                context,
                'كيف تبدو المبيعات؟',
                'قيمة الـPipeline الحالية ${money(store.pipelineValue)}، والتوقع المرجح ${money(store.forecastValue)}.',
              ),
              const SizedBox(height: 8),
              const Text(
                'ملاحظة: هذا مساعد تجريبي يعتمد على بيانات Demo المحلية. سيتم ربطه لاحقاً بمحرك AI حقيقي وبيانات الشركة.',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _aiQuestion(
  BuildContext context,
  String question,
  String answer,
) {
  return Card(
    child: ExpansionTile(
      leading: const Icon(Icons.chat_bubble_outline),
      title: Text(question),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(answer),
        ),
      ],
    ),
  );
}

// ============================================================
// DEMO TOUR
// ============================================================

Future<void> showDemoTour(BuildContext context) async {
  final steps = [
    (
      '1',
      '👥 العملاء',
      'ابدأ من Customer 360 لمعرفة قيمة العميل، حالته، الفرص، الأنشطة والإجراء التالي.'
    ),
    (
      '2',
      '💰 المبيعات',
      'تابع Pipeline ومراحل الفرص وقيمة الصفقات والتوقعات.'
    ),
    (
      '3',
      '⚡ الإجراءات',
      'لا تبحث عن ما يجب فعله. النظام يبرز المهام والمتابعات التي تحتاج انتباهك.'
    ),
    (
      '4',
      '❤️ صحة العملاء',
      'اكتشف العملاء الذين قد يحتاجون تدخلاً قبل أن تتحول المشكلة إلى خسارة.'
    ),
    (
      '5',
      '🧠 الذكاء',
      'في النسخ القادمة سيتم ربط هذه المؤشرات بمحرك AI حقيقي وتوصيات متقدمة.'
    ),
  ];

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('CRM Business Demo Tour'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: steps.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final step = steps[index];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(step.$1),
                ),
                title: Text(
                  step.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(step.$3),
              );
            },
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ابدأ الاستكشاف'),
          ),
        ],
      );
    },
  );
}

// ============================================================
// HELPERS
// ============================================================

String money(double value) {
  if (value >= 1000000) {
    return '\$${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '\$${(value / 1000).toStringAsFixed(1)}K';
  }

  return '\$${value.toStringAsFixed(0)}';
}

String stageName(String stage) {
  switch (stage) {
    case 'Lead':
      return 'Leads';
    case 'Qualified':
      return 'Qualified';
    case 'Proposal':
      return 'Proposal';
    case 'Negotiation':
      return 'Negotiation';
    case 'Won':
      return 'Won';
    default:
      return stage;
  }
}

IconData stageIcon(String stage) {
  switch (stage) {
    case 'Lead':
      return Icons.person_search;
    case 'Qualified':
      return Icons.verified_outlined;
    case 'Proposal':
      return Icons.description_outlined;
    case 'Negotiation':
      return Icons.handshake_outlined;
    case 'Won':
      return Icons.check_circle_outline;
    default:
      return Icons.track_changes;
  }
}

IconData activityIcon(String type) {
  switch (type) {
    case 'اتصال':
      return Icons.phone;
    case 'اجتماع':
      return Icons.groups;
    case 'عرض':
      return Icons.description;
    case 'صفقة':
      return Icons.monetization_on;
    default:
      return Icons.event_note;
  }
}

_HealthStatus healthStatus(int score) {
  if (score >= 70) {
    return const _HealthStatus(
      label: 'Healthy',
      explanation: 'العميل نشط والتفاعل معه جيد.',
    );
  }

  if (score >= 50) {
    return const _HealthStatus(
      label: 'Attention',
      explanation: 'العميل يحتاج متابعة أقرب.',
    );
  }

  return const _HealthStatus(
    label: 'Risk',
    explanation: 'هناك مؤشرات تستدعي تدخلاً سريعاً.',
  );
}

class _HealthStatus {
  const _HealthStatus({
    required this.label,
    required this.explanation,
  });

  final String label;
  final String explanation;
}