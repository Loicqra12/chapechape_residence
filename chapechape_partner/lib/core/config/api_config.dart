class ApiConfig {
  final String baseUrl;
  final String wsUrl;

  const ApiConfig({
    required this.baseUrl,
    required this.wsUrl,
  });

  factory ApiConfig.development() {
    return const ApiConfig(
      baseUrl: 'http://localhost:4000/api',  // Mise à jour du port pour correspondre au backend
      wsUrl: 'ws://localhost:4000/ws',
    );
  }

  factory ApiConfig.production() {
    return const ApiConfig(
      baseUrl: 'https://api.chapechape.com/api',
      wsUrl: 'wss://api.chapechape.com/ws',
    );
  }
}
