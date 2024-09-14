import net.http
import os
import tracks_mod
import json
import time

fn main() {
	content := os.read_file('tracks.json')!
	tracks := json.decode([]tracks_mod.Track, content)!

	if !os.exists('images') {
		os.mkdir('images')!
	}

	if !os.exists('metadata') {
		os.mkdir('metadata')!
	}

	for track in tracks {
		image_path := download_image(track) or { '' }
		metadata_path := save_metadata(track) or {
			println(err)
			continue
		}

		track_path := set_metadata(track, metadata_path, image_path) or {
			println(err)
			continue
		}

		os.mv(track_path, track_name(track)) or {
			println(msg(track, 'track rename error'))
			continue
		}

		println(msg(track, 'OK!'))
	}
}

fn download_image(track tracks_mod.Track) !string {
	path := os.join_path('images', track.id)

	if os.exists(path) {
		return path
	}

	res := http.get(track.album_image_url)!
	os.write_file(path, res.body)!
	return path
}

fn save_metadata(track tracks_mod.Track) !string {
	mut rows := []string{}
	rows << build_tag_row('TITLE', track.name)
	rows << build_tag_row('ARTIST', track.artists)
	rows << build_tag_row('ALBUM', track.album_name)
	rows << build_tag_row('DATE', track.album_release_date)
	rows << build_tag_row('COMMENT', track.spotify_url)

	if parsed_date := time.parse_format(track.album_release_date, 'YYYY-MM-DD') {
		rows << build_tag_row('YEAR', parsed_date.year.str())
	}

	if track.track_number != 0 {
		rows << build_tag_row('TRACKNUMBER', track.track_number.str())
	}

	if track.total_tracks != 0 {
		rows << build_tag_row('TOTALTRACKS', track.total_tracks.str())
	}

	metadata_path := os.join_path('metadata', track.id)
	os.write_file(metadata_path, rows.join('\n') + '\n')!
	return metadata_path
}

fn build_tag_row(key string, value string) string {
	return '${key.to_upper()}=${value}'
}

fn set_metadata(track tracks_mod.Track, metadata_path string, image_path string) !string {
	track_path := '${track.id}.flac'

	if !os.exists(track_path) {
		return error(msg(track, 'track not found'))
	}

	mut parts := ['metaflac']
	parts << '--no-utf8-convert'
	parts << '--remove-all-tags'

	if os.exists(metadata_path) {
		parts << '--import-tags-from "${escaped(metadata_path)}"'
	} else {
		println(msg(track, 'metadata file not found'))
	}

	if image_path != '' && os.exists(image_path) {
		parts << '--import-picture-from ${escaped(image_path)}'
	} else {
		println(msg(track, 'image file not found'))
	}

	parts << escaped(track_path)
	cmd := parts.join(' ')

	os.execute_opt(cmd) or { return error(msg(track, err.msg())) }
	return track_path
}

fn msg(track tracks_mod.Track, message string) string {
	return '${track.id} : ${message}'
}

fn escaped(str string) string {
	return str.replace('"', '\\"')
}

fn track_name(track tracks_mod.Track) string {
	artists := track.artists.replace(';', ',')
	return '${artists} - ${track.name}.flac'
}
