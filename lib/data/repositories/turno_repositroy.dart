
import 'package:turni/domain/models/place.dart';
import 'package:turni/domain/models/turno.dart';

class TurnoRepositroy {


  Future<List<Turno>> getTurnos() async {
/*     FirebaseFirestore firestore = FirebaseFirestore.instance;

    CollectionReference ac = firestore.collection("turnos");
    // This is dart code. 
    final querySnapshot = await ac.get();
    final printt = querySnapshot.docs.map((e) => Turno.fromJson(e.data() as Map<String, dynamic>)).toList();

     */

    return [
      Turno(
        startAt: DateTime(2024, 01, 24, 20, 35),
        createdAt: DateTime(2024, 01, 22, 20, 35),
        duration: '01:30',
        place: Place("Beduinos", "Cancha 3", "Cancha del fondo, de cristal", ""),
        persons: 2,
        price: 3500
      )
    ];
  }
}
