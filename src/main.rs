mod get_playlist;
mod item;
mod set_metadata;
mod track;
mod utils;

use std::env;

use utils::Result;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    if let Some(cmd) = args.get(1) {
        match cmd.as_str() {
            "get_playlist" => get_playlist::call()?,
            "set_metadata" => set_metadata::call()?,
            _ => usage(),
        }
    } else {
        usage()
    }

    Ok(())
}

fn usage() {
    println!("get_playlist | set_metadata");
}
