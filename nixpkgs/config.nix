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
        protobuf
        figlet
        fzf
        jq
        yq
        direnv

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
