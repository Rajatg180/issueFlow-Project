import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remote;
  DashboardRepositoryImpl({required this.remote});

  @override
  Future<DashboardHomeEntity> getDashboardHome() => remote.getDashboardHome();
}
