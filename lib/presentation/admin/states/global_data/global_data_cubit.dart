import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/data_source.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/label.dart';
import '../../../../domain/entities/product.dart';
import '../../../../domain/repositories/label_repository.dart';
import '../../../../domain/repositories/product_repository.dart';

part 'global_data_state.dart';
part 'global_data_cubit.freezed.dart';

class GlobalDataCubit extends Cubit<GlobalDataState> {

  final LabelRepository _labelRepository;
  final ProductRepository _productRepository;

  GlobalDataCubit(this._labelRepository, this._productRepository) 
  : 
  super(
    GlobalDataState.initial(
      labels: DataSource(status: DataSourceStatus.loading),
      products: DataSource(status: DataSourceStatus.loading),
    )
  ) {
    loadLabels();
    loadProducts();
  }


  loadLabels() async {
    final labels = await _labelRepository.getLabels();

    switch (labels) {
      case Right(:final value):
        emit(state.copyWith(labels: DataSource(status: DataSourceStatus.loaded, data: value)));
      case Left(:final failure):
        emit(state.copyWith(labels: DataSource(status: DataSourceStatus.error, errorMessage: failure.message)));
    }
  
  }

  addLabel(Label newLabel){
    emit(
      state.copyWith(
        labels: DataSource(data: [newLabel, ...state.labels.data ?? []], status: DataSourceStatus.loaded)
      )
    );
  }

  loadProducts() async {
    final products = await _productRepository.getProducts();

    products.when(
      right: (value) => emit(
        state.copyWith(
          products: DataSource(
            status: DataSourceStatus.loaded,
            data: value,
          ),
        ),
      ),
      left: (value) => emit(
        state.copyWith(
          products: DataSource(
            status: DataSourceStatus.error,
            errorMessage: value.message,
          ),
        ),
      ),
    );
  }

}
