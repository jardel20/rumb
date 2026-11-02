# O pacote nativo. Recebe o pkgs de quem instala (flake, overlay ou módulo),
# então usa o nixpkgs do próprio sistema.
{ lib
, rustPlatform
, makeWrapper
, bash
, jq
, coreutils
, findutils
, gawk
, gnused
, gnugrep
, curl
, git
, nix
, systemd
, libxml2
, makeDesktopItem
  # Comando que abre um terminal e roda o que vem depois, por exemplo
  # "kitty --title rumb -e". Com null, a entrada do launcher usa Terminal=true.
, terminal ? null
}:

let
  desktopItem = makeDesktopItem {
    name = "rumb";
    desktopName = "rumb";
    genericName = "NixOS system health";
    comment = "Terminal dashboard for NixOS: generations, flake inputs, failed units and disk space";
    exec = if terminal == null then "rumb" else "${terminal} rumb";
    icon = "rumb";
    terminal = terminal == null;
    categories = [ "System" "Monitor" ];
    keywords = [ "nixos" "health" "generations" "journal" "flake" ];
  };
in
rustPlatform.buildRustPackage {
  pname = "rumb";
  version = "0.1.9";

  src = lib.cleanSource ../.;
  cargoRoot = "tui";
  buildAndTestSubdir = "tui";
  cargoLock.lockFile = ../tui/Cargo.lock;

  nativeBuildInputs = [ makeWrapper ];

  # Os testes rodam no checkPhase (cargo test) e precisam do scanner ao lado.
  postInstall = ''
    install -Dm755 bin/rumb-scan $out/libexec/rumb/rumb-scan
    substituteInPlace $out/libexec/rumb/rumb-scan \
      --replace-fail '#!/usr/bin/env bash' '#!${bash}/bin/bash'
    install -Dm644 man/rumb.1 $out/share/man/man1/rumb.1
    install -Dm644 nix/icon/rumb.svg $out/share/icons/hicolor/scalable/apps/rumb.svg
    install -Dm644 nix/icon/rumb.png $out/share/icons/hicolor/256x256/apps/rumb.png
    install -Dm644 ${desktopItem}/share/applications/rumb.desktop $out/share/applications/rumb.desktop
    wrapProgram $out/bin/rumb \
      --set RUMB_SCAN $out/libexec/rumb/rumb-scan \
      --suffix PATH : ${lib.makeBinPath [ jq coreutils findutils gawk gnused gnugrep curl git nix systemd libxml2.bin ]}
  '';

  meta = {
    description = "Terminal dashboard for NixOS system health";
    homepage = "https://github.com/jardel20/rumb";
    license = lib.licenses.mit;
    mainProgram = "rumb";
    platforms = lib.platforms.linux;
  };
}
