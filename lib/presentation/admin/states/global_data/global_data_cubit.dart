import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/data_source.dart';
import '../../../../domain/entities/label.dart';
import '../../../../domain/repositories/label_repository.dart';

part 'global_data_state.dart';
part 'global_data_cubit.freezed.dart';

class GlobalDataCubit extends Cubit<GlobalDataState> {

  final LabelRepository _labelRepository;

  GlobalDataCubit(this._labelRepository) 
  : 
  super(
    GlobalDataState.initial(
      labels: DataSource(status: DataSourceStatus.loading)
    )
  ) {
    loadLabels();
  }


  loadLabels() async {
    final labels = await _labelRepository.getLabels();

    labels.when(
      right: (value) => emit(state.copyWith(labels: DataSource(status: DataSourceStatus.loaded, data: value))),
      left: (value) => emit(state.copyWith(labels: DataSource(status: DataSourceStatus.error, errorMessage: value.message)))
    );
  
  }

  addLabel(Label newLabel){
    emit(
      state.copyWith(
        labels: DataSource(data: [newLabel, ...state.labels.data ?? []], status: DataSourceStatus.loaded)
      )
    );
  }

}
