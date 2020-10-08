{
  allowUnfree = true;

  permittedInsecurePackages = [
    "openssl-1.0.2u"
  ];

  packageOverrides = nixpkgs: let
    allPackages = nixpkgs // packages;
    callPackage = nixpkgs.lib.callPackageWith allPackages;

    packages = rec {
      gore = callPackage ./gore.nix {};
      mockgen = callPackage ./mockgen.nix {};
      wire = callPackage ./wire.nix {};
      errcheck = callPackage ./errcheck.nix {};
      syntaxerl = callPackage ./syntaxerl.nix {};
      countdown = callPackage ./countdown.nix {};
      evans = callPackage ./evans.nix {};
      teip = callPackage ./teip.nix {};
      askgit = callPackage ./askgit.nix {};
      bottom = callPackage ./bottom.nix {};
      xcp = callPackage ./xcp.nix {};

      erlang = nixpkgs.erlangR18;
      rebar3 = (nixpkgs.rebar3.override { erlang = erlang; });

      nodejs = nixpkgs.nodejs-14_x;
      prettier = (nixpkgs.nodePackages.override { nodejs = nodejs; }).prettier;

      statik = nixpkgs.statik.overrideAttrs (oldAttrs: rec {
        version = "0.1.7";
        src = nixpkgs.fetchFromGitHub rec {
          owner = "rakyll";
          repo = "statik";
          rev = "v${version}";
          sha256 = "0y0kbzma55vmyqhyrw9ssgvxn6nw7d0zg72a7nz8vp1zly4hs6va";
        };
      });

      all = nixpkgs.buildEnv {
        name = "all";
        paths = with nixpkgs; [
          i3-gaps
          i3status
          i3status-rust
          wmfocus
          rofi
          feh
          glibcLocales

          gitAndTools.gitFull
          gitAndTools.hub
          gitAndTools.tig
          gitAndTools.diff-so-fancy
          gitAndTools.gh
          askgit

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
          grpcurl
          pup
          youtube-dl
          zenith
          tmux
          protobuf
          qpdf
          stress-ng
          speedtest-cli
          light
          mysql80
          countdown
          hugo
          evans
          inotify-tools
          starship
          tree-sitter
          redis
          bandwhich
          ytop
          dust
          tealdeer
          zoxide
          watchexec
          bottom
          parallel
          xcp
          docker-compose
          diskonaut

          erlang
          rebar3
          syntaxerl

          rustup
          wasm-pack
          cargo-edit
          cargo-insta

          opam

          nodejs
          prettier

          bs-platform

          go
          gopls
          goimports
          gore
          errcheck
          go-protobuf
          mockgen
          wire
          statik

          ldc
        ];
      };
    };
  in packages;
}
