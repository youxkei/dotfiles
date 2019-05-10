{
  allowUnfree = true;
  packageOverrides = pkgs: with pkgs; rec {
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
        ripgrep
        fd
        exa
        gron
        translate-shell
        powertop
        protobuf
        fzf

        erlangR21
        rustup
        ldc
        opam

        go
        dep
        go-protobuf

        nodejs-10_x
        nodePackages.ocaml-language-server
      ];
    };
  };
}
