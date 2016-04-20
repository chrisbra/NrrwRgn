" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.33
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Thu, 15 Jan 2015 20:52:29 +0100
" Script: http://www.vim.org/scripts/script.php?script_id=3075
" Copyright:   (c) 2009-2015 by Christian Brabandt
"			   The VIM LICENSE applies to NrrwRgn.vim
"			   (see |copyright|) except use "NrrwRgn.vim"
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 33 :AutoInstall: NrrwRgn.vim
"
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_nrrw_rgn") || &cp
  finish
endif
set cpo&vim
let g:loaded_nrrw_rgn = 1

" Debug Setting
let s:debug=0
if s:debug
	exe "call nrrwrgn#Debug(1)"
endif

" ----------------------------------------------------------------------------
" Public Interface: {{{1

" plugin functions "{{{2
fun! <sid>NrrwRgnOp(type, ...) " {{{3
	" used for operator function mapping
	let sel_save = &selection
	let &selection = "inclusive"
	if a:0  " Invoked from Visual mode, use '< and '> marks.
		sil exe "normal! `<" . a:type . "`>y"
	elseif a:type == 'line'
		sil exe "normal! '[V']y"
	elseif a:type == 'block'
		sil exe "normal! `[\<C-V>`]y"
	else
		sil exe "normal! `[v`]y"
	endif
	call nrrwrgn#NrrwRgn(visualmode(), '')
	let &selection = sel_save
endfu

" Define the Command aliases "{{{2
com! -range -bang NRPrepare :<line1>,<line2>NRP<bang>
com! -bang -range NarrowRegion :<line1>,<line2>NR
com! -bang NRMulti :NRM<bang>
com! -bang NarrowWindow :NW
com! -bang NRLast :NRL

" Define the actual Commands "{{{2
com! -range -bang NR	 :<line1>, <line2>call nrrwrgn#NrrwRgn('',<q-bang>)
com! -range -bang NRP    :<line1>, <line2>call nrrwrgn#Prepare(<q-bang>)
com! -bang -range NRV :call nrrwrgn#NrrwRgn(visualmode(), <q-bang>)
com! NUD :call nrrwrgn#UnifiedDiff()
com! -bang NW	 :exe ":" . line('w0') . ',' . line('w$') . "call nrrwrgn#NrrwRgn(0,<q-bang>)"
com! -bang NRM :call nrrwrgn#NrrwRgnDoMulti(<q-bang>)
com! -bang NRL :call nrrwrgn#LastNrrwRgn(<q-bang>)

" Define the Mapping: "{{{2
if !hasmapto('<Plug>NrrwrgnDo') && !get(g:, 'nrrw_rgn_nomap_nr', 0)
	xmap <unique> <Leader>nr <Plug>NrrwrgnDo
	nmap <unique> <Leader>nr <Plug>NrrwrgnDo
endif
if !hasmapto('<Plug>NrrwrgnBangDo') && !get(g:, 'nrrw_rgn_nomap_Nr', 0)
	xmap <unique> <Leader>Nr <Plug>NrrwrgnBangDo
endif
if !hasmapto('VisualNrrwRgn')
	xnoremap <unique> <script> <Plug>NrrwrgnDo <sid>VisualNrrwRgn
	nnoremap <unique> <script> <Plug>NrrwrgnDo <sid>VisualNrrwRgn
endif
if !hasmapto('VisualNrrwRgnBang')
	xnoremap <unique> <script> <Plug>NrrwrgnBangDo <sid>VisualNrrwBang
endif
xnoremap <sid>VisualNrrwRgn  :<c-u>call nrrwrgn#NrrwRgn(visualmode(),'')<cr>
xnoremap <sid>VisualNrrwBang :<c-u>call nrrwrgn#NrrwRgn(visualmode(),'!')<cr>

" operator function
nnoremap <sid>VisualNrrwRgn :set opfunc=<sid>NrrwRgnOp<cr>g@

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\"
