use crate::track::Track;
use anyhow::{Context, Result, bail};
use metaflac::{Tag, block::PictureType};
use reqwest::blocking;
use std::{
    fs,
    path::{Path, PathBuf},
};

pub fn call() -> Result<()> {
    let content = fs::read_to_string("tracks.json")?;
    let tracks: Vec<Track> = serde_json::from_str(&content)?;

    fs::create_dir_all("images")?;

    for track in tracks {
        if let Err(e) = process(&track) {
            eprintln!("{e}")
        }
    }

    Ok(())
}

fn process(track: &Track) -> Result<()> {
    let image_path = download_image(track).unwrap_or_default();
    let track_path = set_metadata(track, &image_path)?;
    let track_name = build_track_name(track);

    fs::rename(&track_path, &track_name).with_context(|| {
        let message = format!("track rename error: {}", &track_name);
        msg(track, &message)
    })?;
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

fn set_metadata(track: &Track, image_path: &Path) -> Result<PathBuf> {
    let p = format!("{}.flac", &track.id);
    let track_path = Path::new(&p);

    if !track_path.exists() {
        bail!(msg(track, "track not found"));
    }

    let mut tag = Tag::read_from_path(track_path).context(msg(track, "tag reading error"))?;

    // clear vorbis
    tag.remove_blocks(metaflac::BlockType::VorbisComment);

    set_vorbis_first(&mut tag, "TITLE", &track.name);
    set_vorbis_first(&mut tag, "ARTIST", &track.artists);
    set_vorbis_first(&mut tag, "ALBUM", &track.album_name);
    set_vorbis_first(&mut tag, "DATE", &track.album_release_date);
    set_vorbis_first(&mut tag, "COMMENT", &track.spotify_url);

    if let Some(year) = extract_year(&track.album_release_date) {
        set_vorbis_first(&mut tag, "YEAR", &year);
    }

    if track.track_number != 0 {
        let track_number = track.track_number.to_string();
        set_vorbis_first(&mut tag, "TRACKNUMBER", &track_number);
    }

    if track.total_tracks != 0 {
        let total_tracks = track.total_tracks.to_string();
        set_vorbis_first(&mut tag, "TOTALTRACKS", &total_tracks);
    }

    match fs::read(image_path) {
        Ok(picture) => match infer::get(&picture) {
            Some(mime_type) => {
                let picture_type = PictureType::CoverFront;
                tag.remove_picture_type(picture_type);
                tag.add_picture(mime_type.mime_type(), picture_type, picture);
            }
            None => {
                eprintln!("{}", msg(track, "unknown image format"));
            }
        },
        Err(_) => {
            eprintln!("{}", msg(track, "image file not found"));
        }
    }

    tag.save().context(msg(track, "tag saving error"))?;

    Ok(track_path.to_path_buf())
}

fn set_vorbis_first(tag: &mut Tag, key: &str, value: &str) {
    tag.set_vorbis(key, vec![value]);
}

// TODO: should sanitize symbols: \/:*?"<>| ?
fn build_track_name(track: &Track) -> String {
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
