{
  description = "Flake for Vencord (Custom)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }:
    let
      forAllSystems = f: nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: f system);
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems
        (system:
          let
            pkgs = pkgsFor system;
            inherit (pkgs) stdenv pnpm_10 lib esbuild fetchFromGitHub;
          in
          rec
          {
            # taken from nixpkgs vencord package and modified by me
            vencord =
              lib.makeOverridable
                ({ buildWebExtension, userplugins }: stdenv.mkDerivation
                  (finalAttrs: {
                    pname = "vencord";
                    version = "1.12.0";

                    src = ./.;

                    # TODO: make as derivations
                    patchPhase = ''
                      mkdir -p "src/userplugins"
                      counter=0

                      for plugin in ${lib.concatStringsSep " " userplugins}; do
                        echo "Processing plugin: $plugin"
                        if [ -f "$plugin" ]
                        then
                          cp "$plugin" "src/userplugins";
                        else
                          mkdir -p "src/userplugins/PLUGIN$counter";
                          cp -a "$plugin/." "src/userplugins/PLUGIN$counter";
                        fi
                        counter=$((counter+1))
                      done
                    '';

                    pnpmDeps = pnpm_10.fetchDeps {
                      inherit (finalAttrs) pname src;

                      hash = "sha256-hO6QKRr4jTfesRDAEGcpFeJmGTGLGMw6EgIvD23DNzw=";
                    };

                    nativeBuildInputs = with pkgs; [
                      git
                      nodejs
                      pnpm_10.configHook
                    ];

                    env = {
                      ESBUILD_BINARY_PATH = lib.getExe (
                        esbuild.overrideAttrs (
                          final: _: {
                            version = "0.25.1";
                            src = fetchFromGitHub {
                              owner = "evanw";
                              repo = "esbuild";
                              rev = "v${final.version}";
                              hash = "sha256-vrhtdrvrcC3dQoJM6hWq6wrGJLSiVww/CNPlL1N5kQ8=";
                            };
                            vendorHash = "sha256-+BfxCyg0KkDQpHt/wycy/8CTG6YBA/VJvJFhhzUnSiQ=";
                          }
                        )
                      );
                      VENCORD_REMOTE = "Vendicated/Vencord";
                      VENCORD_HASH = self.shortRev or self.dirtyShortRev or "unknown";
                    };

                    buildPhase = ''
                      runHook preBuild

                      unset SOURCE_DATE_EPOCH
                      pnpm run ${if buildWebExtension then "buildWeb" else "build"} \
                        -- --standalone --disable-updater

                      runHook postBuild
                    '';

                    installPhase = ''
                      runHook preInstall

                      cp -r dist/${lib.optionalString buildWebExtension "chromium-unpacked/"} $out

                      runHook postInstall
                    '';
                  }))
                {
                  buildWebExtension = false;
                  userplugins = [ ];
                };

            default = vencord;
          });

      devShells =
        forAllSystems
          (system:
            let
              pkgs = pkgsFor system;
            in
            {
              default = pkgs.mkShell {
                packages = with pkgs; [
                  nodejs
                  pnpm_10
                ];
              };
            });
    };
}
