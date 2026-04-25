import 'dart:math';

import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/payment/payment.dart';
import '../../domain/entities/payment/payment_method.dart';
import '../../domain/entities/request/page_response.dart';
import '../../domain/entities/request/payment/payment_list_extra_data.dart';
import '../../domain/entities/request/payment/payment_list_response.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryMock implements PaymentRepository {
  
  // Datos mock de métodos de pago
  static final List<PaymentMethod> _mockPaymentMethods = [
    PaymentMethod(paymentMethodId: 1, name: 'Efectivo'),
    PaymentMethod(paymentMethodId: 2, name: 'Tarjeta de Débito'),
    PaymentMethod(paymentMethodId: 3, name: 'Tarjeta de Crédito'),
    PaymentMethod(paymentMethodId: 4, name: 'Transferencia'),
    PaymentMethod(paymentMethodId: 5, name: 'MercadoPago'),
  ];

  // Datos mock de pagos
  static final List<Payment> _mockPayments = [
    Payment(
      paymentId: 1,
      clientId: 1,
      clientSubscriptionId: 1,
      amount: 15000.0,
      paymentMethod: _mockPaymentMethods[0],
      observation: 'Pago mensual - Enero 2024',
      paymentDate: DateTime(2024, 1, 15),
      createdByAdmin: 1,
    ),
    Payment(
      paymentId: 2,
      clientId: 1,
      clientSubscriptionId: 1,
      amount: 15000.0,
      paymentMethod: _mockPaymentMethods[2],
      observation: 'Pago mensual - Febrero 2024',
      paymentDate: DateTime(2024, 2, 15),
      createdByAdmin: 1,
    ),
    Payment(
      paymentId: 3,
      clientId: 2,
      clientSubscriptionId: 2,
      amount: 20000.0,
      paymentMethod: _mockPaymentMethods[1],
      observation: 'Pago mensual - Enero 2024',
      paymentDate: DateTime(2024, 1, 10),
      createdByAdmin: 1,
    ),
    Payment(
      paymentId: 4,
      clientId: 1,
      clientSubscriptionId: 1,
      amount: 15000.0,
      paymentMethod: _mockPaymentMethods[4],
      observation: 'Pago mensual - Marzo 2024',
      paymentDate: DateTime(2024, 3, 15),
      createdByAdmin: 2,
    ),
    Payment(
      paymentId: 5,
      clientId: 3,
      clientSubscriptionId: 3,
      amount: 18000.0,
      paymentMethod: _mockPaymentMethods[3],
      observation: 'Pago mensual - Enero 2024',
      paymentDate: DateTime(2024, 1, 20),
      createdByAdmin: 1,
    ),
    Payment(
      paymentId: 6,
      clientId: 2,
      clientSubscriptionId: 2,
      amount: 20000.0,
      paymentMethod: _mockPaymentMethods[2],
      observation: 'Pago mensual - Febrero 2024',
      paymentDate: DateTime(2024, 2, 10),
      createdByAdmin: 2,
    ),
    Payment(
      paymentId: 7,
      clientId: 1,
      clientSubscriptionId: 1,
      amount: 15000.0,
      paymentMethod: _mockPaymentMethods[0],
      observation: 'Pago mensual - Abril 2024',
      paymentDate: DateTime(2024, 4, 15),
      createdByAdmin: 1,
    ),
    Payment(
      paymentId: 8,
      clientId: 4,
      clientSubscriptionId: 4,
      amount: 25000.0,
      paymentMethod: _mockPaymentMethods[1],
      observation: 'Pago mensual - Enero 2024',
      paymentDate: DateTime(2024, 1, 25),
      createdByAdmin: 2,
    ),
    Payment(
      paymentId: 9,
      clientId: 3,
      clientSubscriptionId: 3,
      amount: 18000.0,
      paymentMethod: _mockPaymentMethods[4],
      observation: 'Pago mensual - Febrero 2024',
      paymentDate: DateTime(2024, 2, 20),
      createdByAdmin: 1,
    ),
    Payment(
      paymentId: 10,
      clientId: 2,
      clientSubscriptionId: 2,
      amount: 20000.0,
      paymentMethod: _mockPaymentMethods[3],
      observation: 'Pago mensual - Marzo 2024',
      paymentDate: DateTime(2024, 3, 10),
      createdByAdmin: 2,
    ),
  ];

  @override
  Future<Either<DomainError, PageResponse<Payment>>> getClientPayments(int clientId, int page) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Filtrar pagos por cliente
      final clientPayments = _mockPayments.where((payment) => payment.clientId == clientId).toList();
      
      // Ordenar por fecha (más recientes primero)
      clientPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      
      // Paginación (10 elementos por página)
      const pageSize = 10;
      final startIndex = (page - 1) * pageSize;
      final endIndex = min(startIndex + pageSize, clientPayments.length);
      
      if (startIndex >= clientPayments.length) {
        return Right(PageResponse(clientPayments.length, []));
      }
      
      final pagedPayments = clientPayments.sublist(startIndex, endIndex);
      
      return Right(PageResponse(clientPayments.length, pagedPayments));
      
    } catch (e) {
      return Left(DomainError(
        message: 'Error al obtener pagos del cliente',
        internalCode: 2001,
        date: DateTime.now(),
      ));
    }
  }

  @override
  Future<Either<DomainError, Payment>> createPayment(Map<String, dynamic> paymentData) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Generar nuevo ID
      final newId = _mockPayments.isNotEmpty ? _mockPayments.map((p) => p.paymentId ?? 0).reduce(max) + 1 : 1;
      
      // Buscar método de pago
      final paymentMethodId = paymentData['payment_method_id'] as int?;
      final paymentMethod = _mockPaymentMethods.firstWhere(
        (method) => method.paymentMethodId == paymentMethodId,
        orElse: () => _mockPaymentMethods.first,
      );
      
      // Crear nuevo pago
      final newPayment = Payment(
        paymentId: newId,
        clientId: paymentData['client_id'] as int,
        clientSubscriptionId: paymentData['client_subscription_id'] as int?,
        amount: (paymentData['amount'] as num).toDouble(),
        paymentMethod: paymentMethod,
        observation: paymentData['observation'] as String?,
        paymentDate: DateTime.now(),
        createdByAdmin: paymentData['created_by_admin'] as int,
      );
      
      // Agregar a la lista mock
      _mockPayments.add(newPayment);
      
      return Right(newPayment);
      
    } catch (e) {
      return Left(DomainError(
        message: 'Error al crear el pago: ${e.toString()}',
        internalCode: 2002,
        date: DateTime.now(),
      ));
    }
  }

  @override
  Future<Either<DomainError, PaymentListResponse>> getPayments(int page, {DateTime? fechaDesde, DateTime? fechaHasta}) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      // Obtener todos los pagos y aplicar filtros de fecha si se especifican
      var filteredPayments = List<Payment>.from(_mockPayments);
      
      if (fechaDesde != null) {
        filteredPayments = filteredPayments.where((payment) => 
          payment.paymentDate.isAfter(fechaDesde) || payment.paymentDate.isAtSameMomentAs(fechaDesde)
        ).toList();
      }
      
      if (fechaHasta != null) {
        filteredPayments = filteredPayments.where((payment) => 
          payment.paymentDate.isBefore(fechaHasta) || payment.paymentDate.isAtSameMomentAs(fechaHasta)
        ).toList();
      }
      
      // Ordenar por fecha (más recientes primero)
      filteredPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      
      // Calcular el total de los pagos filtrados
      final totalAmount = filteredPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
      
      return Right(PaymentListResponse(
        payments: filteredPayments,
        extraData: PaymentListExtraData(
          totalAmount: totalAmount
        ),
      ));
      
    } catch (e) {
      return Left(DomainError(
        message: 'Error al obtener la lista de pagos',
        internalCode: 2003,
        date: DateTime.now(),
      ));
    }
  }

  // Métodos auxiliares para testing
  void addMockPayment(Payment payment) {
    _mockPayments.add(payment);
  }

  void clearMockPayments() {
    _mockPayments.clear();
  }

  List<Payment> getAllMockPayments() {
    return List.unmodifiable(_mockPayments);
  }

  List<PaymentMethod> getAllMockPaymentMethods() {
    return List.unmodifiable(_mockPaymentMethods);
  }
}
