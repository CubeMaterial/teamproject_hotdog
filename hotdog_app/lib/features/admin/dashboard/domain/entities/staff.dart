class Staff {
  const Staff({
    required this.staffSeq,
    required this.staffName,
    required this.staffPhone,
    required this.staffId,
    required this.staffPw,
    required this.staffDate,
    required this.staffLevel,
    required this.staffSuperSeq,
    this.staffEmail = '',
    this.staffRole = '',
  });

  final String staffSeq;
  final String staffName;
  final String staffPhone;
  final String staffId;
  final String staffPw;
  final DateTime staffDate;
  final int staffLevel;
  final String staffSuperSeq;
  final String staffEmail;
  final String staffRole;

  String get id => staffSeq;
  String get name => staffName;
  String get email {
    final emailSource = staffEmail.isNotEmpty ? staffEmail : staffId;

    if (emailSource.contains('@')) {
      return emailSource;
    }

    return '$emailSource@hotdog.com';
  }

  String get role {
    if (staffRole.isNotEmpty) {
      return staffRole;
    }

    return switch (staffLevel) {
      1 => '사원',
      2 => '주임',
      3 => '대리',
      >= 9 => '관리자',
      _ => '사원',
    };
  }

  bool get isSuper {
    final normalizedRole = staffRole.toUpperCase();

    return staffLevel >= 9 ||
        normalizedRole == 'CEO' ||
        normalizedRole == 'CTO' ||
        staffRole == '관리자';
  }
}
