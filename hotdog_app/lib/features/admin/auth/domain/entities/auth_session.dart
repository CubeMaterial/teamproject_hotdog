class AuthSession {
  const AuthSession({
    required this.staffSeq,
    required this.staffEmail,
    required this.rememberMe,
    required this.createdAt,
  });

  final String staffSeq;
  final String staffEmail;
  final bool rememberMe;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'staffSeq': staffSeq,
      'staffEmail': staffEmail,
      'rememberMe': rememberMe,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static AuthSession? fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final staffSeq = json['staffSeq'];
    final staffEmail = json['staffEmail'];
    final rememberMe = json['rememberMe'];
    final createdAt = DateTime.tryParse('${json['createdAt']}');

    if (staffSeq is! String ||
        staffEmail is! String ||
        rememberMe is! bool ||
        createdAt == null) {
      return null;
    }

    return AuthSession(
      staffSeq: staffSeq,
      staffEmail: staffEmail,
      rememberMe: rememberMe,
      createdAt: createdAt,
    );
  }
}
