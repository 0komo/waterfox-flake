{
  config,
  stdenv,
  fetchzip,
  writeText,
  wrapGAppsHook3,
  gtk3,
  alsa-lib,
  dbus-glib,
  libnotify,
  autoPatchelfHook,
  libva,
  pciutils,
  patchelfUnstable,
  pipewire,
  libXtst,
  curl,
  libGL,
  lib,
  adwaita-icon-theme,
}:

/*
  TODO:
  - support for darwin
*/

let
  inherit (builtins)
    readFile
    fromJSON
    toJSON
    ;

  source = fromJSON (readFile ./source.json);
in
stdenv.mkDerivation (self: {
  pname = "waterfox-bin-unwrapped";
  inherit (source) version;

  src = fetchzip source.src;

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable # see patchelfFlags
  ];

  buildInputs = [
    adwaita-icon-theme
    gtk3
    alsa-lib
    dbus-glib
    libnotify
    libXtst
  ];

  runtimeDependencies = [
    curl
    libva.out
    pciutils
    libGL
  ];

  appendRunpaths = [
    "${pipewire}/lib"
    "${libGL}/lib"
  ];

  # Firefox uses "relrhack" to manually process relocations from a fixed offset
  patchelfFlags = [ "--no-clobber-old-sections" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/waterfox
    cp -r $src/* $out/lib/waterfox

    mkdir -p $out/bin
    ln -s $out/lib/waterfox/waterfox-bin $out/bin/waterfox

    install -D $src/browser/chrome/icons/default/default16.png $out/share/icons/hicolor/16x16/apps/waterfox.png
    install -D $src/browser/chrome/icons/default/default32.png $out/share/icons/hicolor/32x32/apps/waterfox.png
    install -D $src/browser/chrome/icons/default/default48.png $out/share/icons/hicolor/48x48/apps/waterfox.png
    install -D $src/browser/chrome/icons/default/default64.png $out/share/icons/hicolor/64x64/apps/waterfox.png
    install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/waterfox.png

    runHook postInstall
  '';

  passthru = {
    applicationName = "Waterfox";
    binaryName = "waterfox";
    libName = "waterfox-bin-${self.version}";
    ffmpegSupport = true;
    gssSupprot = true;
    inherit gtk3;
  };

  meta = {
    description = "Fast and Private Web Browser";
    longDescription = ''
      Waterfox is an open-source, privacy-focused browser based on the popular open source browser with a red panda as a mascot. It is designed to be a drop-in replacement for said browser that offers enhanced privacy features, performance improvements, and customizability while maintaining compatibility with existing extensions.
    '';
    homepage = "https://www.waterfox.net";
    license = with lib.licenses; [ mpl20 ];
    mainProgram = self.passthru.binaryName;
    platforms = [ "x86_64-linux" ];
  };
})
