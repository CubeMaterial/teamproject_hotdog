import 'staff.dart';

class StaffCreationResult {
  const StaffCreationResult({
    required this.staff,
    required this.emailSent,
    required this.emailSubject,
    required this.emailBody,
    required this.emailWarning,
  });

  final Staff staff;
  final bool emailSent;
  final String emailSubject;
  final String emailBody;
  final String emailWarning;
}
