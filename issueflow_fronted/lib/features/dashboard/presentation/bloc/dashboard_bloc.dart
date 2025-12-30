import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_dashboard_home_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardHomeUseCase getHome;

  DashboardBloc({required this.getHome}) : super(DashboardInitial()) {
    on<LoadDashboardHome>(_onLoad);
    on<RefreshDashboardHome>(_onLoad);
  }

  Future<void> _onLoad(DashboardEvent event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final data = await getHome();
      emit(DashboardLoaded(data));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(DashboardError(msg));
    }
  }
}
