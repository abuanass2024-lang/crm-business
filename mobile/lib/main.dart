// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CrmApp());
}

class CrmApp extends StatelessWidget {
  const CrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM Business',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const StartupPage(),
    );
  }
}

class CompanyProfile {
  CompanyProfile({
    required this.companyName,
    required this.managerName,
    required this.email,
    required this.phone,
  });

  final String companyName;
  final String managerName;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'managerName': managerName,
        'email': email,
        'phone': phone,
      };

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      companyName: json['companyName'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class Customer {
  Customer(this.name, this.company, this.phone, this.status);

  final String name;
  final String company;
  final String phone;
  final String status;

  Map<String, dynamic> toJson() => {
        'name': name,
        'company': company,
        'phone': phone,
        'status': status,
      };

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        j['name'] as String? ?? '',
        j['company'] as String? ?? '',
        j['phone'] as String? ?? '',
        j['status'] as String? ?? 'نشط',
      );
}

class Opportunity {
  Opportunity(this.title, this.customer, this.value, this.stage);

  final String title;
  final String customer;
  final double value;
  final String stage;

  Map<String, dynamic> toJson() => {
        'title': title,
        'customer': customer,
        'value': value,
        'stage': stage,
      };

  factory Opportunity.fromJson(Map<String, dynamic> j) => Opportunity(
        j['title'] as String? ?? '',
        j['customer'] as String? ?? '',
        (j['value'] as num?)?.toDouble() ?? 0,
        j['stage'] as String? ?? 'جديدة',
      );
}

class CrmTask {
  CrmTask(this.title, this.customer, this.done);

  final String title;
  final String customer;
  bool done;

  Map<String, dynamic> toJson() => {
        'title': title,
        'customer': customer,
        'done': done,
      };

  factory CrmTask.fromJson(Map<String, dynamic> j) => CrmTask(
        j['title'] as String? ?? '',
        j['customer'] as String? ?? '',
        j['done'] as bool? ?? false,
      );
}

class CrmData extends ChangeNotifier {
  static const _dataKey = 'crm_business_v3';
  static const _companyKey = 'crm_company_profile';

  final customers = <Customer>[];
  final opportunities = <Opportunity>[];
  final tasks = <CrmTask>[];

  CompanyProfile? company;
  bool ready = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final companyRaw = prefs.getString(_companyKey);

    if (companyRaw != null) {
      try {
        company = CompanyProfile.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(companyRaw) as Map,
          ),
        );
      } catch (_) {
        company = null;
      }
    }

    final raw = prefs.getString(_dataKey);

    if (raw == null) {
      customers.addAll([
        Customer(
          'أحمد محمد',
          'شركة الريادة',
          '777000111',
          'نشط',
        ),
        Customer(
          'سارة علي',
          'مؤسسة الأفق',
          '733000222',
          'يحتاج متابعة',
        ),
      ]);

      opportunities.addAll([
        Opportunity(
          'عقد خدمات سنوي',
          'شركة الريادة',
          12000,
          'تفاوض',
        ),
        Opportunity(
          'توريد أجهزة',
          'مؤسسة الأفق',
          7500,
          'عرض سعر',
        ),
      ]);

      tasks.addAll([
        CrmTask(
          'متابعة عرض السعر',
          'مؤسسة الأفق',
          false,
        ),
        CrmTask(
          'الاتصال بالعميل',
          'شركة الريادة',
          false,
        ),
      ]);

      await save();
    } else {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;

        customers.addAll(
          (j['customers'] as List<dynamic>? ?? []).map(
            (x) => Customer.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          ),
        );

        opportunities.addAll(
          (j['opportunities'] as List<dynamic>? ?? []).map(
            (x) => Opportunity.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          ),
        );

        tasks.addAll(
          (j['tasks'] as List<dynamic>? ?? []).map(
            (x) => CrmTask.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          ),
        );
      } catch (_) {
        customers.clear();
        opportunities.clear();
        tasks.clear();
      }
    }

    ready = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _dataKey,
      jsonEncode({
        'customers': customers.map((x) => x.toJson()).toList(),
        'opportunities': opportunities.map((x) => x.toJson()).toList(),
        'tasks': tasks.map((x) => x.toJson()).toList(),
      }),
    );

    notifyListeners();
  }

  Future<void> saveCompany(CompanyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();

    company = profile;

    await prefs.setString(
      _companyKey,
      jsonEncode(profile.toJson()),
    );

    notifyListeners();
  }

  Future<void> addCustomer(Customer x) async {
    customers.insert(0, x);
    await save();
  }

  Future<void> addOpportunity(Opportunity x) async {
    opportunities.insert(0, x);
    await save();
  }

  Future<void> addTask(CrmTask x) async {
    tasks.insert(0, x);
    await save();
  }

  Future<void> toggle(CrmTask x) async {
    x.done = !x.done;
    await save();
  }

  double get pipeline => opportunities
      .where((x) => !x.stage.startsWith('مغلقة'))
      .fold(0, (a, x) => a + x.value);
}

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  final data = CrmData();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await data.load();

    if (!mounted) return;

    if (data.company == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompanyRegistrationPage(data: data),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CrmHome(data: data),
        ),
      );
    }
  }

  @override
  void dispose() {
    data.dispose();
    super.dispose();
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

class CompanyRegistrationPage extends StatefulWidget {
  const CompanyRegistrationPage({
    super.key,
    required this.data,
  });

  final CrmData data;

  @override
  State<CompanyRegistrationPage> createState() =>
      _CompanyRegistrationPageState();
}

class _CompanyRegistrationPageState
    extends State<CompanyRegistrationPage> {
  final companyController = TextEditingController();
  final managerController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  bool acceptTerms = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    companyController.dispose();
    managerController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final companyName = companyController.text.trim();
    final managerName = managerController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (companyName.isEmpty ||
        managerName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _message('يرجى تعبئة جميع الحقول.');
      return;
    }

    if (!email.contains('@')) {
      _message('يرجى إدخال بريد إلكتروني صحيح.');
      return;
    }

    if (password.length < 6) {
      _message('كلمة المرور يجب أن تكون 6 أحرف على الأقل.');
      return;
    }

    if (password != confirm) {
      _message('كلمتا المرور غير متطابقتين.');
      return;
    }

    if (!acceptTerms) {
      _message('يرجى الموافقة على الشروط والأحكام.');
      return;
    }

    setState(() => loading = true);

    final profile = CompanyProfile(
      companyName: companyName,
      managerName: managerName,
      email: email,
      phone: phone,
    );

    await widget.data.saveCompany(profile);

    if (!mounted) return;

    setState(() => loading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CrmHome(data: widget.data),
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إنشاء حساب شركة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Icon(
                  Icons.business,
                  size: 70,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 12),
                const Text(
                  'مرحباً بك في CRM Business',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أنشئ حساب شركتك للبدء في إدارة العملاء والفرص والمهام.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                _field(
                  controller: companyController,
                  label: 'اسم الشركة',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: managerController,
                  label: 'اسم المدير / المستخدم',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => obscurePassword = !obscurePassword,
                        );
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => obscureConfirm = !obscureConfirm,
                        );
                      },
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: acceptTerms,
                  onChanged: (value) {
                    setState(() {
                      acceptTerms = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'أوافق على الشروط والأحكام وسياسة الخصوصية',
                  ),
                  controlAffinity:
                      ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: loading ? null : register,
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.business_center),
                    label: Text(
                      loading
                          ? 'جاري إنشاء الحساب...'
                          : 'إنشاء حساب الشركة',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'نسخة تجريبية: سيتم ربط التسجيل الحقيقي بالخادم وقاعدة البيانات في المرحلة التالية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class CrmHome extends StatefulWidget {
  const CrmHome({
    super.key,
    required this.data,
  });

  final CrmData data;

  @override
  State<CrmHome> createState() => _CrmHomeState();
}

class _CrmHomeState extends State<CrmHome> {
  int tab = 0;

  CrmData get data => widget.data;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: data,
      builder: (context, _) {
        final pages = <Widget>[
          _dashboard(),
          _customers(),
          _opportunities(),
          _tasks(),
          _analytics(),
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'CRM Business',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _showCompany,
                  icon: const Icon(Icons.business_outlined),
                  tooltip: 'ملف الشركة',
                ),
                IconButton(
                  onPressed: () => showAboutDialog(
                    context: context,
                    applicationName: 'CRM Business',
                    applicationVersion: '3.0.0',
                  ),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'حول التطبيق',
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  tooltip: 'تسجيل الخروج',
                ),
              ],
            ),
            body: IndexedStack(
              index: tab,
              children: pages,
            ),
            floatingActionButton: tab == 1
                ? FloatingActionButton.extended(
                    onPressed: _newCustomer,
                    icon: const Icon(Icons.person_add),
                    label: const Text('عميل جديد'),
                  )
                : tab == 2
                    ? FloatingActionButton.extended(
                        onPressed: _newOpportunity,
                        icon: const Icon(Icons.add),
                        label: const Text('فرصة جديدة'),
                      )
                    : tab == 3
                        ? FloatingActionButton.extended(
                            onPressed: _newTask,
                            icon: const Icon(Icons.add_task),
                            label: const Text('مهمة جديدة'),
                          )
                        : null,
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) {
                setState(() => tab = i);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  label: 'العملاء',
                ),
                NavigationDestination(
                  icon: Icon(Icons.trending_up),
                  label: 'الفرص',
                ),
                NavigationDestination(
                  icon: Icon(Icons.task_alt),
                  label: 'المهام',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  label: 'التحليلات',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text(
            'هل تريد تسجيل الخروج من CRM Business؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('crm_company_profile');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CompanyRegistrationPage(data: data),
      ),
      (route) => false,
    );
  }

  void _showCompany() {
    final company = data.company;

    if (company == null) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ملف الشركة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الشركة: ${company.companyName}'),
            const SizedBox(height: 8),
            Text('المستخدم: ${company.managerName}'),
            const SizedBox(height: 8),
            Text('البريد: ${company.email}'),
            const SizedBox(height: 8),
            Text('الهاتف: ${company.phone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _dashboard() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF303F9F),
                  Color(0xFF6574CD),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً بك 👋',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.company?.companyName ?? 'شركتك',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'حوّل علاقاتك إلى نتائج',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _metric(
                'العملاء',
                '${data.customers.length}',
                Icons.people,
              ),
              _metric(
                'قيمة الفرص',
                money(data.pipeline),
                Icons.trending_up,
              ),
              _metric(
                'المهام المفتوحة',
                '${data.tasks.where((x) => !x.done).length}',
                Icons.task,
              ),
              _metric(
                'الفرص البيعية',
                '${data.opportunities.length}',
                Icons.show_chart,
              ),
            ],
          ),
          _heading(
            'الإجراءات القادمة',
            () => setState(() => tab = 3),
          ),
          ...data.tasks
              .where((x) => !x.done)
              .take(4)
              .map(
                (x) => ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                  ),
                  title: Text(x.title),
                  subtitle: Text(x.customer),
                ),
              ),
          _heading(
            'أحدث الفرص',
            () => setState(() => tab = 2),
          ),
          ...data.opportunities.take(3).map(_opportunityTile),
        ],
      );

  Widget _metric(
    String title,
    String value,
    IconData icon,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: Colors.indigo,
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _heading(
    String title,
    VoidCallback onTap,
  ) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text('عرض الكل'),
          ),
        ],
      );

  Widget _customers() => data.customers.isEmpty
      ? const Center(
          child: Text('لا يوجد عملاء بعد.'),
        )
      : ListView(
          padding: const EdgeInsets.all(12),
          children: data.customers
              .map(
                (x) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(x.name),
                    subtitle: Text(
                      '${x.company}\n${x.phone}',
                    ),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(x.status),
                    ),
                  ),
                ),
              )
              .toList(),
        );

  Widget _opportunities() => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _metric(
            'قيمة الفرص المفتوحة',
            money(data.pipeline),
            Icons.trending_up,
          ),
          const SizedBox(height: 10),
          ...data.opportunities.map(_opportunityTile),
        ],
      );

  Widget _opportunityTile(Opportunity x) => Card(
        child: ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.show_chart),
          ),
          title: Text(x.title),
          subtitle: Text(
            '${x.customer} • ${x.stage}',
          ),
          trailing: Text(
            money(x.value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _tasks() => ListView(
        padding: const EdgeInsets.all(12),
        children: data.tasks
            .map(
              (x) => Card(
                child: CheckboxListTile(
                  value: x.done,
                  onChanged: (_) => data.toggle(x),
                  title: Text(x.title),
                  subtitle: Text(x.customer),
                  controlAffinity:
                      ListTileControlAffinity.leading,
                ),
              ),
            )
            .toList(),
      );

  Widget _analytics() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ملخص الأداء',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          _metric(
            'إجمالي العملاء',
            '${data.customers.length}',
            Icons.people,
          ),
          const SizedBox(height: 10),
          _metric(
            'قيمة الفرص المفتوحة',
            money(data.pipeline),
            Icons.trending_up,
          ),
          const SizedBox(height: 10),
          _metric(
            'المهام المنجزة',
            '${data.tasks.where((x) => x.done).length}',
            Icons.task_alt,
          ),
          const SizedBox(height: 10),
          _metric(
            'المهام المفتوحة',
            '${data.tasks.where((x) => !x.done).length}',
            Icons.pending,
          ),
        ],
      );

  Future<void> _newCustomer() async {
    final form = await _showForm(
      'عميل جديد',
      [
        'اسم العميل',
        'الشركة',
        'الهاتف',
      ],
    );

    if (form != null &&
        form[0].isNotEmpty &&
        form[1].isNotEmpty) {
      await data.addCustomer(
        Customer(
          form[0],
          form[1],
          form[2],
          'نشط',
        ),
      );
    }
  }

  Future<void> _newOpportunity() async {
    final form = await _showForm(
      'فرصة جديدة',
      [
        'اسم الفرصة',
        'العميل',
        'القيمة',
      ],
    );

    if (form != null &&
        form[0].isNotEmpty &&
        form[1].isNotEmpty) {
      final value = double.tryParse(form[2]) ?? 0;

      await data.addOpportunity(
        Opportunity(
          form[0],
          form[1],
          value,
          'جديدة',
        ),
      );
    }
  }

  Future<void> _newTask() async {
    final form = await _showForm(
      'مهمة جديدة',
      [
        'عنوان المهمة',
        'العميل',
      ],
    );

    if (form != null && form[0].isNotEmpty) {
      await data.addTask(
        CrmTask(
          form[0],
          form.length > 1 && form[1].isNotEmpty
              ? form[1]
              : 'غير محدد',
          false,
        ),
      );
    }
  }

  Future<List<String>?> _showForm(
    String title,
    List<String> labels,
  ) async {
    final controllers = labels
        .map(
          (_) => TextEditingController(),
        )
        .toList();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                labels.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: TextField(
                    controller: controllers[i],
                    keyboardType: labels[i] == 'القيمة'
                        ? TextInputType.number
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: labels[i],
                    ),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                controllers
                    .map((c) => c.text.trim())
                    .toList(),
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    for (final c in controllers) {
      c.dispose();
    }

    return result;
  }
}

String money(double value) {
  final n = value.round().toString();
  final out = StringBuffer();

  for (var i = 0; i < n.length; i++) {
    out.write(n[i]);

    if ((n.length - i - 1) % 3 == 0 &&
        i != n.length - 1) {
      out.write(',');
    }
  }

  return out.toString();
}