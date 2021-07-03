{
  allowUnfree = true;

  packageOverrides = nixpkgs: let
    allPackages = nixpkgs // packages;
    callPackage = nixpkgs.lib.callPackageWith allPackages;

    nodePackages = callPackage ./node/default.nix {};

    packages = rec {
      gore = callPackage ./gore.nix {};
      mockgen = callPackage ./mockgen.nix {};
      wire = callPackage ./wire.nix {};
      errcheck = callPackage ./errcheck.nix {};
      syntaxerl = callPackage ./syntaxerl.nix {};
      countdown = callPackage ./countdown.nix {};
      evans = callPackage ./evans.nix {};
      teip = callPackage ./teip.nix {};
      xcp = callPackage ./xcp.nix {};
      protoc-gen-grpc-gateway = callPackage ./protoc-gen-grpc-gateway.nix {};
      pueue = callPackage ./pueue.nix {};
      dust = callPackage ./dust.nix {};
      xgetres = callPackage ./xgetres.nix {};
      tts = callPackage ./tts.nix {};
      nicolive-comments = callPackage ./nicolive-comments.nix {};

      typescript = nodePackages.typescript;
      typescript-language-server = nodePackages.typescript-language-server;

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
          rofi-unwrapped
          feh

          glibcLocales

          gitAndTools.gitFull
          gitAndTools.hub
          gitAndTools.tig
          gitAndTools.diff-so-fancy
          gitAndTools.gh
          gitAndTools.delta

          nix-prefetch-git

          rlwrap
          trash-cli
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
          mysql57
          countdown
          hugo
          evans
          inotify-tools
          starship
          tree-sitter
          redis
          bandwhich
          tealdeer
          zoxide
          watchexec
          bottom
          parallel
          xcp
          docker-compose
          diskonaut
          traceroute
          tcptraceroute
          netcat
          shellcheck
          multitail
          pv
          wasmtime
          valgrind
          pueue
          dust
          xgetres
          msgpack-tools
          tts
          nicolive-comments
          neovim-unwrapped
          yadm
          rpg-cli
          protontricks
          duf
          mcfly
          choose
          glances
          gping
          dogdns

          #rustup
          rust-analyzer
          wasm-pack
          wasm-bindgen-cli
          cargo-edit
          cargo-insta
          cargo-generate

          opam

          nodejs
          prettier

          typescript
          typescript-language-server

          # bs-platform

          go
          gopls
          goimports
          gore
          errcheck
          go-protobuf
          mockgen
          wire
          statik
          protoc-gen-grpc-gateway
        ];
      };
    };
  in packages;
}
