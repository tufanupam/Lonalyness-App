/// AI Muse — API Constants
/// Centralized endpoint and configuration constants.
library;

class ApiConstants {
  ApiConstants._();

  /// Base URL for the AI Muse backend server.
  /// Change this to your production server URL.
  static const String baseUrl = 'https://api.aimuse.app';

  /// OpenAI-compatible API endpoint for chat completions.
  static const String chatEndpoint = '/api/chat';

  /// Translation endpoint.
  static const String translateEndpoint = '/api/translate';

  /// WebRTC signaling server URL.
  static const String signalingUrl = 'wss://signaling.aimuse.app';

  /// Auth verification endpoint.
  static const String authVerify = '/api/auth/verify';

  /// Subscription webhook endpoint.
  static const String subscriptionWebhook = '/api/subscription/webhook';

  /// Default request timeout in seconds.
  static const int requestTimeout = 30;

  /// Max message length for free tier.
  static const int freeMessageLimit = 50;

  /// Max message length for premium tier.
  static const int premiumMessageLimit = -1; // unlimited
}
