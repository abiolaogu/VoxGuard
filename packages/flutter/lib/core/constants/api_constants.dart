/// API Constants for the ACM Platform
class ApiConstants {
  ApiConstants._();

  /// Hasura GraphQL endpoint
  static const String hasuraEndpoint = String.fromEnvironment(
    'HASURA_ENDPOINT',
    defaultValue: 'http://localhost:8080',
  );

  /// Hasura WebSocket endpoint
  static const String hasuraWsEndpoint = String.fromEnvironment(
    'HASURA_WS_ENDPOINT',
    defaultValue: 'ws://localhost:8080',
  );

  /// Hasura admin secret (for development only)
  static const String hasuraAdminSecret = String.fromEnvironment(
    'HASURA_ADMIN_SECRET',
    defaultValue: '',
  );

  /// API version
  static const String apiVersion = 'v1';

  /// GraphQL path
  static const String graphqlPath = '/v1/graphql';

  /// Full GraphQL URL
  static String get graphqlUrl => '$hasuraEndpoint$graphqlPath';

  /// Full WebSocket URL
  static String get wsUrl => '$hasuraWsEndpoint$graphqlPath';

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 10);
}
