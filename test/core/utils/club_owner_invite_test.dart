import 'package:flutter_test/flutter_test.dart';
import 'package:turni/core/utils/club_owner_invite.dart';

void main() {
  final invite = ClubOwnerInvite(
    clubName: 'Club Norte',
    ownerName: 'Ana',
    email: 'ana+club@gmail.com',
    panelUrl: 'https://panel.example.com/',
  );

  test('arma asunto y cuerpo con el club, la cuenta y la URL del panel', () {
    expect(invite.subject, 'Tu acceso a Turni para Club Norte');
    expect(invite.body, startsWith('Hola Ana:'));
    expect(invite.body, contains('entrá a https://panel.example.com/ y tocá'));
    expect(invite.body, contains('con la cuenta ana+club@gmail.com.'));
    expect(invite.fullText, startsWith('Para: ana+club@gmail.com\nAsunto: Tu acceso a Turni para Club Norte\n\n'));
  });

  test('el mailto codifica espacios como %20 (no +) y conserva el texto al decodificar', () {
    final raw = invite.mailto.toString();
    expect(raw, startsWith('mailto:ana%2Bclub%40gmail.com?subject=Tu%20acceso%20a%20Turni'));
    expect(raw.contains('+'), isFalse);

    expect(Uri.decodeComponent(raw.split('subject=')[1].split('&body=')[0]), invite.subject);
    expect(Uri.decodeComponent(raw.split('&body=')[1]), invite.body);
  });
}
