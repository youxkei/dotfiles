{
  allowUnfree = true;
  packageOverrides = super: with super; let
    modified-i3-gaps = i3-gaps.overrideAttrs (oldAttrs : rec {
      version = "4.16.1";
      releaseDate = "2019-01-28";

      src = fetchurl {
        url = "https://github.com/Airblader/i3/archive/${version}.tar.gz";
        sha256 = "1jvyd8p8dfsidfy2yy7adydynzvaf72lx67x71r13hrk8w77hp0k";
      };
    });
  in {
    all = buildEnv {
      name = "all";
      paths = [
        modified-i3-gaps
        i3status
        rofi
        feh
        compton-git
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

        erlangR21
        rustup
        opam

        go
        dep

        nodejs-10_x
        nodePackages.ocaml-language-server

        ldc
      ];
    };
  };
}
