import 'package:equatable/equatable.dart';

enum WeightliftingStatus { initial, loading, success, failure }

class WeightliftingState extends Equatable {
  final WeightliftingStatus status;
  final String? errorMessage;
  final String? subTypeStr;

  const WeightliftingState({
    this.status = WeightliftingStatus.initial,
    this.errorMessage,
    this.subTypeStr,
  });

  WeightliftingState copyWith({
    WeightliftingStatus? status,
    String? errorMessage,
    String? subTypeStr,
  }) {
    return WeightliftingState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      subTypeStr: subTypeStr ?? this.subTypeStr,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, subTypeStr];
}
