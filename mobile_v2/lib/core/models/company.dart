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
      companyName: json['companyName']?.toString() ?? '',
      managerName: json['managerName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}
