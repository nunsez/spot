mod get_playlist;
mod get_tracks;
mod item;
mod set_metadata;
mod track;

use anyhow::Result;
use std::env;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    if let Some(cmd) = args.get(1) {
        match cmd.as_str() {
            "get_playlist" => get_playlist::call()?,
            "set_metadata" => set_metadata::call()?,
            "get_tracks" => get_tracks::call()?,
            _ => usage(),
        }
    } else {
        usage()
    }

    Ok(())
}

fn usage() {
    println!("get_playlist | set_metadata | get_tracks");
}
