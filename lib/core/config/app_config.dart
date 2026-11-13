class AppConfig {
  static const String insforgeUrl = 'https://w8a8emnb.us-east.insforge.app';
  static const String anonKey = 'YOUR_INSFORGE_ANON_KEY';
  static const String apiKey = 'YOUR_INSFORGE_API_KEY';

  /// Groq key used directly by the AI advisor chat.
  ///
  /// NOTE: this ships inside the client bundle. It is fine for a demo/portfolio
  /// build; for production move it behind a server (edge function or proxy).
  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String groqModel = 'openai/gpt-oss-120b';
  static const String groqFallbackModel = 'openai/gpt-oss-20b';
  static const String groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
}
