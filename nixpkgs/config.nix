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
        brotli
        arp-scan-rs

        yt-dlp
        protols
        python3Packages.yt-dlp-ejs

        swi-prolog

        pipenv
        pyenv
        uv
        pyright

        rust-analyzer
        wasm-pack
        wasm-bindgen-cli
        cargo-edit
        cargo-insta
        cargo-generate
        cargo-cross

        nodejs_25
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
