{
  allowUnfree = true;

  packageOverrides = nixpkgs: let
    allPackages = nixpkgs // packages;
    callPackage = nixpkgs.lib.callPackageWith allPackages;

    nodePackages = callPackage ./node/default.nix {};

    packages = rec {
      xgetres = callPackage ./xgetres.nix {};
      tts = callPackage ./tts.nix {};
      nicolive-comments = callPackage ./nicolive-comments.nix {};
      google-youtube3-cli = callPackage ./google-youtube3-cli.nix {};
      libtree = callPackage ./libtree.nix {};
      nvim = callPackage ./nvim.nix {};

      typescript = nodePackages.typescript;
      typescript-language-server = nodePackages.typescript-language-server;

      nodejs = nixpkgs.nodejs-14_x;
      prettier = (nixpkgs.nodePackages.override { nodejs = nodejs; }).prettier;

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
          du-dust
          xgetres
          msgpack-tools
          tts
          nicolive-comments
          #neovim-unwrapped
          yadm
          rpg-cli
          #protontricks
          duf
          mcfly
          choose
          glances
          gping
          dogdns
          neovim-remote
          sumneko-lua-language-server
          ocamlPackages.ocaml-lsp
          ocamlformat
          google-youtube3-cli
          libtree
          imagemagick
          nvim
          nix-tree

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

          go_1_17
          gopls
          goimports
          gore
          errcheck
          go-protobuf
          mockgen
          wire
          statik
        ];
      };
    };
  in packages;
}
