
import 'package:calendar_view/calendar_view.dart';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';
import 'client.dart';
import 'extra.dart';
import 'payment/payment.dart';
import 'physical_partition.dart';
import 'session_status.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
sealed class Session with _$Session {
  factory Session({
    @JsonKey(name: "session_id") required int sessionId,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(
        name: "start_time",
        fromJson: ValueTransformers.fromJsonDateTimeLocale,
        toJson: ValueTransformers.toJsonDateTimeUtc)
    required DateTime startTime,
    @JsonKey(defaultValue: 90)
    required int duration,
    @JsonKey(name: "client_id") int? clientId,
    @JsonKey(fromJson: ValueTransformers.fromJsonDouble) required double price,
    @JsonKey(name: "admin_creator_id") int? adminCreatorId,
    @JsonKey(name: "partition_physical_id") required int partitionPhysicalId,
    @JsonKey(name: "club_name") String? clubName,
    @JsonKey(name: "club_type_name") String? clubTypeName,
    @JsonKey(
      name: "status",
      fromJson: SessionStatusTransformers.fromJson,
      toJson: SessionStatusTransformers.toJson,
    ) SessionStatus? status,
    @JsonKey(includeIfNull: false,) Client? client,
    @JsonKey(includeIfNull: false)
    List<Payment>? payments,
    @JsonKey(includeIfNull: false)
    List<Extra>? extras,

    @JsonKey(name:"partition_physical", includeIfNull: false) PhysicalPartition? physicalPartition
  }) = _Session;

  Session._();

  getDurationInMinutes() {

    return duration;

  }

  double get extrasTotalPrice {
    if (extras == null) return 0.0;

    return extras!.fold(0.0, (total, extra) => total + (extra.amount));
  }


  double get totalPayedPrice {
    return sessionPayedPrice + extrasPayedPrice;
  }

  double get extrasPayedPrice {
    if(extras == null) return 0.0;

    return extras!.where((extra) => extra.payment != null).fold(0.0, (total, extra) => total + extra.payment!.amount);
  }

  double get sessionPayedPrice {
    if(payments == null) return 0.0;
    return payments!.fold(0.0, (total, payment) => total + payment.amount);
  }

  double get totalPrice {
    return price + extrasTotalPrice;
  }

  double get remainingTotalPrice {
    return totalPrice - totalPayedPrice;
  }

  double get remainingSessionPrice {
    return price - sessionPayedPrice;
  }

  double get remainingExtrasPrice {
    return extrasTotalPrice - extrasPayedPrice;
  }

  static Session fromDates(DateTime startTime, TimeOfDay duration) {
    return Session(
      sessionId: 1,
      createdAt: DateTime.now(),
      startTime: startTime,
      duration: duration.getTotalMinutes, //"${duration.hour}:${duration.minute}",
      price: 1500,
      adminCreatorId: 1,
      partitionPhysicalId: 1
    );

  }

  get endTime => startTime.add(Duration(minutes: getDurationInMinutes()));

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);

  /// El slot nunca tuvo una solicitud, o la que tuvo terminó en un estado
  /// terminal (`rejected`/`cancelled`/`expired`) — el backend ya liberó
  /// `client_id` en esos casos, así que la disponibilidad se decide
  /// únicamente por `client_id`, nunca por `status` directamente (ver
  /// PLAN_SOLICITUD_TURNO.md, Fase 0).
  bool get isFree => clientId == null;

  bool get isReserved => !isFree;

  /// Hay una solicitud de turno esperando aprobación del admin.
  bool get isPending => !isFree && status == SessionStatus.pending;

  /// El turno está confirmado: aprobado explícitamente por el admin, o
  /// reservado directo por el admin (que se auto-confirma sin pasar por
  /// `PENDING`). Cualquier slot ocupado que no esté `PENDING` se trata como
  /// confirmado — cubre tanto `status == confirmed` como datos legacy sin
  /// `status` seteado.
  bool get isConfirmed => !isFree && !isPending;
}
