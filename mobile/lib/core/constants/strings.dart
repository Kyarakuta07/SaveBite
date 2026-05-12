/// App-wide string constants (Indonesian locale).
class Strings {
  const Strings._();

  static const String appName = 'SaveBite';
  static const String tagline = 'Selamatkan Makanan, Hemat Pengeluaran';

  // Order status
  static const Map<String, String> orderStatus = {
    'pending': 'Menunggu Bayar',
    'confirmed': 'Dikonfirmasi',
    'picked_up': 'Diambil Kurir',
    'delivered': 'Sudah Tiba',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
  };

  // Delivery status
  static const Map<String, String> deliveryStatus = {
    'searching': 'Mencari kurir...',
    'driver_found': 'Kurir ditemukan',
    'picked_up': 'Pesanan diambil kurir',
    'on_the_way': 'Dalam perjalanan',
    'delivered': 'Pesanan tiba!',
    'failed': 'Pengiriman gagal',
  };

  // Errors
  static const String networkError = 'Tidak ada koneksi internet';
  static const String serverError = 'Terjadi kesalahan server';
  static const String sessionExpired =
      'Sesi telah berakhir, silakan login kembali';
  static const String unknownError = 'Terjadi kesalahan';
}
