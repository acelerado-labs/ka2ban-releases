{
  description = "ka2ban - Ka2 project management CLI and MCP server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      version = "0.5.4";

      sources = {
        "aarch64-darwin" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.4/ka2ban-v0.5.4-darwin-arm64.tar.gz";
          hash = "sha256-XKIWwsMx57d3NWkYnFWLe23//rmYXEjvHDVnNTsm9Aw=";
        };
        "x86_64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.4/ka2ban-v0.5.4-linux-x64.tar.gz";
          hash = "sha256-aGGF/0fyHMlRA3IRach2+WcJGwCslizA745GbEn2/Xg=";
        };
        "aarch64-linux" = {
          url = "https://github.com/acelerado-labs/ka2ban-releases/releases/download/v0.5.4/ka2ban-v0.5.4-linux-arm64.tar.gz";
          hash = "sha256-UzMetjqxJZuVnfyRWwIy8uVtaLNxml95WI0OBp1NOoY=";
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
