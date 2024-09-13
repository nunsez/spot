module tracks_mod

import items_mod

pub struct Track {
pub:
	id                 string
	name               string
	track_number       int
	spotify_url        string
	artists            string
	added_at           string
	album_name         string
	album_release_date string
pub mut:
	album_image_url string
}

pub fn Track.from_item(item items_mod.Item) Track {
	mut track := Track{
		id:                 item.track.id
		name:               item.track.name
		track_number:       item.track.track_number
		spotify_url:        item.track.external_urls.spotify
		artists:            item.track.artists.map(it.name).join('; ')
		added_at:           item.added_at
		album_name:         item.track.album.name
		album_release_date: item.track.album.release_date
	}

	if album_image := item.track.album.images[0] {
		track.album_image_url = album_image.url
	}

	return track
}

pub fn Track.from_items(items []items_mod.Item) []Track {
	return items.map(Track.from_item(it))
}
