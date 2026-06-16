class TemporaryAdminCredentials {
  const TemporaryAdminCredentials();

  static const loginId = '1004@hotdog.com';
  static const staffSeq = '1004';
  static const staffName = 'Master Admin';
  static const password = '12345';

  bool matches({required String loginId, required String password}) {
    return loginId.trim().toLowerCase() == TemporaryAdminCredentials.loginId &&
        password == TemporaryAdminCredentials.password;
  }
}
