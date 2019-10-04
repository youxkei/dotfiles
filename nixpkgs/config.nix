{
  allowUnfree = true;
  packageOverrides = super: with super; {
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

        erlangR21
        rustup
        opam

        go
        dep

        ldc
      ];
    };
  };
}
