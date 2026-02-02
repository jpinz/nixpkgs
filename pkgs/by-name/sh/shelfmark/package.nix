{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  python3,
  makeWrapper,
}:

let
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "calibrain";
    repo = "shelfmark";
    tag = "v${version}";
    hash = "sha256-CegQkKOU/DKUYZnc3EFVd8mfV0W9qul3tqfoPRckOoA=";
  };

  frontend = buildNpmPackage {
    pname = "shelfmark-frontend";
    inherit version src;

    sourceRoot = "${src.name}/src/frontend";

    npmDepsHash = "sha256-FXxRNIv6O9vyXm9/m89tlkSDtw4RzTgUEY2mad/R6mA=";

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/* $out/
      runHook postInstall
    '';
  };
in
python3.pkgs.buildPythonApplication rec {
  pname = "shelfmark";
  inherit version src;
  pyproject = false;
  format = "other";

  nativeBuildInputs = [
    makeWrapper
  ];

  pythonRelaxDeps = true;

  propagatedBuildInputs = with python3.pkgs; [
    # Core web framework
    flask
    flask-cors
    flask-socketio
    gunicorn
    gevent
    gevent-websocket

    # Socket/networking
    python-socketio
    python-engineio
    requests
    pysocks
    dnspython

    # Web scraping
    beautifulsoup4

    # Utils
    tqdm
    psutil
    emoji
    rarfile

    # Download clients
    qbittorrent-api
    transmission-rpc
  ];

  # Tests require running services (Docker)
  doCheck = false;

  installPhase = ''
    runHook preInstall

    # Install Python package
    mkdir -p $out/${python3.sitePackages}
    cp -r shelfmark $out/${python3.sitePackages}/
    cp -r data $out/${python3.sitePackages}/

    # Install frontend
    mkdir -p $out/${python3.sitePackages}/frontend-dist
    cp -r ${frontend}/* $out/${python3.sitePackages}/frontend-dist/

    # Create wrapper script
    mkdir -p $out/bin
    makeWrapper ${python3.pkgs.gunicorn}/bin/gunicorn $out/bin/shelfmark \
      --prefix PYTHONPATH : "$out/${python3.sitePackages}" \
      --add-flags "--worker-class geventwebsocket.gunicorn.workers.GeventWebSocketWorker" \
      --add-flags "--workers 1" \
      --add-flags "-t 300" \
      --add-flags "-b 0.0.0.0:8084" \
      --add-flags "shelfmark.main:app"

    runHook postInstall
  '';

  pythonImportsCheck = [
    "shelfmark"
  ];

  meta = {
    description = "Unified web interface for searching and downloading books and audiobooks from multiple sources";
    homepage = "https://github.com/calibrain/shelfmark";
    changelog = "https://github.com/calibrain/shelfmark/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpinz ];
    mainProgram = "shelfmark";
  };
}
