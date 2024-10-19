// ignore_for_file: file_names

import '../../presentation/admin/browser/browser_options.dart';

abstract class IARepository {
  void init(BrowserOptions browserOptions);
  void testPrompt();
  Future<Map<String, dynamic>> getResult(String prompt);
}