{ config, pkgs, lib, system, ... }:

let
  sources = pkgs.callPackage ./_sources/generated.nix {};

  debrid-collector = pkgs.stdenv.mkDerivation {
    inherit (sources.debrid-collector) pname version src;
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 debrid-collector $out/bin/debrid-collector
    '';
  };

  collie-server = pkgs.stdenv.mkDerivation {
    inherit (sources.collie-server) pname version src;
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 collie-server $out/bin/collie-server
    '';
  };

  sheets = pkgs.stdenv.mkDerivation {
    inherit (sources.sheets) pname version src;
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 sheets $out/bin/sheets
    '';
  };

  lazyjira = pkgs.stdenv.mkDerivation {
    inherit (sources.lazyjira) pname version src;
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 lazyjira $out/bin/lazyjira
    '';
  };

  pastel = pkgs.stdenv.mkDerivation {
    inherit (sources.pastel) pname version src;
    installPhase = ''
      install -Dm755 pastel $out/bin/pastel
    '';
  };

  officecli = pkgs.stdenv.mkDerivation rec {
    pname = "officecli";
    version = "1.0.113";
    src = pkgs.fetchurl {
      url = "https://github.com/iOfficeAI/OfficeCLI/releases/download/v${version}/officecli-linux-x64";
      sha256 = "sha256-/+CfX47HYkDkT/QxuAK4pEZnda/aMo8fe2BuOnmAcxE=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/officecli
    '';
  };

  # gogcli uses a v-prefixed tag (v0.12.0) but v-less filename (gogcli_0.12.0_linux_amd64.tar.gz).
  # nvfetcher 0.8.0 cannot strip the v prefix in any TOML-valid way; kept hardcoded.
  # To update: bump version + run `nix-prefetch-url <url>` then `nix hash convert --to sri`.
  gogcli = pkgs.stdenv.mkDerivation rec {
    pname = "gogcli";
    version = "0.12.0";
    src = pkgs.fetchurl {
      url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_linux_amd64.tar.gz";
      sha256 = "sha256-oD/MvWfqLlmialbpLeiRhXf0vr5LL5RoI0GXd4J82rI=";
    };
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 gog $out/bin/gog
    '';
  };
in
{
  imports = [ ./common.nix ];

  home.username = "rafa";
  home.homeDirectory = "/home/rafa";

  home.packages = with pkgs; [
    # Shell and prompt

    # Terminal multiplexer and file manager
    # zellij: installed by the devpod image from GitHub releases into /usr/bin.
    # It is a static musl binary, so the host copy also runs inside the toolbox
    # via /run/host/usr/bin -- nix cannot serve the host at all, since /nix
    # only exists inside the container.
    yazi

    # Development tools
    hut         # Sourcehut / sr.ht CLI
    jujutsu     # jj version control
    grafana-loki  # includes logcli for querying remote Loki instances
    google-cloud-sdk
    go
    opencode    # AI coding agent

    # Media and file utilities
    yt-dlp
    rclone
    ffmpeg
    imagemagick
    poppler-utils
    p7zip

    # Search and navigation
    silver-searcher-ng  # ag

    # General utilities
    gum
    cheat
    wl-clipboard
    snyk
    officecli
    gogcli
    debrid-collector
    collie-server
    sheets
    lazyjira
    pastel
    btop
    czkawka     # duplicate/junk file finder (provides czkawka_cli)

    # Build tools
    cmake
    clang
    gnumake
    pkg-config
    openssl
    protobuf

    # Python tools for vim plugins
  ];

  # Persistent Python CLI tools via `uv tool install`
  # Binaries land in ~/.local/bin, virtualenvs in ~/.local/share/uv/tools/
  home.activation.uvTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.uv}/bin:${pkgs.git}/bin:$PATH"
    run uv tool install aider-chat
    run uv tool install --with requests --with icalendar --with python-dateutil "runprompt @ git+https://github.com/KUKARAF/runprompt"
    run uv tool install posting
    run uv tool install "today[cli] @ git+https://github.com/KUKARAF/diary.git"
    run uv tool install "todo @ git+https://github.com/KUKARAF/todo.git"
    run uv tool install "pomodoro @ git+https://github.com/KUKARAF/pomodoro.git"
    run uv tool install --with hermes-agent[web] "hermes-agent @ git+https://github.com/KUKARAF/hermes-agent.git"
    run uv tool install browser-use
  '';

  # Extra vim plugins on top of common.nix.
  programs.vim.plugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "yazi-vim";
      version = "unstable";
      src = pkgs.fetchFromGitHub {
        owner = "chriszarate";
        repo = "yazi.vim";
        rev = "main";
        sha256 = "sha256-W5/BvJ8MrUgJV+ENMa3uU5Rbvj1bItR+Er+yMy4EjSc=";
      };
    })
    (pkgs.vimUtils.buildVimPlugin {
      pname = "diary-vim";
      version = "unstable";
      src = pkgs.fetchFromGitHub {
        owner = "KUKARAF";
        repo = "diary";
        rev = "main";
        sha256 = "sha256-hHojflBf7TgYmm33WUSA+tgO+vMpn5x/MH5OdTeJAWk=";
      };
    })
  ];

  programs.bash.shellAliases = {
    hms = "home-manager switch --flake /home/rafa/.config/home-manager#rafa";
  };

  # Ghostty terminal: config only. The binary comes from the Silverblue image
  # (devpod recipe), because a nix-built ghostty inside a toolbox cannot get an
  # EGL display -- nixpkgs libglvnd looks for the NixOS-only
  # /run/opengl-driver and falls back to the container's broken Mesa.
  programs.ghostty = {
    enable = true;
    package = null;
    enableBashIntegration = true;
    # Both of these need the nix package: vim syntax is pulled from
    # cfg.package.vim, and systemd.enable defaults to true on Linux. The image's
    # ghostty-vim subpackage already provides the vim syntax.
    installVimSyntax = false;
    systemd.enable = false;
  };
}
