{
  allowUnfree = true;

  packageOverrides = nixpkgs: with nixpkgs; rec {
    xgetres = callPackage ./xgetres.nix {};
    tts = callPackage ./tts.nix {};
    nicolive-comments = callPackage ./nicolive-comments.nix {};
    google-youtube3-cli = callPackage ./google-youtube3-cli.nix {};
    libtree = callPackage ./libtree.nix {};
    nvim = callPackage ./nvim.nix {};
    loophole = callPackage ./loophole.nix {};

    all = nixpkgs.buildEnv {
      name = "all";
      paths = with nixpkgs; [
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
        #xsel
        ripgrep
        fd
        eza
        gron
        translate-shell
        #powertop
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
        mysql57
        #light
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
        msgpack-tools
        tts
        nicolive-comments
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
        loophole
        stderred
        cue
        difftastic
        wslu

        #rustup
        rust-analyzer
        wasm-pack
        wasm-bindgen-cli
        cargo-edit
        cargo-insta
        cargo-generate
        cargo-cross

        opam

        nodejs
        nodePackages.prettier
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.pnpm

        # bs-platform

        go_1_21
        gopls
        gotools
        gore
        errcheck
      ];
    };
  };
}
