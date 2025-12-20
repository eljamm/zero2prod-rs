{
  lib,
  craneLib,
  pkg-config,
  postgresql,
  postgresqlTestHook,
  sqlx-cli,
  writers,

  test-config,
  commonArgs,
}:
craneLib.buildPackage (
  commonArgs
  // {
    cargoArtifacts = craneLib.buildDepsOnly commonArgs;

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

    passthru = {
      inherit
        commonArgs
        test-config
        ;
    };
  }
)
