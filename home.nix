{ config, pkgs, claude-desktop, system, ... }:

let
  uvxTool = name: uvxArgs: pkgs.writeShellScriptBin name ''
    exec ${pkgs.uv}/bin/uvx ${uvxArgs} "$@"
  '';

  aider = uvxTool "aider" "aider-chat";
  runprompt = uvxTool "runprompt" "runprompt";
  posting = uvxTool "posting" "posting";
  vibe = uvxTool "vibe" "--from mistral-vibe vibe";
  vibe-acp = uvxTool "vibe-acp" "--from mistral-vibe vibe-acp";

  gogcli = pkgs.stdenv.mkDerivation rec {
    pname = "gogcli";
    version = "0.11.0";
    src = pkgs.fetchurl {
      url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_linux_amd64.tar.gz";
      sha256 = "114w12sfvrwkwg2hnyybrnbipbh0rbykby3vzq9kgkcww9bbm66a";
    };
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 gog $out/bin/gog
    '';
  };
in
{
  home.username = "rafa";
  home.homeDirectory = "/var/home/rafa";

  home.stateVersion = "25.11";

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Shell and prompt
    starship
    zoxide

    # Terminal multiplexer and file manager
    zellij
    yazi

    # Development tools
    gh          # GitHub CLI
    go
    nodejs
    uv          # Python package manager
    opencode    # AI coding agent

    # Media and file utilities
    yt-dlp
    rclone
    ffmpeg
    imagemagick
    poppler-utils
    p7zip

    # Search and navigation
    ripgrep
    fd
    silver-searcher  # ag

    # General utilities
    jq
    gum
    cheat
    wl-clipboard
    claude-code
    claude-desktop.packages.${system}.claude-desktop-with-fhs
    aider
    runprompt
    posting
    vibe
    vibe-acp
    gogcli
    bat
    btop
    delta
    eza

    # Build tools
    cmake
    clang
    gnumake
    pkg-config
  ];

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-lastplace
      vim-fugitive
      vim-commentary
      ctrlp-vim
      fzf-vim
    ];
    settings = {
      number = true;
    };
    extraConfig = ''
      set nocompatible
      set encoding=utf-8
      set backspace=indent,eol,start
      set hlsearch incsearch
      set ignorecase smartcase
    '';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
  };
}
