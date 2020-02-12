{
  allowUnfree = true;
  packageOverrides = nixpkgs: let
    nix-npm-install = nixpkgs.writeScriptBin "nix-npm-install" ''
          #!/usr/bin/env bash
          tempdir="/tmp/nix-npm-install/$1"
          mkdir -p $tempdir
          pushd $tempdir
          # note the differences here:
          ${nixpkgs.nodePackages.node2nix}/bin/node2nix --nodejs-12 --input <( echo "[\"$1\"]")
          nix-env --install --file .
          popd
    '';

    allPackages = nixpkgs // packages;
    callPackage = nixpkgs.lib.callPackageWith allPackages;

    packages = rec {
      all = nixpkgs.buildEnv {
        name = "all";
        paths = with nixpkgs; [
          i3-gaps
          i3status
          rofi
          feh
          glibcLocales

          gitAndTools.gitFull
          gitAndTools.hub
          gitAndTools.tig
          gitAndTools.diff-so-fancy
          rlwrap
          trash-cli
          neovim
          tokei
          xsel
          ripgrep
          fd
          exa
          gron
          translate-shell
          powertop
          figlet
          fzf
          jq
          yq
          jo
          jid
          direnv
          httpie
          sysstat
          universal-ctags
          progress
          procs
          unar

          gcc

          erlangR18
          rebar3

          rustup

          opam

          nodejs
          nix-npm-install

          go
          dep

          ldc

          ruby
        ];
      };
    };
  in packages;
}
