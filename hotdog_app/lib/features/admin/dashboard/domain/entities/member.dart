class Member {
  const Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final DateTime joinedAt;
}
