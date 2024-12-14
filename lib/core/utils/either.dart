import 'package:freezed_annotation/freezed_annotation.dart';

part 'either.freezed.dart';

@freezed
class Either<L, R> with _$Either<L, R> {
  /// Representa el caso de fallo (Left).
  const factory Either.left(L failure) = Left<L, R>;

  /// Representa el caso de éxito (Right).
  const factory Either.right(R value) = Right<L, R>;
}