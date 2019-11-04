{
  allowUnfree = true;
  packageOverrides = super: with super; rec {
    nix-npm-install = pkgs.writeScriptBin "nix-npm-install" ''
      #!/usr/bin/env bash
      tempdir="/tmp/nix-npm-install/$1"
      mkdir -p $tempdir
      pushd $tempdir
      # note the differences here:
      ${nodePackages.node2nix}/bin/node2nix --nodejs-12 --input <( echo "[\"$1\"]")
      nix-env --install --file .
      popd
    '';

    all = buildEnv {
      name = "all";
      paths = [
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
        unar
        httpie
        universal-ctags

        gcc

        erlangR18
        rustup
        opam

        nodejs
        nix-npm-install

        go
        dep

        ldc
      ];
    };
  };
}
