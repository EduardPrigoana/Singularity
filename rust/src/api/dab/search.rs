use flutter_rust_bridge::frb;
use reqwest::Client;


#[frb]
pub async fn rust_dab_search(
    query: String,
) -> Result<String, String> {
    println!("Rust: Dab Search: {query}");
    let client = Client::new();
    let url = format!("https://dab.yeet.su/api/search?offset=0&type=track&q={query}");


    let res = client
        .get(url)
        .send()
        .await.map_err(|e| format!("req send error: {}", e))?;

    if !res.status().is_success() {
        return Err(format!("Status {}", res.status()));
    }    

    let text = res
        .text()
        .await
        .map_err(|e| format!("Body read error: {}", e))?;

    Ok(text)
}
