{
  description = "moon CLI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "2.5.5";

      binSystems = {
        x86_64-linux = { target = "x86_64-unknown-linux-gnu"; sha256 = "sha256-85cFeiLIj/nksopKL78B2Z9Nmk815aQmNCVan1Ccy9Y="; };
        aarch64-linux = { target = "aarch64-unknown-linux-gnu"; sha256 = "sha256-OdVeiHdGdxgdGvNWbEzNKZTNLZ2BmfzzDcLW3vwFrHg="; };
        aarch64-darwin = { target = "aarch64-apple-darwin"; sha256 = "sha256-yQljcRtwYJ2jmMG+juNrTPL2FnxexT9IbYvZuqVupXg="; };
      };

      src = {
        owner = "moonrepo";
        repo = "moon";
        rev = "v${version}";
        sha256 = "14xiac449hiss39p8bggay18v0p86b4mrsfsv7fgwd748yhwwvqk";
      };

      mkMoonBin = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          info = binSystems.${system};
        in
        pkgs.stdenv.mkDerivation {
          pname = "moon-bin";
          inherit version;
          src = pkgs.fetchurl {
            url = "https://github.com/moonrepo/moon/releases/download/v${version}/moon_cli-${info.target}.tar.xz";
            inherit (info) sha256;
          };
          nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
          buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];
          dontConfigure = true;
          dontBuild = true;
          installPhase = ''
            install -Dm755 moon moonx -t $out/bin
          '';
        };

      mkMoon = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          moonSrc = pkgs.fetchFromGitHub { inherit (src) owner repo rev sha256; };
        in
        pkgs.rustPlatform.buildRustPackage {
          pname = "moon";
          inherit version;
          src = moonSrc;
          buildAndTestSubdir = "crates/cli";
          cargoLock.lockFile = "${moonSrc}/Cargo.lock";
          OPENSSL_NO_VENDOR = 1;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ]
            ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.apple-sdk_14 ];
          doCheck = false;
        };
    in
    {
      packages = nixpkgs.lib.genAttrs (builtins.attrNames binSystems) (system: {
        moon-bin = mkMoonBin system;
        moon = mkMoon system;
        default = mkMoonBin system;
      });
    };
}
