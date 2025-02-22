# Vim Config

IDE like vim config inspired by SpaceVim.

# External Dependencies

* General
    * [The Silver Searcher](https://github.com/ggreer/the_silver_searcher)
    * [bat](https://github.com/sharkdp/bat)
    * [Universal Ctags](https://ctags.io/)
    * Node.js >= 14.14
    * [coc-highlight](https://github.com/neoclide/coc-highlight)
    * [Powerline fonts](https://github.com/powerline/fonts)
    * [vim-gtk](https://stackoverflow.com/questions/11489428/how-can-i-make-vim-paste-from-and-copy-to-the-systems-clipboard)

* Python
    * [coc-jedi](https://github.com/pappasam/coc-jedi)
    * [pyright](https://github.com/microsoft/pyright)
    * [PuDB](https://pypi.org/project/pudb/)

* Go
    * [coc-go](https://github.com/josa42/coc-go)

* TypeScript
    * [coc-tsserver](https://github.com/neoclide/coc-tsserver)

# Cheatsheet

* `Shift - f` - global search, use `'` to match exactly
* `\ - f` - file search
* `\ - a - g` - global search current word under cursor
* `\ - s` - split right
* use arrow keys to navigate between splits
* `z - z` - center around current line
* `g - x` - open link
* `\ - q` - close current buffer
* `\ - m` - toggle nerdtree and tagbar
* `\ - g - d` - git diff view
* `\ - tab` - next file in git diff view
* `\ - g - s` - git status
* `\ - g - b` - git branch
* `\ - g - f` - go to current file on GitHub
* `\ - c - p` - copy to clipboard
* `g - d` - go to definition
* `g - r` - go to references
* `\ - r - n` - refactor rename
* `:noh` - remove highlight search
* `/ - /` - search visual selection
* `\ - r - a` - replace all searching keyword with
* `z - a` - toggle YAML fold
* `\ - d` - diff yank and clipboard
* `:Gvdiffsplit!` - resolve conflicts
* `:MarkdownPreview` - preview markdown
