import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);

void main() {
  runApp(const CrmApp());
}

/* =========================================================
   API CLIENT
   ========================================================= */

class ApiClient {
  Future<String?> _token() async {
    final s = await SharedPreferences.getInstance();
    return s.getString('accessToken');
  }

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$apiBase$path');

    switch (method) {
      case 'POST':
        return http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );

      case 'PATCH':
        return http.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );

      case 'DELETE':
        return http.delete(
          uri,
          headers: headers,
        );

      default:
        return http.get(
          uri,
          headers: headers,
        );
    }
  }

  Future<dynamic> parse(
    Future<http.Response> request,
  ) async {
    final response = await request;

    dynamic data;

    if (response.body.trim().isEmpty) {
      data = {};
    } else {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = {'message': response.body};
      }
    }

    if (response.statusCode >= 400) {
      String message = 'حدث خطأ في الخادم';

      if (data is Map && data['message'] != null) {
        final m = data['message'];

        if (m is List) {
          message = m.join('، ');
        } else {
          message = m.toString();
        }
      }

      throw Exception(message);
    }

    return data;
  }

  Future<dynamic> get(String path) {
    return parse(request('GET', path));
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) {
    return parse(
      request(
        'POST',
        path,
        body: body,
      ),
    );
  }
}

final api = ApiClient();

/* =========================================================
   LOCAL DEMO DATABASE
   ========================================================= */

class DemoStore {
  static const customersKey = 'demo_customers';
  static const opportunitiesKey = 'demo_opportunities';
  static const tasksKey = 'demo_tasks';
  static const activitiesKey = 'demo_activities';

  static Future<SharedPreferences> _prefs() {
    return SharedPreferences.getInstance();
  }

  static Future<void> initialize() async {
    final p = await _prefs();

    if (!p.containsKey(customersKey)) {
      await saveCustomers([
        {
          'id': 'C001',
          'name': 'شركة النور للتجارة',
          'phone': '777000001',
          'email': 'info@noor.example',
          'company': 'شركة النور للتجارة',
          'address': 'صنعاء',
          'status': 'نشط',
        },
        {
          'id': 'C002',
          'name': 'مؤسسة البكري للطاقة',
          'phone': '777000002',
          'email': 'info@bakri.example',
          'company': 'مؤسسة البكري للطاقة',
          'address': 'صنعاء',
          'status': 'نشط',
        },
        {
          'id': 'C003',
          'name': 'شركة المستقبل',
          'phone': '777000003',
          'email': 'info@future.example',
          'company': 'شركة المستقبل',
          'address': 'تعز',
          'status': 'نشط',
        },
        {
          'id': 'C004',
          'name': 'مؤسسة النجاح',
          'phone': '777000004',
          'email': 'info@success.example',
          'company': 'مؤسسة النجاح',
          'address': 'إب',
          'status': 'نشط',
        },
      ]);
    }

    if (!p.containsKey(opportunitiesKey)) {
      await saveOpportunities([
        {
          'id': 'O001',
          'name': 'توريد أجهزة مكتبية',
          'customer': 'شركة النور للتجارة',
          'stage': 'مؤهل',
          'value': 50000,
        },
        {
          'id': 'O002',
          'name': 'مشروع طاقة شمسية',
          'customer': 'مؤسسة البكري للطاقة',
          'stage': 'عرض سعر',
          'value': 75000,
        },
        {
          'id': 'O003',
          'name': 'عقد خدمات سنوي',
          'customer': 'شركة المستقبل',
          'stage': 'تفاوض',
          'value': 60000,
        },
      ]);
    }

    if (!p.containsKey(tasksKey)) {
      await saveTasks([
        {
          'id': 'T001',
          'title': 'الاتصال بالعميل',
          'customer': 'شركة النور للتجارة',
          'priority': 'عالية',
          'status': 'مفتوحة',
        },
        {
          'id': 'T002',
          'title': 'إرسال عرض سعر',
          'customer': 'مؤسسة البكري للطاقة',
          'priority': 'متوسطة',
          'status': 'قيد التنفيذ',
        },
        {
          'id': 'T003',
          'title': 'متابعة فرصة المبيعات',
          'customer': 'شركة المستقبل',
          'priority': 'عالية',
          'status': 'مفتوحة',
        },
      ]);
    }

    if (!p.containsKey(activitiesKey)) {
      await saveActivities([
        {
          'id': 'A001',
          'customerId': 'C001',
          'title': 'مكالمة هاتفية',
          'description': 'تم التواصل مع العميل.',
          'date': '2026-10-01',
        },
        {
          'id': 'A002',
          'customerId': 'C002',
          'title': 'زيارة',
          'description': 'زيارة العميل ومناقشة احتياجاته.',
          'date': '2026-10-02',
        },
      ]);
    }
  }

  static Future<List<Map<String, dynamic>>> _list(
    String key,
  ) async {
    final p = await _prefs();
    final raw = p.getString(key);

    if (raw == null) return [];

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        return decoded
            .map(
              (e) => Map<String, dynamic>.from(e),
            )
            .toList();
      }
    } catch (_) {}

    return [];
  }

  static Future<void> _save(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    final p = await _prefs();

    await p.setString(
      key,
      jsonEncode(data),
    );
  }

  static Future<List<Map<String, dynamic>>> customers() {
    return _list(customersKey);
  }

  static Future<void> saveCustomers(
    List<Map<String, dynamic>> data,
  ) {
    return _save(customersKey, data);
  }

  static Future<List<Map<String, dynamic>>> opportunities() {
    return _list(opportunitiesKey);
  }

  static Future<void> saveOpportunities(
    List<Map<String, dynamic>> data,
  ) {
    return _save(opportunitiesKey, data);
  }

  static Future<List<Map<String, dynamic>>> tasks() {
    return _list(tasksKey);
  }

  static Future<void> saveTasks(
    List<Map<String, dynamic>> data,
  ) {
    return _save(tasksKey, data);
  }

  static Future<List<Map<String, dynamic>>> activities() {
    return _list(activitiesKey);
  }

  static Future<void> saveActivities(
    List<Map<String, dynamic>> data,
  ) {
    return _save(activitiesKey, data);
  }

  static Future<void> reset() async {
    final p = await _prefs();

    await p.remove(customersKey);
    await p.remove(opportunitiesKey);
    await p.remove(tasksKey);
    await p.remove(activitiesKey);

    await initialize();
  }
}

/* =========================================================
   SESSION
   ========================================================= */

Future<bool> isGuest() async {
  final p = await SharedPreferences.getInstance();

  return p.getBool('guestMode') ?? false;
}

Future<void> enableGuest() async {
  final p = await SharedPreferences.getInstance();

  await p.setBool('guestMode', true);

  await p.setString(
    'companyName',
    'شركة CRM التجريبية',
  );

  await p.setString(
    'guestOwner',
    'المستخدم التجريبي',
  );

  await p.remove('accessToken');
  await p.remove('refreshToken');

  await DemoStore.initialize();
}

Future<void> disableGuest() async {
  final p = await SharedPreferences.getInstance();

  await p.remove('guestMode');
  await p.remove('guestOwner');
  await p.remove('companyName');
}

/* =========================================================
   APP
   ========================================================= */

class CrmApp extends StatelessWidget {
  const CrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRM Business',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const StartupPage(),
    );
  }
}

/* =========================================================
   STARTUP
   ========================================================= */

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();

    start();
  }

  Future<void> start() async {
    final p = await SharedPreferences.getInstance();

    final guest = p.getBool('guestMode') ?? false;

    if (guest) {
      await DemoStore.initialize();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );

      return;
    }

    final token = p.getString('accessToken');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );

      return;
    }

    try {
      await api.get('/auth/me');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (_) {
      await p.remove('accessToken');
      await p.remove('refreshToken');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/* =========================================================
   LOGIN
   ========================================================= */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> login() async {
    if (email.text.trim().isEmpty ||
        password.text.isEmpty) {
      setState(() {
        error = 'يرجى إدخال البريد وكلمة المرور';
      });

      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await api.post(
        '/auth/login',
        {
          'email': email.text.trim(),
          'password': password.text,
        },
      );

      final p = await SharedPreferences.getInstance();

      await p.setString(
        'accessToken',
        data['accessToken'].toString(),
      );

      await p.setString(
        'refreshToken',
        data['refreshToken'].toString(),
      );

      await p.remove('guestMode');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst(
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

  Future<void> guest() async {
    setState(() {
      loading = true;
      error = null;
    });

    await enableGuest();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
      (_) => false,
    );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 440,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.business_center,
                    size: 80,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'CRM Business',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'نظام إدارة علاقات العملاء',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: email,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),

                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  FilledButton(
                    onPressed: loading ? null : login,
                    child: Text(
                      loading
                          ? 'جاري الدخول...'
                          : 'تسجيل الدخول',
                    ),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterPage(),
                              ),
                            );
                          },
                    child: const Text(
                      'إنشاء شركة جديدة',
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Divider(),

                  const SizedBox(height: 12),

                  FilledButton.icon(
                    onPressed: loading ? null : guest,
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    label: const Text(
                      'الدخول كضيف وتجربة التطبيق',
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'تجربة تفاعلية بدون خادم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   REGISTER
   ========================================================= */

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() =>
      _RegisterPageState();
}

class _RegisterPageState
    extends State<RegisterPage> {
  final company = TextEditingController();
  final owner = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> register() async {
    if (company.text.trim().isEmpty ||
        owner.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty) {
      setState(() {
        error = 'يرجى تعبئة جميع الحقول';
      });

      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await api.post(
        '/auth/register-company',
        {
          'companyName': company.text.trim(),
          'ownerName': owner.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
        },
      );

      final p = await SharedPreferences.getInstance();

      await p.setString(
        'accessToken',
        data['accessToken'].toString(),
      );

      await p.setString(
        'refreshToken',
        data['refreshToken'].toString(),
      );

      await p.remove('guestMode');

      await p.setString(
        'companyName',
        company.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
        (_) => false,
      );
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst(
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
    company.dispose();
    owner.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء شركة جديدة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: company,
            decoration: const InputDecoration(
              labelText: 'اسم الشركة',
              prefixIcon: Icon(Icons.business),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: owner,
            decoration: const InputDecoration(
              labelText: 'اسم المسؤول',
              prefixIcon: Icon(Icons.person),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              prefixIcon: Icon(Icons.email),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: Icon(Icons.lock),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ],

          const SizedBox(height: 18),

          FilledButton(
            onPressed: loading ? null : register,
            child: Text(
              loading
                  ? 'جاري إنشاء الشركة...'
                  : 'إنشاء الشركة',
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   HOME
   ========================================================= */

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    CustomersPage(),
    OpportunitiesPage(),
    TasksPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
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
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'الفرص',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'المهام',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   DASHBOARD
   ========================================================= */

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState
    extends State<DashboardPage> {
  bool guest = false;

  int customers = 0;
  int opportunities = 0;
  int tasks = 0;
  int overdue = 0;
  double pipeline = 0;

  String company = '';

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    final g = await isGuest();

    if (g) {
      final c = await DemoStore.customers();
      final o = await DemoStore.opportunities();
      final t = await DemoStore.tasks();

      final p =
          await SharedPreferences.getInstance();

      final total = o.fold<double>(
        0,
        (sum, item) =>
            sum +
            (double.tryParse(
                  item['value'].toString(),
                ) ??
                0),
      );

      if (!mounted) return;

      setState(() {
        guest = true;
        customers = c.length;
        opportunities = o
            .where(
              (e) => e['stage'] != 'مغلقة',
            )
            .length;
        tasks = t.length;
        overdue = t
            .where(
              (e) => e['status'] == 'متأخرة',
            )
            .length;
        pipeline = total;
        company =
            p.getString('companyName') ??
                'شركة CRM التجريبية';
      });

      return;
    }

    try {
      final data = await api.get('/dashboard');

      if (!mounted) return;

      setState(() {
        guest = false;

        if (data is Map) {
          customers =
              int.tryParse(
                    data['customers']
                            ?.toString() ??
                        '',
                  ) ??
                  0;

          opportunities =
              int.tryParse(
                    data['openOpportunities']
                            ?.toString() ??
                        '',
                  ) ??
                  0;

          tasks =
              int.tryParse(
                    data['tasks']?.toString() ??
                        '',
                  ) ??
                  0;

          overdue =
              int.tryParse(
                    data['tasksOverdue']
                            ?.toString() ??
                        '',
                  ) ??
                  0;
        }
      });
    } catch (_) {}
  }

  String money(double value) {
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (guest)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.visibility,
                  ),
                  title: const Text(
                    'وضع الضيف التفاعلي',
                  ),
                  subtitle: Text(
                    company,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Text(
              'مرحباً 👋',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall,
            ),

            const SizedBox(height: 4),

            Text(
              company,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Metric(
                  title: 'العملاء',
                  value: customers.toString(),
                  icon: Icons.people,
                ),
                Metric(
                  title: 'الفرص المفتوحة',
                  value: opportunities.toString(),
                  icon: Icons.trending_up,
                ),
                Metric(
                  title: 'المهام',
                  value: tasks.toString(),
                  icon: Icons.task_alt,
                ),
                Metric(
                  title: 'المتأخرة',
                  value: overdue.toString(),
                  icon: Icons.warning_amber,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.attach_money,
                ),
                title: const Text(
                  'قيمة الفرص',
                ),
                subtitle: const Text(
                  'إجمالي قيمة Pipeline التجريبي',
                ),
                trailing: Text(
                  money(pipeline),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.insights,
                ),
                title: const Text(
                  'التحليلات',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AnalyticsPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const Metric({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   CUSTOMERS
   ========================================================= */

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() =>
      _CustomersPageState();
}

class _CustomersPageState
    extends State<CustomersPage> {
  List<Map<String, dynamic>> items = [];

  final search = TextEditingController();

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    final guest = await isGuest();

    if (guest) {
      final data = await DemoStore.customers();

      if (!mounted) return;

      setState(() {
        items = data;
      });

      return;
    }

    try {
      final result = await api.get('/customers');

      if (!mounted) return;

      final list = <Map<String, dynamic>>[];

      if (result is List) {
        for (final item in result) {
          if (item is Map) {
            list.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      setState(() {
        items = list;
      });
    } catch (_) {}
  }

  List<Map<String, dynamic>> filtered() {
    final q = search.text.trim().toLowerCase();

    if (q.isEmpty) return items;

    return items.where((e) {
      final name =
          e['name']?.toString().toLowerCase() ?? '';

      final phone =
          e['phone']?.toString().toLowerCase() ?? '';

      final email =
          e['email']?.toString().toLowerCase() ?? '';

      return name.contains(q) ||
          phone.contains(q) ||
          email.contains(q);
    }).toList();
  }

  Future<void> addCustomer() async {
    final result = await showCustomerDialog(
      context,
    );

    if (result == null) return;

    final guest = await isGuest();

    if (!guest) return;

    final list = await DemoStore.customers();

    list.insert(
      0,
      {
        'id': 'C${DateTime.now().millisecondsSinceEpoch}',
        ...result,
      },
    );

    await DemoStore.saveCustomers(list);

    await load();
  }

  Future<void> editCustomer(
    Map<String, dynamic> customer,
  ) async {
    final result = await showCustomerDialog(
      context,
      existing: customer,
    );

    if (result == null) return;

    final list = await DemoStore.customers();

    final index = list.indexWhere(
      (e) => e['id'] == customer['id'],
    );

    if (index >= 0) {
      list[index] = {
        ...list[index],
        ...result,
      };
    }

    await DemoStore.saveCustomers(list);

    await load();
  }

  Future<void> deleteCustomer(
    Map<String, dynamic> customer,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text(
          'هل تريد حذف ${customer['name']}؟',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final list = await DemoStore.customers();

    list.removeWhere(
      (e) => e['id'] == customer['id'],
    );

    await DemoStore.saveCustomers(list);

    await load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = filtered();

    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCustomer,
        icon: const Icon(Icons.person_add),
        label: const Text('عميل جديد'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'بحث عن عميل',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          search.clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.clear,
                        ),
                      ),
              ),
            ),
          ),

          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد نتائج',
                    ),
                  )
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                      height: 1,
                    ),
                    itemBuilder:
                        (context, index) {
                      final customer =
                          visible[index];

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.person,
                          ),
                        ),
                        title: Text(
                          customer['name']
                                  ?.toString() ??
                              '',
                        ),
                        subtitle: Text(
                          customer['phone']
                                  ?.toString() ??
                              '',
                        ),
                        trailing: PopupMenuButton(
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
                          onSelected: (value) {
                            if (value == 'edit') {
                              editCustomer(
                                customer,
                              );
                            } else {
                              deleteCustomer(
                                customer,
                              );
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  Customer360Page(
                                customer: customer,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<Map<String, String>?> showCustomerDialog(
  BuildContext context, {
  Map<String, dynamic>? existing,
}) async {
  final name = TextEditingController(
    text: existing?['name']?.toString() ?? '',
  );

  final phone = TextEditingController(
    text: existing?['phone']?.toString() ?? '',
  );

  final email = TextEditingController(
    text: existing?['email']?.toString() ?? '',
  );

  final address = TextEditingController(
    text: existing?['address']?.toString() ?? '',
  );

  final result =
      await showDialog<Map<String, String>>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
        existing == null
            ? 'إضافة عميل'
            : 'تعديل العميل',
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'اسم العميل',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: address,
              decoration: const InputDecoration(
                labelText: 'العنوان',
              ),
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
          onPressed: () {
            if (name.text.trim().isEmpty) return;

            Navigator.pop(
              context,
              {
                'name': name.text.trim(),
                'phone': phone.text.trim(),
                'email': email.text.trim(),
                'address': address.text.trim(),
                'company': name.text.trim(),
                'status': 'نشط',
              },
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );

  name.dispose();
  phone.dispose();
  email.dispose();
  address.dispose();

  return result;
}

/* =========================================================
   CUSTOMER 360
   ========================================================= */

class Customer360Page extends StatefulWidget {
  final Map<String, dynamic> customer;

  const Customer360Page({
    super.key,
    required this.customer,
  });

  @override
  State<Customer360Page> createState() =>
      _Customer360PageState();
}

class _Customer360PageState
    extends State<Customer360Page> {
  List<Map<String, dynamic>> activities = [];

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    final all = await DemoStore.activities();

    final id = widget.customer['id'];

    if (!mounted) return;

    setState(() {
      activities = all
          .where(
            (e) => e['customerId'] == id,
          )
          .toList();
    });
  }

  Future<void> addActivity() async {
    final title = TextEditingController();
    final description = TextEditingController();

    final result =
        await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'إضافة نشاط',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'نوع النشاط',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              decoration: const InputDecoration(
                labelText: 'الوصف',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty) return;

              Navigator.pop(context, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != true) {
      title.dispose();
      description.dispose();
      return;
    }

    final list = await DemoStore.activities();

    list.insert(
      0,
      {
        'id':
            'A${DateTime.now().millisecondsSinceEpoch}',
        'customerId': widget.customer['id'],
        'title': title.text.trim(),
        'description': description.text.trim(),
        'date':
            DateTime.now().toString().substring(0, 10),
      },
    );

    await DemoStore.saveActivities(list);

    title.dispose();
    description.dispose();

    await load();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer 360'),
        actions: [
          IconButton(
            onPressed: addActivity,
            icon: const Icon(
              Icons.add_comment,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              (c['name']?.toString().isNotEmpty ?? false)
                  ? c['name']
                      .toString()
                      .substring(0, 1)
                  : '?',
              style: const TextStyle(
                fontSize: 30,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            c['name']?.toString() ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: Text(
                c['phone']?.toString() ??
                    'لا يوجد',
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
              title: Text(
                c['email']?.toString() ??
                    'لا يوجد',
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(
                c['address']?.toString() ??
                    'لا يوجد',
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'سجل التفاعل',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 8),

          if (activities.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'لا توجد أنشطة بعد',
                ),
              ),
            ),

          ...activities.map(
            (activity) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.history,
                ),
                title: Text(
                  activity['title']
                          ?.toString() ??
                      '',
                ),
                subtitle: Text(
                  '${activity['description'] ?? ''}\n${activity['date'] ?? ''}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   OPPORTUNITIES
   ========================================================= */

class OpportunitiesPage extends StatefulWidget {
  const OpportunitiesPage({super.key});

  @override
  State<OpportunitiesPage> createState() =>
      _OpportunitiesPageState();
}

class _OpportunitiesPageState
    extends State<OpportunitiesPage> {
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    if (await isGuest()) {
      final data =
          await DemoStore.opportunities();

      if (!mounted) return;

      setState(() {
        items = data;
      });

      return;
    }

    try {
      final result =
          await api.get('/opportunities/pipeline');

      if (!mounted) return;

      if (result is List) {
        setState(() {
          items = result
              .map(
                (e) => Map<String, dynamic>.from(e),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> addOpportunity() async {
    final result =
        await showOpportunityDialog(context);

    if (result == null) return;

    final list =
        await DemoStore.opportunities();

    list.insert(
      0,
      {
        'id':
            'O${DateTime.now().millisecondsSinceEpoch}',
        ...result,
      },
    );

    await DemoStore.saveOpportunities(list);

    await load();
  }

  Future<void> changeStage(
    Map<String, dynamic> item,
  ) async {
    final stages = [
      'جديد',
      'مؤهل',
      'عرض سعر',
      'تفاوض',
      'مغلقة',
    ];

    final selected =
        await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text(
          'مرحلة الفرصة',
        ),
        children: stages
            .map(
              (stage) => SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(
                  context,
                  stage,
                ),
                child: Text(stage),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null) return;

    final list =
        await DemoStore.opportunities();

    final index = list.indexWhere(
      (e) => e['id'] == item['id'],
    );

    if (index >= 0) {
      list[index]['stage'] = selected;
    }

    await DemoStore.saveOpportunities(list);

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفرص'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addOpportunity,
        icon: const Icon(Icons.add),
        label: const Text('فرصة جديدة'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'لا توجد فرص',
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder:
                  (_, __) => const Divider(
                height: 1,
              ),
              itemBuilder: (context, index) {
                final item = items[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.trending_up,
                    ),
                  ),
                  title: Text(
                    item['name']?.toString() ??
                        '',
                  ),
                  subtitle: Text(
                    '${item['customer'] ?? ''} • ${item['stage'] ?? ''}',
                  ),
                  trailing: Text(
                    item['value']?.toString() ??
                        '0',
                  ),
                  onTap: () =>
                      changeStage(item),
                );
              },
            ),
    );
  }
}

Future<Map<String, dynamic>?> showOpportunityDialog(
  BuildContext context,
) async {
  final name = TextEditingController();
  final customer = TextEditingController();
  final value = TextEditingController();

  final result =
      await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text(
        'إضافة فرصة',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'اسم الفرصة',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: customer,
            decoration: const InputDecoration(
              labelText: 'العميل',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: value,
            keyboardType:
                TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'القيمة',
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
          onPressed: () {
            if (name.text.trim().isEmpty) return;

            Navigator.pop(
              context,
              {
                'name': name.text.trim(),
                'customer': customer.text.trim(),
                'value':
                    double.tryParse(
                          value.text,
                        ) ??
                        0,
                'stage': 'جديد',
              },
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );

  name.dispose();
  customer.dispose();
  value.dispose();

  return result;
}

/* =========================================================
   TASKS
   ========================================================= */

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() =>
      _TasksPageState();
}

class _TasksPageState
    extends State<TasksPage> {
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    if (await isGuest()) {
      final data = await DemoStore.tasks();

      if (!mounted) return;

      setState(() {
        items = data;
      });

      return;
    }

    try {
      final result = await api.get('/tasks');

      if (!mounted) return;

      if (result is List) {
        setState(() {
          items = result
              .map(
                (e) => Map<String, dynamic>.from(e),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> addTask() async {
    final result = await showTaskDialog(context);

    if (result == null) return;

    final list = await DemoStore.tasks();

    list.insert(
      0,
      {
        'id':
            'T${DateTime.now().millisecondsSinceEpoch}',
        ...result,
      },
    );

    await DemoStore.saveTasks(list);

    await load();
  }

  Future<void> changeStatus(
    Map<String, dynamic> item,
  ) async {
    final statuses = [
      'مفتوحة',
      'قيد التنفيذ',
      'مكتملة',
      'متأخرة',
    ];

    final selected =
        await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text(
          'حالة المهمة',
        ),
        children: statuses
            .map(
              (status) => SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(
                  context,
                  status,
                ),
                child: Text(status),
              ),
            )
            .toList(),
      ),
    );

    if (selected == null) return;

    final list = await DemoStore.tasks();

    final index = list.indexWhere(
      (e) => e['id'] == item['id'],
    );

    if (index >= 0) {
      list[index]['status'] = selected;
    }

    await DemoStore.saveTasks(list);

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTask,
        icon: const Icon(Icons.add_task),
        label: const Text('مهمة جديدة'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'لا توجد مهام',
              ),
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder:
                  (_, __) => const Divider(
                height: 1,
              ),
              itemBuilder: (context, index) {
                final item = items[index];

                final completed =
                    item['status'] == 'مكتملة';

                return ListTile(
                  leading: Icon(
                    completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(
                    item['title']?.toString() ??
                        '',
                  ),
                  subtitle: Text(
                    '${item['customer'] ?? ''} • ${item['priority'] ?? ''}',
                  ),
                  trailing: Text(
                    item['status']?.toString() ??
                        '',
                  ),
                  onTap: () =>
                      changeStatus(item),
                );
              },
            ),
    );
  }
}

Future<Map<String, dynamic>?> showTaskDialog(
  BuildContext context,
) async {
  final title = TextEditingController();
  final customer = TextEditingController();

  String priority = 'متوسطة';

  final result =
      await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text(
            'إضافة مهمة',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'عنوان المهمة',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: customer,
                decoration: const InputDecoration(
                  labelText: 'العميل',
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
                    value: 'منخفضة',
                    child: Text('منخفضة'),
                  ),
                  DropdownMenuItem(
                    value: 'متوسطة',
                    child: Text('متوسطة'),
                  ),
                  DropdownMenuItem(
                    value: 'عالية',
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
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  {
                    'title': title.text.trim(),
                    'customer':
                        customer.text.trim(),
                    'priority': priority,
                    'status': 'مفتوحة',
                  },
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    ),
  );

  title.dispose();
  customer.dispose();

  return result;
}

/* =========================================================
   ANALYTICS
   ========================================================= */

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() =>
      _AnalyticsPageState();
}

class _AnalyticsPageState
    extends State<AnalyticsPage> {
  int customers = 0;
  int opportunities = 0;
  int tasks = 0;
  int completed = 0;
  double pipeline = 0;

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    if (await isGuest()) {
      final c = await DemoStore.customers();
      final o = await DemoStore.opportunities();
      final t = await DemoStore.tasks();

      final total = o.fold<double>(
        0,
        (sum, item) =>
            sum +
            (double.tryParse(
                  item['value'].toString(),
                ) ??
                0),
      );

      if (!mounted) return;

      setState(() {
        customers = c.length;
        opportunities = o.length;
        tasks = t.length;
        completed = t
            .where(
              (e) => e['status'] == 'مكتملة',
            )
            .length;
        pipeline = total;
      });

      return;
    }

    try {
      final data =
          await api.get('/analytics/dashboard');

      if (!mounted) return;

      if (data is Map) {
        setState(() {
          customers =
              int.tryParse(
                    data['customers']
                            ?.toString() ??
                        '',
                  ) ??
                  0;

          opportunities =
              int.tryParse(
                    data['opportunities']
                            ?.toString() ??
                        '',
                  ) ??
                  0;

          tasks =
              int.tryParse(
                    data['tasks']?.toString() ??
                        '',
                  ) ??
                  0;

          completed =
              int.tryParse(
                    data['completed']
                            ?.toString() ??
                        '',
                  ) ??
                  0;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final conversion = opportunities == 0
        ? 0
        : ((completed / opportunities) * 100)
            .round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحليلات'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'مؤشرات الأداء',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          analyticsCard(
            'إجمالي العملاء',
            customers.toString(),
            Icons.people,
          ),

          analyticsCard(
            'الفرص',
            opportunities.toString(),
            Icons.trending_up,
          ),

          analyticsCard(
            'إجمالي المهام',
            tasks.toString(),
            Icons.task,
          ),

          analyticsCard(
            'المهام المكتملة',
            completed.toString(),
            Icons.check_circle,
          ),

          analyticsCard(
            'قيمة Pipeline',
            pipeline.toStringAsFixed(0),
            Icons.attach_money,
          ),

          analyticsCard(
            'مؤشر الإنجاز',
            '$conversion%',
            Icons.insights,
          ),
        ],
      ),
    );
  }

  Widget analyticsCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   MORE
   ========================================================= */

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() =>
      _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool guest = false;

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    final value = await isGuest();

    if (!mounted) return;

    setState(() {
      guest = value;
    });
  }

  Future<void> resetDemo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'إعادة بيانات التجربة',
        ),
        content: const Text(
          'سيتم حذف التعديلات التي أجريتها وإعادة البيانات التجريبية الأصلية.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DemoStore.reset();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تمت إعادة بيانات التجربة',
        ),
      ),
    );

    setState(() {});
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();

    await p.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }

  Future<void> exitGuest() async {
    await disableGuest();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المزيد'),
      ),
      body: ListView(
        children: [
          if (guest)
            const Card(
              margin: EdgeInsets.all(12),
              child: ListTile(
                leading: Icon(
                  Icons.visibility,
                ),
                title: Text(
                  'وضع الضيف التفاعلي',
                ),
                subtitle: Text(
                  'يمكنك إضافة وتعديل البيانات وتجربة النظام.',
                ),
              ),
            ),

          ListTile(
            leading: const Icon(
              Icons.insights,
            ),
            title: const Text(
              'التحليلات',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AnalyticsPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.refresh,
            ),
            title: const Text(
              'إعادة بيانات التجربة',
            ),
            subtitle: const Text(
              'إرجاع Demo إلى الحالة الأصلية',
            ),
            onTap: guest ? resetDemo : null,
          ),

          const Divider(),

          ListTile(
            leading: Icon(
              guest
                  ? Icons.logout
                  : Icons.logout,
            ),
            title: Text(
              guest
                  ? 'الخروج من وضع الضيف'
                  : 'تسجيل الخروج',
            ),
            onTap: guest
                ? exitGuest
                : logout,
          ),
        ],
      ),
    );
  }
}