import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiBaseUrl = 'http://10.0.2.2:3000/api';

const Color primaryColor = Color(0xFF155EEF);
const Color successColor = Color(0xFF12B76A);
const Color warningColor = Color(0xFFF79009);
const Color dangerColor = Color(0xFFF04438);

const List<String> opportunityStages = [
  'جديد',
  'مؤهل',
  'اجتماع',
  'عرض سعر',
  'تفاوض',
  'مغلقة',
  'خاسرة',
];

const List<String> taskStatuses = [
  'مفتوحة',
  'قيد التنفيذ',
  'مكتملة',
];

const List<String> priorities = [
  'عالية',
  'متوسطة',
  'منخفضة',
];

const List<String> activityTypes = [
  'مكالمة',
  'زيارة',
  'اجتماع',
  'بريد',
  'ملاحظة',
];

String money(num value) {
  return '\$${value.toStringAsFixed(0)}';
}

String shortDate(String? value) {
  if (value == null || value.isEmpty) {
    return '-';
  }

  return value.length >= 10 ? value.substring(0, 10) : value;
}

bool isOverdue(String? date) {
  if (date == null || date.isEmpty) {
    return false;
  }

  final d = DateTime.tryParse(date);

  if (d == null) {
    return false;
  }

  final today = DateTime.now();
  final t = DateTime(today.year, today.month, today.day);

  return d.isBefore(t);
}

class DemoStore {
  final SharedPreferences prefs;

  DemoStore(this.prefs);

  List<Map<String, dynamic>> _list(String key) {
    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _save(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    await prefs.setString(key, jsonEncode(data));
  }

  List<Map<String, dynamic>> get customers {
    return _list('demo_customers');
  }

  List<Map<String, dynamic>> get opportunities {
    return _list('demo_opportunities');
  }

  List<Map<String, dynamic>> get tasks {
    return _list('demo_tasks');
  }

  List<Map<String, dynamic>> get activities {
    return _list('demo_activities');
  }

  Future<void> initialize() async {
    if (prefs.getBool('demo_initialized') == true) {
      return;
    }

    await reset();
    await prefs.setBool('demo_initialized', true);
  }

  Future<void> reset() async {
    final now = DateTime.now().toIso8601String();

    await _save('demo_customers', [
      {
        'id': 'c1',
        'name': 'مؤسسة البكري للكهرباء والطاقة الشمسية',
        'contactName': 'محمد البكري',
        'phone': '777000001',
        'email': 'info@bakri.example',
        'sector': 'الكهرباء والطاقة الشمسية',
        'status': 'نشط',
        'notes': 'عميل استراتيجي في مجال الطاقة الشمسية.',
      },
      {
        'id': 'c2',
        'name': 'شركة النور التجارية',
        'contactName': 'أحمد النور',
        'phone': '777000002',
        'email': 'sales@alnoor.example',
        'sector': 'تجارة عامة',
        'status': 'نشط',
        'notes': 'فرص توسع محتملة.',
      },
      {
        'id': 'c3',
        'name': 'مؤسسة الأفق للمقاولات',
        'contactName': 'علي الأفق',
        'phone': '777000003',
        'email': 'info@alofoq.example',
        'sector': 'مقاولات',
        'status': 'متابعة',
        'notes': 'يحتاج إلى متابعة دورية.',
      },
    ]);

    await _save('demo_opportunities', [
      {
        'id': 'o1',
        'customerId': 'c1',
        'title': 'مشروع منظومة طاقة شمسية',
        'value': 75000,
        'probability': 60,
        'stage': 'عرض سعر',
        'expectedClose': '2026-10-22',
      },
      {
        'id': 'o2',
        'customerId': 'c2',
        'title': 'توريد معدات كهربائية',
        'value': 50000,
        'probability': 40,
        'stage': 'مؤهل',
        'expectedClose': '2026-10-15',
      },
      {
        'id': 'o3',
        'customerId': 'c3',
        'title': 'مشروع تجهيز كهربائي',
        'value': 60000,
        'probability': 75,
        'stage': 'تفاوض',
        'expectedClose': '2026-11-05',
      },
    ]);

    await _save('demo_tasks', [
      {
        'id': 't1',
        'customerId': 'c1',
        'title': 'متابعة عرض مشروع الطاقة الشمسية',
        'priority': 'عالية',
        'dueDate': '2026-10-04',
        'status': 'مفتوحة',
      },
      {
        'id': 't2',
        'customerId': 'c2',
        'title': 'الاتصال بالعميل',
        'priority': 'متوسطة',
        'dueDate': '2026-10-06',
        'status': 'قيد التنفيذ',
      },
      {
        'id': 't3',
        'customerId': 'c3',
        'title': 'مراجعة متطلبات المشروع',
        'priority': 'عالية',
        'dueDate': '2026-09-28',
        'status': 'مفتوحة',
      },
    ]);

    await _save('demo_activities', [
      {
        'id': 'a1',
        'customerId': 'c1',
        'type': 'اجتماع',
        'title': 'اجتماع مع العميل',
        'note': 'مناقشة عرض منظومة الطاقة الشمسية.',
        'date': now,
      },
      {
        'id': 'a2',
        'customerId': 'c2',
        'type': 'مكالمة',
        'title': 'مكالمة متابعة',
        'note': 'العميل مهتم بالتوسع.',
        'date': now,
      },
      {
        'id': 'a3',
        'customerId': 'c3',
        'type': 'زيارة',
        'title': 'زيارة ميدانية',
        'note': 'مراجعة احتياجات المشروع.',
        'date': now,
      },
    ]);
  }

  String newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> addCustomer(Map<String, dynamic> item) async {
    final data = customers;
    data.add(item);
    await _save('demo_customers', data);
  }

  Future<void> updateCustomer(Map<String, dynamic> item) async {
    final data = customers;
    final index = data.indexWhere((x) => x['id'] == item['id']);

    if (index >= 0) {
      data[index] = item;
      await _save('demo_customers', data);
    }
  }

  Future<void> deleteCustomer(String id) async {
    final customerData =
        customers.where((x) => x['id'] != id).toList();

    await _save('demo_customers', customerData);

    final opportunitiesData =
        opportunities.where((x) => x['customerId'] != id).toList();

    final tasksData =
        tasks.where((x) => x['customerId'] != id).toList();

    final activitiesData =
        activities.where((x) => x['customerId'] != id).toList();

    await _save(
      'demo_opportunities',
      opportunitiesData,
    );

    await _save(
      'demo_tasks',
      tasksData,
    );

    await _save(
      'demo_activities',
      activitiesData,
    );
  }

  Future<void> addOpportunity(
    Map<String, dynamic> item,
  ) async {
    final data = opportunities;
    data.add(item);

    await _save(
      'demo_opportunities',
      data,
    );
  }

  Future<void> updateOpportunity(
    Map<String, dynamic> item,
  ) async {
    final data = opportunities;

    final index = data.indexWhere(
      (x) => x['id'] == item['id'],
    );

    if (index >= 0) {
      data[index] = item;

      await _save(
        'demo_opportunities',
        data,
      );
    }
  }

  Future<void> addTask(
    Map<String, dynamic> item,
  ) async {
    final data = tasks;
    data.add(item);

    await _save(
      'demo_tasks',
      data,
    );
  }

  Future<void> updateTask(
    Map<String, dynamic> item,
  ) async {
    final data = tasks;

    final index = data.indexWhere(
      (x) => x['id'] == item['id'],
    );

    if (index >= 0) {
      data[index] = item;

      await _save(
        'demo_tasks',
        data,
      );
    }
  }

  Future<void> addActivity(
    Map<String, dynamic> item,
  ) async {
    final data = activities;
    data.add(item);

    await _save(
      'demo_activities',
      data,
    );
  }

  Map<String, dynamic>? customerById(String id) {
    for (final customer in customers) {
      if (customer['id'] == id) {
        return customer;
      }
    }

    return null;
  }

  String customerName(String id) {
    return customerById(id)?['name']?.toString() ??
        'عميل غير معروف';
  }

  double pipelineValue() {
    return opportunities
        .where(
          (o) =>
              o['stage'] != 'مغلقة' &&
              o['stage'] != 'خاسرة',
        )
        .fold<double>(
          0,
          (sum, o) =>
              sum + (o['value'] as num).toDouble(),
        );
  }

  double weightedPipeline() {
    return opportunities
        .where(
          (o) =>
              o['stage'] != 'مغلقة' &&
              o['stage'] != 'خاسرة',
        )
        .fold<double>(
          0,
          (sum, o) =>
              sum +
              (o['value'] as num).toDouble() *
                  ((o['probability'] as num).toDouble() /
                      100),
        );
  }

  double wonValue() {
    return opportunities
        .where((o) => o['stage'] == 'مغلقة')
        .fold<double>(
          0,
          (sum, o) =>
              sum + (o['value'] as num).toDouble(),
        );
  }

  int overdueTasks() {
    return tasks
        .where(
          (t) =>
              t['status'] != 'مكتملة' &&
              isOverdue(
                t['dueDate']?.toString(),
              ),
        )
        .length;
  }

  int highPriorityOpportunities() {
    return opportunities
        .where(
          (o) =>
              o['stage'] != 'مغلقة' &&
              o['stage'] != 'خاسرة' &&
              (o['probability'] as num) >= 60,
        )
        .length;
  }
}

class ApiClient {
  String? accessToken;
  String? refreshToken;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null)
          'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );

    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body)
            as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw Exception(
        data['message']?.toString() ??
            'حدث خطأ في الاتصال بالخادم',
      );
    }

    return data;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs =
      await SharedPreferences.getInstance();

  final store = DemoStore(prefs);

  await store.initialize();

  runApp(
    CrmBusinessApp(
      store: store,
    ),
  );
}

class CrmBusinessApp extends StatelessWidget {
  final DemoStore store;

  const CrmBusinessApp({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRM Business',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: primaryColor,
        scaffoldBackgroundColor:
            const Color(0xFFF7F8FA),
        inputDecorationTheme:
            InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: StartupPage(
        store: store,
      ),
    );
  }
}

class StartupPage extends StatelessWidget {
  final DemoStore store;

  const StartupPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration:
                        BoxDecoration(
                      color: primaryColor,
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.business_center,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CRM Business',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'منصة حديثة لإدارة العملاء والمبيعات والنمو',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HomePage(
                              store: store,
                              guest: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.rocket_launch,
                      ),
                      label: const Text(
                        'الدخول كضيف وتجربة النظام',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LoginPage(
                              store: store,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.login,
                      ),
                      label: const Text(
                        'تسجيل الدخول',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DemoInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DemoInfoCard extends StatelessWidget {
  const DemoInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          children: const [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: primaryColor,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تجربة Demo متكاملة',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'يمكنك إضافة العملاء والفرص والمهام والأنشطة وتغيير المراحل، وستتغير المؤشرات والتحليلات تلقائيًا.',
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final DemoStore store;

  const LoginPage({
    super.key,
    required this.store,
  });

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {
  final email =
      TextEditingController();

  final password =
      TextEditingController();

  bool loading = false;

  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = ApiClient();

      final data = await api.post(
        '/auth/login',
        {
          'email': email.text.trim(),
          'password': password.text,
        },
      );

      final prefs =
          await SharedPreferences
              .getInstance();

      if (data['accessToken'] != null) {
        await prefs.setString(
          'accessToken',
          data['accessToken'].toString(),
        );
      }

      if (data['refreshToken'] != null) {
        await prefs.setString(
          'refreshToken',
          data['refreshToken'].toString(),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            store: widget.store,
            guest: false,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تسجيل الدخول',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 520,
            ),
            child: Column(
              children: [
                TextField(
                  controller: email,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'البريد الإلكتروني',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'كلمة المرور',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    error!,
                    style:
                        const TextStyle(
                      color: dangerColor,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'دخول',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final DemoStore store;
  final bool guest;

  const HomePage({
    super.key,
    required this.store,
    required this.guest,
  });

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  int index = 0;

  Future<void> refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        store: widget.store,
        onChanged: refresh,
      ),
      CustomersPage(
        store: widget.store,
        onChanged: refresh,
      ),
      OpportunitiesPage(
        store: widget.store,
        onChanged: refresh,
      ),
      TasksPage(
        store: widget.store,
        onChanged: refresh,
      ),
      MorePage(
        store: widget.store,
        guest: widget.guest,
      ),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar:
          NavigationBar(
        selectedIndex: index,
        onDestinationSelected:
            (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
            ),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline,
            ),
            selectedIcon: Icon(
              Icons.people,
            ),
            label: 'العملاء',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.trending_up,
            ),
            label: 'الفرص',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.task_alt,
            ),
            label: 'المهام',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.more_horiz,
            ),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final DemoStore store;
  final VoidCallback onChanged;

  const DashboardPage({
    super.key,
    required this.store,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pipeline =
        store.pipelineValue();

    final weighted =
        store.weightedPipeline();

    final overdue =
        store.overdueTasks();

    final highPriority =
        store.highPriorityOpportunities();

    final topOpportunity =
        [...store.opportunities]
          ..removeWhere(
            (o) =>
                o['stage'] == 'مغلقة' ||
                o['stage'] == 'خاسرة',
          )
          ..sort(
            (a, b) =>
                ((b['value'] as num) *
                        (b['probability']
                            as num))
                    .compareTo(
              (a['value'] as num) *
                  (a['probability'] as num),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CRM Business',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: onChanged,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          onChanged();
        },
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            const Text(
              'صورة العمل اليوم',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'قراءة سريعة لما يحتاج انتباهك الآن.',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                KpiCard(
                  title: 'Pipeline',
                  value: money(
                    pipeline,
                  ),
                  icon:
                      Icons.account_balance_wallet,
                ),
                KpiCard(
                  title: 'Weighted',
                  value: money(
                    weighted,
                  ),
                  icon:
                      Icons.analytics,
                ),
                KpiCard(
                  title: 'العملاء',
                  value:
                      '${store.customers.length}',
                  icon: Icons.people,
                ),
                KpiCard(
                  title: 'مهام متأخرة',
                  value: '$overdue',
                  icon:
                      Icons.warning_amber,
                  danger:
                      overdue > 0,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionTitle(
              icon:
                  Icons.auto_awesome,
              title:
                  'Next Best Actions',
            ),
            const SizedBox(height: 8),
            ActionCard(
              icon: overdue > 0
                  ? Icons.warning_amber
                  : Icons.check_circle_outline,
              title: overdue > 0
                  ? 'لديك مهام متأخرة تحتاج متابعة'
                  : 'لا توجد مهام متأخرة',
              subtitle: overdue > 0
                  ? 'ابدأ بإغلاق المهام القديمة قبل إضافة أعمال جديدة.'
                  : 'استمر في المحافظة على انضباط المتابعة.',
            ),
            ActionCard(
              icon:
                  Icons.trending_up,
              title:
                  '$highPriority فرص ذات أولوية عالية',
              subtitle:
                  'راجع الفرص ذات الاحتمال الأعلى وقرب الإغلاق.',
            ),
            if (topOpportunity
                .isNotEmpty)
              ActionCard(
                icon:
                    Icons.star_outline,
                title:
                    'ركز على ${topOpportunity.first['title']}',
                subtitle:
                    '${money(topOpportunity.first['value'])} — احتمال ${topOpportunity.first['probability']}%',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OpportunityDetailsPage(
                        store: store,
                        opportunityId:
                            topOpportunity
                                .first['id']
                                .toString(),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            const SectionTitle(
              icon: Icons.insights,
              title:
                  'Executive Brief',
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملخص المدير',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                        height: 12),
                    Text(
                      'لديك ${store.opportunities.length} فرص، '
                      'منها $highPriority فرص ذات احتمال مرتفع. '
                      'قيمة الـPipeline الحالية ${money(pipeline)} '
                      'والقيمة المرجحة ${money(weighted)}.',
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

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool danger;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: danger
                  ? dangerColor
                  : primaryColor,
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Text(
              title,
              style:
                  const TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    primaryColor.withValues(
                  alpha: .1,
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                        height: 4),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_left,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomersPage extends StatefulWidget {
  final DemoStore store;
  final VoidCallback onChanged;

  const CustomersPage({
    super.key,
    required this.store,
    required this.onChanged,
  });

  @override
  State<CustomersPage> createState() =>
      _CustomersPageState();
}

class _CustomersPageState
    extends State<CustomersPage> {
  String query = '';

  Future<void> addCustomer() async {
    await showCustomerDialog(
      context,
      widget.store,
    );

    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        widget.store.customers
            .where((customer) {
      final q =
          query.toLowerCase();

      return customer['name']
              .toString()
              .toLowerCase()
              .contains(q) ||
          customer['contactName']
              .toString()
              .toLowerCase()
              .contains(q) ||
          customer['sector']
              .toString()
              .toLowerCase()
              .contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'العملاء',
        ),
        actions: [
          IconButton(
            onPressed:
                addCustomer,
            icon: const Icon(
              Icons.person_add_alt_1,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addCustomer,
        icon:
            const Icon(Icons.add),
        label:
            const Text('عميل'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                query = value;
              });
            },
            decoration:
                const InputDecoration(
              hintText:
                  'بحث عن عميل...',
              prefixIcon:
                  Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          ...filtered.map(
            (customer) =>
                CustomerCard(
              store:
                  widget.store,
              customer:
                  customer,
              onChanged: () {
                setState(() {});
                widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  final DemoStore store;
  final Map<String, dynamic> customer;
  final VoidCallback onChanged;

  const CustomerCard({
    super.key,
    required this.store,
    required this.customer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final customerId =
        customer['id'].toString();

    final opportunities =
        store.opportunities
            .where(
              (o) =>
                  o['customerId'] ==
                  customerId,
            )
            .toList();

    final value =
        opportunities.fold<double>(
      0,
      (sum, o) =>
          sum +
          (o['value'] as num)
              .toDouble(),
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Customer360Page(
                store: store,
                customerId:
                    customerId,
              ),
            ),
          );

          onChanged();
        },
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor:
                        primaryColor.withValues(
                      alpha: .1,
                    ),
                    child:
                        const Icon(
                      Icons.business,
                      color:
                          primaryColor,
                    ),
                  ),
                  const SizedBox(
                      width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer[
                                  'name']
                              .toString(),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(
                            height: 4),
                        Text(
                          customer[
                                  'sector']
                              .toString(),
                          style:
                              const TextStyle(
                            color:
                                Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left,
                  ),
                ],
              ),
              const Divider(
                height: 24,
              ),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Text(
                    'الحالة: ${customer['status']}',
                  ),
                  Text(
                    money(value),
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
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

Future<void> showCustomerDialog(
  BuildContext context,
  DemoStore store, {
  Map<String, dynamic>? existing,
}) async {
  final name =
      TextEditingController(
    text:
        existing?['name']
                ?.toString() ??
            '',
  );

  final contact =
      TextEditingController(
    text:
        existing?['contactName']
                ?.toString() ??
            '',
  );

  final phone =
      TextEditingController(
    text:
        existing?['phone']
                ?.toString() ??
            '',
  );

  final email =
      TextEditingController(
    text:
        existing?['email']
                ?.toString() ??
            '',
  );

  final sector =
      TextEditingController(
    text:
        existing?['sector']
                ?.toString() ??
            '',
  );

  final notes =
      TextEditingController(
    text:
        existing?['notes']
                ?.toString() ??
            '',
  );

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          existing == null
              ? 'إضافة عميل'
              : 'تعديل العميل',
        ),
        content:
            SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration:
                    const InputDecoration(
                  labelText:
                      'اسم الشركة',
                ),
              ),
              const SizedBox(
                  height: 10),
              TextField(
                controller: contact,
                decoration:
                    const InputDecoration(
                  labelText:
                      'جهة الاتصال',
                ),
              ),
              const SizedBox(
                  height: 10),
              TextField(
                controller: phone,
                decoration:
                    const InputDecoration(
                  labelText: 'الهاتف',
                ),
              ),
              const SizedBox(
                  height: 10),
              TextField(
                controller: email,
                decoration:
                    const InputDecoration(
                  labelText:
                      'البريد',
                ),
              ),
              const SizedBox(
                  height: 10),
              TextField(
                controller: sector,
                decoration:
                    const InputDecoration(
                  labelText:
                      'القطاع',
                ),
              ),
              const SizedBox(
                  height: 10),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration:
                    const InputDecoration(
                  labelText:
                      'ملاحظات',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              dialogContext,
            ),
            child:
                const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text
                  .trim()
                  .isEmpty) {
                return;
              }

              final item = {
                'id': existing?[
                        'id'] ??
                    store.newId(
                      'customer',
                    ),
                'name':
                    name.text.trim(),
                'contactName':
                    contact.text
                        .trim(),
                'phone':
                    phone.text.trim(),
                'email':
                    email.text.trim(),
                'sector':
                    sector.text.trim(),
                'status':
                    existing?[
                            'status'] ??
                        'نشط',
                'notes':
                    notes.text.trim(),
              };

              if (existing ==
                  null) {
                await store
                    .addCustomer(
                  item,
                );
              } else {
                await store
                    .updateCustomer(
                  item,
                );
              }

              if (dialogContext
                  .mounted) {
                Navigator.pop(
                  dialogContext,
                );
              }
            },
            child:
                const Text('حفظ'),
          ),
        ],
      );
    },
  );

  name.dispose();
  contact.dispose();
  phone.dispose();
  email.dispose();
  sector.dispose();
  notes.dispose();
}

class Customer360Page
    extends StatefulWidget {
  final DemoStore store;
  final String customerId;

  const Customer360Page({
    super.key,
    required this.store,
    required this.customerId,
  });

  @override
  State<Customer360Page> createState() =>
      _Customer360PageState();
}

class _Customer360PageState
    extends State<Customer360Page> {
  Future<void> addActivity() async {
    final title =
        TextEditingController();

    final note =
        TextEditingController();

    String type =
        activityTypes.first;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title:
                  const Text(
                'إضافة نشاط',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          type,
                      items:
                          activityTypes
                              .map(
                        (x) =>
                            DropdownMenuItem(
                          value: x,
                          child:
                              Text(x),
                        ),
                      )
                              .toList(),
                      onChanged:
                          (value) {
                        if (value !=
                            null) {
                          setDialogState(
                            () {
                              type =
                                  value;
                            },
                          );
                        }
                      },
                      decoration:
                          const InputDecoration(
                        labelText:
                            'نوع النشاط',
                      ),
                    ),
                    const SizedBox(
                        height: 10),
                    TextField(
                      controller:
                          title,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'العنوان',
                      ),
                    ),
                    const SizedBox(
                        height: 10),
                    TextField(
                      controller:
                          note,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'التفاصيل',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    dialogContext,
                  ),
                  child:
                      const Text(
                    'إلغاء',
                  ),
                ),
                FilledButton(
                  onPressed:
                      () async {
                    if (title
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    await widget
                        .store
                        .addActivity({
                      'id': widget
                          .store
                          .newId(
                        'activity',
                      ),
                      'customerId':
                          widget.customerId,
                      'type': type,
                      'title':
                          title.text
                              .trim(),
                      'note':
                          note.text
                              .trim(),
                      'date': DateTime
                              .now()
                          .toIso8601String(),
                    });

                    if (dialogContext
                        .mounted) {
                      Navigator.pop(
                        dialogContext,
                      );
                    }
                  },
                  child:
                      const Text(
                    'حفظ',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    title.dispose();
    note.dispose();

    setState(() {});
  }

  int calculateHealth({
    required List<
            Map<String, dynamic>>
        opportunities,
    required List<
            Map<String, dynamic>>
        tasks,
    required List<
            Map<String, dynamic>>
        activities,
  }) {
    var score = 0;

    if (activities.isNotEmpty) {
      score += 25;
    }

    if (opportunities.isNotEmpty) {
      score += 25;
    }

    if (tasks.any(
      (t) =>
          t['status'] == 'مكتملة',
    )) {
      score += 20;
    }

    if (opportunities.any(
      (o) =>
          (o['probability']
              as num) >=
          60,
    )) {
      score += 20;
    }

    if (!tasks.any(
      (t) =>
          t['status'] !=
              'مكتملة' &&
          isOverdue(
            t['dueDate']
                ?.toString(),
          ),
    )) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final customer =
        widget.store.customerById(
      widget.customerId,
    );

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(),
        body:
            const Center(
          child: Text(
            'العميل غير موجود',
          ),
        ),
      );
    }

    final opportunities =
        widget.store.opportunities
            .where(
              (o) =>
                  o['customerId'] ==
                  widget.customerId,
            )
            .toList();

    final tasks =
        widget.store.tasks
            .where(
              (t) =>
                  t['customerId'] ==
                  widget.customerId,
            )
            .toList();

    final activities =
        widget.store.activities
            .where(
              (a) =>
                  a['customerId'] ==
                  widget.customerId,
            )
            .toList()
          ..sort(
            (a, b) =>
                b['date']
                    .toString()
                    .compareTo(
                  a['date']
                      .toString(),
                ),
          );

    final health =
        calculateHealth(
      opportunities:
          opportunities,
      tasks: tasks,
      activities:
          activities,
    );

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Customer 360',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await showCustomerDialog(
                context,
                widget.store,
                existing:
                    customer,
              );

              setState(() {});
            },
            icon:
                const Icon(
              Icons.edit,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            addActivity,
        icon:
            const Icon(Icons.add),
        label:
            const Text('نشاط'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor:
                        primaryColor
                            .withValues(
                      alpha: .1,
                    ),
                    child:
                        const Icon(
                      Icons.business,
                      size: 34,
                      color:
                          primaryColor,
                    ),
                  ),
                  const SizedBox(
                      height: 12),
                  Text(
                    customer['name']
                        .toString(),
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                      height: 6),
                  Text(
                    customer[
                            'sector']
                        .toString(),
                  ),
                  const SizedBox(
                      height: 14),
                  HealthBadge(
                    score: health,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
              height: 14),
          Row(
            children: [
              Expanded(
                child: MiniStat(
                  title:
                      'الفرص',
                  value:
                      '${opportunities.length}',
                ),
              ),
              const SizedBox(
                  width: 10),
              Expanded(
                child: MiniStat(
                  title:
                      'المهام',
                  value:
                      '${tasks.length}',
                ),
              ),
              const SizedBox(
                  width: 10),
              Expanded(
                child: MiniStat(
                  title:
                      'الأنشطة',
                  value:
                      '${activities.length}',
                ),
              ),
            ],
          ),
          const SizedBox(
              height: 18),
          const SectionTitle(
            icon:
                Icons.trending_up,
            title: 'الفرص',
          ),
          const SizedBox(
              height: 8),
          ...opportunities.map(
            (o) =>
                OpportunityTile(
              store:
                  widget.store,
              opportunity: o,
              onChanged: () =>
                  setState(() {}),
            ),
          ),
          const SizedBox(
              height: 18),
          const SectionTitle(
            icon: Icons.timeline,
            title: 'Timeline',
          ),
          const SizedBox(
              height: 8),
          ...activities.map(
            (a) => Card(
              child: ListTile(
                leading:
                    const CircleAvatar(
                  child: Icon(
                    Icons.event_note,
                  ),
                ),
                title: Text(
                  a['title']
                      .toString(),
                ),
                subtitle: Text(
                  '${a['type']} • ${shortDate(a['date']?.toString())}\n${a['note']}',
                ),
              ),
            ),
          ),
          if (activities.isEmpty)
            const Card(
              child: Padding(
                padding:
                    EdgeInsets.all(18),
                child: Text(
                  'لا توجد أنشطة مسجلة بعد.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HealthBadge extends StatelessWidget {
  final int score;

  const HealthBadge({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (score >= 80) {
      color = successColor;
      label = 'Healthy';
    } else if (score >= 50) {
      color = warningColor;
      label = 'Attention';
    } else {
      color = dangerColor;
      label = 'At Risk';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration:
          BoxDecoration(
        color: color.withValues(
          alpha: .1,
        ),
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child: Text(
        '$label • $score/100',
        style: TextStyle(
          color: color,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  final String title;
  final String value;

  const MiniStat({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Text(
              title,
              style:
                  const TextStyle(
                color:
                    Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpportunitiesPage
    extends StatefulWidget {
  final DemoStore store;
  final VoidCallback onChanged;

  const OpportunitiesPage({
    super.key,
    required this.store,
    required this.onChanged,
  });

  @override
  State<OpportunitiesPage> createState() =>
      _OpportunitiesPageState();
}

class _OpportunitiesPageState
    extends State<OpportunitiesPage> {
  String selectedStage =
      'الكل';

  Future<void>
      addOpportunity() async {
    await showOpportunityDialog(
      context,
      widget.store,
    );

    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final stages = [
      'الكل',
      ...opportunityStages,
    ];

    final list =
        selectedStage == 'الكل'
            ? widget.store
                .opportunities
            : widget.store
                .opportunities
                .where(
                  (o) =>
                      o['stage'] ==
                      selectedStage,
                )
                .toList();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Sales Pipeline',
        ),
        actions: [
          IconButton(
            onPressed:
                addOpportunity,
            icon:
                const Icon(
              Icons.add_chart,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            addOpportunity,
        icon:
            const Icon(Icons.add),
        label:
            const Text('فرصة'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 46,
            child: ListView
                .separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  stages.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                width: 8,
              ),
              itemBuilder:
                  (_, index) {
                final stage =
                    stages[index];

                return ChoiceChip(
                  label:
                      Text(stage),
                  selected:
                      selectedStage ==
                          stage,
                  onSelected:
                      (_) {
                    setState(
                      () {
                        selectedStage =
                            stage;
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(
              height: 14),
          ...list.map(
            (o) =>
                OpportunityTile(
              store:
                  widget.store,
              opportunity: o,
              onChanged: () {
                setState(() {});
                widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OpportunityTile
    extends StatelessWidget {
  final DemoStore store;
  final Map<String, dynamic>
      opportunity;
  final VoidCallback onChanged;

  const OpportunityTile({
    super.key,
    required this.store,
    required this.opportunity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value =
        (opportunity['value']
                as num)
            .toDouble();

    final probability =
        opportunity[
            'probability'] as num;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OpportunityDetailsPage(
                store: store,
                opportunityId:
                    opportunity[
                            'id']
                        .toString(),
              ),
            ),
          );

          onChanged();
        },
        leading:
            CircleAvatar(
          backgroundColor:
              primaryColor
                  .withValues(
            alpha: .1,
          ),
          child:
              const Icon(
            Icons.trending_up,
            color:
                primaryColor,
          ),
        ),
        title: Text(
          opportunity[
                  'title']
              .toString(),
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${store.customerName(opportunity['customerId'].toString())}\n'
          '${opportunity['stage']} • ${probability.toInt()}%',
        ),
        isThreeLine: true,
        trailing:
            Text(
          money(value),
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

Future<void>
    showOpportunityDialog(
  BuildContext context,
  DemoStore store, {
  Map<String, dynamic>? existing,
}) async {
  final title =
      TextEditingController(
    text:
        existing?['title']
                ?.toString() ??
            '',
  );

  final value =
      TextEditingController(
    text:
        existing?['value']
                ?.toString() ??
            '',
  );

  final probability =
      TextEditingController(
    text:
        existing?['probability']
                ?.toString() ??
            '50',
  );

  String? customerId =
      existing?['customerId']
          ?.toString();

  String stage =
      existing?['stage']
              ?.toString() ??
          'جديد';

  if (customerId == null &&
      store.customers.isNotEmpty) {
    customerId =
        store.customers.first[
                'id']
            .toString();
  }

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder:
            (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existing == null
                  ? 'إضافة فرصة'
                  : 'تعديل الفرصة',
            ),
            content:
                SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        customerId,
                    items: store
                        .customers
                        .map(
                      (c) =>
                          DropdownMenuItem(
                        value: c['id']
                            .toString(),
                        child: Text(
                          c['name']
                              .toString(),
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged:
                        (value) {
                      setDialogState(
                        () {
                          customerId =
                              value;
                        },
                      );
                    },
                    decoration:
                        const InputDecoration(
                      labelText:
                          'العميل',
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  TextField(
                    controller: title,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'اسم الفرصة',
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  TextField(
                    controller: value,
                    keyboardType:
                        TextInputType
                            .number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'القيمة',
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  TextField(
                    controller:
                        probability,
                    keyboardType:
                        TextInputType
                            .number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'احتمال الإغلاق %',
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        stage,
                    items:
                        opportunityStages
                            .map(
                      (x) =>
                          DropdownMenuItem(
                        value: x,
                        child:
                            Text(x),
                      ),
                    )
                            .toList(),
                    onChanged:
                        (v) {
                      if (v !=
                          null) {
                        setDialogState(
                          () {
                            stage =
                                v;
                          },
                        );
                      }
                    },
                    decoration:
                        const InputDecoration(
                      labelText:
                          'المرحلة',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                ),
                child:
                    const Text(
                  'إلغاء',
                ),
              ),
              FilledButton(
                onPressed:
                    () async {
                  if (customerId ==
                          null ||
                      title.text
                          .trim()
                          .isEmpty ||
                      value.text
                          .trim()
                          .isEmpty) {
                    return;
                  }

                  final item = {
                    'id': existing?[
                            'id'] ??
                        store.newId(
                          'opportunity',
                        ),
                    'customerId':
                        customerId,
                    'title':
                        title.text
                            .trim(),
                    'value':
                        double.tryParse(
                              value.text
                                  .trim(),
                            ) ??
                            0,
                    'probability':
                        int.tryParse(
                              probability
                                  .text
                                  .trim(),
                            ) ??
                            50,
                    'stage':
                        stage,
                    'expectedClose':
                        existing?[
                                'expectedClose'] ??
                            DateTime
                                .now()
                                .add(
                                  const Duration(
                                    days:
                                        30,
                                  ),
                                )
                                .toIso8601String()
                                .substring(
                                  0,
                                  10,
                                ),
                  };

                  if (existing ==
                      null) {
                    await store
                        .addOpportunity(
                      item,
                    );
                  } else {
                    await store
                        .updateOpportunity(
                      item,
                    );
                  }

                  if (dialogContext
                      .mounted) {
                    Navigator.pop(
                      dialogContext,
                    );
                  }
                },
                child:
                    const Text(
                  'حفظ',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  title.dispose();
  value.dispose();
  probability.dispose();
}

class OpportunityDetailsPage
    extends StatefulWidget {
  final DemoStore store;
  final String opportunityId;

  const OpportunityDetailsPage({
    super.key,
    required this.store,
    required this.opportunityId,
  });

  @override
  State<OpportunityDetailsPage>
      createState() =>
          _OpportunityDetailsPageState();
}

class _OpportunityDetailsPageState
    extends State<
        OpportunityDetailsPage> {
  Map<String, dynamic>?
      get opportunity {
    for (final o
        in widget.store
            .opportunities) {
      if (o['id'].toString() ==
          widget.opportunityId) {
        return o;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final o = opportunity;

    if (o == null) {
      return Scaffold(
        appBar: AppBar(),
        body:
            const Center(
          child: Text(
            'الفرصة غير موجودة',
          ),
        ),
      );
    }

    final value =
        (o['value'] as num)
            .toDouble();

    final probability =
        (o['probability']
                as num)
            .toDouble();

    final weighted =
        value *
            probability /
            100;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Opportunity',
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await showOpportunityDialog(
                context,
                widget.store,
                existing: o,
              );

              setState(() {});
            },
            icon:
                const Icon(
              Icons.edit,
            ),
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.trending_up,
                    size: 50,
                    color:
                        primaryColor,
                  ),
                  const SizedBox(
                      height: 12),
                  Text(
                    o['title']
                        .toString(),
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                      height: 8),
                  Text(
                    widget.store
                        .customerName(
                      o['customerId']
                          .toString(),
                    ),
                  ),
                  const SizedBox(
                      height: 20),
                  Row(
                    children: [
                      Expanded(
                        child:
                            MiniStat(
                          title:
                              'القيمة',
                          value:
                              money(
                            value,
                          ),
                        ),
                      ),
                      const SizedBox(
                          width: 8),
                      Expanded(
                        child:
                            MiniStat(
                          title:
                              'الاحتمال',
                          value:
                              '${probability.toInt()}%',
                        ),
                      ),
                      const SizedBox(
                          width: 8),
                      Expanded(
                        child:
                            MiniStat(
                          title:
                              'مرجح',
                          value:
                              money(
                            weighted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
              height: 18),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    icon: Icons
                        .auto_awesome,
                    title:
                        'Opportunity Intelligence',
                  ),
                  const SizedBox(
                      height: 14),
                  Text(
                    probability >= 70
                        ? 'الفرصة ذات احتمال إغلاق مرتفع. ركز على إزالة أي عائق متبقٍ قبل موعد الإغلاق.'
                        : probability >=
                                40
                            ? 'الفرصة في منطقة تحتاج متابعة. تسجيل نشاط جديد أو اجتماع قد يرفع وضوح المسار.'
                            : 'الفرصة تحتاج qualification ومعلومات إضافية قبل زيادة توقعات الإغلاق.',
                  ),
                  const SizedBox(
                      height: 14),
                  const Text(
                    'Next Best Action',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                  const SizedBox(
                      height: 6),
                  Text(
                    o['stage'] ==
                            'عرض سعر'
                        ? 'جدولة اجتماع لمراجعة العرض.'
                        : o['stage'] ==
                                'تفاوض'
                            ? 'تأكيد الاعتراضات والشروط النهائية.'
                            : 'تسجيل النشاط التالي مع العميل.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
              height: 18),
          const Text(
            'تغيير المرحلة',
            style:
                TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
              height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                opportunityStages
                    .map(
              (stage) {
                return ChoiceChip(
                  label:
                      Text(stage),
                  selected:
                      o['stage'] ==
                          stage,
                  onSelected:
                      (_) async {
                    final updated =
                        Map<String,
                            dynamic>.from(
                      o,
                    );

                    updated[
                            'stage'] =
                        stage;

                    await widget
                        .store
                        .updateOpportunity(
                      updated,
                    );

                    setState(() {});
                  },
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}

class TasksPage
    extends StatefulWidget {
  final DemoStore store;
  final VoidCallback onChanged;

  const TasksPage({
    super.key,
    required this.store,
    required this.onChanged,
  });

  @override
  State<TasksPage> createState() =>
      _TasksPageState();
}

class _TasksPageState
    extends State<TasksPage> {
  Future<void> addTask() async {
    await showTaskDialog(
      context,
      widget.store,
    );

    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final tasks =
        [...widget.store.tasks];

    tasks.sort(
      (a, b) =>
          a['dueDate']
              .toString()
              .compareTo(
            b['dueDate']
                .toString(),
          ),
    );

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('المهام'),
        actions: [
          IconButton(
            onPressed: addTask,
            icon:
                const Icon(
              Icons.add_task,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addTask,
        icon:
            const Icon(Icons.add),
        label:
            const Text('مهمة'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          ...tasks.map(
            (task) => TaskCard(
              store:
                  widget.store,
              task: task,
              onChanged: () {
                setState(() {});
                widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard
    extends StatelessWidget {
  final DemoStore store;
  final Map<String, dynamic> task;
  final VoidCallback onChanged;

  const TaskCard({
    super.key,
    required this.store,
    required this.task,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final overdue =
        task['status'] !=
                'مكتملة' &&
            isOverdue(
              task['dueDate']
                  ?.toString(),
            );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: Icon(
          task['status'] ==
                  'مكتملة'
              ? Icons.check_circle
              : overdue
                  ? Icons.warning_amber
                  : Icons
                      .radio_button_unchecked,
          color:
              task['status'] ==
                      'مكتملة'
                  ? successColor
                  : overdue
                      ? dangerColor
                      : primaryColor,
        ),
        title: Text(
          task['title']
              .toString(),
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${store.customerName(task['customerId'].toString())}\n'
          '${task['priority']} • ${shortDate(task['dueDate']?.toString())}',
        ),
        isThreeLine: true,
        trailing:
            PopupMenuButton<
                String>(
          onSelected:
              (value) async {
            final updated =
                Map<String,
                    dynamic>.from(
              task,
            );

            updated['status'] =
                value;

            await store.updateTask(
              updated,
            );

            onChanged();
          },
          itemBuilder: (_) =>
              taskStatuses
                  .map(
            (status) =>
                PopupMenuItem(
              value: status,
              child:
                  Text(status),
            ),
          ).toList(),
        ),
      ),
    );
  }
}

Future<void> showTaskDialog(
  BuildContext context,
  DemoStore store,
) async {
  final title =
      TextEditingController();

  String? customerId =
      store.customers.isNotEmpty
          ? store.customers.first[
                  'id']
              .toString()
          : null;

  String priority =
      'متوسطة';

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder:
            (context, setDialogState) {
          return AlertDialog(
            title:
                const Text(
              'إضافة مهمة',
            ),
            content:
                SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        customerId,
                    items: store
                        .customers
                        .map(
                      (c) =>
                          DropdownMenuItem(
                        value:
                            c['id']
                                .toString(),
                        child: Text(
                          c['name']
                              .toString(),
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged:
                        (v) {
                      setDialogState(
                        () {
                          customerId =
                              v;
                        },
                      );
                    },
                    decoration:
                        const InputDecoration(
                      labelText:
                          'العميل',
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  TextField(
                    controller: title,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'المهمة',
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        priority,
                    items:
                        priorities
                            .map(
                      (x) =>
                          DropdownMenuItem(
                        value: x,
                        child:
                            Text(x),
                      ),
                    )
                            .toList(),
                    onChanged:
                        (v) {
                      if (v !=
                          null) {
                        setDialogState(
                          () {
                            priority =
                                v;
                          },
                        );
                      }
                    },
                    decoration:
                        const InputDecoration(
                      labelText:
                          'الأولوية',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                ),
                child:
                    const Text(
                  'إلغاء',
                ),
              ),
              FilledButton(
                onPressed:
                    () async {
                  if (customerId ==
                          null ||
                      title.text
                          .trim()
                          .isEmpty) {
                    return;
                  }

                  await store.addTask({
                    'id': store
                        .newId(
                      'task',
                    ),
                    'customerId':
                        customerId,
                    'title':
                        title.text
                            .trim(),
                    'priority':
                        priority,
                    'dueDate':
                        DateTime
                            .now()
                            .add(
                              const Duration(
                                days:
                                    1,
                              ),
                            )
                            .toIso8601String()
                            .substring(
                              0,
                              10,
                            ),
                    'status':
                        'مفتوحة',
                  });

                  if (dialogContext
                      .mounted) {
                    Navigator.pop(
                      dialogContext,
                    );
                  }
                },
                child:
                    const Text(
                  'حفظ',
                ),
              ),
            ],
          );
        },
      );
    },
  );

  title.dispose();
}

class MorePage
    extends StatelessWidget {
  final DemoStore store;
  final bool guest;

  const MorePage({
    super.key,
    required this.store,
    required this.guest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('المزيد'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.analytics,
              ),
              title:
                  const Text(
                'التحليلات',
              ),
              subtitle:
                  const Text(
                'Sales, Conversion & Forecast',
              ),
              trailing:
                  const Icon(
                Icons.chevron_left,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AnalyticsPage(
                      store: store,
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.auto_awesome,
              ),
              title:
                  const Text(
                'Smart Assistant',
              ),
              subtitle:
                  const Text(
                'توصيات ذكية مبنية على بيانات CRM',
              ),
              trailing:
                  const Icon(
                Icons.chevron_left,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AssistantPage(
                      store: store,
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.restart_alt,
              ),
              title:
                  const Text(
                'إعادة بيانات التجربة',
              ),
              subtitle:
                  const Text(
                'إرجاع Demo إلى الحالة الأصلية',
              ),
              onTap: () async {
                await store.reset();

                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تمت إعادة بيانات Demo',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          if (guest)
            Card(
              child: ListTile(
                leading:
                    const Icon(
                  Icons.logout,
                ),
                title:
                    const Text(
                  'الخروج من وضع الضيف',
                ),
                onTap: () {
                  Navigator.popUntil(
                    context,
                    (route) =>
                        route.isFirst,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class AnalyticsPage
    extends StatelessWidget {
  final DemoStore store;

  const AnalyticsPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final pipeline =
        store.pipelineValue();

    final weighted =
        store.weightedPipeline();

    final won =
        store.wonValue();

    final open = store
        .opportunities
        .where(
          (o) =>
              o['stage'] !=
                  'مغلقة' &&
              o['stage'] !=
                  'خاسرة',
        )
        .length;

    final closed = store
        .opportunities
        .where(
          (o) =>
              o['stage'] ==
              'مغلقة',
        )
        .length;

    final conversion =
        store.opportunities.isEmpty
            ? 0
            : closed /
                store.opportunities
                    .length *
                100;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Analytics',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const SectionTitle(
            icon: Icons.analytics,
            title:
                'Sales Intelligence',
          ),
          const SizedBox(
              height: 14),
          KpiCard(
            title: 'Pipeline',
            value:
                money(pipeline),
            icon:
                Icons.trending_up,
          ),
          KpiCard(
            title:
                'Weighted Forecast',
            value:
                money(weighted),
            icon:
                Icons.auto_graph,
          ),
          KpiCard(
            title: 'Won',
            value: money(won),
            icon:
                Icons.verified,
          ),
          KpiCard(
            title: 'Conversion',
            value:
                '${conversion.toStringAsFixed(1)}%',
            icon:
                Icons.swap_horiz,
          ),
          const SizedBox(
              height: 18),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Pipeline by Stage',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                  const SizedBox(
                      height: 14),
                  ...opportunityStages
                      .map(
                    (stage) {
                      final items =
                          store
                              .opportunities
                              .where(
                                (o) =>
                                    o['stage'] ==
                                    stage,
                              )
                              .toList();

                      final total =
                          items.fold<
                              double>(
                        0,
                        (sum, o) =>
                            sum +
                            (o['value']
                                    as num)
                                .toDouble(),
                      );

                      return Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child:
                                  Text(
                                stage,
                              ),
                            ),
                            Expanded(
                              child:
                                  LinearProgressIndicator(
                                value: pipeline ==
                                        0
                                    ? 0
                                    : (total /
                                            pipeline)
                                        .clamp(
                                            0,
                                            1),
                              ),
                            ),
                            const SizedBox(
                                width: 10),
                            Text(
                              money(
                                total,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
              height: 18),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Text(
                'عدد الفرص المفتوحة: $open\n'
                'عدد الفرص المغلقة: $closed\n'
                'قيمة الـPipeline: ${money(pipeline)}\n'
                'القيمة المرجحة: ${money(weighted)}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AssistantPage
    extends StatelessWidget {
  final DemoStore store;

  const AssistantPage({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final actions =
        <String>[];

    if (store.overdueTasks() >
        0) {
      actions.add(
        'ابدأ بالمهام المتأخرة وعددها ${store.overdueTasks()}.',
      );
    }

    final opportunities =
        [...store.opportunities]
          ..removeWhere(
            (o) =>
                o['stage'] ==
                    'مغلقة' ||
                o['stage'] ==
                    'خاسرة',
          )
          ..sort(
            (a, b) =>
                ((b['value']
                            as num) *
                        (b['probability']
                            as num))
                    .compareTo(
              (a['value'] as num) *
                  (a['probability']
                      as num),
            ),
          );

    if (opportunities
        .isNotEmpty) {
      final o =
          opportunities.first;

      actions.add(
        'ركز على فرصة "${o['title']}" بقيمة '
        '${money((o['value'] as num).toDouble())} '
        'واحتمال ${o['probability']}%.',
      );
    }

    if (store.activities
        .isEmpty) {
      actions.add(
        'ابدأ بتسجيل أنشطة العملاء لتحسين Customer Health.',
      );
    }

    if (actions.isEmpty) {
      actions.add(
        'لا توجد تنبيهات حرجة. استمر في متابعة العملاء.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Smart Assistant',
        ),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    child: Icon(
                      Icons
                          .auto_awesome,
                      size: 34,
                    ),
                  ),
                  const SizedBox(
                      height: 14),
                  const Text(
                    'مساعد CRM Business',
                    style:
                        TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                  const SizedBox(
                      height: 8),
                  const Text(
                    'تحليل محلي لبيانات Demo وتحديد الإجراءات التالية.',
                    textAlign:
                        TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
              height: 16),
          const SectionTitle(
            icon:
                Icons.lightbulb_outline,
            title:
                'التوصيات',
          ),
          const SizedBox(
              height: 8),
          ...actions
              .asMap()
              .entries
              .map(
            (entry) => Card(
              child: ListTile(
                leading:
                    CircleAvatar(
                  child: Text(
                    '${entry.key + 1}',
                  ),
                ),
                title: Text(
                  entry.value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}