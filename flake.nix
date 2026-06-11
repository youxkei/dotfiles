{
  description = "youxkei's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    gws.url = "github:googleworkspace/cli";
  };

  outputs = { self, nixpkgs, gws }:
    let
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          libtree = pkgs.callPackage ./nixpkgs/libtree.nix {};
          tree = pkgs.callPackage ./nixpkgs/tree.nix {};
        in
        {
          default = pkgs.buildEnv {
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
              starship
              tree-sitter
              redis
              bandwhich
              zoxide
              watchexec
              bottom
              xcp
              tcptraceroute
              netcat
              shellcheck
              multitail
              pv
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
              cue
              difftastic
              sheldon
              colorized-logs
              podman-compose
              graphviz
              brotli
              gws.packages.${system}.default
              (google-cloud-sdk.withExtraComponents [
                google-cloud-sdk.components.kubectl
                google-cloud-sdk.components.gke-gcloud-auth-plugin
              ])

              # editor
              neovim-unwrapped
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
              rustup
              #rust-analyzer
              wasm-pack
              wasm-bindgen-cli
              cargo-edit
              cargo-insta
              cargo-generate
              cargo-cross

              # javascript / typescript
              nodejs_26
              prettier
              prettierd
              typescript
              typescript-language-server
              pnpm
              deno
              bun
              fnm

              # go
              go
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

              # lean
              elan
            ] ++ lib.optionals stdenv.isLinux [
              # Linux-only: kernel-specific APIs, Wayland, LD_PRELOAD, or
              # custom derivations that fetch Linux x86_64 binaries.
              sysstat
              inotify-tools
              valgrind
              traceroute
              arp-scan-rs
              stderred
              wl-clipboard
              libtree
              tree
            ];
          };
        });
    };
}
