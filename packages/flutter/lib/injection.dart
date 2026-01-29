import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ferry/ferry.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/network/graphql_client.dart';
import 'core/network/network_info.dart';

final getIt = GetIt.instance;

/// Configure dependency injection
@InjectableInit()
Future<void> configureDependencies() async {
  // Core dependencies
  
  // Network info
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(),
  );
  
  // GraphQL Client (Ferry)
  final graphqlClient = await initGraphQLClient();
  getIt.registerSingleton<Client>(graphqlClient);
  
  // Hive boxes
  final settingsBox = await Hive.openBox('settings');
  getIt.registerSingleton<Box>(settingsBox);
  
  // Register features
  await _registerAntiMaskingFeature();
  await _registerRemittanceFeature();
  await _registerMarketplaceFeature();
  await _registerAuthFeature();
}

Future<void> _registerAntiMaskingFeature() async {
  // Data sources
  // getIt.registerLazySingleton<AntiMaskingRemoteDataSource>(
  //   () => AntiMaskingRemoteDataSourceImpl(client: getIt()),
  // );
  
  // Repositories
  // getIt.registerLazySingleton<AntiMaskingRepository>(
  //   () => AntiMaskingRepositoryImpl(
  //     remoteDataSource: getIt(),
  //     networkInfo: getIt(),
  //   ),
  // );
  
  // Use cases
  // getIt.registerLazySingleton(() => VerifyCall(getIt()));
  // getIt.registerLazySingleton(() => GetVerificationHistory(getIt()));
  // getIt.registerLazySingleton(() => ReportMasking(getIt()));
}

Future<void> _registerRemittanceFeature() async {
  // TODO: Register remittance dependencies
}

Future<void> _registerMarketplaceFeature() async {
  // TODO: Register marketplace dependencies
}

Future<void> _registerAuthFeature() async {
  // TODO: Register auth dependencies
}
