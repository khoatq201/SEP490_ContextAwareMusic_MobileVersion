import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final LocalStorageService localStorage;
  final NetworkInfo networkInfo;
  final DioClient dioClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
    required this.networkInfo,
    required this.dioClient,
  });

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
      // 1. Call login API → get accessToken + expiresAt + roles
      final authResponse = await remoteDataSource.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      // 2. Save access token & expiry
      await localStorage.saveAuthToken(authResponse.accessToken);
      await localStorage.saveAccessTokenExpiry(authResponse.expiresAt);

      // 3. Fetch full profile
      final profileResponse = await remoteDataSource.getProfile();
      final user = profileResponse.toUser();

      // 4. Save user locally for offline / cache-first reads
      await localStorage.saveUser(UserModel.fromEntity(user).toJson());

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to login: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call API to logout (invalidate refresh token cookie on server)
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (_) {
          // Even if logout API fails, we still clear local state
        }
      }

      // Clear local storage & cookies
      await localStorage.clearAuthToken();
      await localStorage.clearUser();
      await dioClient.clearCookies();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to logout: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Cache-first: check local storage
      final userJson = await localStorage.getUser();
      if (userJson != null) {
        final userModel = UserModel.fromJson(userJson);
        return Right(userModel.toEntity());
      }

      // Fallback: fetch from API if online
      if (await networkInfo.isConnected) {
        final token = await localStorage.getAuthToken();
        if (token != null && token.isNotEmpty) {
          final profileResponse = await remoteDataSource.getProfile();
          final user = profileResponse.toUser();
          await localStorage.saveUser(UserModel.fromEntity(user).toJson());
          return Right(user);
        }
      }

      return const Left(CacheFailure('No user found'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthenticationException {
      return const Left(ServerFailure('Session expired. Please login again.'));
    } catch (e) {
      return Left(CacheFailure('Failed to get current user: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = await localStorage.getAuthToken();
      return Right(token != null && token.isNotEmpty);
    } catch (e) {
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to change password: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // 1. Call refresh-token API (uses HttpOnly cookie)
      final authResponse = await remoteDataSource.refreshToken();

      // 2. Save new access token & expiry
      await localStorage.saveAuthToken(authResponse.accessToken);
      await localStorage.saveAccessTokenExpiry(authResponse.expiresAt);

      // 3. Fetch updated profile
      final profileResponse = await remoteDataSource.getProfile();
      final user = profileResponse.toUser();
      await localStorage.saveUser(UserModel.fromEntity(user).toJson());

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to refresh token: $e'));
    }
  }
}
