import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);

// ============================================================
// API CLIENT
// ============================================================

class ApiClient {
  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<String?> _refresh() async {
    final prefs = await SharedPreferences.getInstance();

    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await http.post(
      Uri.parse('$apiBase/auth/refresh'),
      headers: {
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

    await prefs.setString(
      'accessToken',
      accessToken.toString(),
    );

    await prefs.setString(
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
    final token = await _token();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$apiBase$path');

    final encodedBody =
        body == null ? null : jsonEncode(body);

    late http.Response response;

    switch (method) {
      case 'POST':
        response = await http.post(
          url,
          headers: headers,
          body: encodedBody,
        );
        break;

      case 'PATCH':
        response = await http.patch(
          url,
          headers: headers,
          body: encodedBody,
        );
        break;

      case 'DELETE':
        response = await http.delete(
          url,
          headers: headers,
        );
        break;

      default:
        response = await http.get(
          url,
          headers: headers,
        );
    }

    if (response.statusCode == 401 &&
        retry &&
        path != '/auth/refresh') {
      final newToken = await _refresh();

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

  Future<dynamic> get(String path) {
    return _parse(
      request('GET', path),
    );
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

  Future<dynamic> _parse(
    Future<http.Response> future,
  ) async {
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
      String message = 'حدث خطأ';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      throw Exception(message);
    }

    return data;
  }
}

final api = ApiClient();

// ============================================================
// GUEST HELPERS
// ============================================================

Future<bool> isGuestMode() async {
  final storage = await SharedPreferences.getInstance();

  return storage.getBool('guestMode') ?? false;
}

Future<void> enableGuestMode() async {
  final storage = await SharedPreferences.getInstance();

  await storage.setBool(
    'guestMode',
    true,
  );

  await storage.setString(
    'companyName',
    'شركة تجريبية',
  );

  await storage.setString(
    'guestOwner',
    'المستخدم التجريبي',
  );
}

Future<void> disableGuestMode() async {
  final storage = await SharedPreferences.getInstance();

  await storage.remove('guestMode');
  await storage.remove('guestOwner');
  await storage.remove('companyName');
}

// ============================================================
// MAIN
// ============================================================

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

// ============================================================
// STARTUP
// ============================================================

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() =>
      _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final storage =
        await SharedPreferences.getInstance();

    final guest =
        storage.getBool('guestMode') ?? false;

    // --------------------------------------------------------
    // GUEST MODE
    // --------------------------------------------------------

    if (guest) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // REAL USER
    // --------------------------------------------------------

    final token =
        storage.getString('accessToken');

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

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;

  String? error;

  // ----------------------------------------------------------
  // REAL LOGIN
  // ----------------------------------------------------------

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        error =
            'يرجى إدخال البريد الإلكتروني وكلمة المرور';
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
          'email':
              emailController.text.trim(),
          'password':
              passwordController.text,
        },
      );

      if (data is! Map) {
        throw Exception(
          'استجابة غير صحيحة من الخادم',
        );
      }

      final accessToken =
          data['accessToken'];

      final refreshToken =
          data['refreshToken'];

      final company =
          data['company'];

      if (accessToken == null ||
          refreshToken == null) {
        throw Exception(
          'بيانات تسجيل الدخول غير مكتملة',
        );
      }

      final storage =
          await SharedPreferences.getInstance();

      await storage.remove('guestMode');

      await storage.setString(
        'accessToken',
        accessToken.toString(),
      );

      await storage.setString(
        'refreshToken',
        refreshToken.toString(),
      );

      if (company is Map &&
          company['name'] != null) {
        await storage.setString(
          'companyName',
          company['name'].toString(),
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

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

  // ----------------------------------------------------------
  // GUEST LOGIN
  // ----------------------------------------------------------

  Future<void> loginAsGuest() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await enableGuestMode();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error =
            'تعذر تشغيل وضع الضيف';
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
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.business_center,
                    size: 70,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'CRM Business',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'نظام إدارة علاقات العملاء',
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller:
                        emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'البريد الإلكتروني',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        passwordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'كلمة المرور',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  if (error != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 10,
                      ),
                      child: Text(
                        error!,
                        style:
                            const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),

                  FilledButton(
                    onPressed:
                        loading
                            ? null
                            : login,
                    child: Text(
                      loading
                          ? 'جاري الدخول...'
                          : 'تسجيل الدخول',
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
                                builder: (_) =>
                                    const RegisterPage(),
                              ),
                            );
                          },
                    child:
                        const Text(
                      'إنشاء شركة جديدة',
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // GUEST BUTTON
                  // ==================================================

                  TextButton.icon(
                    onPressed:
                        loading
                            ? null
                            : loginAsGuest,
                    icon: const Icon(
                      Icons.visibility_outlined,
                    ),
                    label: const Text(
                      'الدخول كضيف وتجربة التطبيق',
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'وضع الضيف لا يحتاج إلى خادم أو حساب حقيقي',
                    textAlign:
                        TextAlign.center,
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

// ============================================================
// REGISTER COMPANY
// ============================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() =>
      _RegisterPageState();
}

class _RegisterPageState
    extends State<RegisterPage> {
  final companyController =
      TextEditingController();

  final ownerController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;

  String? error;

  Future<void> register() async {
    if (companyController.text.trim().isEmpty ||
        ownerController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        error =
            'يرجى تعبئة جميع الحقول';
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
          'companyName':
              companyController.text.trim(),
          'ownerName':
              ownerController.text.trim(),
          'email':
              emailController.text.trim(),
          'password':
              passwordController.text,
        },
      );

      if (data is! Map) {
        throw Exception(
          'استجابة غير صحيحة من الخادم',
        );
      }

      final accessToken =
          data['accessToken'];

      final refreshToken =
          data['refreshToken'];

      final company =
          data['company'];

      if (accessToken == null ||
          refreshToken == null) {
        throw Exception(
          'بيانات التسجيل غير مكتملة',
        );
      }

      final storage =
          await SharedPreferences.getInstance();

      await storage.remove(
        'guestMode',
      );

      await storage.setString(
        'accessToken',
        accessToken.toString(),
      );

      await storage.setString(
        'refreshToken',
        refreshToken.toString(),
      );

      if (company is Map &&
          company['name'] != null) {
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
        title:
            const Text('إنشاء شركة'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          TextField(
            controller:
                companyController,
            decoration:
                const InputDecoration(
              labelText:
                  'اسم الشركة',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller:
                ownerController,
            decoration:
                const InputDecoration(
              labelText:
                  'اسم المسؤول',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller:
                emailController,
            keyboardType:
                TextInputType.emailAddress,
            decoration:
                const InputDecoration(
              labelText:
                  'البريد الإلكتروني',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller:
                passwordController,
            obscureText: true,
            decoration:
                const InputDecoration(
              labelText:
                  'كلمة المرور',
              border:
                  OutlineInputBorder(),
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: 10),

            Text(
              error!,
              style:
                  const TextStyle(
                color: Colors.red,
              ),
            ),
          ],

          const SizedBox(height: 18),

          FilledButton(
            onPressed:
                loading
                    ? null
                    : register,
            child: Text(
              loading
                  ? 'جاري الإنشاء...'
                  : 'إنشاء الشركة',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  int tab = 0;

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
        index: tab,
        children: pages,
      ),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex: tab,

        onDestinationSelected:
            (index) {
          setState(() {
            tab = index;
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
            selectedIcon: Icon(
              Icons.trending_up,
            ),
            label: 'الفرص',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.task_alt_outlined,
            ),
            selectedIcon: Icon(
              Icons.task_alt,
            ),
            label: 'المهام',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.more_horiz,
            ),
            selectedIcon: Icon(
              Icons.more_horiz,
            ),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage
    extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState
    extends State<DashboardPage> {
  Map<String, dynamic>? data;

  bool loading = true;

  bool guest = false;

  String company = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final storage =
        await SharedPreferences.getInstance();

    guest =
        storage.getBool(
              'guestMode',
            ) ??
            false;

    company =
        storage.getString(
              'companyName',
            ) ??
            '';

    if (guest) {
      setState(() {
        data = {
          'customers': 12,
          'openOpportunities': 7,
          'tasks': 18,
          'tasksOverdue': 2,
        };

        loading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final result =
          await api.get(
        '/dashboard',
      );

      if (!mounted) return;

      if (result is Map) {
        setState(() {
          data =
              Map<String, dynamic>.from(
            result,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل لوحة التحكم: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('CRM Business'),
        actions: [
          IconButton(
            onPressed: load,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: load,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(16),

          children: [
            if (guest)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.visibility,
                  ),
                  title:
                      const Text(
                    'وضع الضيف',
                  ),
                  subtitle:
                      const Text(
                    'البيانات المعروضة تجريبية ومحلية',
                  ),
                ),
              ),

            Text(
              'مرحباً 👋',
              style:
                  Theme.of(context)
                      .textTheme
                      .headlineSmall,
            ),

            Text(
              company.isEmpty
                  ? 'شركة جديدة'
                  : company,
              style:
                  Theme.of(context)
                      .textTheme
                      .titleMedium,
            ),

            const SizedBox(height: 18),

            if (loading)
              const LinearProgressIndicator(),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: [
                Metric(
                  'العملاء',
                  data?['customers'] ??
                      '—',
                  Icons.people,
                ),

                Metric(
                  'الفرص المفتوحة',
                  data?[
                        'openOpportunities',
                      ] ??
                      '—',
                  Icons.trending_up,
                ),

                Metric(
                  'المهام',
                  data?['tasks'] ??
                      '—',
                  Icons.task_alt,
                ),

                Metric(
                  'المتأخرة',
                  data?[
                        'tasksOverdue',
                      ] ??
                      '—',
                  Icons.warning_amber,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Card(
              child: ListTile(
                leading:
                    const Icon(
                  Icons.insights,
                ),
                title:
                    const Text(
                  'التقارير والتحليلات',
                ),
                subtitle:
                    const Text(
                  'المبيعات، العملاء، المهام والأنشطة',
                ),
                trailing:
                    const Icon(
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

            Card(
              child: ListTile(
                leading:
                    const Icon(
                  Icons.card_membership,
                ),
                title:
                    const Text(
                  'الاشتراك',
                ),
                subtitle:
                    const Text(
                  'الخطة الحالية والاستخدام',
                ),
                trailing:
                    const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SubscriptionPage(),
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

// ============================================================
// METRIC
// ============================================================

class Metric
    extends StatelessWidget {
  final String title;

  final dynamic value;

  final IconData icon;

  const Metric(
    this.title,
    this.value,
    this.icon, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:
          MediaQuery.sizeOf(
                context,
              ).width /
              2 -
          22,

      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(14),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(icon),

              const SizedBox(
                height: 8,
              ),

              Text(title),

              Text(
                '$value',
                style:
                    const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOMERS
// ============================================================

class CustomersPage
    extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() =>
      _CustomersPageState();
}

class _CustomersPageState
    extends State<CustomersPage> {
  List<dynamic> list = [];

  bool loading = true;

  bool guest = false;

  final searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    guest =
        await isGuestMode();

    if (guest) {
      setState(() {
        list = [
          {
            'name':
                'شركة النور التجارية',
            'phone':
                '777000001',
            'email':
                'info@alnoor.demo',
            'companyName':
                'شركة النور',
          },
          {
            'name':
                'مؤسسة المستقبل',
            'phone':
                '777000002',
            'email':
                'future@demo.local',
            'companyName':
                'مؤسسة المستقبل',
          },
          {
            'name':
                'عميل تجريبي',
            'phone':
                '777000003',
            'email':
                'customer@demo.local',
          },
        ];

        loading = false;
      });

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final query =
          searchController.text.trim();

      final path = query.isEmpty
          ? '/customers'
          : '/customers?q=${Uri.encodeQueryComponent(query)}';

      final result =
          await api.get(path);

      if (!mounted) return;

      if (result is List) {
        setState(() {
          list = result;
        });
      } else {
        setState(() {
          list = [];
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
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
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('العملاء'),
        actions: [
          IconButton(
            onPressed: load,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(12),

            child: TextField(
              controller:
                  searchController,

              onSubmitted:
                  (_) => load(),

              decoration:
                  InputDecoration(
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                hintText:
                    'بحث عن عميل',
                border:
                    const OutlineInputBorder(),
                suffixIcon:
                    IconButton(
                  onPressed: load,
                  icon:
                      const Icon(
                    Icons.search,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: loading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : list.isEmpty
                    ? const Center(
                        child: Text(
                          'لا يوجد عملاء',
                        ),
                      )
                    : ListView.separated(
                        itemCount:
                            list.length,

                        separatorBuilder:
                            (_, __) =>
                                const Divider(
                          height: 1,
                        ),

                        itemBuilder:
                            (context, index) {
                          final item =
                              list[index];

                          final customer =
                              item is Map
                                  ? Map<String, dynamic>.from(
                                      item,
                                    )
                                  : <String, dynamic>{};

                          return ListTile(
                            leading:
                                const CircleAvatar(
                              child:
                                  Icon(
                                Icons.person,
                              ),
                            ),

                            title: Text(
                              '${customer['name'] ?? ''}',
                            ),

                            subtitle:
                                Text(
                              '${customer['phone'] ?? customer['email'] ?? '—'}',
                            ),

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          Customer360Page(
                                    customer:
                                        customer,
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

// ============================================================
// CUSTOMER 360
// ============================================================

class Customer360Page
    extends StatelessWidget {
  final Map<String, dynamic>
      customer;

  const Customer360Page({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Customer 360'),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(16),

        children: [
          Text(
            '${customer['name'] ?? ''}',
            style:
                Theme.of(context)
                    .textTheme
                    .headlineSmall,
          ),

          if (customer[
                  'companyName'] !=
              null)
            Text(
              '${customer['companyName']}',
            ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.phone,
              ),
              title: Text(
                '${customer['phone'] ?? 'لا يوجد هاتف'}',
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.email,
              ),
              title: Text(
                '${customer['email'] ?? 'لا يوجد بريد'}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OPPORTUNITIES
// ============================================================

class OpportunitiesPage
    extends StatefulWidget {
  const OpportunitiesPage({
    super.key,
  });

  @override
  State<OpportunitiesPage>
      createState() =>
          _OpportunitiesPageState();
}

class _OpportunitiesPageState
    extends State<
        OpportunitiesPage> {
  Map<String, dynamic>? data;

  bool loading = true;

  bool guest = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    guest =
        await isGuestMode();

    if (guest) {
      setState(() {
        data = {
          'pipelineValue':
              185000,
          'weightedPipeline':
              126000,
          'stages': {
            'LEAD': {
              'count': 4,
              'value': 50000,
            },
            'QUALIFIED': {
              'count': 3,
              'value': 65000,
            },
            'MEETING': {
              'count': 2,
              'value': 30000,
            },
            'PROPOSAL': {
              'count': 2,
              'value': 40000,
            },
            'NEGOTIATION': {
              'count': 1,
              'value': 25000,
            },
            'WON': {
              'count': 2,
              'value': 50000,
            },
            'LOST': {
              'count': 1,
              'value': 15000,
            },
          },
        };

        loading = false;
      });

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result =
          await api.get(
        '/opportunities/pipeline',
      );

      if (!mounted) return;

      if (result is Map) {
        setState(() {
          data =
              Map<String, dynamic>.from(
            result,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل الفرص: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawStages =
        data?['stages'];

    final stages = rawStages is Map
        ? Map<String, dynamic>.from(
            rawStages,
          )
        : <String, dynamic>{};

    const stageNames = [
      'LEAD',
      'QUALIFIED',
      'MEETING',
      'PROPOSAL',
      'NEGOTIATION',
      'WON',
      'LOST',
    ];

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Sales Pipeline'),
        actions: [
          IconButton(
            onPressed: load,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [
                Card(
                  child: ListTile(
                    title:
                        const Text(
                      'Pipeline Value',
                    ),
                    trailing:
                        Text(
                      '${data?['pipelineValue'] ?? 0}',
                    ),
                  ),
                ),

                Card(
                  child: ListTile(
                    title:
                        const Text(
                      'Weighted Pipeline',
                    ),
                    trailing:
                        Text(
                      '${data?['weightedPipeline'] ?? 0}',
                    ),
                  ),
                ),

                ...stageNames.map(
                  (stage) {
                    final rawStage =
                        stages[stage];

                    final stageData =
                        rawStage is Map
                            ? Map<String, dynamic>.from(
                                rawStage,
                              )
                            : <String, dynamic>{};

                    return Card(
                      child: ListTile(
                        leading:
                            CircleAvatar(
                          child:
                              Text(
                            '${stageData['count'] ?? 0}',
                          ),
                        ),
                        title:
                            Text(stage),
                        subtitle:
                            Text(
                          'Value: ${stageData['value'] ?? 0}',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

// ============================================================
// TASKS
// ============================================================

class TasksPage
    extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() =>
      _TasksPageState();
}

class _TasksPageState
    extends State<TasksPage> {
  List<dynamic> list = [];

  bool loading = true;

  bool guest = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    guest =
        await isGuestMode();

    if (guest) {
      setState(() {
        list = [
          {
            'title':
                'الاتصال بالعميل التجريبي',
            'priority':
                'HIGH',
            'status':
                'OPEN',
          },
          {
            'title':
                'إرسال عرض سعر',
            'priority':
                'MEDIUM',
            'status':
                'IN_PROGRESS',
          },
          {
            'title':
                'متابعة فرصة المبيعات',
            'priority':
                'HIGH',
            'status':
                'OPEN',
          },
          {
            'title':
                'تحديث بيانات العميل',
            'priority':
                'LOW',
            'status':
                'COMPLETED',
          },
        ];

        loading = false;
      });

      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final result =
          await api.get('/tasks');

      if (!mounted) return;

      if (result is List) {
        setState(() {
          list = result;
        });
      } else {
        setState(() {
          list = [];
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل المهام: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('مهام المتابعة'),
        actions: [
          IconButton(
            onPressed: load,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : list.isEmpty
              ? const Center(
                  child:
                      Text(
                    'لا توجد مهام',
                  ),
                )
              : ListView.separated(
                  itemCount:
                      list.length,

                  separatorBuilder:
                      (_, __) =>
                          const Divider(),

                  itemBuilder:
                      (context, index) {
                    final item =
                        list[index];

                    final task =
                        item is Map
                            ? Map<String, dynamic>.from(
                                item,
                              )
                            : <String, dynamic>{};

                    final completed =
                        task['status'] ==
                            'COMPLETED';

                    return ListTile(
                      leading:
                          Icon(
                        completed
                            ? Icons
                                .check_circle
                            : Icons
                                .radio_button_unchecked,
                      ),

                      title: Text(
                        '${task['title'] ?? ''}',
                      ),

                      subtitle:
                          Text(
                        '${task['priority'] ?? ''} • ${task['status'] ?? ''}',
                      ),
                    );
                  },
                ),
    );
  }
}

// ============================================================
// ANALYTICS
// ============================================================

class AnalyticsPage
    extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() =>
      _AnalyticsPageState();
}

class _AnalyticsPageState
    extends State<AnalyticsPage> {
  Map<String, dynamic>? data;

  bool loading = true;

  bool guest = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    guest =
        await isGuestMode();

    if (guest) {
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
      final result =
          await api.get(
        '/analytics/dashboard',
      );

      if (!mounted) return;

      if (result is Map) {
        setState(() {
          data =
              Map<String, dynamic>.from(
            result,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل التحليلات: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries =
        data?.entries.toList() ??
            [];

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'التقارير والتحليلات',
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [
                Text(
                  'ملخص الأداء',
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleLarge,
                ),

                const SizedBox(
                  height: 12,
                ),

                if (entries.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text(
                        'لا توجد بيانات تحليلية حالياً',
                      ),
                    ),
                  ),

                ...entries.map(
                  (entry) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          entry.key
                              .toString(),
                        ),
                        trailing:
                            Text(
                          '${entry.value}',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

// ============================================================
// SUBSCRIPTION
// ============================================================

class SubscriptionPage
    extends StatefulWidget {
  const SubscriptionPage({
    super.key,
  });

  @override
  State<SubscriptionPage>
      createState() =>
          _SubscriptionPageState();
}

class _SubscriptionPageState
    extends State<
        SubscriptionPage> {
  Map<String, dynamic>? data;

  bool loading = true;

  bool guest = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    guest =
        await isGuestMode();

    if (guest) {
      setState(() {
        data = {
          'planName':
              'Demo / تجربة',
          'status':
              'تجريبية',
          'users':
              1,
          'customers':
              12,
        };

        loading = false;
      });

      return;
    }

    try {
      final result =
          await api.get(
        '/subscriptions/current',
      );

      if (!mounted) return;

      if (result is Map) {
        setState(() {
          data =
              Map<String, dynamic>.from(
            result,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تحميل الاشتراك: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawPlan =
        data?['plan'];

    String planName = '—';

    if (rawPlan is Map &&
        rawPlan['name'] != null) {
      planName =
          rawPlan['name'].toString();
    } else if (data?[
            'planName'] !=
        null) {
      planName =
          data!['planName']
              .toString();
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('الاشتراك'),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(16),

              children: [
                Card(
                  child: ListTile(
                    title:
                        const Text(
                      'الخطة الحالية',
                    ),
                    subtitle:
                        Text(planName),
                  ),
                ),

                Card(
                  child: ListTile(
                    title:
                        const Text(
                      'الحالة',
                    ),
                    subtitle:
                        Text(
                      '${data?['status'] ?? '—'}',
                    ),
                  ),
                ),

                if (guest)
                  const Card(
                    child: ListTile(
                      leading:
                          Icon(
                        Icons.info_outline,
                      ),
                      title:
                          Text(
                        'وضع تجريبي',
                      ),
                      subtitle:
                          Text(
                        'هذه البيانات للتجربة فقط ولا تمثل اشتراكاً حقيقياً.',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ============================================================
// MORE
// ============================================================

class MorePage
    extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() =>
      _MorePageState();
}

class _MorePageState
    extends State<MorePage> {
  bool guest = false;

  @override
  void initState() {
    super.initState();
    loadMode();
  }

  Future<void> loadMode() async {
    final value =
        await isGuestMode();

    if (!mounted) return;

    setState(() {
      guest = value;
    });
  }

  Future<void> logout(
      BuildContext context) async {
    final storage =
        await SharedPreferences.getInstance();

    await storage.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
      ),
      (_) => false,
    );
  }

  Future<void> exitGuest(
      BuildContext context) async {
    await disableGuestMode();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('المزيد'),
      ),

      body: ListView(
        children: [
          if (guest)
            const Card(
              margin:
                  EdgeInsets.all(12),
              child: ListTile(
                leading: Icon(
                  Icons.visibility,
                ),
                title:
                    Text(
                  'أنت تستخدم وضع الضيف',
                ),
                subtitle:
                    Text(
                  'البيانات تجريبية ومحلية',
                ),
              ),
            ),

          ListTile(
            leading:
                const Icon(
              Icons.insights,
            ),
            title:
                const Text(
              'التقارير والتحليلات',
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
            leading:
                const Icon(
              Icons.card_membership,
            ),
            title:
                const Text(
              'الاشتراك',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SubscriptionPage(),
                ),
              );
            },
          ),

          const Divider(),

          if (guest)
            ListTile(
              leading:
                  const Icon(
                Icons.login,
              ),
              title:
                  const Text(
                'الخروج من وضع الضيف',
              ),
              subtitle:
                  const Text(
                'العودة إلى شاشة تسجيل الدخول',
              ),
              onTap: () =>
                  exitGuest(context),
            )
          else
            ListTile(
              leading:
                  const Icon(
                Icons.logout,
              ),
              title:
                  const Text(
                'تسجيل الخروج',
              ),
              onTap: () =>
                  logout(context),
            ),
        ],
      ),
    );
  }
}