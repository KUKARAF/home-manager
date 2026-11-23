# Shared by every profile (rafa = full desktop setup, user = the sandboxed Open Terminal).
# Anything heavy, personal or credential-bearing belongs in home.nix, not here.
{ config, pkgs, lib, ... }:

let
  sources = pkgs.callPackage ./_sources/generated.nix {};

  kv-cli = pkgs.stdenv.mkDerivation {
    inherit (sources.kv-cli) pname version src;
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 kv $out/bin/kv
    '';
  };

  # Prebuilt glibc binary from github.com/can1357/oh-my-pi releases (the flake builds the
  # whole Rust + Bun tree from source: ~2500 derivations). Tracked by nvfetcher.
  omp = pkgs.stdenv.mkDerivation {
    inherit (sources.omp) pname version src;
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/omp
    '';
  };
in
{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # Shell and prompt
    starship
    zoxide

    # Development tools
    gh
    nodejs
    bun
    uv
    claude-code
    kv-cli
    omp            # oh-my-pi coding agent (prebuilt release binary)

    # Search and file utilities
    ripgrep
    fd
    jq
    bat
    eza
    delta

    # Python tools for vim plugins
    python3Packages.jedi
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-lastplace
      vim-fugitive
      vim-commentary
      ctrlp-vim
      fzf-vim
      vimwiki
      ack-vim
      jedi-vim
    ];
    settings = {
      number = true;
    };
    extraConfig = ''
      if filereadable(expand('~/.vimrc'))
        source ~/.vimrc
      endif
    '';
  };

  programs.home-manager.enable = true;

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
    fileWidget.command = "fd --type f --hidden --follow --exclude .git";
    changeDirWidget.command = "fd --type d --hidden --follow --exclude .git";
  };
}
