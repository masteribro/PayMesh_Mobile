import '../../core/constants/app_constants.dart';
import '../../data/datasource/remote_datasource.dart';
import '../../data/datasource/local_datasource.dart';
import '../../data/repository/auth_repository.dart';
import '../../data/repository/transaction_repository.dart';
import 'package:dio/dio.dart';

import '../../data/repository/user_repository.dart';

/// Initialize all repositories and services
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  late final RemoteDataSource _remoteDataSource;
  late final LocalDataSource _localDataSource;
  late final AuthRepository _authRepository;
  late final UserRepository _userRepository;
  late final TransactionRepository _transactionRepository;

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  void setupServiceLocator() {
    // Setup Dio
    final dio = Dio(
      BaseOptions(
        baseUrl: Constants.baseUrl,
        connectTimeout: Constants.connectTimeout,
        receiveTimeout: Constants.receiveTimeout,
      ),
    );

    // Setup data sources
    _remoteDataSource = RemoteDataSource(dio: dio);
    _localDataSource = LocalDataSource();

    // Setup repositories
    _authRepository = AuthRepository(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
    );

    _userRepository = UserRepository(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
    );

    _transactionRepository = TransactionRepository(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
    );
  }

  // Getters
  AuthRepository get authRepository => _authRepository;
  UserRepository get userRepository => _userRepository;
  TransactionRepository get transactionRepository => _transactionRepository;
  LocalDataSource get localDataSource => _localDataSource;
}
