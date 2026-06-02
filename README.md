# Vim Config

IDE like vim config inspired by SpaceVim.

# External Dependencies

* General
    * [The Silver Searcher](https://formulae.brew.sh/formula/the_silver_searcher)
    * [bat](https://formulae.brew.sh/formula/bat)
    * Node.js >= 14.14
    * [coc-highlight](https://github.com/neoclide/coc-highlight)
    * [Powerline fonts](https://github.com/powerline/fonts)
    * [vim-gtk](https://stackoverflow.com/questions/11489428/how-can-i-make-vim-paste-from-and-copy-to-the-systems-clipboard)
    * [opencode](https://formulae.brew.sh/formula/opencode)
    * [GCM](https://formulae.brew.sh/cask/git-credential-manager)
    * [lazygit](https://formulae.brew.sh/formula/lazygit)
    * [git-delta](https://dandavison.github.io/delta/get-started.html)
    * [zellij](https://formulae.brew.sh/formula/zellij)

* Python
    * [coc-pyright](https://github.com/fannheyward/coc-pyright)
    * [pyright](https://github.com/microsoft/pyright)
    * [PuDB](https://pypi.org/project/pudb/)

* Go
    * [coc-go](https://github.com/josa42/coc-go)

* TypeScript
    * [coc-tsserver](https://github.com/neoclide/coc-tsserver)

* YAML
    * [coc-yaml](https://github.com/neoclide/coc-yaml)

# Cheatsheet

* `Shift - f` - global search, use `'` to match exactly
* `\ - f` - file search
* `\ - a - g` - toggle grep clipboard with file type and result preview
* `\ - s` - split right
* use arrow keys to navigate between splits
* `z - z` - center around current line
* `g - x` - open link
* `\ - q` - close current buffer
* `\ - m` - toggle nerdtree
* `\ - o` - open CocOutline
* `\ - g - f` - go to current file on GitHub
* `\ - g - i - t` - open git client
* `\ - c - p` - copy to clipboard
* `\ - p` - copy current buffer's relative path to clipboard
* `g - d` - go to definition
* `g - r` - go to references
* `\ - r - n` - refactor rename
* `:noh` - remove highlight search
* `/ - /` - search visual selection
* `\ - r - a` - replace all searching keyword with
* `z - a` - toggle YAML fold
* `\ - d` - diff yank and clipboard
* `:MarkdownPreview` - preview markdown
