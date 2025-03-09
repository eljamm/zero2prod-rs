use std::net::TcpListener;

use sqlx::{Connection, PgConnection};
use zero2prod::config::get_config;
use zero2prod::startup::run;

#[tokio::main]
async fn main() -> Result<(), std::io::Error> {
    let config = get_config().expect("Failed to read configuration.");
    let connection = PgConnection::connect(&config.database.connection_string())
        .await
        .expect("Failed to connect to PostgreSQL.");
    let address = format!("127.0.0.1:{}", config.app_port);
    let listener = TcpListener::bind(address)?;
    run(listener, connection)?.await
}
