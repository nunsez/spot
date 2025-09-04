use crate::item::Item;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct Track {
    pub id: String,
    pub name: String,
    pub track_number: u32,
    pub total_tracks: u32,
    pub spotify_url: String,
    pub artists: String,
    pub added_at: String,
    pub album_name: String,
    pub album_release_date: String,
    pub album_image_url: String,
}

impl Track {
    pub fn from_item(item: Item) -> Self {
        let track = item.track;
        let album = track.album;
        let images = album.images;

        let artists = track
            .artists
            .into_iter()
            .map(|a| a.name)
            .collect::<Vec<String>>()
            .join("; ");

        let album_image_url = match images.first() {
            Some(image) => image.url.clone(),
            None => String::from(""),
        };

        Self {
            id: track.id,
            name: track.name,
            track_number: track.track_number,
            total_tracks: album.total_tracks,
            spotify_url: track.external_urls.spotify,
            artists,
            added_at: item.added_at,
            album_name: album.name,
            album_release_date: album.release_date,
            album_image_url,
        }
    }

    pub fn from_items(items: Vec<Item>) -> Vec<Self> {
        items.into_iter().map(Self::from_item).collect()
    }
}
