class PayPalConfig {
  static const String clientId = 'ARqht7xxhqOF0qCc6HiF4kIghfcg4UQZbNuUDxKfTIllMCm3pRMQAqz7d0SX4bDwoppTfpoOahuhoVxM';
  static const String secret = 'EMwQ4lt9hyPrFieM-Ib60Pr-bXW1XkxlyjDdOhske6Z1PU0alw2p26efE3npWMfNPctSZxoRM8Z_WYO9';
  static const String baseUrl = 'https://api-m.sandbox.paypal.com';

  static const String returnUrl = 'http://127.0.0.1:3000/payment/success';
  static const String cancelUrl = 'http://127.0.0.1:3000/payment/cancel';
}
