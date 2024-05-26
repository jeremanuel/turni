import 'package:json_annotation/json_annotation.dart';

part 'template_message.g.dart';

@JsonSerializable()
class TemplateMessage {
  TemplateMessage({required this.link, required this.text});

  final String link;
  final String text;

  factory TemplateMessage.fromJson(Map<String, dynamic> json) =>
      _$TemplateMessageFromJson(json);
}
