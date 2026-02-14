import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
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

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final userModel = await remoteDataSource.login(
        username: username,
        password: password,
      );

      // Save user to local storage
      await localStorage.saveUser(userModel.toJson());
      await localStorage.saveAuthToken('mock_token_${userModel.id}');

      return Right(userModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to login: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Call API to logout
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }

      // Clear local storage
      await localStorage.clearAuthToken();
      await localStorage.clearUser();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to logout: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userJson = await localStorage.getUser();
      if (userJson != null) {
        final userModel = UserModel.fromJson(userJson);
        return Right(userModel.toEntity());
      }

      // If no local user, try to fetch from server
      if (await networkInfo.isConnected) {
        final userModel = await remoteDataSource.getCurrentUser();
        await localStorage.saveUser(userModel.toJson());
        return Right(userModel.toEntity());
      }

      return const Left(CacheFailure('No user found'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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
  Future<Either<Failure, String>> requestPasswordReset(String email) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final message = await remoteDataSource.requestPasswordReset(email);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to request password reset: $e'));
    }
  }
}
