/// Payment Gateway Credentials
///
/// WARNING: This file contains test credentials. Before production:
/// 1. Replace with real client credentials from OnePay merchant dashboard
/// 2. Add this file to .gitignore to prevent credential leaks
/// 3. Never commit real credentials to version control

class AppSecrets {
  // ─── OnePay Test Credentials (Development Only) ───
  // These are placeholder test credentials. Replace before going live.

  static const String onepayAppId = "80NR1189D04CD635D8ACD";
  static const String onepayHashToken = "GR2P1189D04CD635D8AFD";
  static const String onepayAppToken = "ca00d67bf74d77b01fa26dc6780d7ff9522d8f82d30ff813d4c605f2662cea9ad332054cc66aff68.EYAW1189D04CD635D8B20";

  // ─── Production Credentials (To be replaced by client) ───
  // static const String onepayAppId = "REPLACE_WITH_CLIENT_APP_ID";
  // static const String onepayHashToken = "REPLACE_WITH_CLIENT_HASH_TOKEN";
  // static const String onepayAppToken = "REPLACE_WITH_CLIENT_APP_TOKEN";

  AppSecrets._(); // Private constructor to prevent instantiation
}
