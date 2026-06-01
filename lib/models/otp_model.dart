// Autor: João Vitor Roventini
// RA: 22005168

class OtpModel {
  final String code;
  final DateTime expiresAt;

  OtpModel({required this.code, required this.expiresAt});

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory OtpModel.fromMap(Map<String, dynamic> map) {
    return OtpModel(
      code: map['code'],
      expiresAt: DateTime.parse(map['expiresAt']),
    );
  }
}