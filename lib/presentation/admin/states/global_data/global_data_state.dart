part of 'global_data_cubit.dart';

@freezed
class GlobalDataState with _$GlobalDataState {
  const factory GlobalDataState.initial({
    required DataSource<List<Label>> labels
  }) = _Initial;
}
