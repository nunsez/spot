import 'package:json/json.dart' show JsonCodable;
import 'package:spot/item.dart' show Item;

@JsonCodable()
class Track {
  final String id;
  final String name;
  final int trackNumber;
  final int totalTracks;
  final String spotifyUrl;
  final String artists;
  final String addedAt;
  final String albumName;
  final String albumReleaseDate;
  final String albumImageUrl;

  Track(
      {required this.id,
      required this.name,
      required this.trackNumber,
      required this.totalTracks,
      required this.spotifyUrl,
      required this.artists,
      required this.addedAt,
      required this.albumName,
      required this.albumReleaseDate,
      required this.albumImageUrl});

  factory Track.fromItem(Item item) {
    final albumImage = item.track.album.images.firstOrNull;

    return Track(
        id: item.track.id,
        name: item.track.name,
        trackNumber: item.track.track_number,
        totalTracks: item.track.album.total_tracks,
        spotifyUrl: item.track.external_urls.spotify,
        artists: item.track.artists.map((a) => a.name).join('; '),
        addedAt: item.added_at,
        albumName: item.track.album.name,
        albumReleaseDate: item.track.album.release_date,
        albumImageUrl: albumImage?.url ?? '');
  }

  static List<Track> fromItems(List<Item> items) {
    return items.map(Track.fromItem).toList();
  }
}
