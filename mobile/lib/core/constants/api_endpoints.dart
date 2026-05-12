import '../config/app_env.dart';

/// API endpoint constants matching backend API_DESIGN.md v1.1 (66 endpoints).
///
/// Base URL is now sourced from [AppEnv.apiBaseUrl] (compile-time `--dart-define`).
/// See `core/config/app_env.dart` for usage instructions.
class ApiEndpoints {
  const ApiEndpoints._();

  /// Base URL — sourced from compile-time `--dart-define=API_BASE_URL=...`.
  /// Defaults to `http://10.0.2.2:8000/api/v1` (Android emulator).
  static String get baseUrl => AppEnv.apiBaseUrl;

  static Duration get connectTimeout => AppEnv.connectTimeout;
  static Duration get receiveTimeout => AppEnv.receiveTimeout;

  // Auth — User (7)
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/me'; // PUT — multipart
  static const String updatePassword = '/auth/me/password';
  static const String updateFcmToken = '/auth/me/fcm-token';

  // Auth — Merchant (7)
  static const String merchantRegister = '/merchant/auth/register';
  static const String merchantLogin = '/merchant/auth/login';
  static const String merchantLogout = '/merchant/auth/logout';
  static const String merchantMe = '/merchant/auth/me';
  static const String merchantUpdatePassword = '/merchant/auth/me/password';
  static const String merchantUpdateFcmToken = '/merchant/auth/me/fcm-token';

  // Food Items — User (4)
  static const String foodItems = '/food-items';
  static const String flashSale = '/food-items/flash-sale';
  static String foodItem(int id) => '/food-items/$id';
  static String merchantProfile(int id) => '/merchants/$id';

  // Food Items — Merchant (5)
  static const String merchantFoodItems = '/merchant/food-items';
  static String merchantFoodItem(int id) => '/merchant/food-items/$id';
  static String merchantFoodItemStock(int id) =>
      '/merchant/food-items/$id/stock';
  static String merchantDeleteFoodItem(int id) => '/merchant/food-items/$id';

  // Orders — User (6)
  static const String orders = '/orders';
  static String order(int id) => '/orders/$id';
  static String orderComplete(int id) => '/orders/$id/complete';
  static String orderCancel(int id) => '/orders/$id/cancel';
  static String orderReorder(int id) => '/orders/$id/reorder';

  // Orders — Merchant (2)
  static const String merchantOrders = '/merchant/orders';
  static String merchantOrder(int id) => '/merchant/orders/$id';

  // Deliveries (2)
  static String delivery(int id) => '/orders/$id/delivery';
  static String selfPickup(int id) => '/orders/$id/self-pickup';

  // Reviews (3)
  static String createReview(int orderId) => '/orders/$orderId/review';
  static String merchantReviews(int id) => '/merchants/$id/reviews';
  static String replyReview(int id) => '/merchant/reviews/$id/reply';

  // Disputes (2)
  static String createDispute(int orderId) => '/orders/$orderId/dispute';
  static String dispute(int id) => '/disputes/$id';

  // Follow & Notifications (5)
  static String followMerchant(int id) => '/merchants/$id/follow';
  static const String follows = '/me/follows';
  static const String notifications = '/me/notifications';
  static const String readAllNotifications = '/me/notifications/read-all';

  // Wallet — User (3)
  static const String wallet = '/me/wallet';
  static const String walletTopup = '/me/wallet/topup';
  static const String walletTransactions = '/me/wallet/transactions';

  // Wallet — Merchant (3)
  static const String merchantWallet = '/merchant/wallet';
  static const String merchantWalletTransactions =
      '/merchant/wallet/transactions';
  static const String merchantWalletWithdraw = '/merchant/wallet/withdraw';

  // Addresses (5)
  static const String addresses = '/me/addresses';
  static String address(int id) => '/me/addresses/$id';
  static String setDefaultAddress(int id) => '/me/addresses/$id/default';
}
