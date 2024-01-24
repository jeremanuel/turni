
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:turni/data/repositories/turno_repositroy.dart';
import 'package:turni/domain/models/turno.dart';

part 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {

  final turnoRepositroy = TurnoRepositroy();
  
  FeedCubit() : super(FeedInitial()){
    getTurnos();
    

  }

  void getTurnos() async {
    final turnos = await turnoRepositroy.getTurnos();
    emit(FeedLoaded(turnos));
  }

/*   void openWhatsapp(Turnt t) async {
    
    var contact = "+5492262363735";
    String text = "Hola, vengo de la app \n me interesa el  turno en ${t.place.name} a las ${t.startAt.hour.toString().padLeft(2, '0')}:${t.startAt.minute.toString().padLeft(2, '0')} \n en la cancha ${t.place.court} \n duracion ${t.duration} \n "; 
   var iosUrl = "https://wa.me/$contact?text=${text}"; 
   
   try{
      await launchUrl(Uri.parse(iosUrl));
   } on Exception{
     print('WhatsApp is not installed.');
  }
    
  } */
}
