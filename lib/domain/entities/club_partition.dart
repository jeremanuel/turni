
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';
import 'club_type.dart';
import 'partition_vocabulary.dart';
import 'physical_partition.dart';
import 'subscription/subscription.dart';

part 'club_partition.freezed.dart';
part 'club_partition.g.dart';

@freezed
sealed class ClubPartition with _$ClubPartition {


    const factory ClubPartition({
      int? club_partition_id,
      required int club_id,
      @JsonKey(fromJson: ValueTransformers.fromJsonInt)
      required int club_type_id,
      String? phone,
      /// Nombre del servicio ("Pádel techado"). null = el de su tipo. Para
      /// mostrarlo, `displayName`.
      String? name,
      // Overrides del vocabulario del tipo. null = usa el del tipo.
      @JsonKey(name: 'physical_partition_name') String? physicalPartitionName,
      @JsonKey(name: 'physical_partition_plural') String? physicalPartitionPlural,
      @JsonKey(name: 'participant_singular') String? participantSingular,
      @JsonKey(name: 'participant_plural') String? participantPlural,
      /// Vocabulario resuelto por el backend. Usar `PartitionVocabulary.of`,
      /// que lo resuelve localmente cuando el endpoint no lo manda.
      @JsonKey(fromJson: PartitionVocabulary.fromJsonNullable, includeToJson: false)
      PartitionVocabulary? vocabulary,
      @Default(true) bool active,

      // Relations
      @JsonKey(name: "partition_physical")
      List<PhysicalPartition>? physicalPartitions,
       @JsonKey(name: "club_type")
      ClubType? clubType,
      @JsonKey(name: "subscription")
      List<Subscription>? subscriptions,

  }) = _ClubPartition;


    factory ClubPartition.fromJson(Map<String, dynamic> json) => _$ClubPartitionFromJson(json);


}

extension ClubPartitionDisplayName on ClubPartition {
  /// Nombre del servicio para mostrar: el propio o, si no tiene, el de su
  /// tipo ("Pádel").
  String get displayName {
    final own = name?.trim();
    if (own != null && own.isNotEmpty) return own;
    return clubType?.name ?? 'Servicio';
  }
}