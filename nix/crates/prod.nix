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
  commonArgs = rec {
    inherit (crateInfo src)
      pname
      version
      ;

    src =
      let
        sqlFilter = path: _type: builtins.match ".*sql$" path != null;
        finalFilter = path: type: (sqlFilter path type) || (craneLib.filterCargoSources path type);
      in
      lib.cleanSourceWith {
        src = ../../.;
        filter = finalFilter;
        name = "source";
      };

    cargoLock = "${src}/Cargo.lock";
    strictDeps = true;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
    ];
  };

  cargoArtifacts = craneLib.buildDepsOnly (
    commonArgs
    // {
      pname = "${commonArgs.pname}-deps";
    }
  );

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
in
craneLib.buildPackage (
  commonArgs
  // rec {
    inherit cargoArtifacts;

    nativeBuildInputs = [
      pkg-config
      postgresql
      postgresqlTestHook
      sqlx-cli
    ];

    env = with test-config.database; {
      DBHOST = host;
      PGDATABASE = name;
      PGUSER = username;
      PGPASSWORD = password;
      postgresqlEnableTCP = 1;
    };

    postgresqlTestUserOptions = "LOGIN SUPERUSER";
    postgresqlTestSetupPost = ''
      export DATABASE_URL="postgresql://$PGUSER:$PGPASSWORD@$DBHOST/$PGDATABASE"
    '';

    preBuild = ''
      postgresqlStart

      cp ${writers.writeYAML "config.yaml" test-config} config.yaml
      cp -R ${commonArgs.src.outPath}/migrations .

      sqlx database create
      sqlx migrate run

      # Don't attempt to start the database again in the check hook.
      skipHook=postgresqlStart
      preCheckHooks=( "''${preCheckHooks[@]/''$skipHook}" )
    '';
  }
)
