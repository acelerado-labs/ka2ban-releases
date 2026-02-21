{
  description = "ka2ban - Ka2 project management CLI and MCP server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "0.5.2";

      sources = {
        "aarch64-darwin" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.2/ka2ban-v0.5.2-darwin-arm64.tar.gz";
          hash = "__DARWIN_ARM64_HASH__";
        };
        "x86_64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.2/ka2ban-v0.5.2-linux-x64.tar.gz";
          hash = "__LINUX_X64_HASH__";
        };
        "aarch64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.2/ka2ban-v0.5.2-linux-arm64.tar.gz";
          hash = "__LINUX_ARM64_HASH__";
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
