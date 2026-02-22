{
  description = "ka2ban - Ka2 project management CLI and MCP server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "0.6.3";

      sources = {
        "aarch64-darwin" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.6.3/ka2ban-v0.6.3-darwin-arm64.tar.gz";
          hash = "sha256-QFpG2J5pwghPS+8mOelwc2sD2OiDWz2G65NPMki5ZRw=";
        };
        "x86_64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.6.3/ka2ban-v0.6.3-linux-x64.tar.gz";
          hash = "sha256-vPvTE08MOZ45OhefO62rh4/H8yK8EsFrd4ILY/AMgvE=";
        };
        "aarch64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.6.3/ka2ban-v0.6.3-linux-arm64.tar.gz";
          hash = "sha256-NniThnrVCAkR12OaTPB6/QfiCKkI3CevGQsZZh4JSkc=";
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
