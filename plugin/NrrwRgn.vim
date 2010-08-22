" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.13
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Sun, 22 Aug 2010 14:59:59 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 13 :AutoInstall: NrrwRgn.vim
"
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_nrrw_rgn") || &cp
  finish
endif
set cpo&vim
let g:loaded_nrrw_rgn = 1

" ------------------------------------------------------------------------------
" Public Interface: {{{1

" Define the Command:
com! -range NarrowRegion :exe ":" . <line1> . ',' . <line2> . "call nrrwrgn#NrrwRgn()"
com! -range NR	 :exe ":" . <line1> . ',' . <line2> . "call nrrwrgn#NrrwRgn()"
com! -range NRV  :call nrrwrgn#VisualNrrwRgn(visualmode())
com! NW	 :exe ":" . line('w0') . ',' . line('w$') . "call nrrwrgn#NrrwRgn()"
com! NarrowWindow :exe ":" . line('w0') . ',' . line('w$') . "call nrrwrgn#NrrwRgn()"
com! NUD :call nrrwrgn#UnifiedDiff()

" Define the Mapping:
if !hasmapto('<Plug>NrrwrgnDo')
	xmap <unique> <Leader>nr <Plug>NrrwrgnDo
endif
xnoremap <unique> <script> <Plug>NrrwrgnDo <sid>VisualNrrwRgn
xnoremap <sid>VisualNrrwRgn :<c-u>call nrrwrgn#VisualNrrwRgn(visualmode())<cr>

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\"
