call rpcnotify(1, 'Gui', 'Option', 'Popupmenu', 0)
call rpcnotify(1, 'Gui', 'Option', 'Tabline', 0)

function! SetFontSize(point)
  call GuiFont(join([split(g:GuiFont, "h")[0], a:point], "h"), 1)
endfunction

function! ChangeFontSize(point_diff)
  let split = split(g:GuiFont, "h")
  call GuiFont(join([split[0], split[1] + a:point_diff], "h"), 1)
endfunction

nnoremap <silent> <C-+> :<C-U>call ChangeFontSize(1)<CR>
nnoremap <silent> <C--> :<C-U>call ChangeFontSize(-1)<CR>
nnoremap <silent> <C-0> :<C-U>call SetFontSize(14)<CR>

call SetFontSize(11)
