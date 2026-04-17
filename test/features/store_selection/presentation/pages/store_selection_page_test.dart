import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/core/session/session_cubit.dart';
import 'package:cams_store_manager/features/auth/domain/entities/user.dart';
import 'package:cams_store_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:cams_store_manager/features/auth/domain/usecases/change_password.dart';
import 'package:cams_store_manager/features/auth/domain/usecases/get_current_user.dart';
import 'package:cams_store_manager/features/auth/domain/usecases/login.dart';
import 'package:cams_store_manager/features/auth/domain/usecases/logout.dart';
import 'package:cams_store_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cams_store_manager/features/auth/presentation/bloc/auth_event.dart';
import 'package:cams_store_manager/features/store_selection/domain/entities/store_summary.dart';
import 'package:cams_store_manager/features/store_selection/domain/repositories/store_selection_repository.dart';
import 'package:cams_store_manager/features/store_selection/domain/usecases/get_user_stores.dart';
import 'package:cams_store_manager/features/store_selection/presentation/bloc/store_selection_bloc.dart';
import 'package:cams_store_manager/features/store_selection/presentation/bloc/store_selection_event.dart';
import 'package:cams_store_manager/features/store_selection/presentation/bloc/store_selection_state.dart';
import 'package:cams_store_manager/features/store_selection/presentation/pages/store_selection_page.dart';

void main() {
  group('StoreSelectionPage', () {
    late _StaticStoreSelectionBloc storeSelectionBloc;
    late _TestAuthBloc authBloc;

    setUp(() {
      storeSelectionBloc = _StaticStoreSelectionBloc(
        const [
          StoreSummary(
            id: 'store-1',
            brandId: 'brand-1',
            name: 'Downtown Flagship',
            address: '1 Main St',
            city: 'Ho Chi Minh City',
          ),
          StoreSummary(
            id: 'store-2',
            brandId: 'brand-1',
            name: 'Airport Kiosk',
            address: '2 Terminal Ave',
            city: 'Ho Chi Minh City',
          ),
        ],
      );
      authBloc = _TestAuthBloc(_brandManagerUser());
    });

    tearDown(() async {
      await storeSelectionBloc.close();
      await authBloc.close();
    });

    testWidgets('BrandManager can enter bulk governance mode', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<StoreSelectionBloc>.value(value: storeSelectionBloc),
            ],
            child: const StoreSelectionPage(),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);

      expect(authBloc.state.user?.isBrandManager, isTrue);
      expect(storeSelectionBloc.state, isA<StoreSelectionLoaded>());
      expect(find.byTooltip('Bulk governance'), findsOneWidget);

      await tester.tap(find.byTooltip('Bulk governance'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('1 selected'), findsNothing);
      expect(find.text('Set mode'), findsOneWidget);
      expect(find.text('Filtered'), findsOneWidget);
    });
  });
}

class _StaticStoreSelectionBloc extends StoreSelectionBloc {
  _StaticStoreSelectionBloc(List<StoreSummary> stores)
      : super(
          getUserStores: GetUserStores(
            _FakeStoreSelectionRepository(stores: stores),
          ),
        ) {
    emit(StoreSelectionLoaded(
      stores: stores,
      filteredStores: stores,
    ));
  }

  @override
  void add(StoreSelectionEvent event) {
    if (event is LoadUserStores) return;
    super.add(event);
  }
}

User _brandManagerUser() {
  return const User(
    id: 'user-1',
    username: 'brand.manager',
    email: 'brand@example.com',
    role: 'BrandManager',
    roles: ['BrandManager'],
    storeIds: ['store-1', 'store-2'],
  );
}

class _FakeStoreSelectionRepository implements StoreSelectionRepository {
  _FakeStoreSelectionRepository({required this.stores});

  final List<StoreSummary> stores;

  @override
  Future<Either<Failure, List<StoreSummary>>> getUserStores() async {
    return Right(stores);
  }
}

class _TestAuthBloc extends AuthBloc {
  _TestAuthBloc(User user)
      : super(
          login: Login(_NoopAuthRepository(user)),
          logout: Logout(_NoopAuthRepository(user)),
          getCurrentUser: GetCurrentUser(_NoopAuthRepository(user)),
          changePassword: ChangePassword(_NoopAuthRepository(user)),
          sessionCubit: SessionCubit(localStorage: LocalStorageService()),
        ) {
    add(const AuthUserLoaded());
  }
}

class _NoopAuthRepository implements AuthRepository {
  const _NoopAuthRepository(this.user);

  final User user;

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    return Right(user);
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    return Right(user);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    return Right(user);
  }
}
