class DomainError implements Exception {
  // Códigos de error predefinidos
  static const int sessionNotFoundCode = 1001;
  static const int unknwonError = 1100;

  // Propiedades
  final String message;
  final int internalCode;
  final int httpStatusCode;
  final dynamic details;
  final DateTime date;

  // Constructor
  DomainError({
    required this.message,
    required this.internalCode,
    required this.date,
    this.httpStatusCode = 400,
    this.details,
    
  });

  // Factory para crear un error específico de "Session not found"
  factory DomainError.sessionNotFound({dynamic details}) {
    return DomainError(
      message: "Session not found",
      internalCode: sessionNotFoundCode,
      details: details, 
      date: DateTime.now(),
    );
  }

  factory DomainError.unknownError(){
    return DomainError(message: "Unknown Error", internalCode: unknwonError, date: DateTime.now());
  }

  factory DomainError.fromErrorResponse(dynamic response){
    try {
      return DomainError(message: response['error'], internalCode: response['code'], date: DateTime.now());
    } catch (e) {
      return DomainError(message: "Unknown Error", internalCode: unknwonError, details: { "originalError":response }, date: DateTime.now());
    }
  }



}
