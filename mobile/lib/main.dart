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
        child: const Column(
          children: [
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
              if (existing == null) {
                await store.addCustomer(item);
              } else {
                await store.updateCustomer(item);
              }

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('حفظ'),
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

class Customer360Page extends StatefulWidget {
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

    String type = activityTypes.first;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'إضافة نشاط',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<
                        String>(
                      initialValue: type,
                      decoration:
                          const InputDecoration(
                        labelText: 'نوع النشاط',
                      ),
                      items:
                          activityTypes.map(
                        (item) {
                          return DropdownMenuItem(
                            value: item,
                            child:
                                Text(item),
                          );
                        },
                      ).toList(),
                      onChanged:
                          (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          type = value;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: title,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'عنوان النشاط',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: note,
                      maxLines: 4,
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
                      const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (title.text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    await widget.store
                        .addActivity({
                      'id': widget.store
                          .newId('activity'),
                      'customerId':
                          widget.customerId,
                      'type': type,
                      'title':
                          title.text.trim(),
                      'note':
                          note.text.trim(),
                      'date': DateTime.now()
                          .toIso8601String(),
                    });

                    if (dialogContext
                        .mounted) {
                      Navigator.pop(
                        dialogContext,
                      );
                    }

                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child:
                      const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    title.dispose();
    note.dispose();
  }

  Future<void> editCustomer(
    Map<String, dynamic> customer,
  ) async {
    await showCustomerDialog(
      context,
      widget.store,
      existing: customer,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteCustomer() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف العميل',
          ),
          content: const Text(
            'سيتم حذف العميل والفرص والمهام والأنشطة المرتبطة به. هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child:
                  const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child:
                  const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.store.deleteCustomer(
      widget.customerId,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
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
        body: const Center(
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
            .toList();

    final opportunityValue =
        opportunities.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item['value'] as num)
              .toDouble(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer 360',
        ),
        actions: [
          IconButton(
            onPressed: () =>
                editCustomer(customer),
            icon:
                const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: deleteCustomer,
            icon: const Icon(
              Icons.delete_outline,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addActivity,
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
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(
                          Icons.business,
                          size: 30,
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              customer[
                                      'name']
                                  .toString(),
                              style:
                                  const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
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
                    ],
                  ),
                  const Divider(
                    height: 28,
                  ),
                  InfoRow(
                    label:
                        'جهة الاتصال',
                    value:
                        customer[
                                'contactName']
                            .toString(),
                  ),
                  InfoRow(
                    label: 'الهاتف',
                    value:
                        customer['phone']
                            .toString(),
                  ),
                  InfoRow(
                    label: 'البريد',
                    value:
                        customer['email']
                            .toString(),
                  ),
                  InfoRow(
                    label: 'الحالة',
                    value:
                        customer['status']
                            .toString(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child: MiniMetric(
                  title: 'الفرص',
                  value:
                      '${opportunities.length}',
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: MiniMetric(
                  title: 'قيمة الفرص',
                  value:
                      money(opportunityValue),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: MiniMetric(
                  title: 'المهام',
                  value:
                      '${tasks.length}',
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          const SectionTitle(
            icon: Icons.trending_up,
            title: 'الفرص',
          ),
          const SizedBox(
            height: 8,
          ),
          if (opportunities.isEmpty)
            const EmptyCard(
              text:
                  'لا توجد فرص لهذا العميل.',
            ),
          ...opportunities.map(
            (opportunity) =>
                OpportunityCompactCard(
              store: widget.store,
              opportunity:
                  opportunity,
              onChanged: () {
                setState(() {});
              },
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          const SectionTitle(
            icon: Icons.task_alt,
            title: 'المهام',
          ),
          const SizedBox(
            height: 8,
          ),
          if (tasks.isEmpty)
            const EmptyCard(
              text:
                  'لا توجد مهام لهذا العميل.',
            ),
          ...tasks.map(
            (task) => TaskCompactCard(
              store: widget.store,
              task: task,
              onChanged: () {
                setState(() {});
              },
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          const SectionTitle(
            icon: Icons.timeline,
            title: 'Timeline',
          ),
          const SizedBox(
            height: 8,
          ),
          if (activities.isEmpty)
            const EmptyCard(
              text:
                  'لا توجد أنشطة مسجلة.',
            ),
          ...activities.reversed.map(
            (activity) =>
                ActivityCard(
              activity: activity,
            ),
          ),
          const SizedBox(
            height: 80,
          ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style:
                  const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniMetric extends StatelessWidget {
  final String title;
  final String value;

  const MiniMetric({
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
                fontWeight:
                    FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              title,
              style:
                  const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  final String text;

  const EmptyCard({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Center(
          child: Text(
            text,
            style:
                const TextStyle(
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityCard({
    super.key,
    required this.activity,
  });

  IconData get icon {
    switch (activity['type']) {
      case 'مكالمة':
        return Icons.phone;
      case 'زيارة':
        return Icons.location_on;
      case 'اجتماع':
        return Icons.groups;
      case 'بريد':
        return Icons.email;
      default:
        return Icons.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          activity['title']
              .toString(),
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          activity['note']
                  ?.toString() ??
              '',
        ),
        trailing: Text(
          shortDate(
            activity['date']
                ?.toString(),
          ),
        ),
      ),
    );
  }
}

class OpportunityCompactCard
    extends StatelessWidget {
  final DemoStore store;
  final Map<String, dynamic> opportunity;
  final VoidCallback onChanged;

  const OpportunityCompactCard({
    super.key,
    required this.store,
    required this.opportunity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        title: Text(
          opportunity['title']
              .toString(),
        ),
        subtitle: Text(
          '${opportunity['stage']} • ${opportunity['probability']}%',
        ),
        trailing: Text(
          money(
            opportunity['value']
                as num,
          ),
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
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
      ),
    );
  }
}

class TaskCompactCard
    extends StatelessWidget {
  final DemoStore store;
  final Map<String, dynamic> task;
  final VoidCallback onChanged;

  const TaskCompactCard({
    super.key,
    required this.store,
    required this.task,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: Icon(
          task['priority'] == 'عالية'
              ? Icons.priority_high
              : Icons.task_alt,
          color:
              task['priority'] == 'عالية'
                  ? dangerColor
                  : primaryColor,
        ),
        title: Text(
          task['title']
              .toString(),
        ),
        subtitle: Text(
          '${task['status']} • ${shortDate(task['dueDate']?.toString())}',
        ),
        trailing:
            isOverdue(
              task['dueDate']
                  ?.toString(),
            ) &&
                    task['status'] !=
                        'مكتملة'
                ? const Icon(
                    Icons.warning_amber,
                    color:
                        dangerColor,
                  )
                : null,
        onTap: () async {
          await showTaskDialog(
            context,
            store,
            existing: task,
          );

          onChanged();
        },
      ),
    );
  }
}                        .customers
                        .map(
                      (customer) =>
                          DropdownMenuItem(
                        value:
                            customer['id']
                                .toString(),
                        child: Text(
                          customer['name']
                              .toString(),
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged:
                        (value) {
                      setDialogState(() {
                        customerId =
                            value;
                      });
                    },
                    decoration:
                        const InputDecoration(
                      labelText:
                          'العميل',
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: title,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'اسم الفرصة',
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: value,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                          decimal: true,
                        ),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'قيمة الفرصة',
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller:
                        probability,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'احتمال الإغلاق %',
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  DropdownButtonFormField<
                      String>(
                    initialValue:
                        stage,
                    items:
                        opportunityStages
                            .map(
                      (item) =>
                          DropdownMenuItem(
                        value: item,
                        child:
                            Text(item),
                      ),
                    ).toList(),
                    onChanged:
                        (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        stage = value;
                      });
                    },
                    decoration:
                        const InputDecoration(
                      labelText:
                          'مرحلة البيع',
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
                  final parsedValue =
                      double.tryParse(
                    value.text
                        .trim(),
                  );

                  final parsedProbability =
                      int.tryParse(
                    probability.text
                        .trim(),
                  );

                  if (title.text
                          .trim()
                          .isEmpty ||
                      customerId == null ||
                      parsedValue == null ||
                      parsedProbability ==
                          null) {
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
                        title.text.trim(),
                    'value':
                        parsedValue,
                    'probability':
                        parsedProbability
                            .clamp(0, 100),
                    'stage': stage,
                    'expectedClose':
                        existing?[
                                'expectedClose'] ??
                            DateTime.now()
                                .add(
                              const Duration(
                                days: 30,
                              ),
                            )
                                .toIso8601String()
                                .substring(
                                  0,
                                  10,
                                ),
                  };

                  if (existing == null) {
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
                    const Text('حفظ'),
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
  Future<void> changeStage(
    String stage,
  ) async {
    final opportunities =
        widget.store.opportunities;

    final index =
        opportunities.indexWhere(
      (item) =>
          item['id'] ==
          widget.opportunityId,
    );

    if (index < 0) {
      return;
    }

    final updated = {
      ...opportunities[index],
      'stage': stage,
    };

    await widget.store
        .updateOpportunity(
      updated,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> edit() async {
    final opportunity =
        widget.store.opportunities
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (item) =>
                  item?['id'] ==
                  widget.opportunityId,
              orElse: () => null,
            );

    if (opportunity == null) {
      return;
    }

    await showOpportunityDialog(
      context,
      widget.store,
      existing: opportunity,
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? opportunity;

    for (final item
        in widget.store.opportunities) {
      if (item['id'] ==
          widget.opportunityId) {
        opportunity = item;
        break;
      }
    }

    if (opportunity == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'الفرصة غير موجودة',
          ),
        ),
      );
    }

    final value =
        (opportunity['value']
                as num)
            .toDouble();

    final probability =
        (opportunity[
                'probability']
            as num)
            .toDouble();

    final weighted =
        value *
            probability /
            100;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('تفاصيل الفرصة'),
        actions: [
          IconButton(
            onPressed: edit,
            icon:
                const Icon(Icons.edit),
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
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity[
                            'title']
                        .toString(),
                    style:
                        const TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    widget.store
                        .customerName(
                      opportunity[
                              'customerId']
                          .toString(),
                    ),
                    style:
                        const TextStyle(
                      color:
                          Colors.black54,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                            MiniStat(
                          title:
                              'القيمة',
                          value:
                              money(value),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
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
                        width: 10,
                      ),
                      Expanded(
                        child:
                            MiniStat(
                          title:
                              'Weighted',
                          value:
                              money(weighted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          const SectionTitle(
            icon:
                Icons.alt_route,
            title:
                'مسار الفرصة',
          ),
          const SizedBox(
            height: 10,
          ),
          ...opportunityStages.map(
            (stage) {
              final selected =
                  opportunity![
                          'stage'] ==
                      stage;

              return Card(
                margin:
                    const EdgeInsets
                        .only(
                  bottom: 8,
                ),
                child: ListTile(
                  leading:
                      CircleAvatar(
                    backgroundColor:
                        selected
                            ? primaryColor
                            : Colors.black12,
                    child: Icon(
                      selected
                          ? Icons.check
                          : Icons.circle_outlined,
                      color: selected
                          ? Colors.white
                          : Colors.black54,
                    ),
                  ),
                  title:
                      Text(stage),
                  trailing:
                      selected
                          ? const Text(
                              'الحالية',
                              style:
                                  TextStyle(
                                color:
                                    primaryColor,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            )
                          : null,
                  onTap: () =>
                      changeStage(
                    stage,
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            height: 10,
          ),
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تاريخ الإغلاق المتوقع',
                    style:
                        TextStyle(
                      color:
                          Colors.black54,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    shortDate(
                      opportunity[
                              'expectedClose']
                          ?.toString(),
                    ),
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
  String filter = 'الكل';

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
    final filters = [
      'الكل',
      ...taskStatuses,
    ];

    final list =
        filter == 'الكل'
            ? widget.store.tasks
            : widget.store.tasks
                .where(
                  (t) =>
                      t['status'] ==
                      filter,
                )
                .toList();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('المهام'),
        actions: [
          IconButton(
            onPressed: addTask,
            icon:
                const Icon(Icons.add_task),
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
          SizedBox(
            height: 46,
            child: ListView
                .separated(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  filters.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                width: 8,
              ),
              itemBuilder:
                  (_, index) {
                final item =
                    filters[index];

                return ChoiceChip(
                  label:
                      Text(item),
                  selected:
                      filter == item,
                  onSelected:
                      (_) {
                    setState(() {
                      filter = item;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          ...list.map(
            (task) =>
                TaskListCard(
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

class TaskListCard
    extends StatelessWidget {
  final DemoStore store;
  final Map<String, dynamic> task;
  final VoidCallback onChanged;

  const TaskListCard({
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
        leading:
            CircleAvatar(
          backgroundColor:
              overdue
                  ? dangerColor.withValues(
                      alpha: .1,
                    )
                  : primaryColor.withValues(
                      alpha: .1,
                    ),
          child: Icon(
            task['status'] ==
                    'مكتملة'
                ? Icons.check
                : Icons.task_alt,
            color: overdue
                ? dangerColor
                : primaryColor,
          ),
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
          '${task['status']} • ${task['priority']} • ${shortDate(task['dueDate']?.toString())}',
        ),
        isThreeLine: true,
        trailing:
            overdue
                ? const Icon(
                    Icons.warning_amber,
                    color:
                        dangerColor,
                  )
                : null,
        onTap: () async {
          await showTaskDialog(
            context,
            store,
            existing: task,
          );

          onChanged();
        },
      ),
    );
  }
}