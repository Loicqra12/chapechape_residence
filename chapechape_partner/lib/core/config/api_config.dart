class ApiConfig {
  final String baseUrl;
  final String wsUrl;

  const ApiConfig({
    required this.baseUrl,
    required this.wsUrl,
  });

  factory ApiConfig.development() {
    return const ApiConfig(
      baseUrl: 'http://192.168.1.66:4000/api',
      wsUrl: 'ws://192.168.1.66:4000/ws',
    );
  }

  factory ApiConfig.production() {
    return const ApiConfig(
      baseUrl: 'https://api.chapechape.com/api',
      wsUrl: 'wss://api.chapechape.com/ws',
    );
  }
}
