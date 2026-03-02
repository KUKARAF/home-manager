{ config, pkgs, lib, claude-desktop, system, ... }:

let
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

  # Persistent Python CLI tools via `uv tool install`
  # Binaries land in ~/.local/bin, virtualenvs in ~/.local/share/uv/tools/
  home.activation.uvTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.uv}/bin:${pkgs.git}/bin:$PATH"
    run uv tool install aider-chat
    run uv tool install --with requests "runprompt @ git+https://github.com/chr15m/runprompt"
    run uv tool install posting
    run uv tool install mistral-vibe
    run uv tool install "today[cli] @ git+https://github.com/KUKARAF/diary.git"
    run uv tool install "todo @ git+https://github.com/KUKARAF/todo.git"
    run uv tool install "pomodoro @ git+https://github.com/KUKARAF/pomodoro.git"
  '';

  # Ensure ~/.local/bin is on PATH for uv tool binaries
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
    settings = {
      number = true;
    };
    extraConfig = ''
      syntax on
      set nocompatible
      filetype plugin on
      let $PATH = $HOME . '/.local/share/mise/shims:' . $PATH

      let g:vimwiki_list = [{'path': '~/vimwiki/',
                            \ 'syntax': 'markdown', 'ext': 'md'}]

      if !executable('vibe')
          echohl WarningMsg
          echo "Warning: 'vibe' command not found. The :Vibe command will not work."
          echohl None
      endif

      " Create autocmd group for terminal handling
      augroup terminal_handling
          autocmd!
      augroup END

      if executable('ag')
        let g:ackprg = 'ag --vimgrep'
        nnoremap <leader>a :Ag<CR>
      endif
      set number
      nnoremap <esc> :noh<return><esc>
      nnoremap <esc>^[ <esc>^[
      nmap <leader>E :exec 'r!'.getline('.')<CR>

      set rtp+=~/.fzf
      nnoremap <silent> <Leader>b :call fzf#run(fzf#wrap({'source': map(range(1, bufnr('$')), 'bufname(v:val)'), 'sink': 'buffer'}))<CR>
      let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -g ""'
      nnoremap <silent> <leader>t :Files<CR>
      nnoremap <leader>h :bprevious<CR>
      nnoremap <leader>l :bnext<CR>
      nnoremap <leader>r :e!<CR>
      nnoremap <leader><leader> :e!<CR>

      function! VibeCommand(...)
          " Run the 'vibe' command without additional flags
          let cmd = 'vibe'
          let buf = term_start(cmd, {'term_rows': &lines, 'term_cols': &columns, 'vertical': 0, 'exit_cb': {->execute(['bd!', 'bufdo e!'])}})
          " Switch to terminal mode
          startinsert
      endfunction

      function! ExecuteVisualSelection()
          " Get the visually selected text
          let [line_start, column_start] = getpos("'<")[1:2]
          let [line_end, column_end] = getpos("'>")[1:2]
          let lines = getline(line_start, line_end)
          if len(lines) == 0
              return
          endif
          " Handle partial line selections
          let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
          let lines[0] = lines[0][column_start - 1:]
          let selected_text = join(lines, "\n")

          " Expand % to current file path
          let expanded_text = substitute(selected_text, '%', expand('%'), 'g')

          " Execute the command and get output
          let output = system(expanded_text)
          " Remove trailing newline if present
          let output = substitute(output, '\n$', ''', ''')

          " Replace the selected text with the output
          execute line_start . ',' . line_end . 'delete'
          call append(line_start - 1, split(output, "\n"))
      endfunction

      function! ExecutePythonSelection()
          " Get the visually selected text
          let [line_start, column_start] = getpos("'<")[1:2]
          let [line_end, column_end] = getpos("'>")[1:2]
          let lines = getline(line_start, line_end)
          if len(lines) == 0
              return
          endif
          " Handle partial line selections
          let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
          let lines[0] = lines[0][column_start - 1:]
          let selected_text = join(lines, "\n")

          " Execute the Python code and get output
          let output = system('python3 -c ' . shellescape(selected_text))
          " Remove trailing newline if present
          let output = substitute(output, '\n$', ''', ''')

          " Append the output after the selected text
          call append(line_end, split(output, "\n"))
      endfunction

      command! -nargs=? Vibe call VibeCommand(<f-args>)

      " Visual mode mappings
      vnoremap <leader>e :<C-u>call ExecuteVisualSelection()<CR>
      vnoremap <leader>p :<C-u>call ExecutePythonSelection()<CR>
      nnoremap <silent> <C-v> :vsplit \| :Yazi<cr>
      const g:yazi_exec_on_open = 'tabnew'
      nnoremap <silent> - :Yazi<cr>
      nnoremap <silent> _ :YaziWorkingDirectory<cr>

      set encoding=utf-8
      set backspace=indent,eol,start
      set hlsearch incsearch
      set ignorecase smartcase
      set autoread
      au CursorHold * checktime

      " Bracketed paste support (needed for Rio terminal)
      let &t_BE = "\e[?2004h"
      let &t_BD = "\e[?2004l"
      let &t_PS = "\e[200~"
      let &t_PE = "\e[201~"
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
