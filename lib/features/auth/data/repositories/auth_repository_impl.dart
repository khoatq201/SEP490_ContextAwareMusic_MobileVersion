import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
    required this.networkInfo,
    required this.dioClient,
  });

  final AuthRemoteDataSource remoteDataSource;
  final LocalStorageService localStorage;
  final NetworkInfo networkInfo;
  final DioClient dioClient;

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final authResponse = await remoteDataSource.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      await localStorage.clearDeviceSession();
      await localStorage.saveManagerAuthToken(authResponse.accessToken);
      await localStorage.saveManagerAccessTokenExpiry(authResponse.expiresAt);
      await localStorage.saveActiveSessionMode(
        LocalStorageService.sessionModeManager,
      );

      final profileResponse = await remoteDataSource.getProfile();
      final user = profileResponse.toUser();

      await localStorage.saveUser(UserModel.fromEntity(user).toJson());

      return Right(user);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Login failed. Please try again.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (_) {}
      }

      await localStorage.clearManagerSession();
      await dioClient.clearCookies();

      return const Right(null);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not sign you out right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final token = localStorage.getManagerAuthToken();
      if (token == null || token.isEmpty) {
        await localStorage.clearUser();
        return const Left(CacheFailure('No user found'));
      }

      final userJson = await localStorage.getUser();
      if (userJson != null) {
        final userModel = UserModel.fromJson(userJson);
        return Right(userModel.toEntity());
      }

      if (await networkInfo.isConnected) {
        final profileResponse = await remoteDataSource.getProfile();
        final user = profileResponse.toUser();
        await localStorage.saveUser(UserModel.fromEntity(user).toJson());
        await localStorage.saveActiveSessionMode(
          LocalStorageService.sessionModeManager,
        );
        return Right(user);
      }

      return const Left(CacheFailure('No user found'));
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not restore your session.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = localStorage.getManagerAuthToken();
      return Right(token != null && token.isNotEmpty);
    } catch (_) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return const Right(null);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not change your password right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final authResponse = await remoteDataSource.refreshToken();

      await localStorage.saveManagerAuthToken(authResponse.accessToken);
      await localStorage.saveManagerAccessTokenExpiry(authResponse.expiresAt);
      await localStorage.saveActiveSessionMode(
        LocalStorageService.sessionModeManager,
      );

      final profileResponse = await remoteDataSource.getProfile();
      final user = profileResponse.toUser();
      await localStorage.saveUser(UserModel.fromEntity(user).toJson());

      return Right(user);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not refresh your session right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
