class ApiConstants {
  // Base URL: Use 10.0.2.2 for Android Emulator, localhost for iOS / Web
  static const String baseUrl = 'http://10.0.2.2:5001';

  // Auth endpoints
  static const String login = '/api/login';
  static const String register = '/api/register';
  static const String logout = '/api/logout';
  static const String forgotPassword = '/api/forgot-password';
  static const String resetPassword = '/api/reset-password';
  static const String profile = '/api/profile';

  // Customers endpoints
  static const String customers = '/api/customers';
  static String customerDetails(int id) => '/api/customers/$id';
  static String customerActivity(int id) => '/api/customers/$id/activity';
  static String customerStatement(int id) => '/api/customers/$id/statement';
  static String customerStatementPdf(int id) => '/api/customers/$id/statement/pdf';
  static String customerStatementSend(int id) => '/api/customers/$id/statement/send';

  // Items endpoints
  static const String items = '/api/items';
  static String itemDetails(int id) => '/api/items/$id';
  static String itemHistory(int id) => '/api/items/$id/history';

  // Quotes endpoints
  static const String quotes = '/api/quotes';
  static String quoteDetails(int id) => '/api/quotes/$id';

  // Invoices endpoints
  static const String invoices = '/api/invoices';
  static String invoiceDetails(int id) => '/api/invoices/$id';

  // Expenses endpoints
  static const String expenses = '/api/expenses';
  static String expenseDetails(int id) => '/api/expenses/$id';

  // Dashboard endpoints
  static const String financeSummary = '/api/dashboard/finance-summary';
  static const String monthlyFinanceSummary = '/api/dashboard/monthly-finance-summary';

  // Documents endpoints
  static const String documents = '/api/documents';
  static String documentDetails(int id) => '/api/documents/$id';
  static String documentDownload(int id) => '/api/documents/$id/download';

  // Users endpoints
  static const String users = '/api/users';
  static String userRole(int id) => '/api/users/$id/role';
  static const String organizationSettings = '/api/organization-settings';

  // Vendors endpoints
  static const String vendors = '/api/vendors';
  static String vendorDetails(int id) => '/api/vendors/$id';
}
