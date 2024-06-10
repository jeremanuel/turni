enum Symbol { admiration }

class SymbolString {
  static String trasnform(Symbol symbol) {
    switch (symbol) {
      case Symbol.admiration:
        return '%21';
      default:
        return '';
    }
  }
}
