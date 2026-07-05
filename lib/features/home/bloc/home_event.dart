import 'package:equatable/equatable.dart';
import '../../../models/workout.dart';
import '../../../models/protein_entry.dart';
import '../../../models/schedule_event.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadData extends HomeEvent {
  final bool isRefresh;
  const HomeLoadData({this.isRefresh = false});
}

class HomeLoadMoreFeed extends HomeEvent {}

class HomeChangeTab extends HomeEvent {
  final int tabIndex;
  const HomeChangeTab(this.tabIndex);
  @override
  List<Object?> get props => [tabIndex];
}

class HomeBackgroundSync extends HomeEvent {}
