" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/NrrwRgn.vim	[[[1
45
" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.14
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Thu, 26 Aug 2010 12:52:51 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 14 :AutoInstall: NrrwRgn.vim
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
autoload/nrrwrgn.vim	[[[1
382
" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.14
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Thu, 26 Aug 2010 12:52:51 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to NrrwRgn.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 14 :AutoInstall: NrrwRgn.vim
"
" Functions:

fun! <sid>WarningMsg(msg)"{{{1
	echohl WarningMsg
	let msg = "NarrowRegion: " . a:msg
	if exists(":unsilent") == 2
		unsilent echomsg msg
	else
		echomsg msg
	endif
	echohl Normal
	let v:errmsg = msg
endfun

fun! <sid>Init()"{{{1
    if !exists("s:instn")
		let s:instn=1
    else
		let s:instn+=1
    endif
	if !exists("s:nrrw_rgn_lines")
		let s:nrrw_rgn_lines = {}
	endif
	let s:nrrw_rgn_lines[s:instn] = {}
    let s:nrrw_winname='Narrow_Region'

    " Customization
    let s:nrrw_rgn_vert = (exists("g:nrrw_rgn_vert")  ? g:nrrw_rgn_vert   : 0)
    let s:nrrw_rgn_wdth = (exists("g:nrrw_rgn_wdth")  ? g:nrrw_rgn_wdth   : 20)
    let s:nrrw_rgn_hl   = (exists("g:nrrw_rgn_hl")    ? g:nrrw_rgn_hl     : "WildMenu")
    let s:nrrw_rgn_nohl = (exists("g:nrrw_rgn_nohl")  ? g:nrrw_rgn_nohl   : 0)

    let s:debug=0
	if exists("s:debug") && s:debug
		com! NI :call <sid>WarningMsg("Instance: ".s:instn)
		com! NJ :call <sid>WarningMsg("Data: ".string(s:nrrw_rgn_lines))
	endif
		
endfun 

fun! <sid>NrwRgnWin() "{{{1
	let s:nrrw_winname .= '_' . s:instn
    let nrrw_win = bufwinnr('^'.s:nrrw_winname.'$')
    if nrrw_win != -1
		exe ":noa " . nrrw_win . 'wincmd w'
		silent %d _
		noa wincmd p
    else
		exe 'topleft ' . s:nrrw_rgn_wdth . (s:nrrw_rgn_vert?'v':'') . "sp " . s:nrrw_winname
		setl noswapfile buftype=acwrite bufhidden=wipe foldcolumn=0 nobuflisted
		let nrrw_win = bufwinnr("")
    endif
    return nrrw_win
endfu

fun! nrrwrgn#NrrwRgn() range  "{{{1
	let o_lz = &lz
	let s:o_s  = @/
	set lz
	let orig_buf=bufnr('')

	" initialize Variables
	call <sid>Init()
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that might later be overwritten
	setl noma
	let ft=&l:ft
	let s:nrrw_rgn_lines[s:instn].startline = [ a:firstline, 0 ]
	let s:nrrw_rgn_lines[s:instn].endline   = [ a:lastline, 0 ]
	if exists("s:nrrw_rgn_lines[s:instn].matchid")
	    " if you call :NarrowRegion several times, without widening 
	    " the previous region, b:matchid might already be defined so
	    " make sure, the previous highlighting is removed.
	    call matchdelete(s:nrrw_rgn_lines[s:instn].matchid)
	endif
	if !s:nrrw_rgn_nohl
	    let s:nrrw_rgn_lines[s:instn].matchid =  matchadd(s:nrrw_rgn_hl, 
		\<sid>GeneratePattern(
		\s:nrrw_rgn_lines[s:instn].startline, 
		\s:nrrw_rgn_lines[s:instn].endline, 
		\'V')) "set the highlighting
	endif
	let a=getline(
	    \s:nrrw_rgn_lines[s:instn].startline[0], 
	    \s:nrrw_rgn_lines[s:instn].endline[0])
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, a)
	let b:nrrw_instn = s:instn
	setl nomod
	"com! -buffer WidenRegion :call nrrwrgn#WidenRegion(0) |sil bd!
    com! -buffer -bang WidenRegion :call nrrwrgn#WidenRegion(0, (empty("<bang>") ? 0 : 1))
	call <sid>NrrwRgnAuCmd(0)

	" restore settings
	let &l:ft = ft
	let &lz   = o_lz
endfun

fu! s:WriteNrrwRgn(...) "{{{1
	if exists("b:orig_buf") && (bufwinnr(b:orig_buf) == -1)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
    if &l:mod && exists("a:1") && a:1
		" Write the buffer back to the original buffer
		setl nomod
		exe ":WidenRegion"
    else
		if bufname('') !~# 'Narrow_Region'
			exe ':noa' . bufwinnr('Narrow_Region') . 'wincmd w'
		endif
		call setbufvar(b:orig_buf, '&ma', 1)
		exe ':noa' . bufwinnr(b:orig_buf) . 'wincmd w'
		"if exists("s:nrrw_rgn_lines[s:instn].matchid")
		"	call matchdelete(s:nrrw_rgn_lines[s:instn].matchid)
		"	unlet s:nrrw_rgn_lines[s:instn].matchid
		"endif
    endif
endfun

fu! nrrwrgn#WidenRegion(vmode,force) "{{{1
    let nrw_buf  = bufnr('')
    let orig_win = bufwinnr(b:orig_buf)
	if (orig_win == -1)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
    let cont     = getline(1,'$')
	let instn    = b:nrrw_instn
    call <sid>SaveRestoreRegister(1)
    exe ':noa' . orig_win . 'wincmd w'
	let wsv=winsaveview()
    if !(&l:ma)
		setl ma
    endif
    if a:vmode "charwise, linewise or blockwise selection 
		call setreg('a', join(cont, "\n") . "\n", s:nrrw_rgn_lines[instn].vmode)
		if s:nrrw_rgn_lines[instn].vmode == 'v'
		   " in characterwise selection, remove trailing \n
		   call setreg('a', substitute(@a, '\n$', '', ''), 
			   \s:nrrw_rgn_lines[instn].vmode)
		endif
		exe "keepj" s:nrrw_rgn_lines[instn].startline[0]
		exe "keepj norm!" s:nrrw_rgn_lines[instn].startline[1] . '|'
		exe "keepj norm!" s:nrrw_rgn_lines[instn].vmode
		exe "keepj" s:nrrw_rgn_lines[instn].endline[0]
		exe "keepj norm!" s:nrrw_rgn_lines[instn].endline[1] . '|'
		norm! "aP
		" Recalculate the start and end positions of the narrowed window
		" so subsequent calls will adjust the region accordingly
		let [ s:nrrw_rgn_lines[instn].startline, 
			 \s:nrrw_rgn_lines[instn].endline ] = <sid>RetVisRegionPos()
		" also, renew the highlighted region
		if exists("s:nrrw_rgn_lines[instn].matchid")
			" if you call :NarrowRegion several times, without widening 
			" the previous region, b:matchid might already be defined so
			" make sure, the previous highlighting is removed.
			call matchdelete(s:nrrw_rgn_lines[instn].matchid)
		endif
		if !s:nrrw_rgn_nohl
			let s:nrrw_rgn_lines[instn].matchid =  matchadd(s:nrrw_rgn_hl, 
			\<sid>GeneratePattern(
			\s:nrrw_rgn_lines[instn].startline, 
			\s:nrrw_rgn_lines[instn].endline, 
			\s:nrrw_rgn_lines[instn].vmode))
		endif
    else "linewise selection because we started the NarrowRegion with the command NarrowRegion(0)
		"
		" if the endposition of the narrowed buffer is also the last line of
		" the buffer, the append will add an extra newline that needs to be
		" cleared.
		if s:nrrw_rgn_lines[instn].endline[0]==line('$') &&
		\  s:nrrw_rgn_lines[instn].startline[0] == 1
			let delete_last_line=1
		else
			let delete_last_line=0
		endif
		exe ':silent :'.s:nrrw_rgn_lines[instn].startline[0].','
			\.s:nrrw_rgn_lines[instn].endline[0].'d _'
		call append((s:nrrw_rgn_lines[instn].startline[0]-1),cont)
		" Recalculate the start and end positions of the narrowed window
		" so subsequent calls will adjust the region accordingly
		" so subsequent calls will adjust the region accordingly
	    let  s:nrrw_rgn_lines[instn].endline[0] =
			\s:nrrw_rgn_lines[instn].startline[0] + len(cont) -1
		if s:nrrw_rgn_lines[instn].endline[0] > line('$')
			let s:nrrw_rgn_lines[instn].endline[0] = line('$')
		endif
		" also, renew the highlighted region
		if exists("s:nrrw_rgn_lines[instn].matchid")
			" if you call :NarrowRegion several times, without widening 
			" the previous region, b:matchid might already be defined so
			" make sure, the previous highlighting is removed.
			call matchdelete(s:nrrw_rgn_lines[instn].matchid)
		endif
		if !s:nrrw_rgn_nohl
			let s:nrrw_rgn_lines[instn].matchid =  matchadd(s:nrrw_rgn_hl, 
			\<sid>GeneratePattern(
			\s:nrrw_rgn_lines[instn].startline, 
			\s:nrrw_rgn_lines[instn].endline, 
			\'V'))
		endif
	    if delete_last_line
			:$d _
	    endif
    endif
    call <sid>SaveRestoreRegister(0)
    let  @/=s:o_s
	call winrestview(wsv)
    " jump back to narrowed window
    exe ':noa' . bufwinnr(nrw_buf) . 'wincmd w'
    "call <sid>NrrwRgnAuCmd(0)
	"exe ':silent :bd!' nrw_buf
	setl nomod
	if a:force
		"exe 'bd! ' nrw_buf
		:bd!
	endif
endfu

fu! <sid>SaveRestoreRegister(mode) "{{{1
    if a:mode
		let s:savereg  = getreg('a')
		let s:saveregt = getregtype('a')
    else
		call setreg('a', s:savereg, s:saveregt)
    endif
endfu!

fu! nrrwrgn#VisualNrrwRgn(mode) "{{{1
    if empty(a:mode)
		" in case, visual mode wasn't entered, visualmode()
		" returns an empty string and in that case, we finish
		" here
		call <sid>WarningMsg("There was no region visually selected!")
		return
    endif
    " This beeps, when called from command mode
    " e.g. by using :NRV, so using :sil!
    " else exiting visual mode
    exe "sil! norm! \<ESC>"
    " stop visualmode
    let o_lz = &lz
    let s:o_s  = @/
    set lz
    call <sid>Init()
    let s:nrrw_rgn_lines[s:instn].vmode=a:mode
    " Protect the original buffer,
    " so you won't accidentally modify those lines,
    " that will later be overwritten
    setl noma
    let orig_buf=bufnr('')
    call <sid>SaveRestoreRegister(1)

    let ft=&l:ft
    let [ s:nrrw_rgn_lines[s:instn].startline, s:nrrw_rgn_lines[s:instn].endline ] = <sid>RetVisRegionPos()
    if exists("s:nrrw_rgn_lines[s:instn].matchid")
		" if you call :NarrowRegion several times, without widening 
		" the previous region, b:matchid might already be defined so
		" make sure, the previous highlighting is removed.
		call matchdelete(s:nrrw_rgn_lines[s:instn].matchid)
    endif
    if !s:nrrw_rgn_nohl
		let s:nrrw_rgn_lines[s:instn].matchid =  matchadd(s:nrrw_rgn_hl, 
		\<sid>GeneratePattern(s:nrrw_rgn_lines[s:instn].startline, s:nrrw_rgn_lines[s:instn].endline, s:nrrw_rgn_lines[s:instn].vmode))
    endif
    norm gv"ay
    let win=<sid>NrwRgnWin()
    exe ':noa ' win 'wincmd w'
    let b:orig_buf = orig_buf
    silent put a
	let b:nrrw_instn = s:instn
    silent 0d _
    setl nomod
    "com! -buffer WidenRegion :call nrrwrgn#WidenRegion(1)|sil bd!
    com! -buffer -bang WidenRegion :call nrrwrgn#WidenRegion(1, (empty("<bang>") ? 0 : 1))
    call <sid>NrrwRgnAuCmd(0)
    call <sid>SaveRestoreRegister(0)

    " restore settings
    let &l:ft = ft
    let &lz   = o_lz
endfu

fu! <sid>NrrwRgnAuCmd(bufnr) "{{{1
	" If a:bufnr==0, then enable auto commands
	" else disable auto commands for a:bufnr
    if !a:bufnr
		exe "aug NrrwRgn" . b:nrrw_instn
			au!
			au BufWriteCmd <buffer> nested :call s:WriteNrrwRgn(1)
			exe "au BufWipeout,BufDelete <buffer> nested :call s:WriteNrrwRgn()|:call <sid>NrrwRgnAuCmd(".b:nrrw_instn.")"
		aug end
    else
		exe "aug NrrwRgn" .  a:bufnr
		au!
		aug end
		exe "aug! NrrwRgn" . a:bufnr
		if exists("s:nrrw_rgn_lines[a:bufnr].matchid")
			call matchdelete(s:nrrw_rgn_lines[a:bufnr].matchid)
			unlet s:nrrw_rgn_lines[a:bufnr].matchid
		endif
		if s:instn>0
			unlet s:nrrw_rgn_lines[a:bufnr]
			let s:instn-=1
		endif
    endif
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
endfun "}}}
fun! nrrwrgn#UnifiedDiff() "{{{1
	let save_winposview=winsaveview()
	let orig_win = winnr()
	" close previous opened Narrowed buffers
	silent! windo | if bufname('')=~'^Narrow_Region' && &diff |diffoff|q!|endif
	" minimize Window
	" this is disabled, because this might be useful, to see everything
	"exe "vert resize -999999"
	"setl winfixwidth
	" move to current start of chunk of unified diff
	if search('^@@', 'bcW') > 0
		call search('^@@', 'bc')
	else
		call search('^@@', 'c')
	endif
	let curpos=getpos('.')
	for i in range(2)
		if search('^@@', 'nW') > 0
			.+,/@@/-NR
		else
			" Last chunk in file
			.+,$NR
		endif
	   " Split vertically
	   wincmd H
	   if i==0
		   silent! g/^-/d _
	   else
		   silent! g/^+/d _
	   endif
	   diffthis
	   0
	   exe ":noa wincmd p"
	   call setpos('.', curpos)
	endfor
	call winrestview(save_winposview)
endfun
	

" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdl=0
doc/NarrowRegion.txt	[[[1
257
*NrrwRgn.txt*   A Narrow Region Plugin (similar to Emacs)

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.14 Thu, 26 Aug 2010 12:52:51 +0200

Copyright: (c) 2009, 2010 by Christian Brabandt         
           The VIM LICENSE applies to NrrwRgnPlugin.vim and NrrwRgnPlugin.txt
           (see |copyright|) except use NrrwRgnPlugin instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents                                     *NarrowRegion*  *NrrwRgnPlugin*

        1.  Contents.....................................: |NrrwRgnPlugin|
        2.  NrrwRgn Manual...............................: |NrrwRgn-manual|
        2.1   NrrwRgn Configuration......................: |NrrwRgn-config|
        3.  NrrwRgn Feedback.............................: |NrrwRgn-feedback|
        4.  NrrwRgn History..............................: |NrrwRgn-history|

==============================================================================
2. NrrwRgn Manual                                       *NrrwRgn-manual*

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
:[range]NarrowRegion        When [range] is omited, select only the current
                            line, else use the lines in the range given and 
                            open it in a new Scratch Window. 
                            Whenever you are finished modifying that region
                            simply write the buffer.

:[range]NR                  This is a shortcut for :NarrowRegion

                                                        *:NarrowWindow* *:NW*
:NarrowWindow               Select only the range that is visible the current
                            window and open it in a new Scratch Window. 
                            Whenever you are finished modifying that region
                            simply write the buffer.

:NW                         This is a shortcut for :NarrowWindow

                                                                *:WidenRegion*
:WidenRegion[!]             This command is only available in the narrowed 
                            scratch window. If the buffer has been modified,
                            the contents will be put back on the original
                            buffer. If ! is specified, the window will be
                            closed, otherwise it will remain open.

                                                                        *:NRV*
:NRW                        Opened the narrowed window for the region that was
                            last selected in visual mode

                                                                        *:NUD*

:NUD                        When viewing unified diffs, this command opens the
                            current chunk in 2 Narrowed Windows in |diff-mode|
                            The current chunk is determined as the one, that
                            the cursor is at.
                            This command does not make sense if editing a
                            different file format (or even different diff format)

You can also start visual mode and have the selected region being narrowed. In
this mode, NarrowRegion allows you to block select |CTRL-V| , character select
|v| or linewise select |V| a region. Then press <Leader>nr where <Leader> by
default is set to '\', unless you have set it to something different (see
|<Leader>| for information how to change this) and the selected range will
open in a new scratch buffer. This key combination only works in |Visual-mode|

When finished, simply write that Narrowed Region window, from which you want
to take the modifications in your original file.

It is possible, to recursively open a Narrowed Window on top of an already
narrowed window. This sounds a little bit silly, but this makes it possible,
to have several narrowed windows, which you can use for several different
things, e.g. If you have 2 different buffers opened and you want to diff a
certain region of each of those 2 buffers, simply open a Narrowed Window for
each buffer, and execute |:diffthis| in each narrowed window.

You can then interactively merge those 2 windows. And when you are finished,
simply write the narrowed window and the changes will be taken back into the
original buffer.

When viewing unified diffs, you can use the provided |:NUD| command to open 2
Narrowed Windows side by side viewing the current chunk in |diff-mode|. Those
2 Narrowed windows will be marked 'modified', since there was some post
processing involved when opening the narrowed windows. Be careful, when
quitting the windows, not to write unwanted changes into your patch file! In
the window that contains the unified buffer, you can move to a different
chunk, run :NUD and the 2 Narrowed Windows in diff mode will update.

==============================================================================
2.1 NrrwRgn Configuration                                    *NrrwRgn-config*

NarrowRegion can be customized by setting some global variables. If you'd
like to open the narrowed windo as a vertical split buffer, simply set the
variable g:nrrw_rgn_vert to 1 in your |.vimrc| >

    let g:nrrw_rgn_vert = 1
<
------------------------------------------------------------------------------

If you'd like to specify a certain width/height for you scratch buffer, then
set the variable g:nrrw_rgn_wdth in your |.vimrc| . This variable defines the
width or the nr of columns, if you have also set g:nrrw_rgn_vert. >

    let g:nrrw_rgn_wdth = 30
<
------------------------------------------------------------------------------

By default, NarrowRegion highlights the region that has been selected
using the WildMenu highlighting (see |hl-WildMenu|). If you'd like to use a
different highlighting, set the variable g:nrrw_rgn_hl to your preferred
highlighting Group. For example to have the region highlighted like a search
result, you could put that in your |.vimrc| >

    let g:nrrw_rgn_hl = 'Search'
<
If you want to turn off the highlighting (because this can be disturbing, you
can set the global variable g:nrrw_rgn_nohl to 1 in your |.vimrc| >

    let g:nrrw_rgn_nohl = 1
<
------------------------------------------------------------------------------

If you'd like to change the key combination, that starts the Narrowed Window
for you selected range, you could put this in your |.vimrc| >

   xmap <F3> <Plug>NrrwrgnDo
<
This will let <F3> open the Narrow-Window, but only if you have pressed it in
Visual Mode. It doesn't really make sense to map this combination to any other
mode, unless you want it to Narrow your last visually selected range.

==============================================================================
3. NrrwRgn Feedback                                         *NrrwRgn-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3075

You can also follow the development of the plugin at github:
http://github.com/chrisbra/NrrwRgn

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
4. NrrwRgn History                                          *NrrwRgn-history*

0.14: August, 26, 2010
- Bugfix: :only in the original buffer resulted in errors (reported by Adam
  Monsen)

0.13: August, 22, 2010
- Unified Diff Handling (experimental feature)

0.12: July 29, 2010

- Version 0.11, wasn't packaged correctly and the vimball file
  contained some garbage. (Thanks Dennis Hostetler!)

0.11: July 28, 2010

- Don't set 'winfixwidth' and 'winfixheight' (suggested by Charles Campbell)

0.10: May 20,2010

- Restore Cursorposition using winrestview() and winsaveview()
- fix a bug, that prevented the use of visual narrowing
- Make sure when closing the narrowed buffer, the content will be written to
  the right original region
- use topleft for opening the Narrowed window
- check, that the original buffer is still available
- If you Narrow the complete buffer using :NRV and write the changes back, an
  additional trailing line is inserted. Remove that line.
- When writing the changes back, update the highlighting.

0.9: May 20, 2010

- It is now possible to Narrow a window recursively. This allows to have
  several narrowed windows, and allows for example to only diff certain
  regions (as was suggested in a recent thread at the vim_use mailinglist:
  http://groups.google.com/group/vim_use/msg/05d7fd9bd1556f0e) therefore, the
  use for the g:nrrw_rgn_sepwin variable isn't necessary anymore.
- Small documentation updates

0.8: May 18, 2010

- the g:nrrw_rgn_sepwin variable can be used to force seperate Narrowed
  Windows, so you could easily diff those windows.
- make the separating of several windows a little bit safer (look at the
  bufnr(), so it should work without problems for several buffers)
- switch from script local variables to buffer local variables, so narrowing
  for several buffers should work.
- set 'winfixheight' for narrowed window 
- Added command :NRV (suggested by Charles Campbell, thanks!)
- added error handling, in case :NRV is called, without a selected region
- take care of beeps, when calling :NRV
- output WarningMsg

0.7: May 17, 2010

- really use the black hole register for deleting the old buffer contents in
  the narrowed buffer (suggestion by esquifit in
  http://groups.google.com/group/comp.editors/msg/3eb3e3a7c68597db)
- make autocommand nesting, so the highlighting will be removed when writing
  the buffer contents.
- Use g:nrrw_rgn_nohl variable to disable highlighting (as this can be
  disturbing).

0.6: May 04, 2010

- the previous version had problems restoring the orig buffer, this version
  fixes it (highlighting and setl ma did not work correctly)

0.5: May 04, 2010       

- The mapping that allows for narrowing a visually selected range, did not
  work.  (Fixed!)
- Make :WidenRegion work as expected (close the widened window) (unreleased)

0.4: Apr 28, 2010       

- Highlight narrowed region in the original buffer
- Save and Restore search-register
- Provide shortcut commands |:NR| 
- Provide command |:NW| and |:NarrowWindow|
- Make plugin autoloadable
- Enable GLVS (see |:GLVS|)
- Provide Documenation (:h NarrowRegion)
- Distribute Plugin as vimball |pi_vimball.txt|

0.3: Apr 28, 2010       

- Initial upload
- development versions are available at the github repository
- put plugin on a public repository (http://github.com/chrisbra/NrrwRgn)

==============================================================================
Modeline:
vim:tw=78:ts=8:ft=help:et
