{
  stdenv,
  lib,
  makeDesktopItem,
  copyDesktopItems,
}:

stdenv.mkDerivation rec {
  pname = "algolink";
  version = "1.0";

  src = ../bin/algolink.AppImage;

  nativeBuildInputs = [ copyDesktopItems ];

  unpackPhase = "true";
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/algolink
    chmod +x $out/bin/algolink
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname; # -> algolink.desktop
      desktopName = "AlgoLink";
      comment = "Client distant AlgoLink";
      exec = "algolink";
      icon = "computer";
      categories = [ "Network" ];
      terminal = false;
    })
  ];

  meta = with lib; {
    description = "AlgoLink remote‑desktop AppImage";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
