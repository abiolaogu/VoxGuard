import 'package:ferry/ferry.dart';
import 'package:ferry_hive_store/ferry_hive_store.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:gql_websocket_link/gql_websocket_link.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gql_exec/gql_exec.dart' as gql_exec;

import '../constants/api_constants.dart';

/// Initialize the Ferry GraphQL client
Future<Client> initGraphQLClient() async {
  // Open Hive box for cache
  final box = await Hive.openBox<Map<String, dynamic>>('graphql_cache');

  // Create cache with Hive store
  final store = HiveStore(box);
  final cache = Cache(store: store);

  // Get auth token from secure storage
  const secureStorage = FlutterSecureStorage();
  final authToken = await secureStorage.read(key: 'auth_token');

  // Create HTTP link with authentication
  final httpLink = HttpLink(
    ApiConstants.graphqlUrl,
    defaultHeaders: {
      if (authToken != null) 'Authorization': 'Bearer $authToken',
      if (ApiConstants.hasuraAdminSecret.isNotEmpty)
        'x-hasura-admin-secret': ApiConstants.hasuraAdminSecret,
      'Content-Type': 'application/json',
    },
  );

  // Create WebSocket link for subscriptions
  final wsLink = WebSocketLink(
    ApiConstants.wsUrl,
    initialPayload: () async {
      final token = await secureStorage.read(key: 'auth_token');
      return {
        'headers': {
          if (token != null) 'Authorization': 'Bearer $token',
          if (ApiConstants.hasuraAdminSecret.isNotEmpty)
            'x-hasura-admin-secret': ApiConstants.hasuraAdminSecret,
        },
      };
    },
  );

  // Split link - use WebSocket for subscriptions, HTTP for queries/mutations
  final link = Link.split(
    (request) => request.isSubscription,
    wsLink,
    httpLink,
  );

  // Create and return Ferry client
  return Client(
    link: link,
    cache: cache,
    defaultFetchPolicies: {
      OperationType.query: FetchPolicy.CacheFirst,
      OperationType.mutation: FetchPolicy.NetworkOnly,
      OperationType.subscription: FetchPolicy.NetworkOnly,
    },
  );
}

/// Create a fresh client with new auth headers
Future<Client> refreshGraphQLClient() async {
  return initGraphQLClient();
}

/// Extension for checking request type
extension on OperationRequest {
  bool get isSubscription {
    // Check if the operation is a subscription by looking at the operation definition
    return operation.document.definitions.any((def) {
      if (def is gql_exec.OperationDefinitionNode) {
        return def.type == gql_exec.OperationType.subscription;
      }
      return false;
    });
  }
}
