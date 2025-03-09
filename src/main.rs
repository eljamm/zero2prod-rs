use std::net::TcpListener;

use zero2prod::config::get_config;
use zero2prod::startup::run;

#[tokio::main]
async fn main() -> Result<(), std::io::Error> {
    let config = get_config().expect("Failed to read configuration.");
    let address = format!("127.0.0.1:{}", config.app_port);
    let listener = TcpListener::bind(address)?;
    run(listener)?.await
}
