{
  allowUnfree = true;
  packageOverrides = pkgs: with pkgs; {
    all = buildEnv {
      name = "all";
      paths = [
        i3
        i3status
        rofi
        feh
        compton-git

        gitAndTools.gitFull
        gitAndTools.hub
        gitAndTools.tig
        gitAndTools.diff-so-fancy
        rlwrap
        trash-cli
        neovim
        tokei
        xsel
        skim
        ripgrep
        fd
        exa
        gron
        translate-shell
        powertop

        erlangR21
        rustup
      ];
    };
  };
}
