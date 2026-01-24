{
  allowUnfree = true;

  packageOverrides = nixpkgs: with nixpkgs; rec {
    libtree = callPackage ./libtree.nix {};
    nvim = callPackage ./nvim.nix {};

    all = nixpkgs.buildEnv {
      name = "all";
      paths = with nixpkgs; [
        gitFull
        tig
        gh

        nix-prefetch-git

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
        #parallel
        xcp
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
        #msgpack-tools
        rpg-cli
        duf
        mcfly
        choose
        glances
        gping
        doggo
        lua-language-server
        libtree
        imagemagick
        nvim
        nix-tree
        glow
        ouch
        stderred
        cue
        difftastic
        wslu
        sheldon
        colorized-logs
        podman-compose
        graphviz
        yt-dlp
        protols

        swi-prolog

        pipenv
        pyenv
        uv

        #rustup
        rust-analyzer
        wasm-pack
        wasm-bindgen-cli
        cargo-edit
        cargo-insta
        cargo-generate
        cargo-cross

        nodejs
        nodePackages.prettier
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.pnpm
        deno

        go
        gopls
        gotools
        gore
        errcheck
      ];
    };
  };
}
