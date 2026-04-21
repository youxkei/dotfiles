{
  description = "youxkei's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    gws.url = "github:googleworkspace/cli";
  };

  outputs = { self, nixpkgs, gws }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      libtree = pkgs.callPackage ./nixpkgs/libtree.nix {};
      nvim = pkgs.callPackage ./nixpkgs/nvim.nix {};
      tree = pkgs.callPackage ./nixpkgs/tree.nix {};
    in
    {
      packages.${system}.default = pkgs.buildEnv {
        name = "all";
        paths = with pkgs; [
          # git
          gitFull
          tig
          gh
          git-lfs

          # nix
          nix-prefetch-git
          nix-tree

          # cli tools
          rlwrap
          trash-cli
          tokei
          ripgrep
          fd
          eza
          gron
          translate-shell
          figlet
          fzf
          jq
          yq-go
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
          tmux
          protobuf
          qpdf
          stress-ng
          speedtest-cli
          inotify-tools
          starship
          tree-sitter
          redis
          bandwhich
          zoxide
          watchexec
          bottom
          xcp
          traceroute
          tcptraceroute
          netcat
          shellcheck
          multitail
          pv
          valgrind
          pueue
          dust
          duf
          mcfly
          choose
          glances
          gping
          doggo
          imagemagick
          glow
          ouch
          stderred
          cue
          difftastic
          sheldon
          colorized-logs
          podman-compose
          graphviz
          brotli
          arp-scan-rs
          wl-clipboard
          libtree
          tree
          gws.packages.${system}.default

          # editor
          nvim
          lua-language-server

          # media
          yt-dlp
          python3Packages.yt-dlp-ejs

          # protobuf
          protols

          # prolog
          swi-prolog

          # python
          pipenv
          pyenv
          uv
          pyright

          # rust
          rust-analyzer
          wasm-pack
          wasm-bindgen-cli
          cargo-edit
          cargo-insta
          cargo-generate
          cargo-cross

          # javascript / typescript
          nodejs_25
          prettier
          typescript
          typescript-language-server
          pnpm
          deno
          bun
          fnm

          # go
          go_1_25
          gopls
          (gotools.overrideAttrs (old: {
            # gopls also ships bin/modernize, so drop gotools' copy to avoid buildEnv collision.
            postFixup = (old.postFixup or "") + ''
              rm -f $out/bin/modernize
            '';
          }))
          gore
          errcheck

          # java
          jdk25_headless
        ];
      };
    };
}
