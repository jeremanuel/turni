
class ValueTransformers {


  // Transforma el valor en string
  static String fromJsonString(value){

    if(value is String) return value;
    
    return value.toString();
  }
}