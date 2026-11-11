import '../../../core/utils/value_transformers.dart';

double _money(dynamic value) => value == null ? 0 : ValueTransformers.fromJsonDouble(value);
DateTime? _dateOrNull(dynamic value) => ValueTransformers.fromJsonDateTimeLocaleNullable(value);
List<Map<String, dynamic>> _list(dynamic value) => (value as List? ?? const []).cast<Map<String, dynamic>>();

/// "2026-11-09" sin hora: una fecha fiscal, no un instante.
DateTime? _dayOrNull(dynamic value) {
  if (value is! String || value.length < 10) return null;
  return DateTime.tryParse(value.substring(0, 10));
}

/// Códigos de ARCA que usa la pantalla (la fuente de verdad es el backend).
abstract final class FiscalCodes {
  static const docCuit = 80;
  static const docCuil = 86;
  static const docDni = 96;

  static const ivaResponsableInscripto = 1;
  static const ivaExento = 4;
  static const ivaConsumidorFinal = 5;
  static const ivaMonotributo = 6;
}

/// Una opción de un selector: alícuota, condición frente al IVA, documento.
class FiscalOption {
  const FiscalOption(this.id, this.label);

  final int id;
  final String label;
}

class FiscalOptions {
  const FiscalOptions({required this.regimes, required this.ivaRates, required this.ivaConditions, required this.docTypes});

  final List<(String, String)> regimes;
  final List<FiscalOption> ivaRates;
  final List<FiscalOption> ivaConditions;
  final List<FiscalOption> docTypes;

  static FiscalOption _option(Map<String, dynamic> json) => FiscalOption(json['id'] as int, json['label']?.toString() ?? '');

  factory FiscalOptions.fromJson(Map<String, dynamic>? json) => FiscalOptions(
        regimes: [for (final r in _list(json?['regimes'])) (r['code'].toString(), r['label'].toString())],
        ivaRates: _list(json?['iva_rates']).map(_option).toList(),
        ivaConditions: _list(json?['iva_conditions']).map(_option).toList(),
        docTypes: _list(json?['doc_types']).map(_option).toList(),
      );

  String ivaRateLabel(int? id) => ivaRates.where((rate) => rate.id == id).firstOrNull?.label ?? '';
}

/// Datos fiscales del club y su conexión con ARCA.
class FiscalProfile {
  const FiscalProfile({
    required this.regime,
    required this.regimeLabel,
    required this.cuit,
    required this.legalName,
    required this.commercialAddress,
    required this.iibbNumber,
    required this.activityStart,
    required this.pointOfSale,
    required this.connectionStatus,
    required this.connectionError,
    required this.connectionCheckedAt,
    required this.emissionMode,
    required this.enabled,
    required this.enabledAt,
    required this.defaultTaxTreatment,
    required this.defaultIvaRateId,
  });

  /// MONOTRIBUTO, RESPONSABLE_INSCRIPTO o EXENTO.
  final String regime;
  final String regimeLabel;
  final String cuit;
  final String legalName;
  final String commercialAddress;
  final String? iibbNumber;
  final DateTime? activityStart;
  final int? pointOfSale;

  /// NOT_CONNECTED, PENDING_TURNI, VERIFYING, ACTIVE o BLOCKED.
  final String connectionStatus;
  final String? connectionError;
  final DateTime? connectionCheckedAt;

  /// AUTOMATIC o MANUAL.
  final String emissionMode;
  final bool enabled;
  final DateTime? enabledAt;
  final String defaultTaxTreatment;
  final int defaultIvaRateId;

  bool get isConnected => connectionStatus == 'ACTIVE';
  bool get isResponsableInscripto => regime == 'RESPONSABLE_INSCRIPTO';

  factory FiscalProfile.fromJson(Map<String, dynamic> json) => FiscalProfile(
        regime: json['regime']?.toString() ?? 'MONOTRIBUTO',
        regimeLabel: json['regime_label']?.toString() ?? '',
        cuit: json['cuit']?.toString() ?? '',
        legalName: json['legal_name']?.toString() ?? '',
        commercialAddress: json['commercial_address']?.toString() ?? '',
        iibbNumber: json['iibb_number']?.toString(),
        activityStart: _dayOrNull(json['activity_start']),
        pointOfSale: json['point_of_sale'] as int?,
        connectionStatus: json['connection_status']?.toString() ?? 'NOT_CONNECTED',
        connectionError: json['connection_error']?.toString(),
        connectionCheckedAt: _dateOrNull(json['connection_checked_at']),
        emissionMode: json['emission_mode']?.toString() ?? 'MANUAL',
        enabled: json['enabled'] == true,
        enabledAt: _dateOrNull(json['enabled_at']),
        defaultTaxTreatment: json['default_tax_treatment']?.toString() ?? 'TAXED',
        defaultIvaRateId: json['default_iva_rate_id'] as int? ?? 5,
      );
}

/// GET /admin/fiscal/settings.
class FiscalSettings {
  const FiscalSettings({required this.profile, required this.provider, required this.providerReady, required this.options, this.representativeCuit});

  final FiscalProfile? profile;

  /// MOCK (simulador) o ARCA.
  final String provider;

  /// false: con ARCA real todavía no se puede verificar la conexión.
  final bool providerReady;
  final FiscalOptions options;

  /// CUIT de Turni, que el club carga como representante en ARCA.
  final String? representativeCuit;

  bool get isSimulated => provider == 'MOCK';

  factory FiscalSettings.fromJson(Map<String, dynamic> json) => FiscalSettings(
        profile: json['profile'] is Map<String, dynamic> ? FiscalProfile.fromJson(json['profile'] as Map<String, dynamic>) : null,
        provider: json['provider']?.toString() ?? 'ARCA',
        providerReady: json['provider_ready'] == true,
        options: FiscalOptions.fromJson(json['options'] as Map<String, dynamic>?),
        representativeCuit: json['representative_cuit']?.toString(),
      );
}

/// A nombre de quién sale un comprobante.
class FiscalReceiver {
  const FiscalReceiver({
    required this.docType,
    required this.docNumber,
    required this.ivaConditionId,
    this.legalName,
    this.address,
    this.email,
    this.docTypeLabel,
    this.ivaConditionLabel,
    this.label = 'Consumidor final',
    this.isConsumerFinal = true,
  });

  final int docType;
  final String docNumber;
  final int ivaConditionId;
  final String? legalName;
  final String? address;
  final String? email;
  final String? docTypeLabel;
  final String? ivaConditionLabel;

  /// "Acme SA · CUIT 30500010912" o "Consumidor final".
  final String label;
  final bool isConsumerFinal;

  static FiscalReceiver? fromJsonOrNull(dynamic json) => json is Map<String, dynamic> ? FiscalReceiver.fromJson(json) : null;

  factory FiscalReceiver.fromJson(Map<String, dynamic> json) => FiscalReceiver(
        docType: json['doc_type'] as int? ?? 99,
        docNumber: json['doc_number']?.toString() ?? '0',
        ivaConditionId: json['iva_condition_id'] as int? ?? FiscalCodes.ivaConsumidorFinal,
        legalName: json['legal_name']?.toString(),
        address: json['address']?.toString(),
        email: json['email']?.toString(),
        docTypeLabel: json['doc_type_label']?.toString(),
        ivaConditionLabel: json['iva_condition_label']?.toString(),
        label: json['label']?.toString() ?? 'Consumidor final',
        isConsumerFinal: json['is_consumer_final'] != false,
      );
}

/// Lo que carga el admin al corregir un comprobante o los datos del cliente.
class FiscalReceiverInput {
  const FiscalReceiverInput.consumerFinal()
      : consumerFinal = true,
        docType = null,
        docNumber = null,
        ivaConditionId = null,
        legalName = null,
        address = null,
        email = null;

  const FiscalReceiverInput({required int this.docType, required String this.docNumber, this.ivaConditionId, this.legalName, this.address, this.email})
      : consumerFinal = false;

  final bool consumerFinal;
  final int? docType;
  final String? docNumber;
  final int? ivaConditionId;
  final String? legalName;
  final String? address;
  final String? email;

  Map<String, dynamic> toJson() => consumerFinal
      ? {'consumer_final': true}
      : {
          'doc_type': docType,
          'doc_number': docNumber,
          if (ivaConditionId != null) 'iva_condition_id': ivaConditionId,
          if (legalName != null && legalName!.trim().isNotEmpty) 'legal_name': legalName!.trim(),
          if (address != null && address!.trim().isNotEmpty) 'address': address!.trim(),
          if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
        };
}

class FiscalIvaLine {
  const FiscalIvaLine({required this.label, required this.base, required this.amount});

  final String label;
  final double base;
  final double amount;

  factory FiscalIvaLine.fromJson(Map<String, dynamic> json) =>
      FiscalIvaLine(label: json['label']?.toString() ?? '', base: _money(json['base']), amount: _money(json['amount']));
}

class FiscalItem {
  const FiscalItem({required this.description, required this.quantity, required this.subtotal});

  final String description;
  final double quantity;
  final double subtotal;

  factory FiscalItem.fromJson(Map<String, dynamic> json) => FiscalItem(
        description: json['description']?.toString() ?? '',
        quantity: _money(json['quantity']),
        subtotal: _money(json['subtotal']),
      );
}

class FiscalDocumentActions {
  const FiscalDocumentActions({this.issue = false, this.correct = false, this.retry = false, this.cancel = false});

  final bool issue;
  final bool correct;
  final bool retry;
  final bool cancel;

  factory FiscalDocumentActions.fromJson(Map<String, dynamic>? json) => FiscalDocumentActions(
        issue: json?['issue'] == true,
        correct: json?['correct'] == true,
        retry: json?['retry'] == true,
        cancel: json?['cancel'] == true,
      );
}

/// Una factura o nota de crédito.
class FiscalDocument {
  const FiscalDocument({
    required this.id,
    required this.kind,
    required this.status,
    required this.statusLabel,
    required this.documentLabel,
    required this.number,
    required this.issueDate,
    required this.total,
    required this.netTaxed,
    required this.iva,
    required this.exempt,
    required this.notTaxed,
    required this.ivaBreakdown,
    required this.receiver,
    required this.clientId,
    required this.clientName,
    required this.sessionId,
    required this.cae,
    required this.caeDue,
    required this.errors,
    required this.observations,
    required this.relatedDocumentId,
    required this.cancelReason,
    required this.createdAt,
    required this.can,
    this.items = const [],
    this.related,
    this.creditNotes = const [],
    this.creditLegend = false,
  });

  /// Va como texto: es un BIGINT en la base. Nunca se muestra.
  final String id;

  /// INVOICE o CREDIT_NOTE.
  final String kind;
  final String status;
  final String statusLabel;

  /// "Factura C", "Nota de crédito B".
  final String documentLabel;

  /// "00005-00001284"; null mientras no salió.
  final String? number;
  final DateTime? issueDate;
  final double total;
  final double netTaxed;
  final double iva;
  final double exempt;
  final double notTaxed;
  final List<FiscalIvaLine> ivaBreakdown;
  final FiscalReceiver receiver;
  final int? clientId;
  final String? clientName;
  final int? sessionId;
  final String? cae;
  final DateTime? caeDue;
  final List<String> errors;
  final List<String> observations;
  final String? relatedDocumentId;
  final String? cancelReason;
  final DateTime? createdAt;
  final FiscalDocumentActions can;

  /// Solo en el detalle.
  final List<FiscalItem> items;
  final FiscalDocument? related;
  final List<FiscalDocument> creditNotes;
  final bool creditLegend;

  bool get isCreditNote => kind == 'CREDIT_NOTE';

  /// Con signo: las notas de crédito restan.
  double get signedTotal => isCreditNote ? -total : total;

  static List<String> _messages(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final entry in value)
        if (entry is Map && entry['message'] != null) entry['message'].toString() else if (entry is String) entry,
    ];
  }

  factory FiscalDocument.fromJson(Map<String, dynamic> json) => FiscalDocument(
        id: json['id'].toString(),
        kind: json['kind']?.toString() ?? 'INVOICE',
        status: json['status']?.toString() ?? '',
        statusLabel: json['status_label']?.toString() ?? '',
        documentLabel: json['document_label']?.toString() ?? 'Comprobante',
        number: json['number']?.toString(),
        issueDate: _dayOrNull(json['issue_date']),
        total: _money(json['total']),
        netTaxed: _money(json['net_taxed']),
        iva: _money(json['iva']),
        exempt: _money(json['exempt']),
        notTaxed: _money(json['not_taxed']),
        ivaBreakdown: _list(json['iva_breakdown']).map(FiscalIvaLine.fromJson).toList(),
        receiver: FiscalReceiver.fromJson((json['receiver'] as Map<String, dynamic>?) ?? const {}),
        clientId: json['client_id'] as int?,
        clientName: json['client_name']?.toString(),
        sessionId: json['session_id'] as int?,
        cae: json['cae']?.toString(),
        caeDue: _dayOrNull(json['cae_due']),
        errors: _messages(json['errors']),
        observations: _messages(json['observations']),
        relatedDocumentId: json['related_document_id']?.toString(),
        cancelReason: json['cancel_reason']?.toString(),
        createdAt: _dateOrNull(json['created_at']),
        can: FiscalDocumentActions.fromJson(json['can'] as Map<String, dynamic>?),
        items: _list(json['items']).map(FiscalItem.fromJson).toList(),
        related: json['related'] is Map<String, dynamic> ? FiscalDocument.fromJson(json['related'] as Map<String, dynamic>) : null,
        creditNotes: _list(json['credit_notes']).map(FiscalDocument.fromJson).toList(),
        creditLegend: json['credit_legend'] == true,
      );
}

class FiscalStatusCount {
  const FiscalStatusCount({required this.count, required this.total});

  final int count;
  final double total;
}

/// Una página de comprobantes, con los totales del período.
class FiscalDocumentsPage {
  const FiscalDocumentsPage({required this.documents, required this.nextCursor, required this.counts, required this.attention});

  final List<FiscalDocument> documents;
  final String? nextCursor;
  final Map<String, FiscalStatusCount> counts;

  /// Faltan datos, falta configurar, rechazados y ARCA desconectado.
  final int attention;

  int count(Iterable<String> statuses) => statuses.fold(0, (sum, status) => sum + (counts[status]?.count ?? 0));

  factory FiscalDocumentsPage.fromJson(Map<String, dynamic> json) => FiscalDocumentsPage(
        documents: _list(json['documents']).map(FiscalDocument.fromJson).toList(),
        nextCursor: json['next_cursor']?.toString(),
        counts: {
          for (final entry in ((json['counts'] as Map<String, dynamic>?) ?? const {}).entries)
            entry.key: FiscalStatusCount(
              count: (entry.value as Map)['count'] as int? ?? 0,
              total: _money((entry.value as Map)['total']),
            ),
        },
        attention: json['attention'] as int? ?? 0,
      );
}

class FiscalDocumentFilters {
  const FiscalDocumentFilters({this.status, this.from, this.to, this.clientId, this.sessionId, this.cursor});

  /// Un estado, varios separados por coma, o ATTENTION.
  final String? status;
  final DateTime? from;
  final DateTime? to;
  final int? clientId;
  final int? sessionId;
  final String? cursor;
}

/// Qué comprobante sale al cobrarle a un cliente.
class FiscalPreview {
  const FiscalPreview({required this.enabled, this.emissionMode, this.documentLabel, this.receiver, this.hasClientData = false, this.problem});

  final bool enabled;
  final String? emissionMode;
  final String? documentLabel;
  final FiscalReceiver? receiver;
  final bool hasClientData;

  /// Por qué no saldría solo (ej. falta identificar al cliente).
  final String? problem;

  bool get automatic => emissionMode == 'AUTOMATIC';

  factory FiscalPreview.fromJson(Map<String, dynamic> json) => FiscalPreview(
        enabled: json['enabled'] == true,
        emissionMode: json['emission_mode']?.toString(),
        documentLabel: json['document_label']?.toString(),
        receiver: FiscalReceiver.fromJsonOrNull(json['receiver']),
        hasClientData: json['has_client_data'] == true,
        problem: json['problem']?.toString(),
      );
}

/// Datos fiscales guardados en la ficha de un cliente.
class ClientFiscalData {
  const ClientFiscalData({required this.clientId, required this.name, required this.fiscalData});

  final int clientId;
  final String name;
  final FiscalReceiver? fiscalData;

  factory ClientFiscalData.fromJson(Map<String, dynamic> json) => ClientFiscalData(
        clientId: json['client_id'] as int,
        name: json['name']?.toString() ?? '',
        fiscalData: FiscalReceiver.fromJsonOrNull(json['fiscal_data']),
      );
}
