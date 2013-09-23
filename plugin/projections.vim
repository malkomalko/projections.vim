" projections.vim - Projections based off rails.vim
" Author: Tim Pope <http://tpo.pe/> & Robert Malko

if exists('g:loaded_projections') || &cp || v:version < 700
  finish
endif
let g:loaded_projections = 1

function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction

function! s:autoload(...)
  if !exists("g:autoloaded_projections") && v:version >= 700
    runtime! autoload/projections.vim
  endif
  if exists("g:autoloaded_projections")
    if a:0
      exe a:1
    endif
    return 1
  endif
  if !exists("g:projections_no_autoload_warning")
    let g:projections_no_autoload_warning = 1
    if v:version >= 700
      call s:error("Disabling projections.vim: autoload/projections.vim is missing")
    else
      call s:error("Disabling projections.vim: Vim version 7 or higher required")
    endif
  endif
  return ""
endfunction

function! s:Detect(filename)
  if exists('g:projections_root')
    return s:BufInit(g:projections_root)
  endif
  return s:BufInit(resolve(a:filename))
endfunction

function! s:BufInit(path)
  if s:autoload()
    return ProjectionsBufInit(a:path)
  endif
endfunction

function! s:Update(path)
  return ProjectionsBufUpdate(a:path)
endfunction

augroup projectionsPluginDetect
  autocmd!
  autocmd VimEnter * if !exists("g:projections_root") | call s:Detect(getcwd()) | endif
  autocmd BufWritePost projections.json if exists("g:projections_root") | call s:Update(g:projections_root) | endif
augroup END
