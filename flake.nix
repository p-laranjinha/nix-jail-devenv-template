{
  description = "Development environment.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";
  };

  outputs =
    { nixpkgs, jail-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.replaceStdenv = { pkgs, ... }: pkgs.stdenv;
      };
      inherit (pkgs) lib;
      jail = jail-nix.lib.init pkgs;

      # See all combinators at https://alexdav.id/projects/jail-nix/combinators
      commonCombinators = with jail.combinators; [
        mount-cwd
      ];

      jailCommon =
        jailFunc: packages:
        lib.flatten (
          builtins.map (
            p:
            if (lib.isDerivation p) then
              # If just a package
              (jailFunc p commonCombinators)
            else
              # If a list containing a package and a list of combinators
              (jailFunc p.package (commonCombinators ++ p.combinators))
          ) packages
        );
      jailPackages = jailCommon (
        package: combinators: (jail (builtins.baseNameOf (lib.getExe package)) package combinators)
      );
      jailPackageBinaries = jailCommon (
        package: combinators:
        (lib.mapAttrsToList (filename: _: jail filename "${package}/bin/${filename}" combinators) (
          builtins.readDir "${package}/bin"
        ))
      );
    in
    {
      devShells.${system} = {
        # Arguments set here that don't match anything relevant like 'shellHook' are instead set
        #  as environment variables.
        default = pkgs.mkShell {
          # https://discourse.nixos.org/t/difference-between-buildinputs-and-packages-in-mkshell/60598
          packages =
            with pkgs;
            [
              (writeScriptBin "nvim" ''
                #!${bash}/bin/bash
                # Get nvim in path after this script (so I use the same as system)
                NVIM=$(which -a nvim | sed -n '2 p')
                # Run nvim with regular bash
                PATH=${bash}/bin:$PATH $NVIM
              '')
            ]
            ++
              # To add a package with extra combinators use:
              #  { package = package; combinators = with jail.combinators; [ combinator ]; }
              (jailPackageBinaries [
                bash
              ]);

          # Libary dependencies used by the project.
          # WARN: Will probably have to be changed/removed to be used in jailed packages.
          LD_LIBRARY_PATH = "${lib.makeLibraryPath (
            with pkgs;
            [
            ]
          )}";

          shellHook = ''
            echo "Welcome to the development environment!"
          '';
        };
      };
    };
}
