{
  description = "moon CLI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "2.2.5";

      binSystems = {
        x86_64-linux = { target = "x86_64-unknown-linux-gnu"; sha256 = "sha256-hj95P/XmtWT1MU5Q/ber9AU3cYhEECPhc6Wh6FvsSUg="; };
        aarch64-linux = { target = "aarch64-unknown-linux-gnu"; sha256 = "sha256-goZhXRJ09VF/tBu1y5XGvN4RKX3m4pFUWQWKeu4RLyE="; };
        aarch64-darwin = { target = "aarch64-apple-darwin"; sha256 = "sha256-tf/f/OyuL0trOm/xWwOtnFqoh01n/CERiBOW4Nc8z4w="; };
      };

      src = {
        owner = "moonrepo";
        repo = "moon";
        rev = "v${version}";
        sha256 = "0f2pgyjpz4fzk1x1l8n7qk61441sc412qwji83x2r8y9hcjmmj2k";
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
