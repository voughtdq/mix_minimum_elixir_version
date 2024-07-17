{
  description = "mix_minimum_elixir_version flake";
  
  inputs = {
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    next-ls.url = "github:elixir-tools/next-ls";
  };

  outputs = { self, nixpkgs, flake-utils, next-ls, nix-vscode-extensions }:
   flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      erlangVersion = "erlang_26";
      elixirVersion = "elixir_1_17";

      erlang = pkgs.beam.interpreters.${erlangVersion};
      elixir = (pkgs.beam.packagesWith erlang).${elixirVersion};

      next-ls-packages = next-ls.packages.${system}.default;
      vscodeExt = nix-vscode-extensions.extensions.${system};
      marketplace = vscodeExt.vscode-marketplace;
      inherit (pkgs) vscode-with-extensions vscodium;

      packages.editor = let
        inherit (pkgs) vscode-with-extensions vscodium;
      in 
        vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = [
            marketplace.jnoortheen.nix-ide
            marketplace.elixir-tools.elixir-tools
            marketplace.sztheory.hex-lens
            marketplace.stkb.rewrap
            marketplace.adamzapasnik.elixir-test-explorer
            marketplace.saratravi.elixir-formatter
            marketplace.hbenl.vscode-test-explorer
            marketplace.ms-vscode.test-adapter-converter
            marketplace.pantajoe.vscode-elixir-credo
          ];
      };
      
      inherit (pkgs) lib stdenv mkShell gnused;
      inherit next-ls;
    in
    {
      inherit packages;
      devShells.default = mkShell {
        buildInputs = [
          erlang
          elixir
          gnused
          next-ls-packages  
        ]
        ++ lib.lists.optionals stdenv.isLinux (
          builtins.attrValues {
            inherit (pkgs) libnotify inotify-tools;
        })
        ++ lib.lists.optionals stdenv.isDarwin (
          builtins.attrValues { 
            inherit (pkgs) terminal-notifier; 
            inherit (pkgs.darwin.apple_sdk.frameworks) CoreFoundation CoreServices; 
        });

        shellHook = ''
        # allows mix to work on the local directory
        mkdir -p .nix-mix
        mkdir -p .nix-hex
        export MIX_HOME=$PWD/.nix-mix
        export HEX_HOME=$PWD/.nix-hex
        export ERL_LIBS=$HEX_HOME/lib/erlang/lib

        # concats PATH
        export PATH=$MIX_HOME/bin:$PATH
        export PATH=$MIX_HOME/escripts:$PATH
        export PATH=$HEX_HOME/bin:$PATH

        # enables history for IEx
        export ERL_AFLAGS="-kernel shell_history enabled -kernel shell_history_path '\"$PWD/.erlang-history\"'"
      '';
      };
    }
   );
}
