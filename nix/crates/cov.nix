{
  lib,
  default,
  craneLib,
}:
craneLib.cargoLlvmCov (
  default.commonArgs
  // {
    inherit (default)
      cargoArtifacts
      nativeBuildInputs

      # env
      DBHOST
      PGDATABASE
      PGUSER
      PGPASSWORD
      postgresqlEnableTCP

      postgresqlTestUserOptions
      postgresqlTestSetupPost
      preBuild
      ;

    cargoLlvmCovExtraArgs = "--html --output-dir $out";
    doNotPostBuildInstallCargoBinaries = true;
  }
)
