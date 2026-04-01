{
  description = "ka2ban - Ka2 project management CLI and MCP server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "0.7.10";

      sources = {
        "aarch64-darwin" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.7.10/ka2ban-v0.7.10-darwin-arm64.tar.gz";
          hash = "sha256-yYJtMe/fKn1NRq91KKhnTfWqr0NAFEtZ/BM/6t0Rh6k=";
        };
        "x86_64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.7.10/ka2ban-v0.7.10-linux-x64.tar.gz";
          hash = "sha256-/cWoohvefqGJ0Vg/r23RscLabNDvakICSTR2IapL5PQ=";
        };
        "aarch64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.7.10/ka2ban-v0.7.10-linux-arm64.tar.gz";
          hash = "sha256-uRZ3dcTkFDBqbOs2buRRdWKSjlrsc4UB3dxKBfZsztc=";
        };
      };

      mkPackage = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          source = sources.${system};
          isLinux = pkgs.lib.hasSuffix "-linux" system;
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "ka2ban";
          inherit version;
          src = pkgs.fetchurl { inherit (source) url hash; };
          dontUnpack = true;
          # Bun standalone binaries append JS bytecode + module graph
          # after the ELF segments with a trailer at EOF. Any
          # post-processing that modifies or truncates the binary
          # (strip, patchelf --set-rpath) corrupts these markers and
          # causes the binary to fall back to the raw Bun CLI.
          dontStrip = true;
          dontPatchELF = true;
          nativeBuildInputs = pkgs.lib.optionals isLinux [ pkgs.patchelf ];
          installPhase = ''
            mkdir -p $out/bin
            tar -xzf $src -C $out/bin
            chmod +x $out/bin/ka2ban
          '';
          # Patch only the ELF interpreter for NixOS compatibility.
          # --set-interpreter is safe (modifies ELF headers, not appended data).
          postFixup = pkgs.lib.optionalString isLinux ''
            patchelf --set-interpreter "${pkgs.stdenv.cc.bintools.dynamicLinker}" $out/bin/ka2ban
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
