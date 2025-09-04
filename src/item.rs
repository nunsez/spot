use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct Item {
    pub added_at: String,
    pub track: TrackDetails,
}

#[derive(Debug, Deserialize)]
pub struct TrackDetails {
    pub id: String,
    pub name: String,
    pub track_number: u32,
    pub external_urls: ExternalUrls,
    pub artists: Vec<Artist>,
    pub album: Album,
}

#[derive(Debug, Deserialize)]
pub struct ExternalUrls {
    pub spotify: String,
}

#[derive(Debug, Deserialize)]
pub struct Artist {
    pub name: String,
}

#[derive(Debug, Deserialize)]
pub struct Album {
    pub total_tracks: u32,
    pub name: String,
    pub release_date: String,
    pub images: Vec<Image>,
}

#[derive(Debug, Deserialize)]
pub struct Image {
    pub url: String,
}
