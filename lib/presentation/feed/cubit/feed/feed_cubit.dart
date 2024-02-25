
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:turni/domain/entities/session.dart';

part 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {

  
  FeedCubit() : super(FeedInitial()){
    getTurnos();
    

  }

  void getTurnos() async {
    emit(FeedLoaded([]));
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
