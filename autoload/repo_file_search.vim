" Check if our current path lives in an hg/git repository
function! repo_file_search#check_for_repo()
    let b:repo_file_search_root = get(g:, 'repo_file_search_root', '')
    let b:repo_file_search_type = get(g:, 'repo_file_search_type', 'none')

    " Mercurial
    if len(b:repo_file_search_root) == 0
        call s:run_and_add_to_path('hg', 'hg root')
    endif

    " Git
    if len(b:repo_file_search_root) == 0
        call s:run_and_add_to_path('git', 'git rev-parse --show-toplevel')
    endif

    " Default
    if len(b:repo_file_search_root) == 0
        let b:repo_file_search_root = '.'
    endif

    " Update statusline variable
    call s:update_display()
endfunction

" Asynchronously call the provided command, and then update:
" - &path
" - b:repo_file_search_root
" - b:repo_file_search_type
" - b:repo_file_search_display
function! s:run_and_add_to_path(type, command)
    " Funcrefs must be capitalized
    let l:Callback = function('s:repo_root_callback', [a:type])
    if exists('*job_start')
        " Vim 8
        call job_start(a:command, {'out_cb': l:Callback})
    elseif exists('*jobstart')
        " Neovim
        " Explicitly pass in the cwd when the path is valid  (e.g. not fugitive://...)
        " This is seemingly not necessary for Vim 8
        if isdirectory(expand('%:p:h'))
            call jobstart(a:command, {'on_stdout': l:Callback, 'cwd': expand('%:p:h')})
        else
            call jobstart(a:command, {'on_stdout': l:Callback})
        endif
    else
        " Synchronous fallback
        let l:result = system(a:command)
        if v:shell_error != 0
            " Command failed!
            return
        endif
        call s:repo_root_callback(a:type, 'unused', l:result)
    endif
endfunction

" 'Repo locate' shell command callback: adds outputs to &path if they're valid
" and unique
function s:repo_root_callback(type, ...) abort
    " First, we do some hacky stuff to pull data from stdout
    "
    " If called from job_start (Vim 8), the arguments will look like:
    "   (channel, data)
    " If called from jobstart (Neovim), the arguments will look like:
    "   (job_id, data, event)
    " ...in either case, the data we care about is the second (optional) argument
    let l:message = get(a:, 2)

    " jobstart returns the output as a list of lines; we only care about the
    " first one
    " (job_start returns a string directly)
    if type(l:message) == type([])
        let l:message = l:message[0]
    endif

    " Run command & strip out control sequences (\r, \n, etc)
    let l:repo_path=substitute(l:message, '[[:cntrl:]]', '', 'g')

    " Exit if output is not a valid path
    if l:repo_path !~? '^/\([A-z0-9-_+./]\)\+$'
        return
    endif

    " Set buffer repo root path
    let b:repo_file_search_root = l:repo_path
    let b:repo_file_search_type = a:type

    " Update path if new
    if &path !~ ',' . l:repo_path . '\(/\*\*9\)'
        let &path .= ',' . l:repo_path . '/**9'
    endif

    " Update statusline variable
    call s:update_display()
endfunction

" Helper for generating a human-readable 'path to current file' value, and
" assigning b:repo_file_search_display to it
function! s:update_display()
    " Get a full path to the current file
    let l:full_path = expand('%:p')

    " Chop off the filename
    let l:full_path = l:full_path[:-len(expand('%:t')) - 2]

    " Generate path to our file relative to our repository root
    let l:repo_path = l:full_path
    let l:repo_root = get(b:, 'repo_file_search_root')
    if len(l:repo_root) > 0
        " Generate a path relative to our repository root's parent
        let l:repo_head = fnamemodify(fnamemodify(l:repo_root, ':h'), ':h')
        if l:full_path[:len(l:repo_head)-1] ==# l:repo_head
            let l:repo_path = '.../' . l:full_path[len(l:repo_head) + 1:]
        endif
    endif

    " Generate a path relative to our home directory
    let l:home_path = l:full_path
    if l:full_path[:len($HOME)-1] ==# $HOME
        let l:home_path = '~' . l:full_path[len($HOME):]
    endif

    " Return shorter option
    if len(l:repo_path) < len(l:home_path)
        let b:repo_file_search_display = l:repo_path
    else
        let b:repo_file_search_display = l:home_path
    endif
endfunction
