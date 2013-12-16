" autoload/projections.vim
" Author: Tim Pope <http://tpo.pe/> & Robert Malko

if exists('g:autoloaded_projections') || &cp
  finish
endif
let g:autoloaded_projections = '1.0'

" Utility Functions {{{1

let s:app_prototype = {}

function! s:add_methods(namespace, method_names)
  for name in a:method_names
    let s:{a:namespace}_prototype[name] = s:function('s:'.a:namespace.'_'.name)
  endfor
endfunction

function! s:function(name)
  return function(substitute(a:name,'^s:',matchstr(expand('<sfile>'),
    \ '<SNR>\d\+_'),''))
endfunction

function! s:sub(str,pat,rep)
  return substitute(a:str,'\v\C'.a:pat,a:rep,'')
endfunction

function! s:gsub(str,pat,rep)
  return substitute(a:str,'\v\C'.a:pat,a:rep,'g')
endfunction

function! s:startswith(string,prefix)
  return strpart(a:string, 0, strlen(a:prefix)) ==# a:prefix
endfunction

function! s:endswith(string,suffix)
  return strpart(a:string, len(a:string) - len(a:suffix), len(a:suffix)) ==# a:suffix
endfunction

function! s:uniq(list) abort
  let i = 0
  let seen = {}
  while i < len(a:list)
    if (a:list[i] ==# '' && exists('empty')) || has_key(seen,a:list[i])
      call remove(a:list,i)
    elseif a:list[i] ==# ''
      let i += 1
      let empty = 1
    else
      let seen[a:list[i]] = 1
      let i += 1
    endif
  endwhile
  return a:list
endfunction

function! s:getlist(arg, key)
  let value = get(a:arg, a:key, [])
  return type(value) == type([]) ? copy(value) : [value]
endfunction

function! s:split(arg, ...)
  return type(a:arg) == type([]) ? copy(a:arg) : split(a:arg, a:0 ? a:1 : "\n")
endfunction

function! projections#lencmp(i1, i2) abort
  return len(a:i1) - len(a:i2)
endfunc

function! s:escarg(p)
  return s:gsub(a:p,'[ !%#]','\\&')
endfunction

function! s:fnameescape(file) abort
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

function! s:app_path(...) dict
  return join([self.root]+a:000,'/')
endfunction

function! s:app_has_path(path) dict
  return getftime(self.path(a:path)) != -1
endfunction

call s:add_methods('app', ['path','has_path'])

function! s:warn(str)
  echohl WarningMsg
  echomsg a:str
  echohl None
  let v:warningmsg = a:str
endfunction

function! s:error(str)
  echohl ErrorMsg
  echomsg a:str
  echohl None
  let v:errmsg = a:str
endfunction

" }}}1
" Public Interface {{{1

function! projections#underscore(str)
  let str = s:gsub(a:str,'::','/')
  let str = s:gsub(str,'(\u+)(\u\l)','\1_\2')
  let str = s:gsub(str,'(\l|\d)(\u)','\1_\2')
  let str = tolower(str)
  return str
endfunction

function! projections#camelize(str)
  let str = s:gsub(a:str,'/(.=)','::\u\1')
  let str = s:gsub(str,'%([_-]|<)(.)','\u\1')
  return str
endfunction

function! projections#singularize(word)
  let word = a:word
  if word =~? '\.js$' || word == ''
    return word
  endif
  let word = s:sub(word,'eople$','ersons')
  let word = s:sub(word,'%([Mm]ov|[aeio])@<!ies$','ys')
  let word = s:sub(word,'xe[ns]$','xs')
  let word = s:sub(word,'ves$','fs')
  let word = s:sub(word,'ss%(es)=$','sss')
  let word = s:sub(word,'s$','')
  let word = s:sub(word,'%([nrt]ch|tatus|lias)\zse$','')
  let word = s:sub(word,'%(nd|rt)\zsice$','ex')
  return word
endfunction

function! projections#pluralize(word)
  let word = a:word
  if word == ''
    return word
  endif
  let word = s:sub(word,'[aeio]@<!y$','ie')
  let word = s:sub(word,'%(nd|rt)@<=ex$','ice')
  let word = s:sub(word,'%([osxz]|[cs]h)$','&e')
  let word = s:sub(word,'f@<!f$','ve')
  let word .= 's'
  let word = s:sub(word,'ersons$','eople')
  return word
endfunction

function! projections#file_part(word)
  let word = a:word
  if word == ''
    return word
  endif
  return split(word,'/')[-1]
endfunction

function! projections#app(...)
  let root = a:0 ? a:1 : ProjRoot()
  return get(s:apps,root,0)
endfunction

function! ProjRoot()
  if exists("g:projections_root")
    return g:projections_root
  else
    return ""
  endif
endfunction

function! s:app_buffer_name() dict abort
  let f = s:gsub(resolve(fnamemodify(bufname('%'),':p')),'\\ @!','/')
  let f = s:sub(f,'/$','')
  let sep = matchstr(f,'^[^\\/]\{3,\}\zs[\\/]')
  if sep != ""
    let f = getcwd().sep.f
  endif
  if s:startswith(tolower(f),s:gsub(tolower(self.path()),'\\ @!','/')) || f == ""
    return strpart(f,strlen(self.path())+1)
  else
    if !exists("s:path_warn")
      let s:path_warn = 1
      call s:warn("File ".f." does not appear to be under your application root ".self.path().".")
    endif
    return f
  endif
endfunction

call s:add_methods('app',['buffer_name'])

" }}}1
" Navigation {{{1

function! s:BufNavCommands()
  command! -bar -nargs=* A  :call s:Alternate('<bang>',<f-args>)
  command! -bar -nargs=* AL :call s:AlternateLayout('L<bang>',<f-args>)
  command! -bar -nargs=* AS :call s:Alternate('S<bang>',<f-args>)
  command! -bar -nargs=* AT :call s:Alternate('T<bang>',<f-args>)
  command! -bar -nargs=* AV :call s:Alternate('V<bang>',<f-args>)
  command! -bar -nargs=* R  :call s:Related('<bang>' ,<f-args>)
  command! -bar -nargs=* RL :call s:RelatedLayout('E<bang>',<f-args>)
  command! -bar -nargs=* RS :call s:Related('S<bang>',<f-args>)
  command! -bar -nargs=* RT :call s:Related('T<bang>',<f-args>)
  command! -bar -nargs=* RV :call s:Related('V<bang>',<f-args>)
endfunction

function! s:djump(def)
  let def = s:sub(a:def,'^[#:]','')
  if def =~ '^\d\+$'
    exe def
  elseif def =~ '^!'
    if expand('%') !~ '://' && !isdirectory(expand('%:p:h'))
      call mkdir(expand('%:p:h'),'p')
    endif
  elseif def != ''
    let ext = matchstr(def,'\.\zs.*')
    let def = matchstr(def,'[^.]*')
    let v:errmsg = ''
    silent! exe "djump ".def
  endif
  return ''
endfunction

" }}}1
" Projection Commands {{{1

function! s:app_commands() dict abort
  let commands = {}

  let all = self.projections()
  for pattern in reverse(sort(keys(all), function('projections#lencmp')))
    let projection = all[pattern]
    for name in s:split(get(projection, 'command', get(projection, 'label', get(projection, 'name', get(projection, 'description', '')))))
      let command = {'pattern': pattern}
      if !has_key(commands, name)
        let commands[name] = []
      endif
      call extend(commands[name], [command])
    endfor
  endfor
  call filter(commands, '!empty(v:val)')
  return commands
endfunction

call s:add_methods('app', ['commands'])

function! s:BufProjectionCommands()
  for [name, command] in items(projections#app().commands())
    call s:define_navcommand(name, command)
  endfor
endfunction

function! s:completion_filter(results,A)
  let results = sort(type(a:results) == type("") ? split(a:results,"\n") : copy(a:results))
  call filter(results,'v:val !~# "\\~$"')
  let filtered = filter(copy(results),'s:startswith(v:val,a:A)')
  if !empty(filtered) | return filtered | endif
  let prefix = s:sub(a:A,'(.*[/]|^)','&_')
  let filtered = filter(copy(results),"s:startswith(v:val,prefix)")
  if !empty(filtered) | return filtered | endif
  let regex = s:gsub(a:A,'[^/]','[&].*')
  let filtered = filter(copy(results),'v:val =~# "^".regex')
  if !empty(filtered) | return filtered | endif
  let regex = s:gsub(a:A,'.','[&].*')
  let filtered = filter(copy(results),'v:val =~# regex')
  return filtered
endfunction

function! s:app_relglob(path,glob,...) dict
  if exists("+shellslash") && ! &shellslash
    let old_ss = &shellslash
    let &shellslash = 1
  endif
  let path = a:path
  if path !~ '^/' && path !~ '^\w:'
    let path = self.path(path)
  endif
  let suffix = a:0 ? a:1 : ''
  let full_paths = split(glob(path.a:glob.suffix),"\n")
  let relative_paths = []
  for entry in full_paths
    if suffix == '' && isdirectory(entry) && entry !~ '/$'
      let entry .= '/'
    endif
    let relative_paths += [entry[strlen(path) : -strlen(suffix)-1]]
  endfor
  if exists("old_ss")
    let &shellslash = old_ss
  endif
  return relative_paths
endfunction

call s:add_methods('app', ['relglob'])

function! s:define_navcommand(name, projection, ...) abort
  if empty(a:projection)
    return
  endif
  let name = s:gsub(a:name, '[[:punct:][:space:]]', '')
  if name !~# '^[a-z]\+$'
    return s:error("E182: Invalid command name ".name)
  endif
  for prefix in ['E', 'S', 'T', 'V']
    exe 'command! -bar -bang -nargs=* ' .
          \ '-complete=customlist,'.s:sid.'CommandList ' .
          \ prefix . name . ' :execute s:CommandEdit(' .
          \ string(prefix . "<bang>") . ',' .
          \ string(a:name) . ',' . string(a:projection) . ',<f-args>)' .
          \ (a:0 ? '|' . a:1 : '')
  endfor
endfunction

function! s:CommandList(A,L,P)
  let cmd = matchstr(a:L,'\C[A-Z]\w\+')
  exe cmd." &"
  let matches = []
  for projection in s:last_projections
    if projection.pattern !~# '\*' || !get(projection, 'complete', 1)
      continue
    endif
    let [prefix, suffix; _] = split(projection.pattern, '\*', 1)
    let results = projections#app().relglob(prefix, '**/*', suffix)
    if suffix =~# '\.rb$' && a:A =~# '^\u'
      let matches += map(results, 'projections#camelize(v:val)')
    else
      let matches += results
    endif
  endfor
  return s:completion_filter(matches, a:A)
endfunction

function! s:CommandEdit(cmd, name, projections, ...)
  if a:0 && a:1 == "&"
    let s:last_projections = a:projections
    return ''
  else
    return projections#app().open_command(a:cmd, a:0 ? a:1 : '', a:name, a:projections)
  endif
endfunction

" }}}1
" Alternate/Related {{{1

function! s:findcmdfor(cmd)
  let bang = ''
  if a:cmd =~ '\!$'
    let bang = '!'
    let cmd = s:sub(a:cmd,'\!$','')
  else
    let cmd = a:cmd
  endif
  if cmd == '' || cmd == 'E'
    return 'find'.bang
  elseif cmd == 'S'
    return 'sfind'.bang
  elseif cmd == 'V'
    return 'vert sfind'.bang
  elseif cmd == 'T'
    return 'tabfind'.bang
  else
    return cmd.bang
  endif
endfunction

function! s:editcmdfor(cmd)
  let cmd = s:findcmdfor(a:cmd)
  let cmd = s:sub(cmd,'<sfind>','split')
  let cmd = s:sub(cmd,'find>','edit')
  return cmd
endfunction

function! s:app_open_command(cmd, argument, name, projections) dict abort
  let cmd = s:editcmdfor(a:cmd)
  let djump = ''
  if a:argument =~ '[#!]\|:\d*\%(:in\)\=$'
    let djump = matchstr(a:argument,'!.*\|#\zs.*\|:\zs\d*\ze\%(:in\)\=$')
    let argument = s:sub(a:argument,'[#!].*|:\d*%(:in)=$','')
  else
    let argument = a:argument
  endif
  for projection in a:projections
    if argument ==# '.' && projection.pattern =~# '\*'
      let file = split(projection.pattern, '\*')[0]
    elseif projection.pattern =~# '\*'
      if !empty(argument)
        let root = argument
      else
        continue
      endif
      let file = s:sub(projection.pattern, '\*', root)
    elseif empty(argument) && projection.pattern !~# '\*'
      let file = projection.pattern
    else
      let file = ''
    endif
    if !empty(file) && self.has_path(file)
      let file = self.path(file)
      return cmd . ' ' . s:fnameescape(file) . '|exe ' . s:sid . 'djump('.string(djump) . ')'
    endif
  endfor
  if empty(argument)
    let defaults = filter(map(copy(a:projections), 'v:val.pattern'), 'v:val !~# "\\*"')
    if empty(defaults)
      return 'echoerr "E471: Argument required"'
    else
      return cmd . ' ' . s:fnameescape(defaults[0])
    endif
  endif
  if djump !~# '^!'
    return 'echoerr '.string('No such '.tr(a:name, '_', ' ').' '.root)
  endif
  for projection in a:projections
    if projection.pattern !~# '\*'
      continue
    endif
    let [prefix, suffix; _] = split(projection.pattern, '\*', 1)
    if self.has_path(prefix)
      let relative = prefix . (suffix =~# '\.rb$' ? projections#underscore(root) : root) . suffix
      let file = self.path(relative)
      let projected = self.template_for_pattern(projection.pattern,argument,'template')
      return self.create_template(file,projected,cmd)
    endif
  endfor
  return 'echoerr '.string("Couldn't find destination directory for ".a:name.' '.a:argument)
endfunction

function! s:app_create_template(file,projected,cmd)
  if type(a:projected) == 1
    return a:projected
  endif
  if !isdirectory(fnamemodify(a:file, ':h'))
    call mkdir(fnamemodify(a:file, ':h'), 'p')
  endif
  let template = s:split(get(a:projected, 0, ''))
  call map(template, 's:gsub(v:val, "\t", "  ")')
  return a:cmd . ' ' . s:fnameescape(simplify(a:file)) . '|call setline(1, '.string(template).')' . '|set nomod'
endfunction

call s:add_methods('app', ['open_command','create_template'])

function! s:findedit(cmd,files,...) abort
  let cmd = s:findcmdfor(a:cmd)
  let files = type(a:files) == type([]) ? copy(a:files) : split(a:files,"\n")
  if len(files) == 1
    let file = files[0]
  else
    let file = get(filter(copy(files),'projections#app().has_file(s:sub(v:val,"#.*|:\\d*$",""))'),0,get(files,0,''))
  endif
  if file =~ '[#!]\|:\d*\%(:in\)\=$'
    let djump = matchstr(file,'!.*\|#\zs.*\|:\zs\d*\ze\%(:in\)\=$')
    let file = s:sub(file,'[#!].*|:\d*%(:in)=$','')
  else
    let djump = ''
  endif
  if file == ''
    let testcmd = "edit"
  elseif projections#app().has_path(file.'/')
    let arg = file == "." ? projections#app().path() : projections#app().path(file)
    let testcmd = s:editcmdfor(cmd).' '.(a:0 ? a:1 . ' ' : '').s:escarg(arg)
    exe testcmd
    return ''
  elseif projections#app().path() =~ '://' || cmd =~ 'edit' || cmd =~ 'split'
    if file !~ '^/' && file !~ '^\w:' && file !~ '://'
      let file = s:escarg(projections#app().path(file))
    endif
    let testcmd = s:editcmdfor(cmd).' '.(a:0 ? a:1 . ' ' : '').file
  else
    let testcmd = cmd.' '.(a:0 ? a:1 . ' ' : '').file
  endif
  try
    exe testcmd
    call s:djump(djump)
  catch
    call s:error(s:sub(v:exception,'^.{-}:\zeE',''))
  endtry
  return ''
endfunction

function! s:Alternate(cmd)
  let file = projections#app().alternate('alternate')
  if empty(file)
    let file = projections#app().alternate('test')
  endif
  if !empty(file)
    call s:findedit(a:cmd,file)
  else
    call s:warn("No alternate file is defined")
  endif
endfunction

function! s:Related(cmd)
  let file = projections#app().alternate('related')
  if !empty(file)
    call s:findedit(a:cmd,file)
  else
    call s:warn("No related file is defined")
  endif
endfunction

function! s:Layout(type)
  let layout_cmd = g:projections_open_layout_in_tab ? "tabe" : "e"
  let file = projections#app().alternate(a:type)
  if empty(file)
    let file = projections#app().alternate('test')
  endif
  if !empty(file)
    if !filereadable(file)
      let has_temp = projections#app().projected('template_'.a:type)
      if !empty(has_temp)
        let opts = projections#app().get_pattern_and_root()
        if type(opts) == 1
          return 'echoerr "'.opts.'"'
        else
          let projected = projections#app().template_for_pattern(opts.pattern,opts.root,'template_'.a:type)
          let cmd = projections#app().create_template(file,projected,'vsp')
          silent execute layout_cmd . ' %'
          only!
          execute cmd
          let test_command = projections#app().projected('test_command')
          if len(test_command) > 0
            let t:test_command = test_command[0]
          endif
          call s:ReverseLayout()
          return 0
        endif
      else
        call s:warn("E345: Can't find file \"".file."\" in path")
        return
      endif
    endif
    silent execute layout_cmd . ' %'
    only!
    if a:type == 'alternate'
      AV
    endif
    if a:type == 'related'
      RV
    endif
    let test_command = projections#app().projected('test_command')
    if len(test_command) > 0
      let t:test_command = test_command[0]
    endif
    call s:ReverseLayout()
  else
    call s:warn("No ".a:type." file is defined")
  endif
endfunction

function! s:AlternateLayout(cmd)
  call s:Layout('alternate')
endfunction

function! s:RelatedLayout(cmd)
  call s:Layout('related')
endfunction

function! s:ReverseLayout()
  let reverse_layout = projections#app().projected('reverse_layout')
  if !empty(reverse_layout) && reverse_layout[0]
    exe 'wincmd x'
  endif
  exe 'wincmd p'
endfunction

function! s:app_alternate(type) dict abort
  let candidates = self.projected(a:type)
  for file in candidates
    if self.has_path(file)
      return file
    endif
  endfor
  return get(candidates,0,'')
endfunction

call s:add_methods('app', ['alternate'])

" }}}1
" Cache {{{1

let s:cache_prototype = {'dict': {}}

function! s:cache_clear(...) dict
  if a:0 == 0
    let self.dict = {}
  elseif has_key(self,'dict') && has_key(self.dict,a:1)
    unlet! self.dict[a:1]
  endif
endfunction

function! s:cache_get(...) dict
  if a:0 == 1
    return self.dict[a:1]
  else
    return self.dict
  endif
endfunction

function! s:cache_has(key) dict
  return has_key(self.dict,a:key)
endfunction

function! s:cache_needs(key) dict
  return !has_key(self.dict,a:key)
endfunction

function! s:cache_set(key,value) dict
  let self.dict[a:key] = a:value
endfunction

call s:add_methods('cache', ['clear','needs','has','get','set'])

let s:app_prototype.cache = s:cache_prototype

" }}}1
" Projections {{{1

function! projections#json_parse(string) abort
  let [null, false, true] = ['', 0, 1]
  let string = type(a:string) == type([]) ? join(a:string, ' ') : a:string
  let stripped = substitute(string,'\C"\(\\.\|[^"\\]\)*"','','g')
  if stripped !~# "[^,:{}\\[\\]0-9.\\-+Eaeflnr-u \n\r\t]"
    try
      return eval(substitute(string,"[\r\n]"," ",'g'))
    catch
    endtry
  endif
  throw "invalid JSON: ".string
endfunction

function! s:extend_projection(dest, src)
  let dest = copy(a:dest)
  for key in keys(a:src)
    if !has_key(dest, key)
      let dest[key] = a:src[key]
    elseif type(a:src[key]) == type({}) && type(dest[key]) == type({})
      let dest[key] = extend(copy(dest[key]), a:src[key])
    else
      let dest[key] = s:uniq(s:getlist(a:src, key) + s:getlist(dest, key))
    endif
  endfor
  return dest
endfunction

function! s:combine_projections(dest, src, ...) abort
  let extra = a:0 ? a:1 : {}
  if type(a:src) == type({})
    for [pattern, original] in items(a:src)
      let projection = extend(copy(original), extra)
      if !has_key(projection, 'prefix') && !has_key(projection, 'format')
        let a:dest[pattern] = s:extend_projection(get(a:dest, pattern, {}), projection)
      endif
    endfor
  endif
  return a:dest
endfunction

function! s:app_projections() dict abort
  let dict = {}
  if self.cache.needs('projections')
    call self.cache.set('projections', {})
    let projections = {}
    if self.has_path('projections.json')
      try
        let projections = projections#json_parse(readfile(self.path('projections.json')))
        if type(projections) == type({})
          call self.cache.set('projections', projections)
        endif
      catch /^invalid JSON:/
      endtry
    endif
  endif
  call s:combine_projections(dict, self.cache.get('projections'))
  return dict
endfunction

call s:add_methods('app', ['projections'])

function! s:expand_placeholders(string, placeholders)
  if type(a:string) !=# type('')
    return a:string
  endif
  let ph = extend({'%': '%'}, a:placeholders)
  let value = substitute(a:string, '%\([^: ]\)', '\=get(ph, submatch(1), "\001")', 'g')
  return value =~# "\001" ? '' : value
endfunction

function! s:app_projected(key, ...) dict abort
  let f = self.buffer_name()
  let all = self.projections()
  let mine = []
  if has_key(all, f)
    let mine += map(s:getlist(all[f], a:key), 's:expand_placeholders(v:val, a:0 ? a:1 : 0)')
  endif
  for pattern in reverse(sort(filter(keys(all), 'v:val =~# "^[^*]*\\*[^*]*$"'), s:function('projections#lencmp')))
    let [prefix, suffix; _] = split(pattern, '\*', 1)
    if s:startswith(f, prefix) && s:endswith(f, suffix)
      let root = f[strlen(prefix) : -strlen(suffix)-1]
      let ph = extend({
            \ 's': root,
            \ 'S': projections#camelize(root),
            \ 'h': toupper(root[0]) . tr(projections#underscore(root), '_', ' ')[1:-1],
            \ 'p': projections#pluralize(root),
            \ 'i': projections#singularize(root),
            \ 'f': projections#file_part(root),
            \ '%': '%'}, a:0 ? a:1 : {})
      if suffix =~# '\.js\>'
        let ph.S = s:gsub(ph.S, '::', '.')
      endif
      let mine += map(s:getlist(all[pattern], a:key), 's:expand_placeholders(v:val, ph)')
    endif
  endfor
  return filter(mine, '!empty(v:val)')
endfunction

function! s:app_get_pattern_and_root() dict abort
  let f = self.buffer_name()
  let all = self.projections()
  for pattern in reverse(sort(filter(keys(all), 'v:val =~# "^[^*]*\\*[^*]*$"'), s:function('projections#lencmp')))
    let [prefix, suffix; _] = split(pattern, '\*', 1)
    if s:startswith(f, prefix) && s:endswith(f, suffix)
      let root = f[strlen(prefix) : -strlen(suffix)-1]
      return {'root':root,'pattern':pattern}
    endif
  endfor
  return "No pattern/root found"
endfunction

function! s:app_template_for_pattern(pattern,name,type) dict abort
  let all = self.projections()
  let mine = []
  if has_key(all, a:pattern)
    if !has_key(all,'templates')
      return 'echoerr "No templates found"'
    endif
    if !has_key(all[a:pattern],a:type) || !has_key(all['templates'],all[a:pattern][a:type])
      return 'echoerr "No template found"'
    else
      let template_type = all[a:pattern][a:type]
    endif
    let file_part = projections#file_part(a:name)
    let ph = {
      \ 's': a:name,
      \ 'S': projections#camelize(file_part),
      \ 'h': toupper(file_part[0]) . tr(projections#underscore(file_part), '_', ' ')[1:-1],
      \ 'p': projections#pluralize(file_part),
      \ 'i': projections#singularize(file_part),
      \ 'f': file_part,
      \ '%': '%'}
    let mine += map(s:getlist(all['templates'],template_type),'s:expand_placeholders(v:val, ph)')
  endif
  return filter(mine, '!empty(v:val)')
endfunction

call s:add_methods('app',['projected','get_pattern_and_root','template_for_pattern'])

" }}}1
" Detection {{{1

function! ProjectionsBufInit(path)
  let g:projections_root = a:path
  if !has_key(s:apps,a:path)
    let s:apps[a:path] = deepcopy(s:app_prototype)
    let s:apps[a:path].root = a:path
  endif
  let app = s:apps[a:path]
  if !app.has_path('projections.json')
    return 0
  endif
  call s:BufProjectionCommands()
  call s:BufNavCommands()
  return g:projections_root
endfunction

function! ProjectionsBufUpdate(path)
  let s:apps[a:path] = deepcopy(s:app_prototype)
  let s:apps[a:path].root = a:path
  let app = s:apps[a:path]
  if !app.has_path('projections.json')
    return 0
  endif
  call s:BufProjectionCommands()
  call s:BufNavCommands()
  return g:projections_root
endfunction

" }}}1
" Initialization {{{1

map <SID>xx <SID>xx
let s:sid = s:sub(maparg("<SID>xx"),'xx$','')
unmap <SID>xx
let s:file = expand('<sfile>:p')

if !exists('s:apps')
  let s:apps = {}
endif

" }}}1
