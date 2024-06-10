import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/config/environment.dart';
import '../../core/utils/transformers/symbols.dart';
import 'person.dart';
import 'session.dart';

class TemplateMessage {
  TemplateMessage({required this.link});

  final String link;
  late final String populatedLink;

  Uri getPopulatedLink() {
    return Uri.parse(populatedLink);
  }

  void populateLinkFromSession(List<dynamic> models) {
    try {
      List<String> linkSplitted = link.split('--');
      Map<String, dynamic> jsonModels = {};

      for (var model in models) {
        jsonModels.addAll(model.toJson());
      }

      //Constants values
      jsonModels['baseurl'] =
          kIsWeb ? Environment.apiUrl : Environment.apiNativeUrl;

      for (int i = 1; i < linkSplitted.length; i += 2) {
        String key = linkSplitted[i];
        String? format;

        if (key.contains(SymbolString.trasnform(Symbol.admiration))) {
          [key, format] = key.split(SymbolString.trasnform(Symbol.admiration));
        }

        dynamic value = jsonModels[key];

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
