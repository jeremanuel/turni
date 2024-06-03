import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/config/environment.dart';
import 'person.dart';
import 'session.dart';

class TemplateMessage {
  TemplateMessage({required this.link});

  final String link;
  late final String populatedLink;

  Uri getPopulatedLink() {
    return Uri.parse(populatedLink);
  }

  void populateLinkFromSession(Session session, Person person) {
    try {
      List<String> linkSplitted = link.split('--');
      Map<String, dynamic> sessionJson = session.toJson();
      Map<String, dynamic> personJson = person.toJson();

      sessionJson['baseurl'] =
          kIsWeb ? Environment.apiUrl : Environment.apiNativeUrl;

      print(sessionJson);

      for (int i = 1; i < linkSplitted.length; i += 2) {
        String key = linkSplitted[i];
        String? format;

        if (key.contains('%21')) {
          [key, format] = key.split('%21');
        }

        dynamic value = sessionJson[key] ?? personJson[key];

        if (format != null) {
          value = DateFormat(format).format(DateTime.parse(value));
        }

        linkSplitted[i] = value.toString();
      }

      populatedLink = linkSplitted.join();
    } catch (error) {
      print(error);
    }
  }
}
