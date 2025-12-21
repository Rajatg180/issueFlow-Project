import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'package:issueflow_fronted/features/onboarding/domain/usecase/complete_onboarding_usecase.dart';
import 'package:issueflow_fronted/features/onboarding/domain/usecase/setup_onboarding_usecase.dart';
import 'package:issueflow_fronted/features/onboarding/presentation/bloc/onboarding_bloc.dart';

import 'package:issueflow_fronted/features/projects/data/repositories/invites_repository_impl.dart';
import 'package:issueflow_fronted/features/projects/domain/repositories/invites_repository.dart';
import 'package:issueflow_fronted/features/projects/domain/usecases/accept_invite_usecase.dart';
import 'package:issueflow_fronted/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:issueflow_fronted/features/projects/domain/usecases/invite_members_usecase.dart';
import 'package:issueflow_fronted/features/projects/domain/usecases/list_my_invites_usecase.dart';
import 'package:issueflow_fronted/features/projects/domain/usecases/update_project_preference_usecase.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/invite/invites_bloc.dart';
import 'package:issueflow_fronted/features/projects/presentation/cubit/invite_members_cubit.dart';

import '../storage/token_storage.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/firebase_auth_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/firebase_login_usecase.dart';
import '../../features/auth/domain/usecases/get_me_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';

import 'package:issueflow_fronted/features/projects/data/datasources/projects_remote_datasource.dart';
import 'package:issueflow_fronted/features/projects/data/repositories/projects_repository_impl.dart';
import 'package:issueflow_fronted/features/projects/domain/repositories/projects_repository.dart';
import 'package:issueflow_fronted/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:issueflow_fronted/features/projects/domain/usecases/list_projects_usecase.dart';
import 'package:issueflow_fronted/features/projects/presentation/bloc/project/projects_bloc.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ---------------------------
  // External
  // ---------------------------
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // ---------------------------
  // Core
  // ---------------------------
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());

  // Firebase Google sign-in helper (mobile/web)
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());

  // ---------------------------
  // AUTH - DataSources
  // ---------------------------
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(client: sl<http.Client>()),
  );

  // ---------------------------
  // AUTH - Repository
  // ---------------------------
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl<AuthRemoteDataSource>(),
      tokenStorage: sl<TokenStorage>(),
      firebaseAuthService: sl<FirebaseAuthService>(),
    ),
  );

  // ---------------------------
  // AUTH - UseCases
  // ---------------------------
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<GetMeUseCase>(() => GetMeUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<FirebaseLoginUseCase>(() => FirebaseLoginUseCase(sl<AuthRepository>()));

  // ---------------------------
  // ONBOARDING - DataSources
  // ---------------------------
  sl.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceImpl(
      client: sl<http.Client>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  // ---------------------------
  // ONBOARDING - Repository
  // ---------------------------
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl<OnboardingRemoteDataSource>()),
  );

  // ---------------------------
  // ONBOARDING - UseCases
  // ✅ IMPORTANT: Explicit generic types to avoid "Lookup failed" on some builds
  // ---------------------------
  sl.registerLazySingleton<CompleteOnboardingUseCase>(
    () => CompleteOnboardingUseCase(sl<OnboardingRepository>()),
  );
  sl.registerLazySingleton<SetupOnboardingUseCase>(
    () => SetupOnboardingUseCase(sl<OnboardingRepository>()),
  );

  // ---------------------------
  // BLoCs
  // ---------------------------
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      firebaseLoginUseCase: sl<FirebaseLoginUseCase>(),
      getMeUseCase: sl<GetMeUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
    ),
  );

  sl.registerFactory<OnboardingBloc>(
    () => OnboardingBloc(
      setupOnboardingUseCase: sl<SetupOnboardingUseCase>(),
      completeOnboardingUseCase: sl<CompleteOnboardingUseCase>(),
    ),
  );

  // ---------------------------
  // PROJECTS - DataSource
  // ---------------------------
  sl.registerLazySingleton<ProjectsRemoteDataSource>(
    () => ProjectsRemoteDataSource(
      client: sl<http.Client>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  // ---------------------------
  // PROJECTS - Repository
  // ---------------------------
  sl.registerLazySingleton<ProjectsRepository>(
    () => ProjectsRepositoryImpl(remote: sl<ProjectsRemoteDataSource>()),
  );

  // ---------------------------
  // PROJECTS - UseCases
  // ✅ also made explicit (safe + consistent)
  // ---------------------------
  sl.registerLazySingleton<ListProjectsUseCase>(() => ListProjectsUseCase(sl<ProjectsRepository>()));
  sl.registerLazySingleton<CreateProjectUseCase>(() => CreateProjectUseCase(sl<ProjectsRepository>()));
  sl.registerLazySingleton<DeleteProjectUseCase>(() => DeleteProjectUseCase(sl<ProjectsRepository>()));
  sl.registerLazySingleton<UpdateProjectPreferenceUseCase>(
    () => UpdateProjectPreferenceUseCase(sl<ProjectsRepository>()),
  );

  // ---------------------------
  // PROJECTS - Bloc
  // ---------------------------
  sl.registerFactory<ProjectsBloc>(
    () => ProjectsBloc(
      listProjectsUseCase: sl<ListProjectsUseCase>(),
      createProjectUseCase: sl<CreateProjectUseCase>(),
      deleteProjectUseCase: sl<DeleteProjectUseCase>(),
      updateProjectPreferenceUseCase: sl<UpdateProjectPreferenceUseCase>(),
    ),
  );

  // =========================================================
  // ✅ INVITES
  // =========================================================

  // Repository
  sl.registerLazySingleton<InvitesRepository>(
    () => InvitesRepositoryImpl(remote: sl<ProjectsRemoteDataSource>()),
  );

  // UseCases (explicit)
  sl.registerLazySingleton<ListMyInvitesUseCase>(() => ListMyInvitesUseCase(sl<InvitesRepository>()));
  sl.registerLazySingleton<AcceptInviteUseCase>(() => AcceptInviteUseCase(sl<InvitesRepository>()));
  sl.registerLazySingleton<InviteMembersUseCase>(() => InviteMembersUseCase(sl<InvitesRepository>()));

  // Bloc + Cubit
  sl.registerFactory<InvitesBloc>(
    () => InvitesBloc(
      listMyInvitesUseCase: sl<ListMyInvitesUseCase>(),
      acceptInviteUseCase: sl<AcceptInviteUseCase>(),
    ),
  );

  sl.registerFactory<InviteMembersCubit>(
    () => InviteMembersCubit(
      inviteMembersUseCase: sl<InviteMembersUseCase>(),
    ),
  );
}
