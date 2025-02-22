{
  description = "Flake for Vencord (Custom)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    # flake-compat = {
    #   url = "github:edolstra/flake-compat";
    #   flake = false;
    # };
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

            default =
              # taken from nixpkgs vencord package and modified by me
              ({ buildWebExtension }: stdenv.mkDerivation
                (finalAttrs: {
                  pname = "vencord";
                  version = "1.11.5";

                  src = ./.;

                  pnpmDeps = pnpm_10.fetchDeps {
                    inherit (finalAttrs) pname src;

                    hash = "sha256-g9BSVUKpn74D9eIDj/lS1Y6w/+AnhCw++st4s4REn+A=";
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
                          version = "0.25.0";
                          src = fetchFromGitHub {
                            owner = "evanw";
                            repo = "esbuild";
                            rev = "v${final.version}";
                            hash = "sha256-L9jm94Epb22hYsU3hoq1lZXb5aFVD4FC4x2qNt0DljA=";
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
                { buildWebExtension = false; };

            vencord = default;
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
