class UtilDates {
  static bool isSameDate(DateTime date, DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }
}
