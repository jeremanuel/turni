import 'domain_error.dart';
import 'either.dart';

typedef RepositoryResponse<T> = Either<DomainError, T>;