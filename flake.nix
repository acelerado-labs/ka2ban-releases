{
  description = "ka2ban - Ka2 project management CLI and MCP server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "0.5.1";

      sources = {
        "aarch64-darwin" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.1/ka2ban-v0.5.1-darwin-arm64.tar.gz";
          hash = "sha256-SxeJEKCGHzNILttMZKhlP7PHbArzI+kBnir1q6umqq4=";
        };
        "x86_64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.1/ka2ban-v0.5.1-linux-x64.tar.gz";
          hash = "sha256-KAnJ1n2R64om7cBOVehMDnj4XvzJSYAJYp5SkbhqWl0=";
        };
        "aarch64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.1/ka2ban-v0.5.1-linux-arm64.tar.gz";
          hash = "sha256-c27pwh/RYvmcivNEw43b417Vm6onKxzTwA6ZIbH8Md0=";
        };
      };

      mkPackage = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          source = sources.${system};
        in
        pkgs.stdenv.mkDerivation {
          pname = "ka2ban";
          inherit version;
          src = pkgs.fetchurl { inherit (source) url hash; };
          dontUnpack = true;
          nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.autoPatchelfHook
          ];
          buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.glib
            pkgs.libsecret
          ];
          installPhase = ''
            mkdir -p $out/bin
            tar -xzf $src -C $out/bin
            chmod +x $out/bin/ka2ban
          '';
          meta = with pkgs.lib; {
            description = "Ka2 project management CLI and MCP server";
            mainProgram = "ka2ban";
          };
        };
    in
    {
      packages = nixpkgs.lib.genAttrs
        (builtins.attrNames sources)
        (system: {
          default = mkPackage system;
          ka2ban = mkPackage system;
        });
    };
}
