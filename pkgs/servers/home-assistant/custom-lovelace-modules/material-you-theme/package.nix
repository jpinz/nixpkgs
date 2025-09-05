{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "material-you-theme";
  version = "5.0.1";

  src = fetchFromGitHub {
    owner = "Nerwyn";
    repo = "material-you-theme";
    rev = version;
    hash = "";
  };


  npmDepsHash = "";

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp themes/material_you.yaml $out

    runHook postInstall
  '';

  passthru.entrypoint = "material_you.yaml";

  meta = with lib; {
    description = "Material Design 3 Theme for Home Assistant";
    homepage = "https://github.com/Nerwyn/material-you-theme";
    license = licenses.asl20;
    maintainers = with maintainers; [ k900 ];
    platforms = platforms.all;
  };
}
