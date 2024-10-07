abstract class IARepository {
  void init();
  void testPrompt();
  Future<Map<String, dynamic>> getResult(String prompt);
}