use std::net::TcpListener;

use zero2prod::run;

#[tokio::main]
async fn main() -> Result<(), std::io::Error> {
    let listener = TcpListener::bind("127.0.0.1:8000").expect("Failed to bind random port.");
    // Bubble up the io::Error if we failed to bind the address
    // Otherwise call .await on the Server
    run(listener)?.await
}
