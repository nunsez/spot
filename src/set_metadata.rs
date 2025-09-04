use reqwest::blocking;
use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
};

use crate::{track::Track, utils::Result};

pub fn call() -> Result<()> {
    let content = fs::read_to_string("tracks.json")?;
    let tracks: Vec<Track> = serde_json::from_str(&content)?;

    fs::create_dir_all("images")?;
    fs::create_dir_all("metadata")?;

    for track in tracks {
        if let Err(e) = process(&track) {
            eprintln!("{e}")
        }
    }

    Ok(())
}

fn process(track: &Track) -> Result<()> {
    let image_path = download_image(track).unwrap_or_default();
    let metadata_path = save_metadata(track)?;
    let track_path = set_metadata(track, &metadata_path, &image_path)?;

    fs::rename(&track_path, track_name(track)).map_err(|_| "track rename error")?;
    println!("{}", msg(track, "OK!"));

    Ok(())
}

fn download_image(track: &Track) -> Result<PathBuf> {
    let path = Path::new("images").join(&track.id);

    if path.is_file() {
        return Ok(path);
    }

    let res = blocking::Client::new().get(&track.album_image_url).send()?;
    let image = res.bytes()?;

    fs::write(&path, image)?;

    Ok(path)
}

fn save_metadata(track: &Track) -> Result<PathBuf> {
    let mut rows = vec![
        build_tag_row("TITLE", &track.name),
        build_tag_row("ARTIST", &track.artists),
        build_tag_row("ALBUM", &track.album_name),
        build_tag_row("DATE", &track.album_release_date),
        build_tag_row("COMMENT", &track.spotify_url),
    ];

    if let Some(year) = extract_year(&track.album_release_date) {
        rows.push(build_tag_row("YEAR", &year));
    }

    if track.track_number != 0 {
        rows.push(build_tag_row(
            "TRACKNUMBER",
            &track.track_number.to_string(),
        ));
    }

    if track.total_tracks != 0 {
        rows.push(build_tag_row(
            "TOTALTRACKS",
            &track.total_tracks.to_string(),
        ));
    }

    let metadata_path = Path::new("metadata").join(&track.id);

    let content = format!("{}\n", rows.join("\n"));
    fs::write(&metadata_path, content)?;

    Ok(metadata_path)
}

fn build_tag_row(key: &str, value: &str) -> String {
    format!("{}={}", key.to_uppercase(), value)
}

fn set_metadata(track: &Track, metadata_path: &Path, image_path: &Path) -> Result<PathBuf> {
    let p = format!("{}.flac", &track.id);
    let track_path = Path::new(&p);

    if !track_path.exists() {
        return Err(msg(track, "track not found").into());
    }

    let mut binding = Command::new("metaflac");
    let cmd = binding.arg("--no-utf8-convert").arg("--remove-all-tags");

    if metadata_path.exists() {
        cmd.arg("--import-tags-from").arg(metadata_path);
    } else {
        eprintln!("{}", msg(track, "metadata file not found"));
    }

    if image_path.exists() {
        cmd.arg("--import-picture-from").arg(image_path);
    } else {
        eprintln!("{}", msg(track, "image file not found"));
    }

    cmd.arg(track_path);

    cmd.output().map_err(|_| msg(track, "metaflac error"))?;

    Ok(track_path.to_path_buf())
}

fn track_name(track: &Track) -> String {
    let artists = track.artists.replace(";", ",");
    format!("{} - {}.flac", artists, track.name)
}

fn msg(track: &Track, message: &str) -> String {
    format!("{} : {}", track.id, message)
}

fn extract_year(date_str: &str) -> Option<String> {
    let parts: Vec<&str> = date_str.split('-').collect();

    if let Some(year) = parts.first()
        && year.chars().count() == 4
    {
        Some(year.to_string())
    } else {
        None
    }
}
