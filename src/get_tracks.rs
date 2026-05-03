use std::fs;

use anyhow::Result;
use serde::Deserialize;

use crate::{item::Item, track::Track};

#[derive(Debug, Deserialize)]
struct TracksData {
    items: Vec<Item>,
}

pub fn call() -> Result<()> {
    let content = fs::read_to_string("items.json")?;
    let tracks_data: TracksData = serde_json::from_str(&content)?;

    let mut tracks = Track::from_items(tracks_data.items);
    tracks.sort_by(|a, b| Ord::cmp(&a.added_at, &b.added_at));

    let json = serde_json::to_string_pretty(&tracks)?;
    fs::write("tracks.json", json)?;

    Ok(())
}
