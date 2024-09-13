import json
import net.http
import os
import items_mod
import tracks_mod

struct Config {
	playlist_id   string @[required]
	api_url       string = 'https://api.spotify.com/v1'
	client_id     string @[required]
	client_secret string @[required]
}

struct AccessTokenResponse {
	access_token string
	token_type   string
	expires_in   int
}

struct ResponseData {
	items []items_mod.Item
}

fn main() {
	config := get_config() or { panic(err) }
	items := get_playlist_tracks(config, 3) or { panic(err) }
	mut tracks := tracks_mod.Track.from_items(items)
	tracks.sort(a.added_at < b.added_at)
	os.write_file('tracks.json', json.encode_pretty(tracks)) or { panic(err) }
}

fn get_config() !Config {
	config_path := arguments()[1] or { return error('Config file must be proived') }

	content := os.read_file(config_path) or {
		return error('Failed to read config file, error: ${err}')
	}

	config := json.decode(Config, content) or {
		return error('Failed to decode config, error: ${err}')
	}

	return config
}

fn clear_access_token() ! {
	os.write_file('.access_token', '')!
}

fn get_access_token(config Config, tries int) !string {
	if tries <= 0 {
		panic('get_access_token out of tries!')
	}

	token := os.read_file('.access_token') or { '' }

	if token == '' {
		fetch_access_token(config)!
		return get_access_token(config, tries - 1)
	}
	return token
}

fn fetch_access_token(config Config) ! {
	data := {
		'grant_type':    'client_credentials'
		'client_id':     config.client_id
		'client_secret': config.client_secret
	}

	res := http.post_form('https://accounts.spotify.com/api/token', data)!
	token_data := json.decode(AccessTokenResponse, res.body)!
	os.write_file('.access_token', token_data.access_token)!
}

fn get_playlist_tracks(config Config, tries int) ![]items_mod.Item {
	if tries <= 0 {
		return error('get_playlist_tracks out of tries!')
	}

	params := {
		'limit':  '50'
		'fields': 'items(added_at,track(id,name,track_number,external_urls(spotify),album(total_tracks,name,release_date,images(url)),artists(name)))'
	}

	token := get_access_token(config, 3)!
	mut req := http.Request{
		url: '${config.api_url}/playlists/${config.playlist_id}/tracks?' +
			http.url_encode_form_data(params)
	}
	req.add_header(.authorization, 'Bearer ${token}')
	res := req.do()!

	if res.status_code == 401 {
		clear_access_token()!
		return get_playlist_tracks(config, tries - 1)!
	}

	if res.status_code != 200 {
		return error(res.body)
	}

	content := json.decode(ResponseData, res.body)!
	return content.items
}
