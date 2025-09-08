{
  lib,
  craneLib,
  crateInfo,
  pkg-config,
  openssl,
  postgresql,
  postgresqlTestHook,
  sqlx-cli,
  breakpointHook,
  rustPlatform,
  writers,
}:
let
  sqlFilter = path: _type: builtins.match ".*sql$" path != null;
  finalFilter = path: type: (sqlFilter path type) || (craneLib.filterCargoSources path type);

  test-config = {
    app_port = 8000;
    database = {
      name = "newsletter";
      host = "127.0.0.1";
      port = 5432;
      username = "nixbld";
      password = "password";
    };
  };

  inherit (test-config.database)
    username
    password
    host
    port
    name
    ;
in
rustPlatform.buildRustPackage rec {
  inherit (crateInfo src) pname version;

  src = lib.cleanSourceWith {
    src = ../../.;
    filter = finalFilter;
    name = "source";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";
  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    breakpointHook
    postgresqlTestHook
    postgresql
    sqlx-cli
  ];

  buildInputs = [
    openssl
  ];

  env = {
    PGDATABASE = name;
    PGUSER = username;
    PGPASSWORD = password;
    postgresqlEnableTCP = 1;
  };

  postgresqlTestUserOptions = "LOGIN SUPERUSER";
  postgresqlTestSetupPost = ''
    export DATABASE_URL="postgresql://$PGUSER:$PGPASSWORD@${host}/$PGDATABASE"
  '';

  preBuild = ''
    postgresqlStart

    cp ${writers.writeYAML "config.yaml" test-config} config.yaml
    cp -R ${src.outPath}/migrations .

    sqlx database create
    sqlx migrate run
  '';

  postBuild = ''
    cargo test $cargoTestFlags

    postgresqlStop
  '';

  doCheck = false;
}
