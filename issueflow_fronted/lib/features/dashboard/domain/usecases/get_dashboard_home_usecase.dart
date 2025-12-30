import '../entities/dashboard_entities.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardHomeUseCase {
  final DashboardRepository repo;
  GetDashboardHomeUseCase(this.repo);

  Future<DashboardHomeEntity> call() => repo.getDashboardHome();
}
