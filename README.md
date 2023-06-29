# Improved file search in repositories (Git/Mercurial)


This is a customization for my personal use.\
Please refer to the original version: https://github.com/brentyi/vim-repo-file-search

Adding git/hg repository roots to `&path` when we open version-controlled files.
Make `gf`, `sfind`, `find`, etc in vim actually work for various relative paths (particularly those in #include statements).


Also set some variables in the buffer scope:
- `b:repo_file_search_root`: Root of the repository that the current file is in. Defaults to `.`.
- `b:repo_file_search_type`: `git`, `hg` or `none`. Identifies the current repository's type.
- `b:repo_file_search_display`: Human-readable path to current file, generated intelligently based on repository root & home directory.

Example application: we can ask `fzf` to emulate the behavior of `ctrlp`.
```
Plug 'hvng/vim-repo-file-search'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

function! s:smarter_fuzzy_file_search()
    execute "Files " . b:repo_file_search_root
endfunction
nnoremap <C-P> :call <SID>smarter_fuzzy_file_search()<CR>
```
