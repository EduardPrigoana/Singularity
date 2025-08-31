use reqwest::{Client, Response};
use serde::Deserialize;
use std::error::Error;

#[derive(Debug, Deserialize)]
struct TracksResponse {
    tracks: Vec<Track>,
}

#[serde(rename_all = "camelCase")]
#[derive(Debug, Deserialize)]
pub struct Track {
    pub id: u64,
    pub title: String,
    pub artist: String,
    pub album_title: String,
    pub album_cover: String,
    pub duration: u32,
}

pub struct DabClient {
    base_url: String,
    client: Client,
}

impl DabClient {
    pub fn new() -> Self {
        Self {
            base_url: "https://dab.yeet.su/api".to_string(),
            client: Client::new(),
        }
    }

    pub async fn search(&self, query: &str) -> Result<Vec<Track>, Box<dyn Error>> {
        let url = format!("{}/search?offset=0&type=track&q={}", self.base_url, query);

        let res = self.make_get_req(&url).await?;
        let wrapper = res.json::<TracksResponse>().await?;
        Ok(wrapper.tracks)
        // Ok(res.json::<Vec<Track>>().await?)
    }

    pub async fn get_album(&self, album_id: &str) -> Result<String, Box<dyn Error>> {
        let url = formata!("{}/album?albumId={}", self.base_url, album_id);
        // self.make_get_req(&url).await
        todo!()
    }

    async fn make_get_req(&self, url: &str) -> Result<Response, Box<dyn Error>> {
        let res = self.client.get(url).send().await?;
        if !res.status().is_success() {
            return Err(format!("Status {}", res.status()).into());
        }
        Ok(res)
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let dc = DabClient::new();

    let res = dc.search("pink floyd").await?;

    println!("{:#?}", res);

    Ok(())
}
