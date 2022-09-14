{
  allowUnfree = true;

  packageOverrides = nixpkgs: let
    allPackages = nixpkgs // packages;
    callPackage = nixpkgs.lib.callPackageWith allPackages;

    packages = rec {
      xgetres = callPackage ./xgetres.nix {};
      tts = callPackage ./tts.nix {};
      nicolive-comments = callPackage ./nicolive-comments.nix {};
      google-youtube3-cli = callPackage ./google-youtube3-cli.nix {};
      libtree = callPackage ./libtree.nix {};
      nvim = callPackage ./nvim.nix {};

      inherit (nixpkgs.nodePackages) prettier typescript typescript-language-server;

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
          git-branchless

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
          glow
          ouch

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

          go_1_18
          gopls
          gotools
          gore
          errcheck
        ];
      };
    };
  in packages;
}
