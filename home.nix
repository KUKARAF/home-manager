{ config, pkgs, ... }:

{
  home.username = "rafa";
  home.homeDirectory = "/var/home/rafa";

  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # Shell and prompt
    starship
    zoxide
    fzf

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
    cheat
    vim
    wl-clipboard
    claude-code

    # Build tools
    cmake
    clang
    gnumake
    pkg-config
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
