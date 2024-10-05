import 'package:json/json.dart' show JsonDecodable;

@JsonDecodable()
class Item {
  String added_at = '';
  TrackDetails track = TrackDetails();
}

@JsonDecodable()
class TrackDetails {
  String id = '';
  String name = '';
  int track_number = 0;
  ExternalUrls external_urls = ExternalUrls();
  List<Artist> artists = List.empty();
  Album album = Album();

  TrackDetails();
}

@JsonDecodable()
class ExternalUrls {
  String spotify = '';

  ExternalUrls();
}

@JsonDecodable()
class Artist {
  String name = '';
}

@JsonDecodable()
class Album {
  int total_tracks = 0;
  String name = '';
  String release_date = '';
  List<Image> images = List.empty();

  Album();
}

@JsonDecodable()
class Image {
  String url = '';
}
