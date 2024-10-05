import 'dart:convert' show utf8, jsonDecode;
import 'dart:io' show File;
import 'package:json/json.dart' show JsonEncodable;

const String defaultApi = 'https://api.spotify.com/v1';

@JsonEncodable()
class Config {
  final String playlistId;
  final String apiUrl;
  final String clientId;
  final String clientSecret;

  const Config(
      {required this.playlistId,
      required this.apiUrl,
      required this.clientId,
      required this.clientSecret});

  static Config parse(String path) {
    final file = File(path);
    final content = file.readAsStringSync(encoding: utf8);
    final json = jsonDecode(content);

    return Config(
        playlistId: json['playlistId'],
        apiUrl: json['apiUrl'] ?? defaultApi,
        clientId: json['clientId'],
        clientSecret: json['clientSecret']);
  }
}
