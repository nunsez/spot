module items_mod

pub struct Item {
pub:
	added_at string
	track    TrackDetails
}

struct TrackDetails {
pub:
	id            string
	name          string
	track_number  int
	external_urls ExternalUrls
	artists       []Artist
	album         Album
}

struct ExternalUrls {
pub:
	spotify string
}

struct Artist {
pub:
	name string
}

struct Album {
pub:
	name         string
	release_date string
	images       []Image
}

struct Image {
pub:
	url string
}
