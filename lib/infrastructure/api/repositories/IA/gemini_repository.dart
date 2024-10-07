import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../domain/repositories/IA_repository.dart';

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
        "modalidad": "padel" | "tenis" | "futbol", "basket", "Voleyball" // es opcional, ademas, se pueden incluir otras modalidades, esas son solo ejemplos.
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

  void init(){
     _gemini = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: "AIzaSyCNOxG7l80FjUdylNmQM8kG82-M9TXbC6w",
      systemInstruction: Content.system(systemInstruction)
      
      );

    
  }

  @override
  void testPrompt() async {
    final response = await _gemini.generateContent([Content.text("Turnos disponibles para mañana")]);
    
    print(jsonDecode(response.text!)); 
  }
  
  @override
  Future<Map<String, dynamic>> getResult(String prompt) async {

    final result = await _gemini.generateContent([Content.text(prompt)]);

    print(result.text);

    return jsonDecode(result.text!.replaceAll("json", '').replaceAll('`', ''));

  }
  

}