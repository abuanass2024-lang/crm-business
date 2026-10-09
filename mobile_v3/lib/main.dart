import 'features/reports/reports_page.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/ai/ai_chat_page.dart';
import 'features/customers/customer_360_page.dart';
import 'features/home/dashboard_v2.dart';
import 'core/theme/crm_app.dart';
import 'features/team/team_page.dart';
// ignore_for_file: prefer_const_constructors

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3000/api',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CrmApp(home: StartupPage()));
}

/* =========================================================
   API CLIENT
   ========================================================= */

class ApiClient {
  String get base => apiBaseUrl.replaceFirst(
        RegExp(r'/$'),
        '',
      );

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    if (base.isEmpty) {
      throw Exception(
        'لم يتم ضبط عنوان الخادم API_BASE_URL.',
      );
    }

    final client = HttpClient();

    try {
      final request = await client.postUrl(
        Uri.parse('$base$path'),
      );

      request.headers.contentType =
          ContentType.json;

      if (token != null && token.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $token',
        );
      }

      request.write(jsonEncode(body));

      final response = await request.close();

      final responseText =
          await response.transform(
        utf8.decoder,
      ).join();

      dynamic decoded;

      try {
        decoded = responseText.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(responseText);
      } catch (_) {
        decoded = <String, dynamic>{
          'message': responseText,
        };
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final message = decoded is Map
            ? decoded['message']?.toString() ??
                'فشل الطلب (${response.statusCode})'
            : 'فشل الطلب (${response.statusCode})';

        throw Exception(message);
      }

      return Map<String, dynamic>.from(
        decoded as Map,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
  }) async {
    if (base.isEmpty) {
      throw Exception(
        'لم يتم ضبط عنوان الخادم API_BASE_URL.',
      );
    }

    final client = HttpClient();

    try {
      final request = await client.getUrl(
        Uri.parse('$base$path'),
      );

      if (token != null && token.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $token',
        );
      }

      final response = await request.close();

      final responseText =
          await response.transform(
        utf8.decoder,
      ).join();

      dynamic decoded;

      try {
        decoded = responseText.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(responseText);
      } catch (_) {
        decoded = <String, dynamic>{
          'message': responseText,
        };
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final message = decoded is Map
            ? decoded['message']?.toString() ??
                'فشل الطلب'
            : 'فشل الطلب';

        throw Exception(message);
      }

      return Map<String, dynamic>.from(
        decoded as Map,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    String? token,
  }) async {
    if (base.isEmpty) {
      throw Exception('لم يتم ضبط عنوان الخادم API_BASE_URL.');
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$base$path'));
      if (token != null && token.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $token',
        );
      }
      final response = await request.close();
      final responseText = await response.transform(utf8.decoder).join();
      dynamic decoded;
      try {
        decoded = responseText.isEmpty ? [] : jsonDecode(responseText);
      } catch (_) {
        decoded = <dynamic>[];
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('فشل الطلب (${response.statusCode})');
      }
      if (decoded is List) return decoded;
      return <dynamic>[];
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    if (base.isEmpty) {
      throw Exception('لم يتم ضبط عنوان الخادم API_BASE_URL.');
    }
    final client = HttpClient();
    try {
      final request = await client.patchUrl(Uri.parse('$base$path'));
      request.headers.contentType = ContentType.json;
      if (token != null && token.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $token',
        );
      }
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close();
      final responseText = await response.transform(utf8.decoder).join();
      dynamic decoded;
      try {
        decoded = responseText.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(responseText);
      } catch (_) {
        decoded = <String, dynamic>{'message': responseText};
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? decoded['message']?.toString() ??
                'فشل الطلب (${response.statusCode})'
            : 'فشل الطلب (${response.statusCode})';
        throw Exception(message);
      }
      return Map<String, dynamic>.from(decoded as Map);
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
  }) async {
    if (base.isEmpty) {
      throw Exception('لم يتم ضبط عنوان الخادم API_BASE_URL.');
    }
    final client = HttpClient();
    try {
      final request = await client.deleteUrl(Uri.parse('$base$path'));
      if (token != null && token.isNotEmpty) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $token',
        );
      }
      final response = await request.close();
      final responseText = await response.transform(utf8.decoder).join();
      dynamic decoded;
      try {
        decoded = responseText.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(responseText);
      } catch (_) {
        decoded = <String, dynamic>{'message': responseText};
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map
            ? decoded['message']?.toString() ??
                'فشل الطلب (${response.statusCode})'
            : 'فشل الطلب (${response.statusCode})';
        throw Exception(message);
      }
      return Map<String, dynamic>.from(decoded as Map);
    } finally {
      client.close(force: true);
    }
  }
}

/* =========================================================
   SESSION
   ========================================================= */

class Session {
  static const accessKey =
      'crm_access_token';

  static const refreshKey =
      'crm_refresh_token';

  static const userKey =
      'crm_session_user';

  static const companyKey =
      'crm_session_company';

  final String accessToken;
  final String refreshToken;

  final Map<String, dynamic> user;
  final Map<String, dynamic> company;

  Session({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.company,
  });

  static Future<Session?> load() async {
    final prefs =
        await SharedPreferences.getInstance();

    final access =
        prefs.getString(accessKey);

    final refresh =
        prefs.getString(refreshKey);

    if (access == null ||
        refresh == null ||
        access.isEmpty ||
        refresh.isEmpty) {
      return null;
    }

    return Session(
      accessToken: access,
      refreshToken: refresh,
      user: _decodeMap(
        prefs.getString(userKey),
      ),
      company: _decodeMap(
        prefs.getString(companyKey),
      ),
    );
  }

  static Map<String, dynamic> _decodeMap(
    String? raw,
  ) {
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> save() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      accessKey,
      accessToken,
    );

    await prefs.setString(
      refreshKey,
      refreshToken,
    );

    await prefs.setString(
      userKey,
      jsonEncode(user),
    );

    await prefs.setString(
      companyKey,
      jsonEncode(company),
    );
  }

  static Future<void> clear() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(accessKey);
    await prefs.remove(refreshKey);
    await prefs.remove(userKey);
    await prefs.remove(companyKey);
  }
}

/* =========================================================
   COMPANY
   ========================================================= */

class CompanyProfile {
  CompanyProfile({
    required this.id,
    required this.companyName,
    required this.managerName,
    required this.email,
    required this.phone,
  });

  final String id;
  final String companyName;
  final String managerName;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'managerName': managerName,
      'email': email,
      'phone': phone,
    };
  }

  factory CompanyProfile.fromJson(
    Map<String, dynamic> json,
  ) {
    return CompanyProfile(
      id: json['id']?.toString() ?? '',
      companyName:
          json['companyName']?.toString() ?? '',
      managerName:
          json['managerName']?.toString() ?? '',
      email:
          json['email']?.toString() ?? '',
      phone:
          json['phone']?.toString() ?? '',
    );
  }
}

/* =========================================================
   CUSTOMER
   ========================================================= */

class Customer {
  Customer({
    this.id = '',
    required this.name,
    required this.company,
    this.phone = '',
    this.email = '',
    this.status = 'PROSPECT',
    this.assignedTo = '',
      this.sector = '',
      this.size = '',
      this.branch = '',
      this.salesRep = '',
    this.notes = '',
    this.firstInteractionAt,
    this.lastInteractionAt,
    DateTime? createdAt,
  }) : createdAt =
            createdAt ?? DateTime.now();

  final String id;

  String name;
  String company;
  String phone;
  String email;
  String status;
  String assignedTo;
  String notes;
  String sector;   // القطاع: تجاري، صناعي، خدمي
  String size;     // الحجم: صغير، متوسط، كبير
  String branch;   // الفرع
  String salesRep; // المندوب

  DateTime createdAt;
  DateTime? firstInteractionAt;
  DateTime? lastInteractionAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'status': status,
      'assignedTo': assignedTo,
      'notes': notes,
      'sector': sector,
      'size': size,
      'branch': branch,
      'salesRep': salesRep,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }

  factory Customer.fromJson(
    Map<String, dynamic> json,
  ) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      company:
          json['company']?.toString() ?? '',
      phone:
          json['phone']?.toString() ?? '',
      email:
          json['email']?.toString() ?? '',
      status: _normalizeStatus(
        json['status']?.toString() ?? 'PROSPECT',
      ),
      assignedTo:
          json['assignedTo']?.toString() ?? '',
      notes:
          json['notes']?.toString() ?? '',
      sector:
          json['sector']?.toString() ?? '',
      size:
          json['size']?.toString() ?? '',
      branch:
          json['branch']?.toString() ?? '',
      salesRep:
          json['salesRep']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      firstInteractionAt: json['firstInteractionAt'] != null
          ? DateTime.tryParse(json['firstInteractionAt'].toString())
          : null,
      lastInteractionAt: json['lastInteractionAt'] != null
          ? DateTime.tryParse(json['lastInteractionAt'].toString())
          : null,
    );
  }
}

/* =========================================================
   CUSTOMER STATUS HELPERS
   ========================================================= */

String _normalizeStatus(String raw) {
  // دعم القيم القديمة (عربية/إنجليزية)
  final v = raw.trim().toUpperCase();
  if (v == 'PROSPECT' || v == 'محتمل') return 'PROSPECT';
  if (v == 'CUSTOMER' || v == 'عميل') return 'CUSTOMER';
  if (v == 'ACTIVE' || v == 'نشط') return 'ACTIVE';
  if (v == 'INACTIVE' || v == 'غير فعال' || v == 'غير نشط') return 'INACTIVE';
  if (v == 'WITHDRAWN' || v == 'منسحب') return 'WITHDRAWN';
  return 'PROSPECT';
}

String customerStatusAr(String status) {
  switch (_normalizeStatus(status)) {
    case 'PROSPECT':
      return 'محتمل';
    case 'CUSTOMER':
      return 'عميل';
    case 'ACTIVE':
      return 'نشط';
    case 'INACTIVE':
      return 'غير فعال';
    case 'WITHDRAWN':
      return 'منسحب';
    default:
      return 'محتمل';
  }
}

Color customerStatusColor(String status) {
  switch (_normalizeStatus(status)) {
    case 'PROSPECT':
      return Colors.blue;
    case 'CUSTOMER':
      return Colors.amber.shade700;
    case 'ACTIVE':
      return Colors.green;
    case 'INACTIVE':
      return Colors.orange;
    case 'WITHDRAWN':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/* =========================================================
   OPPORTUNITY
   ========================================================= */

class Opportunity {
  Opportunity({
    this.id = '',
    required this.title,
    required this.customer,
    required this.value,
    this.stage = 'جديدة',
    this.probability = 20,
    this.expectedCloseDate,
    this.assignedTo = '',
    DateTime? createdAt,
  }) : createdAt =
            createdAt ?? DateTime.now();

  final String id;

  String title;
  String customer;
  double value;
  String stage;
  int probability;

  DateTime? expectedCloseDate;

  String assignedTo;

  DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'customer': customer,
      'value': value,
      'stage': stage,
      'probability': probability,
      'expectedCloseDate':
          expectedCloseDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }

  factory Opportunity.fromJson(
    Map<String, dynamic> json,
  ) {
    return Opportunity(
      id: json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ?? '',
      customer:
          json['customer']?.toString() ?? '',
      value:
          (json['value'] as num?)
                  ?.toDouble() ??
              0,
      stage:
          json['stage']?.toString() ??
              'جديدة',
      probability:
          (json['probability'] as num?)
                  ?.toInt() ??
              20,
      expectedCloseDate:
          DateTime.tryParse(
        json['expectedCloseDate']
                ?.toString() ??
            '',
      ),
      assignedTo:
          json['assignedTo']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }
}

/* =========================================================
   TASK
   ========================================================= */

class CrmTask {
  CrmTask({
    this.id = '',
    required this.title,
    this.customer = '',
    this.assignee = '',
    this.description = '',
    this.priority = 'متوسطة',
    this.done = false,
    DateTime? dueAt,
    this.reminderMinutes = 30,
    DateTime? createdAt,
  })  : dueAt =
            dueAt ??
                DateTime.now().add(
                  const Duration(
                    hours: 1,
                  ),
                ),
        createdAt =
            createdAt ?? DateTime.now();

  final String id;

  String title;
  String customer;
  String assignee;
  String description;
  String priority;

  bool done;

  DateTime dueAt;

  int reminderMinutes;

  DateTime createdAt;

  bool get overdue {
    return !done &&
        dueAt.isBefore(
          DateTime.now(),
        );
  }

  bool get today {
    final now = DateTime.now();

    return dueAt.year == now.year &&
        dueAt.month == now.month &&
        dueAt.day == now.day;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'customer': customer,
      'assignee': assignee,
      'description': description,
      'priority': priority,
      'done': done,
      'dueAt': dueAt.toIso8601String(),
      'reminderMinutes':
          reminderMinutes,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }

  factory CrmTask.fromJson(
    Map<String, dynamic> json,
  ) {
    return CrmTask(
      id: json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ?? '',
      customer:
          json['customer']?.toString() ?? '',
      assignee:
          json['assignee']?.toString() ?? '',
      description:
          json['description']?.toString() ??
              '',
      priority:
          json['priority']?.toString() ??
              'متوسطة',
      done:
          json['done'] as bool? ?? false,
      dueAt: DateTime.tryParse(
            json['dueAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      reminderMinutes:
          (json['reminderMinutes'] as num?)
                  ?.toInt() ??
              30,
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }
}

/* =========================================================
   NOTIFICATION
   ========================================================= */

class CrmNotification {
  CrmNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;

  bool read;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'createdAt':
          createdAt.toIso8601String(),
      'read': read,
    };
  }

  factory CrmNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    return CrmNotification(
      id: json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ?? '',
      body:
          json['body']?.toString() ?? '',
      type:
          json['type']?.toString() ??
              'system',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      read:
          json['read'] as bool? ?? false,
    );
  }
}

/* =========================================================
   CRM DATA
   ========================================================= */

class CrmData extends ChangeNotifier {
  static const dataKey =
      'crm_business_v5';

  static const companyKey =
      'crm_company_profile_v5';

  static const notificationsKey =
      'crm_notifications_v1';

  static const settingsKey =
      'crm_settings_v1';

  final List<Customer> customers = [];
  final List<Opportunity> opportunities = [];
  final List<CrmTask> tasks = [];
  final List<CrmNotification> notifications =
      [];

  CompanyProfile? company;
  Session? session;

  bool notificationsEnabled = true;
  bool taskRemindersEnabled = true;
  bool compactMode = false;

  Future<void> load() async {
    final prefs =
        await SharedPreferences.getInstance();

    session = await Session.load();

    final companyRaw =
        prefs.getString(companyKey);

    if (companyRaw != null) {
      try {
        company =
            CompanyProfile.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(companyRaw) as Map,
          ),
        );
      } catch (_) {}
    }

    _loadData(
      prefs.getString(dataKey),
    );

    _loadNotifications(
      prefs.getString(
        notificationsKey,
      ),
    );

    _loadSettings(
      prefs.getString(settingsKey),
    );

    refreshSystemNotifications();

    notifyListeners();
  }

  void _loadData(String? raw) {
    customers.clear();
    opportunities.clear();
    tasks.clear();

    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final json =
          Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );

      customers.addAll(
        (json['customers'] as List? ?? [])
            .map(
          (item) => Customer.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        ),
      );

      opportunities.addAll(
        (json['opportunities']
                    as List? ??
                [])
            .map(
          (item) =>
              Opportunity.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        ),
      );

      tasks.addAll(
        (json['tasks'] as List? ?? [])
            .map(
          (item) => CrmTask.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        ),
      );
    } catch (_) {
      customers.clear();
      opportunities.clear();
      tasks.clear();
    }
  }

  void _loadNotifications(
    String? raw,
  ) {
    notifications.clear();

    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      notifications.addAll(
        (jsonDecode(raw) as List).map(
          (item) =>
              CrmNotification.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  void _loadSettings(String? raw) {
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final json =
          Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );

      notificationsEnabled =
          json['notifications']
                  as bool? ??
              true;

      taskRemindersEnabled =
          json['taskReminders']
                  as bool? ??
              true;

      compactMode =
          json['compactMode']
                  as bool? ??
              false;
    } catch (_) {}
  }

  void refreshSystemNotifications() {
    final now = DateTime.now();

    final ids =
        notifications.map((x) => x.id).toSet();

    for (final task in tasks.where(
      (x) => !x.done && x.overdue,
    )) {
      final id =
          'overdue-${task.id}-${task.title}';

      if (!ids.contains(id)) {
        notifications.insert(
          0,
          CrmNotification(
            id: id,
            title: 'مهمة متأخرة',
            body: task.title,
            type: 'overdue',
            createdAt: now,
          ),
        );
      }
    }

    for (final task in tasks.where(
      (x) => !x.done && x.today,
    )) {
      final id =
          'today-${task.id}-${task.title}';

      if (!ids.contains(id)) {
        notifications.insert(
          0,
          CrmNotification(
            id: id,
            title: 'مهمة اليوم',
            body:
                '${task.title} • ${formatDateTime(task.dueAt)}',
            type: 'task',
            createdAt: now,
          ),
        );
      }
    }

    if (notifications.length > 50) {
      notifications.removeRange(
        50,
        notifications.length,
      );
    }
  }

  Future<void> save() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      dataKey,
      jsonEncode({
        'customers':
            customers
                .map((x) => x.toJson())
                .toList(),
        'opportunities':
            opportunities
                .map((x) => x.toJson())
                .toList(),
        'tasks':
            tasks
                .map((x) => x.toJson())
                .toList(),
      }),
    );

    await prefs.setString(
      notificationsKey,
      jsonEncode(
        notifications
            .map((x) => x.toJson())
            .toList(),
      ),
    );

    await prefs.setString(
      settingsKey,
      jsonEncode({
        'notifications':
            notificationsEnabled,
        'taskReminders':
            taskRemindersEnabled,
        'compactMode':
            compactMode,
      }),
    );

    notifyListeners();
  }

  Future<void> saveCompany(
    CompanyProfile value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    company = value;

    await prefs.setString(
      companyKey,
      jsonEncode(
        value.toJson(),
      ),
    );

    notifyListeners();
  }

  Future<void> setSettings({
    bool? notifications,
    bool? taskReminders,
    bool? compact,
  }) async {
    if (notifications != null) {
      notificationsEnabled =
          notifications;
    }

    if (taskReminders != null) {
      taskRemindersEnabled =
          taskReminders;
    }

    if (compact != null) {
      compactMode = compact;
    }

    await save();
  }

  Future<void> addCustomer(
    Customer customer,
  ) async {
    customers.insert(0, customer);
    await save();
  }

  Future<void> updateCustomer(
    Customer customer,
  ) async {
    final index =
        customers.indexWhere(
      (x) => x.id == customer.id,
    );

    if (index >= 0) {
      customers[index] = customer;
      await save();
    }
  }

  Future<void> deleteCustomer(
    Customer customer,
  ) async {
    customers.remove(customer);
    await save();
  }

  Future<void> addOpportunity(
    Opportunity opportunity,
  ) async {
    opportunities.insert(
      0,
      opportunity,
    );
    await save();
  }

  Future<void> updateOpportunity(
    Opportunity opportunity,
  ) async {
    final index =
        opportunities.indexWhere(
      (x) => x.id == opportunity.id,
    );

    if (index >= 0) {
      opportunities[index] =
          opportunity;
      await save();
    }
  }

  Future<void> deleteOpportunity(
    Opportunity opportunity,
  ) async {
    opportunities.remove(
      opportunity,
    );
    await save();
  }

  Future<void> addTask(
    CrmTask task,
  ) async {
    tasks.insert(0, task);
    refreshSystemNotifications();
    await save();
  }

  Future<void> updateTask(
    CrmTask task,
  ) async {
    final index =
        tasks.indexWhere(
      (x) => x.id == task.id,
    );

    if (index >= 0) {
      tasks[index] = task;
      refreshSystemNotifications();
      await save();
    }
  }

  Future<void> toggleTask(
    CrmTask task,
  ) async {
    task.done = !task.done;
    refreshSystemNotifications();
    await save();
  }

  Future<void> deleteTask(
    CrmTask task,
  ) async {
    tasks.remove(task);
    await save();
  }

  Future<void> markNotificationRead(
    CrmNotification notification,
  ) async {
    notification.read = true;
    await save();
  }

  Future<void>
      markAllNotificationsRead() async {
    for (final notification
        in notifications) {
      notification.read = true;
    }

    await save();
  }

  int get unreadNotifications {
    return notifications
        .where((x) => !x.read)
        .length;
  }

  double get pipeline {
    return opportunities
        .where(
          (x) =>
              !x.stage.startsWith(
            'مغلقة',
          ),
        )
        .fold(
          0,
          (sum, x) => sum + x.value,
        );
  }

  double get weightedPipeline {
    return opportunities
        .where(
          (x) =>
              !x.stage.startsWith(
            'مغلقة',
          ),
        )
        .fold(
          0,
          (sum, x) =>
              sum +
              x.value *
                  x.probability /
                  100,
        );
  }

  int get overdueTasks {
    return tasks
        .where((x) => x.overdue)
        .length;
  }

  int get todayTasks {
    return tasks
        .where(
          (x) => !x.done && x.today,
        )
        .length;
  }

  int get completedTasks {
    return tasks
        .where((x) => x.done)
        .length;
  }

  List<CrmTask> customerTasks(
    String customer,
  ) {
    return tasks
        .where(
          (x) => x.customer == customer,
        )
        .toList();
  }

  List<Opportunity>
      customerOpportunities(
    String customer,
  ) {
    return opportunities
        .where(
          (x) => x.customer == customer,
        )
        .toList();
  }
}

/* =========================================================
   STARTUP
   ========================================================= */

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() =>
      _StartupPageState();
}

class _StartupPageState
    extends State<StartupPage> {
  final CrmData data = CrmData();

  @override
  void initState() {
    super.initState();
    start();
  }

  Future<void> start() async {
    // ✅ try/catch + timeout
    try {
      await data.load().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // إذا انتهت المدة، نستمر بدون بيانات
        },
      );
    } catch (e) {
      // نستمر حتى لو فشل التحميل
    }

    if (!mounted) return;

    final userName = data.session?.user['name']?.toString() ??
        data.company?.managerName ??
        '';

    setState(() {
      _showWelcome = true;
      _userName = userName;
    });
  }

  bool _showWelcome = false;
  String _userName = '';

  void _onWelcomeComplete() {
    if (!mounted) return;

    if (data.session != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CrmHome(data: data),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthPage(data: data),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return WelcomeScreen(
        userName: _userName,
        onComplete: _onWelcomeComplete,
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
        );
  }

  @override
  void dispose() {
    // data.dispose();  // معطل مؤقتاً
    super.dispose();
  }
}

/* =========================================================
   AUTH
   ========================================================= */

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.data,
  });

  final CrmData data;

  @override
  State<AuthPage> createState() =>
      _AuthPageState();
}

class _AuthPageState
    extends State<AuthPage> {
  bool loginMode = true;
  bool loading = false;
  bool obscurePassword = true;

  final emailController =
      TextEditingController();

  final employeeIdController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final companyController =
      TextEditingController();

  final ownerController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    employeeIdController.dispose();
    passwordController.dispose();
    companyController.dispose();
    ownerController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  Future<void> submit() async {
    if (loginMode) {
      if (employeeIdController.text.trim().isEmpty) {
        showError('أدخل الرقم الوظيفي.');
        return;
      }
    } else {
      if (emailController.text.trim().isEmpty) {
        showError('أدخل البريد الإلكتروني.');
        return;
      }
    }

    if (passwordController
        .text
        .isEmpty) {
      showError(
        'أدخل كلمة المرور.',
      );
      return;
    }

    if (!loginMode) {
      if (companyController.text
          .trim()
          .isEmpty) {
        showError(
          'أدخل اسم الشركة.',
        );
        return;
      }

      if (ownerController.text
          .trim()
          .isEmpty) {
        showError(
          'أدخل اسم المدير أو المستخدم.',
        );
        return;
      }

      if (passwordController
              .text
              .length <
          8) {
        showError(
          'كلمة المرور يجب أن تكون 8 أحرف على الأقل.',
        );
        return;
      }
    }

    setState(() {
      loading = true;
    });

    try {
      final Map<String, dynamic> result;
      if (loginMode) {
        final empId = employeeIdController.text.trim();
        final pwd = passwordController.text;
        const Map<String, Map<String, String>> demoUsers = {
          'KIB001': {'pwd': '123456', 'name': 'المدير العام', 'role': 'GENERAL_MANAGER'},
          'KIB002': {'pwd': '123456', 'name': 'مدير الفروع', 'role': 'REGIONAL_MANAGER'},
          'KIB003': {'pwd': '123456', 'name': 'مدير الفرع', 'role': 'BRANCH_MANAGER'},
          'KIB004': {'pwd': '123456', 'name': 'مدير القاعة', 'role': 'HALL_MANAGER'},
          'KIB005': {'pwd': '123456', 'name': 'خدمة العملاء 1', 'role': 'CUSTOMER_SERVICE'},
          'KIB006': {'pwd': '123456', 'name': 'خدمة العملاء 2', 'role': 'CUSTOMER_SERVICE'},
        };
        final demo = demoUsers[empId];
        if (demo != null && demo['pwd'] == pwd) {
          final ts = DateTime.now().millisecondsSinceEpoch.toString();
          result = {
            'accessToken': 'offline_' + ts,
            'refreshToken': 'offline_' + ts,
            'user': {
              'id': 'offline_' + empId,
              'name': demo['name'],
              'email': empId.toLowerCase() + '@crm.local',
              'employeeId': empId,
              'role': demo['role'],
            },
            'company': {
              'id': 'offline_company',
              'name': 'الشركة التجريبية',
            },
          };
        } else {
          result = await ApiClient().post(
            '/auth/login',
            {
              'employeeId': empId,
              'password': pwd,
            },
          );
        }
      } else {
        result = await ApiClient().post(
          '/auth/register-company',
          {
            'companyName': companyController.text.trim(),
            'ownerName': ownerController.text.trim(),
            'email': emailController.text.trim(),
            'password': passwordController.text,
          },
        );
      }

      if (result['accessToken'] == null) {
        throw Exception(
          result['message']?.toString() ?? 'فشل تسجيل الدخول.',
        );
      }

      final session = Session(
        accessToken:
            result['accessToken']
                    ?.toString() ??
                '',
        refreshToken:
            result['refreshToken']
                    ?.toString() ??
                '',
        user:
            Map<String, dynamic>.from(
          result['user'] as Map? ??
              {},
        ),
        company:
            Map<String, dynamic>.from(
          result['company'] as Map? ??
              {},
        ),
      );

      if (session.accessToken
              .isEmpty ||
          session.refreshToken
              .isEmpty) {
        throw Exception(
          'استجابة الخادم لا تحتوي على رموز الجلسة.',
        );
      }

      await session.save();

      widget.data.session =
          session;

      final companyData =
          session.company;

      await widget.data
          .saveCompany(
        CompanyProfile(
          id: companyData['id']
                  ?.toString() ??
              '',
          companyName:
              companyData['name']
                      ?.toString() ??
                  companyController.text
                      .trim(),
          managerName:
              session.user['name']
                      ?.toString() ??
                  ownerController.text
                      .trim(),
          email:
              session.user['email']
                      ?.toString() ??
                  emailController.text
                      .trim(),
          phone:
              phoneController.text
                  .trim(),
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CrmHome(
            data: widget.data,
          ),
        ),
      );
    } catch (error) {
      showError(
        cleanError(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showError(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                22,
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 520,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    const Icon(
                      Icons.hub_outlined,
                      size: 72,
                      color:
                          Colors.indigo,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
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
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      loginMode
                          ? 'تسجيل الدخول إلى حسابك'
                          : 'إنشاء حساب شركة جديد',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.black54,
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label:
                              Text('دخول'),
                          icon: Icon(
                            Icons.login,
                          ),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(
                            'حساب جديد',
                          ),
                          icon: Icon(
                            Icons
                                .person_add,
                          ),
                        ),
                      ],
                      selected: {
                        loginMode,
                      },
                      onSelectionChanged:
                          loading
                              ? null
                              : (value) {
                                  setState(
                                    () {
                                      loginMode =
                                          value
                                              .first;
                                    },
                                  );
                                },
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    if (!loginMode) ...[
                      field(
                        companyController,
                        'اسم الشركة',
                        Icons
                            .business_outlined,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      field(
                        ownerController,
                        'اسم المدير / المستخدم',
                        Icons
                            .person_outline,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      field(
                        phoneController,
                        'رقم الهاتف',
                        Icons
                            .phone_outlined,
                        keyboardType:
                            TextInputType
                                .phone,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                    if (loginMode)
                      field(
                        employeeIdController,
                        'الرقم الوظيفي',
                        Icons.badge_outlined,
                      )
                    else
                      field(
                        emailController,
                        'البريد الإلكتروني',
                        Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          passwordController,
                      obscureText:
                          obscurePassword,
                      decoration:
                          InputDecoration(
                        labelText:
                            'كلمة المرور',
                        prefixIcon:
                            const Icon(
                          Icons
                              .lock_outline,
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons
                                    .visibility
                                : Icons
                                    .visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      height: 54,
                      child:
                          FilledButton.icon(
                        onPressed:
                            loading
                                ? null
                                : submit,
                        icon: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : Icon(
                                loginMode
                                    ? Icons
                                        .login
                                    : Icons
                                        .rocket_launch,
                              ),
                        label: Text(
                          loading
                              ? 'جاري الاتصال بالخادم...'
                              : loginMode
                                  ? 'تسجيل الدخول'
                                  : 'إنشاء الحساب',
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    OutlinedButton.icon(
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CrmHome(
                                    data: widget.data,
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.person_outline),
                      label: const Text('الدخول كضيف'),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    const Text(
                      'لا يتم حفظ كلمة المرور على الجهاز. يتم حفظ رموز الجلسة فقط.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String label,
    IconData icon, {
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

/* =========================================================
   HOME
   ========================================================= */

class CrmHome extends StatefulWidget {
  const CrmHome({
    super.key,
    required this.data,
  });

  final CrmData data;

  @override
  State<CrmHome> createState() =>
      _CrmHomeState();
}

class _CrmHomeState
    extends State<CrmHome> {
  int tab = 0;

  String customerSearch = '';

  String taskFilter = 'الكل';

  CrmData get data => widget.data;

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: data,
      builder: (context, _) {
        final role = data.session?.user['role']?.toString() ?? '';
        final roleLabel = {
          'GENERAL_MANAGER': 'المدير العام',
          'REGIONAL_MANAGER': 'مدير الفروع',
          'BRANCH_MANAGER': 'مدير الفرع',
          'HALL_MANAGER': 'المشرف',
          'SUPERVISOR': 'المشرف',
          'CUSTOMER_SERVICE': 'خدمة العملاء',
          'OWNER': 'المالك',
          'ADMIN': 'مدير النظام',
        }[role] ?? 'مستخدم';
        final isCustomerService = role == 'CUSTOMER_SERVICE';

        final pages = [
          dashboard(),
          customersPage(),
          opportunitiesPage(),
          tasksPage(),
          reportsPage(),
        ];

        final titles = [
          roleLabel + ' - الرئيسية',
          'العملاء',
          'الفرص',
          'المهام',
          isCustomerService ? 'أدائي' : 'التقارير',
        ];

        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                titles[tab],
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              actions: [
                Stack(
                  alignment:
                      Alignment.topLeft,
                  children: [
                    IconButton(
                      onPressed:
                          openNotifications,
                      icon:
                          const Icon(
                        Icons
                            .notifications_none,
                      ),
                    ),
                    if (data
                            .unreadNotifications >
                        0)
                      Positioned(
                        left: 7,
                        top: 7,
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .all(
                            4,
                          ),
                          decoration:
                              const BoxDecoration(
                            color:
                                Colors.red,
                            shape:
                                BoxShape
                                    .circle,
                          ),
                          child: Text(
                            data.unreadNotifications >
                                    9
                                ? '9+'
                                : '${data.unreadNotifications}',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (data.session?.user['role'] == 'GENERAL_MANAGER' ||
                    data.session?.user['role'] == 'REGIONAL_MANAGER' ||
                    data.session?.user['role'] == 'BRANCH_MANAGER')
                  IconButton(
                    onPressed: openTeam,
                    icon: const Icon(Icons.group_outlined),
                  ),
                IconButton(
                  onPressed:
                      openSettings,
                  icon:
                      const Icon(
                    Icons
                        .settings_outlined,
                  ),
                ),
              ],
            ),
            body: pages[tab],
            floatingActionButton:
                floatingButton(),
            bottomNavigationBar:
                NavigationBar(
              selectedIndex: tab,
              onDestinationSelected:
                  (index) {
                setState(() {
                  tab = index;
                });
              },
              destinations:
                  const [
                NavigationDestination(
                  icon: Icon(
                    Icons
                        .dashboard_outlined,
                  ),
                  selectedIcon:
                      Icon(
                    Icons.dashboard,
                  ),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons
                        .people_outline,
                  ),
                  selectedIcon:
                      Icon(
                    Icons.people,
                  ),
                  label: 'العملاء',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.trending_up,
                  ),
                  selectedIcon:
                      Icon(
                    Icons.trending_up,
                  ),
                  label: 'الفرص',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.task_outlined,
                  ),
                  selectedIcon:
                      Icon(
                    Icons.task_alt,
                  ),
                  label: 'المهام',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons
                        .analytics_outlined,
                  ),
                  selectedIcon:
                      Icon(
                    Icons.analytics,
                  ),
                  label: 'التقارير',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? floatingButton() {
    if (tab == 1) {
      return FloatingActionButton
          .extended(
        onPressed: () =>
            customerForm(),
        icon: const Icon(
          Icons.person_add_alt_1,
        ),
        label:
            const Text('عميل'),
      );
    }

    if (tab == 2) {
      return FloatingActionButton
          .extended(
        onPressed: () =>
            opportunityForm(),
        icon: const Icon(
          Icons.add_chart,
        ),
        label:
            const Text('فرصة'),
      );
    }

    if (tab == 3) {
      return FloatingActionButton
          .extended(
        onPressed: () =>
            taskForm(),
        icon: const Icon(
          Icons.add_task,
        ),
        label:
            const Text('مهمة'),
      );
    }

    return null;
  }

  /* =======================================================
     DASHBOARD
     ======================================================= */

  void openAIAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIChatPage(data: data),
      ),
    );
  }

  Widget dashboard() {
    return buildDashboardV2(
      data: data,
      onAddCustomer: () => customerForm(),
      onOpenNotifications: openNotifications,
      onOpenSettings: openSettings,
      onOpenAI: openAIAssistant,
    );
  }
  Widget pipelineRow(
    String stage,
  ) {
    final list =
        data.opportunities
            .where(
              (x) => x.stage == stage,
            )
            .toList();

    final value =
        list.fold<double>(
      0,
      (sum, x) => sum + x.value,
    );

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(stage),
          ),
          Text('${list.length}'),
          const SizedBox(
            width: 12,
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
    );
  }

  /* =======================================================
     CUSTOMERS
     ======================================================= */

  Widget customersPage() {
    final filtered =
        data.customers.where(
      (customer) {
        final q =
            customerSearch
                .trim()
                .toLowerCase();

        return q.isEmpty ||
            customer.name
                .toLowerCase()
                .contains(q) ||
            customer.company
                .toLowerCase()
                .contains(q) ||
            customer.phone
                .toLowerCase()
                .contains(q);
      },
    ).toList();

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            6,
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                customerSearch =
                    value;
              });
            },
            decoration:
                const InputDecoration(
              hintText:
                  'ابحث باسم العميل أو الشركة أو الهاتف',
              prefixIcon:
                  Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? emptyState(
                  'لا توجد نتائج للعملاء.',
                )
              : ListView(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  children: filtered
                      .map(
                        customerCard,
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget customerCard(
    Customer customer,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading:
            const CircleAvatar(
          child: Icon(
            Icons.person,
          ),
        ),
        title: Text(
          customer.name,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${customer.company}\n'
              '${customer.phone.isEmpty ? 'لا يوجد هاتف' : customer.phone}',
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: customerStatusColor(customer.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: customerStatusColor(customer.status).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                customerStatusAr(customer.status),
                style: TextStyle(
                  color: customerStatusColor(customer.status),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing:
            PopupMenuButton<String>(
          onSelected: (value) {
            if (value ==
                'view') {
              customer360(
                customer,
              );
            }

            if (value ==
                'edit') {
              customerForm(
                existing:
                    customer,
              );
            }

            if (value ==
                'delete') {
              deleteCustomer(
                customer,
              );
            }
          },
          itemBuilder: (_) =>
              const [
            PopupMenuItem(
              value: 'view',
              child: Text(
                'Customer 360',
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Text(
                'تعديل',
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'حذف',
              ),
            ),
          ],
        ),
        onTap: () =>
            customer360(
          customer,
        ),
      ),
    );
  }

  /* =======================================================
     OPPORTUNITIES
     ======================================================= */

  Widget opportunitiesPage() {
    return ListView(
      padding:
          const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: metric(
                'Pipeline',
                money(
                  data.pipeline,
                ),
                Icons.trending_up,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: metric(
                'Weighted',
                money(
                  data.weightedPipeline,
                ),
                Icons.balance,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        if (data
            .opportunities
            .isEmpty)
          emptyState(
            'لا توجد فرص حتى الآن.',
          ),
        ...data.opportunities
            .map(
              opportunityCard,
            ),
      ],
    );
  }

  Widget opportunityCard(
    Opportunity opportunity,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading:
            const CircleAvatar(
          child: Icon(
            Icons.show_chart,
          ),
        ),
        title: Text(
          opportunity.title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${opportunity.customer}\n'
          '${opportunity.stage} • احتمال ${opportunity.probability}%',
        ),
        isThreeLine: true,
        trailing:
            PopupMenuButton<String>(
          onSelected: (value) {
            if (value ==
                'edit') {
              opportunityForm(
                existing:
                    opportunity,
              );
            }

            if (value ==
                'delete') {
              deleteOpportunity(
                opportunity,
              );
            }
          },
          itemBuilder: (_) =>
              const [
            PopupMenuItem(
              value: 'edit',
              child:
                  Text('تعديل'),
            ),
            PopupMenuItem(
              value: 'delete',
              child:
                  Text('حذف'),
            ),
          ],
        ),
        onTap: () =>
            opportunityForm(
          existing:
              opportunity,
        ),
      ),
    );
  }

  /* =======================================================
     TASKS
     ======================================================= */

  Widget tasksPage() {
    List<CrmTask> list = [
      ...data.tasks,
    ];

    if (taskFilter ==
        'اليوم') {
      list = list
          .where(
            (x) => x.today,
          )
          .toList();
    }

    if (taskFilter ==
        'متأخرة') {
      list = list
          .where(
            (x) => x.overdue,
          )
          .toList();
    }

    if (taskFilter ==
        'مفتوحة') {
      list = list
          .where(
            (x) => !x.done,
          )
          .toList();
    }

    if (taskFilter ==
        'منجزة') {
      list = list
          .where(
            (x) => x.done,
          )
          .toList();
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          padding:
              const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            4,
          ),
          child: Row(
            children: [
              'الكل',
              'اليوم',
              'متأخرة',
              'مفتوحة',
              'منجزة',
            ].map(
              (filter) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    left: 6,
                  ),
                  child: ChoiceChip(
                    label:
                        Text(filter),
                    selected:
                        taskFilter ==
                            filter,
                    onSelected: (_) {
                      setState(
                        () {
                          taskFilter =
                              filter;
                        },
                      );
                    },
                  ),
                );
              },
            ).toList(),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? emptyState(
                  'لا توجد مهام في هذا التصنيف.',
                )
              : ListView(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  children: list
                      .map(taskCard)
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget taskCard(
    CrmTask task,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.done,
          onChanged: (_) =>
              data.toggleTask(
            task,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            decoration: task.done
                ? TextDecoration
                    .lineThrough
                : null,
          ),
        ),
        subtitle: Text(
          '${task.customer.isEmpty ? 'بدون عميل' : task.customer}\n'
          '${formatDateTime(task.dueAt)} • ${task.priority}',
        ),
        isThreeLine: true,
        trailing:
            PopupMenuButton<String>(
          onSelected: (value) {
            if (value ==
                'edit') {
              taskForm(
                existing: task,
              );
            }

            if (value ==
                'delete') {
              deleteTask(task);
            }
          },
          itemBuilder: (_) =>
              const [
            PopupMenuItem(
              value: 'edit',
              child:
                  Text('تعديل'),
            ),
            PopupMenuItem(
              value: 'delete',
              child:
                  Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  /* =======================================================
     REPORTS
     ======================================================= */

  Widget reportsPage() {
    return buildReportsPage(data: data);
  }

  Future<void> customer360(
    Customer customer,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Customer360Page(
          data: data,
          customer: customer,
        ),
      ),
    );
  }

  Future<void> customerForm({
    Customer? existing,
  }) async {
    final name =
        TextEditingController(
      text: existing?.name ?? '',
    );

    final company =
        TextEditingController(
      text: existing?.company ?? '',
    );

    final phone =
        TextEditingController(
      text: existing?.phone ?? '',
    );

    final email =
        TextEditingController(
      text: existing?.email ?? '',
    );

    final assigned =
        TextEditingController(
      text: existing?.assignedTo ?? '',
    );

    final notes =
        TextEditingController(
      text: existing?.notes ?? '',
    );

    String status =
        existing?.status ?? 'نشط';


    final sectorController = TextEditingController(
      text: existing?.sector ?? '',
    );

    final sizeController = TextEditingController(
      text: existing?.size ?? '',
    );

    final branchController = TextEditingController(
      text: existing?.branch ?? '',
    );

    final salesRepController = TextEditingController(
      text: existing?.salesRep ?? '',
    );

    final saved =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialog) {
            return Directionality(
              textDirection:
                  TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  existing == null
                      ? 'إضافة عميل'
                      : 'تعديل العميل',
                ),
                content:
                    SingleChildScrollView(
                  child: Column(
                    children: [
                      dialogField(
                        name,
                        'اسم العميل',
                      ),
                      dialogField(
                        company,
                        'الشركة',
                      ),
                      dialogField(
                        phone,
                        'الهاتف',
                        keyboardType:
                            TextInputType
                                .phone,
                      ),
                      dialogField(
                        email,
                        'البريد الإلكتروني',
                        keyboardType:
                            TextInputType
                                .emailAddress,
                      ),
                      dialogField(
                        assigned,
                        'المسؤول',
                      ),
                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            status,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'الحالة',
                        ),
                        items: const [
                          'نشط',
                          'يحتاج متابعة',
                          'غير نشط',
                        ]
                            .map(
                              (value) =>
                                  DropdownMenuItem(
                                value:
                                    value,
                                child:
                                    Text(
                                  value,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            (value) {
                          setDialog(
                            () {
                              status =
                                  value ??
                                      status;
                            },
                          );
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    // ─── القطاع (Dropdown) ───
                    DropdownButtonFormField<String>(
                      initialValue: existing?.sector.isNotEmpty == true
                          ? existing!.sector
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'القطاع',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        'تجاري',
                        'صناعي',
                        'خدمي',
                        'حكومي',
                        'تعليمي',
                        'صحي',
                        'تقني',
                        'أخرى',
                      ]
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        setDialog(() {
                          sectorController.text = v ?? '';
                        });
                      },
                    ),

                    // ─── الحجم (Dropdown) ───
                    DropdownButtonFormField<String>(
                      initialValue: existing?.size.isNotEmpty == true
                          ? existing!.size
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'الحجم',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['صغير', 'متوسط', 'كبير', 'مؤسسي']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        setDialog(() {
                          sizeController.text = v ?? '';
                        });
                      },
                    ),

                    // ─── الفرع (Dropdown) ───
                    DropdownButtonFormField<String>(
                      initialValue: existing?.branch.isNotEmpty == true
                          ? existing!.branch
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'الفرع',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['صنعاء', 'الحديدة', 'ذمار', 'تعز', 'عدن']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        setDialog(() {
                          branchController.text = v ?? '';
                        });
                      },
                    ),

                  dialogField(
                    salesRepController,
                    'المندوب',
                  ),
                        TextField(
                        controller:
                            notes,
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
                      false,
                    ),
                    child:
                        const Text(
                      'إلغاء',
                    ),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(
                      dialogContext,
                      true,
                    ),
                    child:
                        const Text(
                      'حفظ',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true &&
        name.text
            .trim()
            .isNotEmpty) {
      final customer =
          Customer(
        id: existing?.id
                    .isNotEmpty ==
                true
            ? existing!.id
            : newId(),
        name:
            name.text.trim(),
        company:
            company.text.trim(),
        phone:
            phone.text.trim(),
        email:
            email.text.trim(),
        status: status,
        assignedTo:
            assigned.text.trim(),
        notes:
            notes.text.trim(),
          sector:
              sectorController.text.trim(),
          size:
              sizeController.text.trim(),
          branch:
              branchController.text.trim(),
          salesRep:
              salesRepController.text.trim(),
        createdAt:
            existing?.createdAt,
      );

      if (existing == null) {
        await data.addCustomer(
          customer,
        );
      } else {
        await data.updateCustomer(
          customer,
        );
      }
    }

//     name.dispose();
//     company.dispose();
//     phone.dispose();
//     email.dispose();
//     assigned.dispose();
//     notes.dispose();
  }

  /* =======================================================
     OPPORTUNITY FORM
     ======================================================= */

  Future<void> opportunityForm({
    Opportunity? existing,
  }) async {
    final title =
        TextEditingController(
      text: existing?.title ?? '',
    );

    final customer =
        TextEditingController(
      text: existing?.customer ?? '',
    );

    final value =
        TextEditingController(
      text: existing == null
          ? ''
          : '${existing.value}',
    );

    final assigned =
        TextEditingController(
      text: existing?.assignedTo ?? '',
    );

    String stage =
        existing?.stage ?? 'جديدة';

    int probability =
        existing?.probability ?? 20;

    DateTime? closeDate =
        existing?.expectedCloseDate;

    final saved =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialog) {
            return Directionality(
              textDirection:
                  TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  existing == null
                      ? 'إضافة فرصة'
                      : 'تعديل الفرصة',
                ),
                content:
                    SingleChildScrollView(
                  child: Column(
                    children: [
                      dialogField(
                        title,
                        'اسم الفرصة',
                      ),
                      dialogField(
                        customer,
                        'العميل',
                      ),
                      dialogField(
                        value,
                        'القيمة',
                        keyboardType:
                            TextInputType
                                .number,
                      ),
                      dialogField(
                        assigned,
                        'المسؤول',
                      ),
                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            stage,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'المرحلة',
                        ),
                        items: const [
                          'جديدة',
                          'مؤهلة',
                          'عرض سعر',
                          'تفاوض',
                          'مغلقة ناجحة',
                          'مغلقة خاسرة',
                        ]
                            .map(
                              (value) =>
                                  DropdownMenuItem(
                                value:
                                    value,
                                child:
                                    Text(
                                  value,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            (value) {
                          setDialog(
                            () {
                              stage =
                                  value ??
                                      stage;
                            },
                          );
                        },
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Align(
                        alignment:
                            Alignment
                                .centerRight,
                        child: Text(
                          'احتمال الإغلاق: $probability%',
                        ),
                      ),
                      Slider(
                        value: probability
                            .toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label:
                            '$probability%',
                        onChanged:
                            (value) {
                          setDialog(
                            () {
                              probability =
                                  value
                                      .round();
                            },
                          );
                        },
                      ),
                      OutlinedButton
                          .icon(
                        onPressed:
                            () async {
                          final date =
                              await showDatePicker(
                            context:
                                dialogContext,
                            initialDate:
                                closeDate ??
                                    DateTime
                                        .now(),
                            firstDate:
                                DateTime(
                              2020,
                            ),
                            lastDate:
                                DateTime(
                              2100,
                            ),
                            textDirection:
                                TextDirection
                                    .rtl,
                          );

                          if (date !=
                              null) {
                            setDialog(
                              () {
                                closeDate =
                                    date;
                              },
                            );
                          }
                        },
                        icon:
                            const Icon(
                          Icons
                              .calendar_today_outlined,
                        ),
                        label:
                            Text(
                          closeDate ==
                                  null
                              ? 'تاريخ الإغلاق المتوقع'
                              : formatDate(
                                  closeDate!,
                                ),
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
                      false,
                    ),
                    child:
                        const Text(
                      'إلغاء',
                    ),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(
                      dialogContext,
                      true,
                    ),
                    child:
                        const Text(
                      'حفظ',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true &&
        title.text
            .trim()
            .isNotEmpty) {
      final opportunity =
          Opportunity(
        id: existing?.id
                    .isNotEmpty ==
                true
            ? existing!.id
            : newId(),
        title:
            title.text.trim(),
        customer:
            customer.text.trim(),
        value:
            double.tryParse(
                  value.text.trim(),
                ) ??
                0,
        stage: stage,
        probability:
            probability,
        expectedCloseDate:
            closeDate,
        assignedTo:
            assigned.text.trim(),
        createdAt:
            existing?.createdAt,
      );

      if (existing == null) {
        await data
            .addOpportunity(
          opportunity,
        );
      } else {
        await data
            .updateOpportunity(
          opportunity,
        );
      }
    }

    title.dispose();
    customer.dispose();
    value.dispose();
//     assigned.dispose();
  }

  /* =======================================================
     TASK FORM
     ======================================================= */

  Future<void> taskForm({
    CrmTask? existing,
  }) async {
    final title =
        TextEditingController(
      text: existing?.title ?? '',
    );

    final customer =
        TextEditingController(
      text: existing?.customer ?? '',
    );

    final assignee =
        TextEditingController(
      text: existing?.assignee ?? '',
    );

    final description =
        TextEditingController(
      text: existing?.description ?? '',
    );

    String priority =
        existing?.priority ?? 'متوسطة';

    DateTime dueAt =
        existing?.dueAt ??
            DateTime.now().add(
              const Duration(
                hours: 1,
              ),
            );

    int reminder =
        existing?.reminderMinutes ??
            30;

    final saved =
        await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialog) {
            return Directionality(
              textDirection:
                  TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  existing == null
                      ? 'إضافة مهمة'
                      : 'تعديل المهمة',
                ),
                content:
                    SingleChildScrollView(
                  child: Column(
                    children: [
                      dialogField(
                        title,
                        'عنوان المهمة',
                      ),
                      dialogField(
                        customer,
                        'العميل',
                      ),
                      dialogField(
                        assignee,
                        'المسؤول',
                      ),
                      dialogField(
                        description,
                        'الوصف',
                      ),
                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            priority,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'الأولوية',
                        ),
                        items: const [
                          'منخفضة',
                          'متوسطة',
                          'عالية',
                          'عاجلة',
                        ]
                            .map(
                              (value) =>
                                  DropdownMenuItem(
                                value:
                                    value,
                                child:
                                    Text(
                                  value,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            (value) {
                          setDialog(
                            () {
                              priority =
                                  value ??
                                      priority;
                            },
                          );
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child:
                                OutlinedButton
                                    .icon(
                              onPressed:
                                  () async {
                                final date =
                                    await showDatePicker(
                                  context:
                                      dialogContext,
                                  initialDate:
                                      dueAt,
                                  firstDate:
                                      DateTime(
                                    2020,
                                  ),
                                  lastDate:
                                      DateTime(
                                    2100,
                                  ),
                                  textDirection:
                                      TextDirection
                                          .rtl,
                                );

                                if (date !=
                                    null) {
                                  setDialog(
                                    () {
                                      dueAt =
                                          DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        dueAt.hour,
                                        dueAt.minute,
                                      );
                                    },
                                  );
                                }
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .calendar_today_outlined,
                              ),
                              label:
                                  Text(
                                formatDate(
                                  dueAt,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                OutlinedButton
                                    .icon(
                              onPressed:
                                  () async {
                                final time =
                                    await showTimePicker(
                                  context:
                                      dialogContext,
                                  initialTime:
                                      TimeOfDay
                                          .fromDateTime(
                                    dueAt,
                                  ),
                                  builder:
                                      (
                                    context,
                                    child,
                                  ) {
                                    return Directionality(
                                      textDirection:
                                          TextDirection
                                              .rtl,
                                      child:
                                          child!,
                                    );
                                  },
                                );

                                if (time !=
                                    null) {
                                  setDialog(
                                    () {
                                      dueAt =
                                          DateTime(
                                        dueAt.year,
                                        dueAt.month,
                                        dueAt.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    },
                                  );
                                }
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .access_time,
                              ),
                              label:
                                  Text(
                                formatTime(
                                  dueAt,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      DropdownButtonFormField<
                          int>(
                        initialValue:
                            reminder,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'التذكير قبل',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(
                              'بدون تذكير',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text(
                              '15 دقيقة',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text(
                              '30 دقيقة',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 60,
                            child: Text(
                              'ساعة',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 1440,
                            child: Text(
                              'يوم',
                            ),
                          ),
                        ],
                        onChanged:
                            (value) {
                          setDialog(
                            () {
                              reminder =
                                  value ??
                                      reminder;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(
                      dialogContext,
                      false,
                    ),
                    child:
                        const Text(
                      'إلغاء',
                    ),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(
                      dialogContext,
                      true,
                    ),
                    child:
                        const Text(
                      'حفظ',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved == true &&
        title.text
            .trim()
            .isNotEmpty) {
      final task =
          CrmTask(
        id: existing?.id
                    .isNotEmpty ==
                true
            ? existing!.id
            : newId(),
        title:
            title.text.trim(),
        customer:
            customer.text.trim(),
        assignee:
            assignee.text.trim(),
        description:
            description.text.trim(),
        priority:
            priority,
        done:
            existing?.done ?? false,
        dueAt: dueAt,
        reminderMinutes:
            reminder,
        createdAt:
            existing?.createdAt,
      );

      if (existing == null) {
        await data.addTask(task);
      } else {
        await data.updateTask(task);
      }
    }

    title.dispose();
    customer.dispose();
    assignee.dispose();
    description.dispose();
  }

  Widget dialogField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: TextField(
        controller:
            controller,
        keyboardType:
            keyboardType,
        decoration:
            InputDecoration(
          labelText: label,
        ),
      ),
    );
  }

  /* =======================================================
     NOTIFICATIONS
     ======================================================= */

  Future<void>
      openNotifications() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Directionality(
          textDirection:
              TextDirection.rtl,
          child: SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    .75,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'التنبيهات',
                          style:
                              TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            data
                                .markAllNotificationsRead(),
                        child:
                            const Text(
                          'تعيين الكل كمقروء',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                ),
                Expanded(
                  child: data
                          .notifications
                          .isEmpty
                      ? emptyState(
                          'لا توجد تنبيهات.',
                        )
                      : ListView(
                          children:
                              data
                                  .notifications
                                  .map(
                            (
                              notification,
                            ) {
                              return ListTile(
                                leading:
                                    CircleAvatar(
                                  child:
                                      Icon(
                                    notification.type ==
                                            'overdue'
                                        ? Icons
                                            .warning_amber
                                        : Icons
                                            .notifications,
                                  ),
                                ),
                                title:
                                    Text(
                                  notification
                                      .title,
                                  style:
                                      TextStyle(
                                    fontWeight: notification.read
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                subtitle:
                                    Text(
                                  '${notification.body}\n'
                                  '${formatDateTime(notification.createdAt)}',
                                ),
                                isThreeLine:
                                    true,
                                tileColor:
                                    notification.read
                                        ? null
                                        : Theme.of(
                                            context,
                                          )
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(
                                              alpha:
                                                  .25,
                                            ),
                                onTap: () =>
                                    data
                                        .markNotificationRead(
                                  notification,
                                ),
                              );
                            },
                          ).toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /* =======================================================
     SETTINGS
     ======================================================= */

  void openTeam() {
    if (!mounted) return;
    final session = data.session;
    if (session == null) return;
    final role = session.user['role']?.toString() ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamPage(
          apiBaseUrl: apiBaseUrl,
          token: session.accessToken,
          role: role,
          myBranch: session.user['branch']?.toString(),
          canManage: true,
          canTransfer: role == 'GENERAL_MANAGER' || role == 'REGIONAL_MANAGER',
        ),
      ),
    );
  }

  void openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SettingsPage(
          data: data,
          onLogout: logout,
        ),
      ),
    );
  }

  Future<void> logout() async {
    final confirmed =
        await confirmDialog(
      'تسجيل الخروج',
      'هل تريد إنهاء الجلسة الحالية؟',
      actionText: 'خروج',
    );

    if (!confirmed) return;

    try {
      if (data.session != null &&
          apiBaseUrl.isNotEmpty) {
        await ApiClient().post(
          '/auth/logout',
          {
            'refreshToken':
                data.session!
                    .refreshToken,
          },
        );
      }
    } catch (_) {}

    await Session.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AuthPage(data: data),
      ),
      (_) => false,
    );
  }

  /* =======================================================
     DELETE
     ======================================================= */

  Future<void> deleteCustomer(
    Customer customer,
  ) async {
    final confirmed =
        await confirmDialog(
      'حذف العميل',
      'هل تريد حذف ${customer.name}؟',
    );

    if (confirmed) {
      await data.deleteCustomer(
        customer,
      );
    }
  }

  Future<void> deleteOpportunity(
    Opportunity opportunity,
  ) async {
    final confirmed =
        await confirmDialog(
      'حذف الفرصة',
      'هل تريد حذف ${opportunity.title}؟',
    );

    if (confirmed) {
      await data.deleteOpportunity(
        opportunity,
      );
    }
  }

  Future<void> deleteTask(
    CrmTask task,
  ) async {
    final confirmed =
        await confirmDialog(
      'حذف المهمة',
      'هل تريد حذف ${task.title}؟',
    );

    if (confirmed) {
      await data.deleteTask(
        task,
      );
    }
  }

  Future<bool> confirmDialog(
    String title,
    String message, {
    String actionText = 'حذف',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) =>
                  AlertDialog(
            title:
                Text(title),
            content:
                Text(message),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                  false,
                ),
                child:
                    const Text(
                  'إلغاء',
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                  true,
                ),
                child: Text(
                  actionText,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /* =======================================================
     UI HELPERS
     ======================================================= */

  Widget metric(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Icon(
              icon,
              color:
                  Colors.indigo,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              value,
              maxLines: 1,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 4,
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

  Widget section(
    String title,
    VoidCallback action,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: action,
          child:
              const Text(
            'عرض الكل',
          ),
        ),
      ],
    );
  }

  Widget emptyState(
    String message,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            const Icon(
              Icons
                  .inbox_outlined,
              size: 54,
              color:
                  Colors.black26,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
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

/* =========================================================
   SETTINGS PAGE
   ========================================================= */

class SettingsPage
    extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.data,
    required this.onLogout,
  });

  final CrmData data;
  final Future<void> Function()
      onLogout;

  @override
  State<SettingsPage> createState() =>
      _SettingsPageState();
}

class _SettingsPageState
    extends State<SettingsPage> {
  CrmData get data =>
      widget.data;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection:
          TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title:
              const Text(
            'الإعدادات',
          ),
        ),
        body: ListView(
          padding:
              const EdgeInsets.all(
            14,
          ),
          children: [
            const Text(
              'الحساب',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Card(
              child: ListTile(
                leading:
                    const CircleAvatar(
                  child: Icon(
                    Icons.business,
                  ),
                ),
                title: Text(
                  data.company
                          ?.companyName ??
                      '',
                ),
                subtitle: Text(
                  data.session?.user[
                              'email']
                          ?.toString() ??
                      '',
                ),
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'التنبيهات',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: data
                        .notificationsEnabled,
                    onChanged:
                        (value) async {
                      await data
                          .setSettings(
                        notifications:
                            value,
                      );

                      setState(
                        () {},
                      );
                    },
                    title:
                        const Text(
                      'التنبيهات داخل التطبيق',
                    ),
                    secondary:
                        const Icon(
                      Icons
                          .notifications_outlined,
                    ),
                  ),
                  const Divider(
                    height: 1,
                  ),
                  SwitchListTile(
                    value: data
                        .taskRemindersEnabled,
                    onChanged: data
                            .notificationsEnabled
                        ? (value) async {
                            await data
                                .setSettings(
                              taskReminders:
                                  value,
                            );

                            setState(
                              () {},
                            );
                          }
                        : null,
                    title:
                        const Text(
                      'تذكيرات المهام',
                    ),
                    secondary:
                        const Icon(
                      Icons
                          .alarm_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'المظهر',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Card(
              child:
                  SwitchListTile(
                value:
                    data.compactMode,
                onChanged:
                    (value) async {
                  await data
                      .setSettings(
                    compact: value,
                  );

                  setState(
                    () {},
                  );
                },
                title:
                    const Text(
                  'الوضع المختصر',
                ),
                secondary:
                    const Icon(
                  Icons
                      .view_compact_outlined,
                ),
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'البيانات',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title:
                        const Text(
                      'العملاء',
                    ),
                    trailing:
                        Text(
                      '${data.customers.length}',
                    ),
                  ),
                  const Divider(
                    height: 1,
                  ),
                  ListTile(
                    title:
                        const Text(
                      'الفرص',
                    ),
                    trailing:
                        Text(
                      '${data.opportunities.length}',
                    ),
                  ),
                  const Divider(
                    height: 1,
                  ),
                  ListTile(
                    title:
                        const Text(
                      'المهام',
                    ),
                    trailing:
                        Text(
                      '${data.tasks.length}',
                    ),
                  ),
                  const Divider(
                    height: 1,
                  ),
                  ListTile(
                    title:
                        const Text(
                      'التنبيهات',
                    ),
                    trailing:
                        Text(
                      '${data.notifications.length}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'الأمان',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            Card(
              child: const ListTile(
                leading:
                    Icon(
                  Icons.security,
                ),
                title:
                    Text(
                  'جلسة JWT',
                ),
                subtitle:
                    Text(
                  'يتم حفظ رموز الجلسة فقط ولا يتم حفظ كلمة المرور.',
                ),
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'الإصدار',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const Card(
              child: ListTile(
                leading:
                    Icon(Icons.apps),
                title:
                    Text(
                  'CRM Business',
                ),
                subtitle:
                    Text(
                  'واجهة CRM مطورة • الإصدار 4.0.0',
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            SizedBox(
              height: 52,
              child:
                  FilledButton.tonalIcon(
                onPressed:
                    widget.onLogout,
                icon: const Icon(
                  Icons.logout,
                ),
                label:
                    const Text(
                  'تسجيل الخروج',
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   HELPERS
   ========================================================= */

String newId() {
  return DateTime.now()
      .microsecondsSinceEpoch
      .toString();
}

String money(double value) {
  final number =
      value.round().toString();

  final sign =
      number.startsWith('-')
          ? '-'
          : '';

  final digits =
      sign.isEmpty
          ? number
          : number.substring(1);

  final result =
      StringBuffer(sign);

  for (var i = 0;
      i < digits.length;
      i++) {
    result.write(
      digits[i],
    );

    if ((digits.length -
                    i -
                    1) %
                3 ==
            0 &&
        i !=
            digits.length -
                1) {
      result.write(',');
    }
  }

  return result.toString();
}

String formatDate(
  DateTime date,
) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String formatTime(
  DateTime date,
) {
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String formatDateTime(
  DateTime date,
) {
  return '${formatDate(date)} ${formatTime(date)}';
}

String cleanError(
  Object error,
) {
  final message = error
      .toString()
      .replaceFirst(
        'Exception: ',
        '',
      )
      .trim();

  if (message.contains(
    'Failed host lookup',
  )) {
    return 'تعذر الوصول إلى الخادم. تحقق من الإنترنت وعنوان API.';
  }

  if (message.contains(
    'Connection refused',
  )) {
    return 'الخادم غير متاح حالياً.';
  }

  if (message.contains(
    'timed out',
  )) {
    return 'انتهت مهلة الاتصال بالخادم.';
  }

  return message.isEmpty
      ? 'حدث خطأ غير متوقع.'
      : message;
}