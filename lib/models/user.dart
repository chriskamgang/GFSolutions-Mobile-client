class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? clientNumber;
  final String role;
  final String? agency;
  final String? agencyId;
  final bool twoFactorEnabled;
  final String? profilePhoto;
  final String? qrCode;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email = '',
    required this.phone,
    this.clientNumber,
    this.role = '',
    this.agency,
    this.agencyId,
    this.twoFactorEnabled = false,
    this.profilePhoto,
    this.qrCode,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      clientNumber: json['clientNumber'],
      role: json['role'] ?? '',
      agency: json['agency'],
      agencyId: json['agencyId'],
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      profilePhoto: json['profilePhoto'],
      qrCode: json['qrCode'],
    );
  }
}
