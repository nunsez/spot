import 'dart:convert';
import 'dart:io';

import 'package:spot/track.dart' show Track;
import 'package:http/http.dart' as http;

void main() async {
  final content = File('tracks.json').readAsStringSync();
  final json = jsonDecode(content) as List<dynamic>;
  final tracks = json.map((dyn) => Track.fromJson(dyn));

  final images = Directory('images');

  if (!images.existsSync()) {
    images.createSync();
  }

  final metadata = Directory('metadata');

  if (!metadata.existsSync()) {
    metadata.createSync();
  }

  for (var track in tracks) {
    File? imageFile;

    try {
      imageFile = await downloadImage(track);
    } catch (e) {
      // noop
    }

    late File metaFile;

    try {
      metaFile = await saveMetadata(track);
    } catch (e) {
      print(e);
      continue;
    }

    late File trackFile;

    try {
      trackFile = await setMetadata(track, metaFile, imageFile);
    } catch (e) {
      print(e);
      continue;
    }

    try {
      await trackFile.rename(trackName(track));
      print(msg(track, 'OK!'));
    } on FileSystemException {
      print(msg(track, 'track rename error'));
    }
  }
}

Future<File> downloadImage(Track track) async {
  final file = File('images/${track.id}');

  if (await file.exists()) {
    return file;
  }

  final url = Uri.parse(track.albumImageUrl);
  final res = await http.get(url);

  await file.writeAsBytes(res.bodyBytes);

  return file;
}

Future<File> saveMetadata(Track track) async {
  List<String> rows = [];
  rows.add(buildTagRow('TITLE', track.name));
  rows.add(buildTagRow('ARTIST', track.artists));
  rows.add(buildTagRow('ALBUM', track.albumName));
  rows.add(buildTagRow('DATE', track.albumReleaseDate));
  rows.add(buildTagRow('COMMENT', track.spotifyUrl));

  final date = DateTime.tryParse('YYYY-MM-DD');

  if (date != null) {
    rows.add(buildTagRow('YEAR', date.year.toString()));
  }

  if (track.trackNumber != 0) {
    rows.add(buildTagRow('TRACKNUMBER', track.trackNumber.toString()));
  }

  if (track.totalTracks != 0) {
    rows.add(buildTagRow('TRACKNUMBER', track.totalTracks.toString()));
  }

  final file = File('metadata/${track.id}');
  await file.writeAsString('${rows.join('\n')}\n');

  return file;
}

String buildTagRow(String key, String value) {
  return '${key.toUpperCase()}=$value';
}

Future<File> setMetadata(Track track, File trackMetaFile, File? imageFile) async {
  final trackFile = File('${track.id}.flac');

  if (!await trackFile.exists()) {
    throw Exception(msg(track, 'track not found'));
  }

  List<String> parts = [];
  parts.add('--no-utf8-convert');
  parts.add('--remove-all-tags');

  if (await trackFile.exists()) {
    parts.add('--import-tags-from "${escaped(trackMetaFile.path)}"');
  } else {
    print(msg(track, 'metadata file not found'));
  }

  if (imageFile != null && await imageFile.exists()) {
    parts.add('--import-picture-from ${escaped(imageFile.path)}');
  } else {
    print(msg(track, 'image file not found'));
  }

  parts.add(escaped(trackFile.path));

  final cmdResult = await Process.run('metaflac', parts);

  if (cmdResult.exitCode == 0) {
    return trackFile;
  } else {
    throw Exception(msg(track, cmdResult.toString()));
  }
}

String escaped(String str) {
	return str.replaceAll('"', '\\"');
}

String trackName(Track track) {
  final artists = track.artists.replaceAll(';', ',');
  return '$artists - ${track.name}.flac';
}

String msg(Track track, String message) {
  return '${track.id} : $message';
}
