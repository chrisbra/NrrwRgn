" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/NrrwRgn.vim	[[[1
43
" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.4
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Wed, 28 Apr 2010 22:13:55 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 4 :AutoInstall: NrrwRgn.vim
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
com! NW	 :exe ":" . line('w0') . ',' . line('w$') . "call nrrwrgn#NrrwRgn()"
com! NarrowWindow :exe ":" . line('w0') . ',' . line('w$') . "call nrrwrgn#NrrwRgn()"

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
autoload/nrrwrgn.vim	[[[1
192
" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.4
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Wed, 28 Apr 2010 22:13:55 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 4 :AutoInstall: NrrwRgn.vim
"
" Functions:
fun! <sid>Init()"{{{1
		if !exists("s:nrrw_winname")
				let s:nrrw_winname='Narrow_Region'
		endif
		if bufname('') != s:nrrw_winname
				let s:orig_buffer = bufnr('')
		endif

		" Customization
		let s:nrrw_rgn_vert = (exists("g:nrrw_rgn_vert") ? g:nrrw_rgn_vert : 0)
		let s:nrrw_rgn_wdth = (exists("g:nrrw_rgn_wdth") ? g:nrrw_rgn_wdth : 20)
		let s:nrrw_rgn_hl   = (exists("g:nrrw_rgn_hl")   ? g:nrrw_rgn_hl   : "WildMenu")
		
endfun 

fun! <sid>NrwRgnWin() "{{{1
		let nrrw_win = bufwinnr('^'.s:nrrw_winname.'$')
		if nrrw_win != -1
			exe ":noa " . nrrw_win . 'wincmd w'
			silent %d_
			noa wincmd p
		else
			execute s:nrrw_rgn_wdth . (s:nrrw_rgn_vert?'v':'') . "sp " . s:nrrw_winname
			setl noswapfile buftype=acwrite bufhidden=wipe foldcolumn=0 nobuflisted winfixwidth
			let nrrw_win = bufwinnr("")
		endif
		return nrrw_win
endfu

fun! nrrwrgn#NrrwRgn() range  "{{{1
	let o_lz = &lz
	let s:o_s  = @/
	set lz
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that will later be overwritten
	setl noma
	let orig_buf=bufnr('')

	" initialize Variables
	call <sid>Init()
	let ft=&l:ft
	let b:startline = [ a:firstline, 0 ]
	let b:endline   = [ a:lastline, 0 ]
	let s:matchid =  matchadd(s:nrrw_rgn_hl, <sid>GeneratePattern(b:startline, b:endline, 'V')) "set the highlighting
	let a=getline(b:startline[0], b:endline[0])
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, a)
	setl nomod
	com! -buffer WidenRegion :call nrrwrgn#WidenRegion(0)
	call <sid>NrrwRgnAuCmd()

	" restore settings
	let &l:ft = ft
	let &lz   = o_lz
endfun

fu! s:WriteNrrwRgn(...)
    if &l:mod && exists("a:1") && a:1
		setl nomod
		exe ":WidenRegion"
    else
		call setbufvar(b:orig_buf, '&ma', 1)
		"close!
		exe ':noa' . bufwinnr(b:orig_buf) . 'wincmd w'
		if exists("s:matchid")
			call matchdelete(s:matchid)
			unlet s:matchid
		endif
    endif
endfun

fu! nrrwrgn#WidenRegion(vmode) "{{{1
	let nrw_buf  = bufnr('')
	let orig_win = bufwinnr(b:orig_buf)
	let cont     = getline(1,'$')
	call <sid>SaveRestoreRegister(1)
	exe ':noa' . orig_win . 'wincmd w'
	if !(&l:ma)
		setl ma
	endif
	if a:vmode "charwise, linewise or blockwise selection 
	    call setreg('a', join(cont, "\n") . "\n", b:vmode)
		if b:vmode == 'v'
		   " in characterwise selection, remove trailing \n
		   call setreg('a', substitute(@a, '\n$', '', ''), b:vmode)
		endif
	    exe "keepj" b:startline[0]
	    exe "keepj norm!" b:startline[1] . '|'
	    exe "keepj norm!" b:vmode
	    exe "keepj" b:endline[0]
	    exe "keepj norm!" b:endline[1] . '|'
	    norm! "aP
		let [ b:startline, b:endline ] = <sid>RetVisRegionPos()
	else "linewise selection because we started the NarrowRegion with the command NarrowRegion(0)
	    exe ':silent :'.b:startline[0].','.b:endline[0].'d _'
	    call append((b:startline[0]-1),cont)
		let  b:endline[0] = b:startline[0] + len(cont) -1
	endif
	call <sid>SaveRestoreRegister(0)
	let  @/=s:o_s
	"exe ':silent :bd!' nrw_buf
endfu

fu! <sid>SaveRestoreRegister(mode) "{{{1
	if a:mode
		let s:savereg  = getreg('a')
		let s:saveregt = getregtype('a')
	else
		call setreg('a', s:savereg, s:saveregt)
	endif
endfu!

fu! <sid>VisualNrrwRgn(mode) "{{{1
	exe "norm! \<ESC>"
	" stop visualmode
	let o_lz = &lz
	let s:o_s  = @/
	set lz
	let b:vmode=a:mode
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that will later be overwritten
	setl noma
	let orig_buf=bufnr('')
	call <sid>SaveRestoreRegister(1)

	call <sid>Init()
	let ft=&l:ft
	let [ b:startline, b:endline ] = <sid>RetVisRegionPos()
	let s:matchid =  matchadd(s:nrrw_rgn_hl, <sid>GeneratePattern(b:startline, b:endline, b:vmode))
	"let b:startline = [ getpos("'<")[1], virtcol("'<") ]
	"let b:endline   = [ getpos("'>")[1], virtcol("'>") ]
	norm gv"ay
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	silent put a
	silent 0d _
	setl nomod
	com! -buffer WidenRegion :call nrrwrgn#WidenRegion(1)
	call <sid>NrrwRgnAuCmd()
	call <sid>SaveRestoreRegister(0)

	" restore settings
	let &l:ft = ft
	let &lz   = o_lz
endfu

fu! <sid>NrrwRgnAuCmd() "{{{1
    aug NrrwRgn
	    au!
	    au BufWriteCmd <buffer> :call s:WriteNrrwRgn(1)
	    au BufWipeout,BufDelete <buffer> :call s:WriteNrrwRgn()
    aug end
endfun

fu! <sid>RetVisRegionPos() "{{{1
	let startline = [ getpos("'<")[1], virtcol("'<") ]
	let endline   = [ getpos("'>")[1], virtcol("'>") ]
	return [ startline, endline ]
endfu

fun! <sid>GeneratePattern(startl, endl, mode) "{{{1
	if a:mode ==# ''
		return '\%>' . (a:startl[0]-1) . 'l\&\%>' . (a:startl[1]-1) . 'v\&\%<' . (a:endl[0]+1) . 'l\&\%<' . (a:endl[1]+1) . 'v'
	elseif a:mode ==# 'v'
		return '\%>' . (a:startl[0]-1) . 'l\&\%>' . (a:startl[1]-1) . 'v\_.*\%<' . (a:endl[0]+1) . 'l\&\%<' . (a:endl[1]+1) . 'v'
	else
	    return '\%>' . (a:startl[0]-1) . 'l\&\%<' . (a:endl[0]+1) . 'l'
	endif
endfun

" vim: ts=4 sts=4 fdm=marker com+=l\:\"
doc/NarrowRegion.txt	[[[1
135
*NrrwRgn.txt*	A Narrow Region Plugin (similar to Emacs)

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.4 Wed, 28 Apr 2010 22:13:55 +0200

Copyright: (c) 2009, 2010 by Christian Brabandt		
           The VIM LICENSE applies to NrrwRgnPlugin.vim and NrrwRgnPlugin.txt
           (see |copyright|) except use NrrwRgnPlugin instead of "Vim".
	   NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents					*NarrowRegion*	*NrrwRgnPlugin*

	1.  Contents.....................................: |NrrwRgnPlugin|
	2.  NrrwRgn Manual...............................: |NrrwRgn-manual|
	2.1   NrrwRgn Configuration......................: |NrrwRgn-config|
	3.  NrrwRgn Feedback.............................: |NrrwRgn-feedback|
	4.  NrrwRgn History..............................: |NrrwRgn-history|

==============================================================================
2. NrrwRgn Manual					*NrrwRgn-manual*

Functionality

This plugin is based on a discussion in comp.editors (see the thread at
http://groups.google.com/group/comp.editors/browse_frm/thread/0f562d97f80dde13)

Narrowing means focussing on a region and making the rest inaccessible. You
simply select the region, call :NarrowRegion and the selected part will open
in a new scratch buffer. The rest of the file will be protected, so you won't
accidentally modify that buffer. In the new buffer, you can do a global
replace, search or anything else to modify that part. When you are finished,
simply write that buffer (e.g. by |:w|) and your modifications will be put in
the original buffer making it accessible again.

NrrwRgn allows you to either select a line based selection using an Ex-command
or you can simply use any visual selected region and press your prefered key
combination to open that selection in a new buffer.

							*:NarrowRegion* *:NR*
:[range]NarrowRegion	    When [range] is omited, select only the current
			    line, else use the lines in the range given and 
			    open it in a new Scratch Window. 
			    Whenever you are finished modifying that region
			    simply write the buffer.

:[range]NR                  This is a shortcut for :NarrowRegion

							*:NarrowWindow* *:NW*
:NarrowWindow		    Select only the range that is visible the current
			    window and open it in a new Scratch Window. 
			    Whenever you are finished modifying that region
			    simply write the buffer.

:NW			    This is a shortcut for :NarrowWindow

								*:WidenRegion*
:WidenRegion                This command is only available in the narrowed 
			    scratch buffer. If the buffer has been modified,
			    the contents will be put back on the original
			    buffer.

You can also start visual mode and have the selected region being narrowed. In
this mode, NarrowRegion allows you to block select |CTRL-V| , character select
|v| or linewise select |V| a region. Then press <Leader>nr where <Leader> by
default is set to '\', unless you have set it to something different (see
|<Leader>| for information how to change this) and the selected range will
open in a new scratch buffer. This key combination only works in |Visual-mode|

==============================================================================
2.1 NrrwRgn Configuration				     *NrrwRgn-config*

NarrowRegion can be customized by setting some global variables. If you'd
like to open the narrowed windo as a vertical split buffer, simply set the
variable g:nrrw_rgn_vert to 1 in your |.vimrc| >

    let g:nrrw_rgn_vert = 1
< 
If you'd like to specify a certain width/height for you scratch buffer, then
set the variable g:nrrw_rgn_wdth in your |.vimrc| . This variable defines the
width or the nr of columns, if you have also set g:nrrw_rgn_vert. >

    let g:nrrw_rgn_wdth = 30

By default, NarrowRegion highlights your the region that has been selected
using the WildMenu highlighting (see |hl-WildMenu|). If you'd like to use a
different highlighting, set the variable g:nrrw_rgn_hl to your preferred
highlighting Group. For example to have the region highlighted like a search
result, you could put that in your |.vimrc| >

    let g:nrrw_rgn_hl = 'Search'

If you'd like to change the key combination, that starts the Narrowed Window
for you selected range, you could put this in your |.vimrc| >

   xmap <F3> <Plug>NrrwrgnDo

This will let <F3> open the Narrow-Window, but only if you have pressed it in
Visual Mode. It doesn't really make sense to map this combination to any other
mode, unless you want it to Narrow your last visually selected range.

==============================================================================
3. NrrwRgn Feedback					    *NrrwRgn-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3075

You can also follow the development of the plugin at github:
http://github.com/chrisbra/NrrwRgn

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
4. NrrwRgn History					    *NrrwRgn-history*
	0.4: Apr 28, 2010       - Highlight narrowed region in the original
				  buffer
				- Save and Restore search-register
				- Provide shortcut commands |:NR| 
				- Provide command |:NW| and |:NarrowWindow|
				- Make plugin autoloadable
				- Enable GLVS (see |:GLVS|)
				- Provide Documenation (:h NarrowRegion)
				- Distribute Plugin as vimball |pi_vimball.txt|
	0.3: Apr 28, 2010       - Initial upload
				- development versions are available at the
				  github repository
				- put plugin on a public repository 
				  (http://github.com/chrisbra/NrrwRgn)

==============================================================================
Modeline:
vim:tw=78:ts=8:ft=help
