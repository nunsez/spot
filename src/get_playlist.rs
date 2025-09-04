use crate::{item::Item, track::Track, utils::Result};
use reqwest::blocking;
use serde::Deserialize;
use serde_json::json;
use std::{cmp::Ord, env, fs};

const ACCESS_TOKEN_PATH: &str = ".access_token";

pub fn call() -> Result<()> {
    let config = Config::from_env()?;
    let items = get_playlist_tracks(&config, 3)?;

    let mut tracks = Track::from_items(items);
    tracks.sort_by(|a, b| Ord::cmp(&a.added_at, &b.added_at));

    let json = serde_json::to_string_pretty(&tracks)?;
    fs::write("tracks.json", json)?;

    Ok(())
}

#[derive(Debug)]
struct Config {
    playlist_id: String,
    api_url: String,
    client_id: String,
    client_secret: String,
}

#[derive(Debug, Deserialize)]
struct ResponseData {
    items: Vec<Item>,
}

fn get_playlist_tracks(config: &Config, tries: u32) -> Result<Vec<Item>> {
    if tries == 0 {
        return Err("get_playlist_tracks out of tries!".into());
    }

    let params = json!({
        "limit": 50,
        "fields": "items(added_at,track(id,name,track_number,external_urls(spotify),album(total_tracks,name,release_date,images(url)),artists(name)))"
    });

    let token = get_access_token(config)?;

    let url = format!("{}/playlists/{}/tracks", config.api_url, config.playlist_id);
    let req = blocking::Client::new()
        .get(url)
        .query(&params)
        .header("Authorization", format!("Bearer {}", token));

    let res = req.send()?;

    if res.status() == 401 {
        clear_access_token()?;
        return get_playlist_tracks(config, tries - 1);
    }

    if res.status() != 200 {
        let text = res.text()?;
        return Err(text.into());
    }

    let data: ResponseData = res.json()?;

    Ok(data.items)
}

fn get_access_token(config: &Config) -> Result<String> {
    let mut token = fs::read_to_string(ACCESS_TOKEN_PATH).unwrap_or("".into());

    if token.is_empty() {
        token = fetch_access_token(config)?;
        fs::write(ACCESS_TOKEN_PATH, &token)?;
    }

    Ok(token)
}

fn fetch_access_token(config: &Config) -> Result<String> {
    let data = json!({
        "grant_type": "client_credentials",
        "client_id": &config.client_id,
        "client_secret": &config.client_secret,
    });

    let req = blocking::Client::new()
        .post("https://accounts.spotify.com/api/token")
        .form(&data);

    let res = req.send()?;
    let json: AccessTokenResponse = res.json()?;

    Ok(json.access_token)
}

fn clear_access_token() -> Result<()> {
    fs::write(ACCESS_TOKEN_PATH, "").map_err(Into::into)
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct AccessTokenResponse {
    pub access_token: String,
    pub token_type: String,
    pub expires_in: u64,
}

impl Config {
    fn from_env() -> Result<Self> {
        dotenvy::dotenv()?;

        let playlist_id = get_var("PLAYLIST_ID")?;
        let api_url = get_var_with_default("API_URL", "https://api.spotify.com/v1");
        let client_id = get_var("CLIENT_ID")?;
        let client_secret = get_var("CLIENT_SECRET")?;

        Ok(Self {
            playlist_id,
            api_url,
            client_id,
            client_secret,
        })
    }
}

fn get_var(name: &str) -> Result<String> {
    env::var(name).map_err(|_| format!("{name} required").into())
}

fn get_var_with_default(name: &str, default: &str) -> String {
    env::var(name).unwrap_or(default.to_owned())
}
