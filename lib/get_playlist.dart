import 'dart:convert';
import 'dart:io';

import 'package:json/json.dart' show JsonDecodable;
import 'package:spot/config.dart' show Config;
import 'package:http/http.dart' as http;
import 'package:spot/item.dart' show Item;
import 'package:spot/track.dart' show Track;

@JsonDecodable()
class AccessTokenResponse {
  String access_token = '';
  String token_type = '';
  int expires_in = 0;
}

@JsonDecodable()
class ResponseData {
  List<Item> items = List.empty();
}

void main() async {
  final config = Config.parse('config.json');
  final items = await getPlaylistTracks(config, 3);
  final tracks = Track.fromItems(items);
  tracks.sort((a, b) => a.addedAt.compareTo(b.addedAt));
  final encoder = JsonEncoder.withIndent('    ');
  final json = encoder.convert(tracks);
  File('tracks.json').writeAsString(json);
}

Future<List<Item>> getPlaylistTracks(Config config, int tries) async {
  if (tries <= 0) {
    throw Exception('getPlaylistTracks out of tries');
  }

  final token = await getAccessToken(config, 3);
  final params = {
    'limit': '50',
    'fields':
        'items(added_at,track(id,name,track_number,external_urls(spotify),album(total_tracks,name,release_date,images(url)),artists(name)))'
  };

  final playlistUrl = '${config.apiUrl}/playlists/${config.playlistId}/tracks';
  final url = Uri.parse(playlistUrl).replace(queryParameters: params);
  final headers = {HttpHeaders.authorizationHeader: 'Bearer $token'};

  final res = await http.get(url, headers: headers);

  if (res.statusCode == 401) {
    await clearAccessToken();
    return getPlaylistTracks(config, tries - 1);
  }

  if (res.statusCode != 200) {
    throw Exception(res.body);
  }

  final json = jsonDecode(res.body);
  final data = ResponseData.fromJson(json);

  return data.items;
}

Future<String> getAccessToken(Config config, int tries) async {
  if (tries <= 0) {
    throw Exception('getAccessToken out of tries!');
  }

  final file = File('.access_token');
  var token = '';

  if (await file.exists()) {
    token = await file.readAsString();
  }

  if (token == '') {
    await fetchAccessToken(config);
    return getAccessToken(config, tries - 1);
  }

  return token;
}

Future<void> fetchAccessToken(Config config) async {
  final data = {
    'grant_type': 'client_credentials',
    'client_id': config.clientId,
    'client_secret': config.clientSecret
  };

  final url = Uri.https('accounts.spotify.com', '/api/token');
  final res = await http.post(url, body: data);
  final json = jsonDecode(res.body);
  final tokenData = AccessTokenResponse.fromJson(json);

  await File('.access_token').writeAsString(tokenData.access_token);
}

Future<void> clearAccessToken() async {
  File('.access_token').writeAsStringSync('');
}
