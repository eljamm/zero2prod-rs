use actix_web::{web, App, HttpRequest, HttpResponse, HttpServer, Responder};

async fn health_check() -> HttpResponse {
    HttpResponse::Ok().finish()
}

pub async fn run() -> Result<(), std::io::Error> {
    // Handle client requests
    HttpServer::new(|| App::new().route("/health_check", web::get().to(health_check)))
        .bind("127.0.0.1:8000")?
        .run()
        .await
}
