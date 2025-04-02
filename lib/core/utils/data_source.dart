class DataSource<T> {

  final T? data;
  final DataSourceStatus status;
  final String? errorMessage;

  DataSource({this.data, required this.status, this.errorMessage});

}

enum DataSourceStatus {
  loading,
  loaded,
  error
}