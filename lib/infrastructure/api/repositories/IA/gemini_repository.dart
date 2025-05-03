import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../domain/repositories/ia_repository.dart';
import '../../../../presentation/admin/browser/browser_options.dart';

class GeminiRepository extends IARepository{

  late GenerativeModel _gemini;

  static String systemInstruction = """

      Debes responder siempre de la misma forma. 

      El usuario te preguntara por TURNOS o por CLIENTES para una fecha.

      Siempre tu formato de respuesta debe:

      "
      {
        "fechaInicio": "2024-10-06 00:00:00.000",
        "fechaFin":"2024-10-09 00:00:00.000",
        "busqueda":  "turnos" | "clientes-reserva" | "turnos-disponibles" | "turnos-reservados" // Esto puede ser SOLO UNA DE LAS DOS.
        "club_partition": 1 // Es opcional, el mapeo de cuales son los club partitions estan debajo, en caso de que no hayan mapeos, se ignora y nunca se rellena esta prop. 
        "cancha": "Cancha 1" // Es opcional, representa una posible cancha.

      }
      "
      Siendo este un Map<String, dynamic>

      Las fechas siempre en formato yyyy-MM-dd HH:mm:ss
      Explicacion:

      "clientes-reserva": representa clientes que hayan realizado ciertas reservas, EJ:, clientes que reservaron la semana pasada.
      "turnos": representa una busqueda de turnos, sea disponibles o reservados, EJ: turnos de la semana que viene
      "turnos-disponibles": representan turnos disponibles unicamente, EJ: turnos reservados de ayer
      "turnos-reservados": representan turnos reservados unicamente, EJ: turnos reservados para mañana

      SIEMPRE que se soliciten turnos y no se indique si son disponibles o reservados, tomarlo como "turnos"
      
      Nigun caracter de mas.
      DEBE SER EN FORMATO Map<String, dynamic>.

      Por ejemplo:

         "json
      {
        "fechaInicio": "2024-10-06 00:00:00.000",
        "fechaFin":"2024-10-09 00:00:00.000",
        "busqueda": "clientes" || "turnos"
      }
      " 
      ESTA MAL, porque la palabra json NO VA.

      En caso de que se te consulte por algo que no podes matchear, o no tener informacion suficiente, devolveme un 

      "
      {
        error:true,
        mensaje:String
      }
      "

      Es importante que ante un string vacio, o falta de informacion, o informacion erronea, devuelvas ERROR, nada de inventar cosas.

      Cuando se sugieren clientes o turnos en una determinada fecha, si no se indica horario, se trata del dia completo.
      

      tene en cuenta que HOY ES : ${DateTime.now()}

  """;

  @override
  void init(BrowserOptions browserOptions){

    if(browserOptions.clubPartitions?.length != null && browserOptions.clubPartitions!.length > 1){
      systemInstruction += """

        Las club_partitions soportadas son : 
         
        ${browserOptions.clubPartitions!.map((e) => "${e.clubType!.name} = ${e.club_partition_id}",).join(" \n ")}

        Esos son los mapeos de que nombre es cada club_partition, para que puedas completar correctamente el campo


      """;  
    } else {
      systemInstruction += " NO HAY club_partitions soportadas, singifica que ignoras el campo ";
    }

    _gemini = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: "AIzaSyCNOxG7l80FjUdylNmQM8kG82-M9TXbC6w",
      systemInstruction: Content.system(systemInstruction)      
    );

  }

  @override
  void testPrompt() async {
    final response = await _gemini.generateContent([Content.text("Turnos disponibles para mañana")]);
    
  }
  
  @override
  Future<Map<String, dynamic>> getResult(String prompt) async {

    final result = await _gemini.generateContent([Content.text(prompt)]);

    return jsonDecode(result.text!.replaceAll("json", '').replaceAll('`', ''));

  }
  

}