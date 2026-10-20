/// Mail para avisarle al dueño de un club recién dado de alta cómo entrar al
/// panel. No lleva token: el email es la llave, el back lo vincula la primera
/// vez que entra con la cuenta de Google de ese email.
class ClubOwnerInvite {
  ClubOwnerInvite({
    required this.clubName,
    required this.ownerName,
    required this.email,
    required this.panelUrl,
  });

  final String clubName;
  final String ownerName;
  final String email;
  final String panelUrl;

  String get subject => 'Tu acceso a Turni para $clubName';

  String get body => 'Hola $ownerName:\n\n'
      'Ya está creado $clubName en Turni. Para empezar, entrá a $panelUrl y tocá '
      '"Iniciar sesión con Google" con la cuenta $email. Tiene que ser exactamente esa cuenta: '
      'es la que quedó como administradora del establecimiento.\n\n'
      'Al entrar te vamos a guiar para completar la dirección, marcar la ubicación en el mapa '
      'y cargar tus servicios y tarifas.\n\n'
      'Cualquier duda, respondé este mail.\n\n'
      'El equipo de Turni';

  /// Para copiar y pegar si no hay un cliente de mail configurado.
  String get fullText => 'Para: $email\nAsunto: $subject\n\n$body';

  /// `mailto:` con asunto y cuerpo. Se arma a mano con `encodeComponent`
  /// porque `Uri(queryParameters: ...)` codifica los espacios como `+`, y los
  /// clientes de mail los muestran tal cual.
  Uri get mailto => Uri.parse(
        'mailto:${Uri.encodeComponent(email)}'
        '?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
      );
}
