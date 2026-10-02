import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);

class ApiClient {
  Future<String?> _getToken() async {
    final storage = await SharedPreferences.getInstance();
    return storage.getString('accessToken');
  }

  Future<String?> _refreshToken() async {
    final storage = await SharedPreferences.getInstance();
    final refreshToken = storage.getString('refreshToken');

    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await http.post(
      Uri.parse('$apiBase/auth/refresh'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode >= 400) {
      return null;
    }

    final data = jsonDecode(response.body);

    if (data is! Map) {
      return null;
    }

    final accessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];

    if (accessToken == null || newRefreshToken == null) {
      return null;
    }

    await storage.setString(
      'accessToken',
      accessToken.toString(),
    );

    await storage.setString(
      'refreshToken',
      newRefreshToken.toString(),
    );

    return accessToken.toString();
  }

  Future<http.Response> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    final token = await _getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$apiBase$path');
    final encodedBody = body == null ? null : jsonEncode(body);

    late http.Response response;

    if (method == 'POST') {
      response = await http.post(
        uri,
        headers: headers,
        body: encodedBody,
      );
    } else if (method == 'PATCH') {
      response = await http.patch(
        uri,
        headers: headers,
        body: encodedBody,
      );
    } else if (method == 'DELETE') {
      response = await http.delete(
        uri,
        headers: headers,
      );
    } else {
      response = await http.get(
        uri,
        headers: headers,
      );
    }

    if (response.statusCode == 401 && retry) {
      final newToken = await _refreshToken();

      if (newToken != null) {
        return request(
          method,
          path,
          body: body,
          retry: false,
        );
      }
    }

    return response;
  }

  Future<dynamic> _parse(Future<http.Response> future) async {
    final response = await future;

    dynamic data;

    if (response.body.trim().isEmpty) {
      data = <String, dynamic>{};
    } else {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = <String, dynamic>{
          'message': response.body,
        };
      }
    }

    if (response.statusCode >= 400) {
      var message = 'حدث خطأ في الاتصال بالخادم';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      throw Exception(message);
    }

    return data;
  }

  Future<dynamic> get(String path) {
    return _parse(request('GET', path));
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) {
    return _parse(
      request(
        'POST',
        path,
        body: body,
      ),
    );
  }

  Future<dynamic> patch(
    String path,
    Map<String, dynamic> body,
  ) {
    return _parse(
      request(
        'PATCH',
        path,
        body: body,
      ),
    );
  }
}

final api = ApiClient();

Future<bool> guestModeEnabled() async {
  final storage = await SharedPreferences.getInstance();
  return storage.getBool('guestMode') ?? false;
}

Future<void> enableGuestMode() async {
  final storage = await SharedPreferences.getInstance();

  await storage.setBool('guestMode', true);
  await storage.setString('companyName', 'شركة تجريبية');
  await storage.setString('guestOwner', 'المستخدم التجريبي');
}

Future<void> disableGuestMode() async {
  final storage = await SharedPreferences.getInstance();

  await storage.remove('guestMode');
  await storage.remove('companyName');
  await storage.remove('guestOwner');
}

void main() {
  runApp(const CrmApp());
}

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
      ),
      home: const StartupPage(),
    );
  }
}

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final storage = await SharedPreferences.getInstance();

    final isGuest = storage.getBool('guestMode') ?? false;

    if (isGuest) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );

      return;
    }

    final token = storage.getString('accessToken');

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
      await storage.clear();

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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        error = 'يرجى إدخال البريد الإلكتروني وكلمة المرور';
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
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (data is! Map) {
        throw Exception('استجابة غير صحيحة من الخادم');
      }

      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      if (accessToken == null || refreshToken == null) {
        throw Exception('بيانات تسجيل الدخول غير مكتملة');
      }

      final storage = await SharedPreferences.getInstance();

      await storage.remove('guestMode');

      await storage.setString(
        'accessToken',
        accessToken.toString(),
      );

      await storage.setString(
        'refreshToken',
        refreshToken.toString(),
      );

      final company = data['company'];

      if (company is Map && company['name'] != null) {
        await storage.setString(
          'companyName',
          company['name'].toString(),
        );
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> loginAsGuest() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await enableGuestMode();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = 'تعذر تشغيل وضع الضيف';
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
    emailController.dispose();
    passwordController.dispose();
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
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.business_center,
                    size: 70,
                  ),
                  const SizedBox(height: 10),
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
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : login,
                    child: Text(
                      loading ? 'جاري الدخول...' : 'تسجيل الدخول',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                    child: const Text('إنشاء شركة جديدة'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: loading ? null : loginAsGuest,
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    label: const Text(
                      'الدخول كضيف وتجربة التطبيق',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'وضع الضيف يعمل بدون خادم وبدون إنشاء حساب حقيقي.',
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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final companyController = TextEditingController();
  final ownerController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? error;

  Future<void> register() async {
    if (companyController.text.trim().isEmpty ||
        ownerController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
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
          'companyName': companyController.text.trim(),
          'ownerName': ownerController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (data is! Map) {
        throw Exception('استجابة غير صحيحة من الخادم');
      }

      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      if (accessToken == null || refreshToken == null) {
        throw Exception('بيانات التسجيل غير مكتملة');
      }

      final storage = await SharedPreferences.getInstance();

      await storage.remove('guestMode');

      await storage.setString(
        'accessToken',
        accessToken.toString(),
      );

      await storage.setString(
        'refreshToken',
        refreshToken.toString(),
      );

      final company = data['company'];

      if (company is Map && company['name'] != null) {
        await storage.setString(
          'companyName',
          company['name'].toString(),
        );
      } else {
        await storage.setString(
          'companyName',
          companyController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
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
    companyController.dispose();
    ownerController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء شركة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: companyController,
            decoration: const InputDecoration(
              labelText: 'اسم الشركة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ownerController,
            decoration: const InputDecoration(
              labelText: 'اسم المسؤول',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'كلمة المرور',
              border: OutlineInputBorder(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
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
              loading ? 'جاري الإنشاء...' : 'إنشاء الشركة',
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

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
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
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
            label: 'الفرص',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  bool guest = false;
  String companyName = '';

  int customers = 0;
  int opportunities = 0;
  int tasks = 0;
  int overdue = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final storage = await SharedPreferences.getInstance();

    final isGuest = storage.getBool('guestMode') ?? false;

    final name = storage.getString('companyName') ?? '';

    if (isGuest) {
      if (!mounted) return;

      setState(() {
        guest = true;
        companyName = name;
        customers = 12;
        opportunities = 7;
        tasks = 18;
        overdue = 2;
        loading = false;
      });

      return;
    }

    try {
      final data = await api.get('/dashboard');

      if (!mounted) return;

      if (data is Map) {
        setState(() {
          companyName = name;
          customers = _toInt(data['customers']);
          opportunities = _toInt(data['openOpportunities']);
          tasks = _toInt(data['tasks']);
          overdue = _toInt(data['tasksOverdue']);
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل لوحة التحكم: $e',
          ),
        ),
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM Business'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (guest)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('وضع الضيف'),
                        subtitle: Text(
                          'هذه بيانات تجريبية محلية وليست بيانات حقيقية.',
                        ),
                      ),
                    ),
                  Text(
                    'مرحباً 👋',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  Text(
                    companyName.isEmpty
                        ? 'شركة جديدة'
                        : companyName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: [
                      MetricCard(
                        title: 'العملاء',
                        value: customers,
                        icon: Icons.people,
                      ),
                      MetricCard(
                        title: 'الفرص المفتوحة',
                        value: opportunities,
                        icon: Icons.trending_up,
                      ),
                      MetricCard(
                        title: 'المهام',
                        value: tasks,
                        icon: Icons.task_alt,
                      ),
                      MetricCard(
                        title: 'المتأخرة',
                        value: overdue,
                        icon: Icons.warning_amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.insights),
                      title: const Text('التقارير والتحليلات'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.card_membership),
                      title: const Text('الاشتراك'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionPage(),
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

class MetricCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(height: 6),
            Text(title),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final searchController = TextEditingController();

  bool loading = true;
  List<Map<String, String>> customers = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final guest = await guestModeEnabled();

    if (guest) {
      if (!mounted) return;

      setState(() {
        customers = [
          {
            'name': 'شركة النور التجارية',
            'phone': '777000001',
            'email': 'info@alnoor.demo',
          },
          {
            'name': 'مؤسسة المستقبل',
            'phone': '777000002',
            'email': 'future@demo.local',
          },
          {
            'name': 'عميل تجريبي',
            'phone': '777000003',
            'email': 'customer@demo.local',
          },
        ];
        loading = false;
      });

      return;
    }

    try {
      final query = searchController.text.trim();

      final path = query.isEmpty
          ? '/customers'
          : '/customers?q=${Uri.encodeQueryComponent(query)}';

      final data = await api.get(path);

      if (!mounted) return;

      final result = <Map<String, String>>[];

      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            result.add({
              'name': item['name']?.toString() ?? '',
              'phone': item['phone']?.toString() ?? '',
              'email': item['email']?.toString() ?? '',
            });
          }
        }
      }

      setState(() {
        customers = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل العملاء: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onSubmitted: (_) => load(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'بحث عن عميل',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: load,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : customers.isEmpty
                    ? const Center(
                        child: Text('لا يوجد عملاء'),
                      )
                    : ListView.separated(
                        itemCount: customers.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final customer = customers[index];

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              customer['name'] ?? '',
                            ),
                            subtitle: Text(
                              customer['phone']?.isNotEmpty == true
                                  ? customer['phone']!
                                  : customer['email'] ?? '',
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Customer360Page(
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

class Customer360Page extends StatelessWidget {
  final Map<String, String> customer;

  const Customer360Page({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer 360'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            customer['name'] ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: Text(
                customer['phone']?.isNotEmpty == true
                    ? customer['phone']!
                    : 'لا يوجد هاتف',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
              title: Text(
                customer['email']?.isNotEmpty == true
                    ? customer['email']!
                    : 'لا يوجد بريد',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OpportunitiesPage extends StatefulWidget {
  const OpportunitiesPage({super.key});

  @override
  State<OpportunitiesPage> createState() =>
      _OpportunitiesPageState();
}

class _OpportunitiesPageState extends State<OpportunitiesPage> {
  bool loading = true;
  List<Map<String, String>> opportunities = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final guest = await guestModeEnabled();

    if (guest) {
      if (!mounted) return;

      setState(() {
        opportunities = [
          {
            'name': 'توريد أجهزة مكتبية',
            'stage': 'QUALIFIED',
            'value': '50000',
          },
          {
            'name': 'مشروع طاقة شمسية',
            'stage': 'PROPOSAL',
            'value': '75000',
          },
          {
            'name': 'عقد خدمات سنوي',
            'stage': 'NEGOTIATION',
            'value': '60000',
          },
          {
            'name': 'توريد معدات',
            'stage': 'LEAD',
            'value': '35000',
          },
        ];
        loading = false;
      });

      return;
    }

    try {
      final data = await api.get('/opportunities/pipeline');

      if (!mounted) return;

      final result = <Map<String, String>>[];

      if (data is Map) {
        final stages = data['stages'];

        if (stages is Map) {
          stages.forEach((key, value) {
            if (value is Map) {
              result.add({
                'name': key.toString(),
                'stage': key.toString(),
                'value': value['value']?.toString() ?? '0',
              });
            }
          });
        }
      }

      setState(() {
        opportunities = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل الفرص: $e',
          ),
        ),
      );
    }
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
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : opportunities.isEmpty
              ? const Center(
                  child: Text('لا توجد فرص'),
                )
              : ListView.separated(
                  itemCount: opportunities.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final opportunity = opportunities[index];

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.trending_up),
                      ),
                      title: Text(
                        opportunity['name'] ?? '',
                      ),
                      subtitle: Text(
                        opportunity['stage'] ?? '',
                      ),
                      trailing: Text(
                        opportunity['value'] ?? '0',
                      ),
                    );
                  },
                ),
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool loading = true;
  List<Map<String, String>> tasks = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final guest = await guestModeEnabled();

    if (guest) {
      if (!mounted) return;

      setState(() {
        tasks = [
          {
            'title': 'الاتصال بالعميل',
            'status': 'OPEN',
            'priority': 'HIGH',
          },
          {
            'title': 'إرسال عرض سعر',
            'status': 'IN_PROGRESS',
            'priority': 'MEDIUM',
          },
          {
            'title': 'متابعة فرصة المبيعات',
            'status': 'OPEN',
            'priority': 'HIGH',
          },
          {
            'title': 'تحديث بيانات العميل',
            'status': 'COMPLETED',
            'priority': 'LOW',
          },
        ];
        loading = false;
      });

      return;
    }

    try {
      final data = await api.get('/tasks');

      if (!mounted) return;

      final result = <Map<String, String>>[];

      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            result.add({
              'title': item['title']?.toString() ?? '',
              'status': item['status']?.toString() ?? '',
              'priority': item['priority']?.toString() ?? '',
            });
          }
        }
      }

      setState(() {
        tasks = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل المهام: $e',
          ),
        ),
      );
    }
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
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : tasks.isEmpty
              ? const Center(
                  child: Text('لا توجد مهام'),
                )
              : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final completed =
                        task['status'] == 'COMPLETED';

                    return ListTile(
                      leading: Icon(
                        completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(
                        task['title'] ?? '',
                      ),
                      subtitle: Text(
                        '${task['priority'] ?? ''} • ${task['status'] ?? ''}',
                      ),
                    );
                  },
                ),
    );
  }
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool loading = true;
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final guest = await guestModeEnabled();

    if (guest) {
      if (!mounted) return;

      setState(() {
        data = {
          'إجمالي العملاء': 12,
          'العملاء النشطون': 9,
          'الفرص المفتوحة': 7,
          'قيمة الفرص': 185000,
          'المهام المكتملة': 24,
          'معدل التحويل': '28%',
        };
        loading = false;
      });

      return;
    }

    try {
      final result = await api.get('/analytics/dashboard');

      if (!mounted) return;

      if (result is Map) {
        setState(() {
          data = Map<String, dynamic>.from(result);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل التحليلات: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحليلات'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'ملخص الأداء',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...entries.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry.key),
                      trailing: Text(
                        entry.value.toString(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() =>
      _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool loading = true;
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final guest = await guestModeEnabled();

    if (guest) {
      if (!mounted) return;

      setState(() {
        data = {
          'الخطة': 'تجريبية',
          'الحالة': 'Demo',
          'المستخدمون': 1,
          'العملاء': 12,
        };
        loading = false;
      });

      return;
    }

    try {
      final result = await api.get('/subscriptions/current');

      if (!mounted) return;

      if (result is Map) {
        setState(() {
          data = Map<String, dynamic>.from(result);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل الاشتراك: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراك'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...data.entries.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry.key),
                      trailing: Text(
                        entry.value.toString(),
                      ),
                    ),
                  ),
                ),
                if (data.isNotEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('معلومات تجريبية'),
                      subtitle: Text(
                        'لا يوجد اشتراك حقيقي أثناء وضع الضيف.',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool guest = false;

  @override
  void initState() {
    super.initState();
    loadMode();
  }

  Future<void> loadMode() async {
    final value = await guestModeEnabled();

    if (!mounted) return;

    setState(() {
      guest = value;
    });
  }

  Future<void> logout() async {
    final storage = await SharedPreferences.getInstance();

    await storage.clear();

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
    await disableGuestMode();

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
                leading: Icon(Icons.visibility),
                title: Text('وضع الضيف'),
                subtitle: Text(
                  'أنت تستخدم النسخة التجريبية المحلية.',
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text('التحليلات'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: const Text('الاشتراك'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              guest ? Icons.login : Icons.logout,
            ),
            title: Text(
              guest
                  ? 'الخروج من وضع الضيف'
                  : 'تسجيل الخروج',
            ),
            onTap: guest ? exitGuest : logout,
          ),
        ],
      ),
    );
  }
}