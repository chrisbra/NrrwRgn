" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.3
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Wed, 28 Apr 2010 12:58:13 +0200
"
" Script: not yet
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
"
" TODO: - currently this works only linewise. 
"         [ should work now with arbitrary selections! ]
"       - make it work with arbitrary selections.
"         (need to find out, how to select/copy arbitrary selections)
"       - mark the narrowed region (using signs?) in the orig buffer        

" Init:
let s:cpo= &cpo
set cpo&vim
if exists("g:loaded_nrrw_rgn") || &cp
  finish
endif

let g:loaded_nrrw_rgn = 1

" Functions:
fun! s:Init()"{{{1
		if !exists("s:nrrw_winname")
				let s:nrrw_winname='Narrow_Region'
		endif
		if bufname('') != s:nrrw_winname
				let s:orig_buffer = bufnr('')
		endif

		" Customization
		let s:nrrw_rgn_vert = (exists("g:nrrw_rgn_vert") ? g:nrrw_rgn_vert : 0)
		let s:nrrw_rgn_wdth = (exists("g:nrrw_rgn_wdth") ? g:nrrw_rgn_wdth : 30)
		
endfun 

fun! s:NrwRgnWin() "{{{1
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

fun! s:NrrwRgn() range  "{{{1
	let o_lz=&lz
	set lz
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that will later be overwritten
	setl noma
	let orig_buf=bufnr('')

	" initialize Variables
	call s:Init()
	let ft=&l:ft
	let b:startline = [ a:firstline, 0 ]
	let b:endline   = [ a:lastline, 0 ]
	let a=getline(b:startline[0], b:endline[0])
	let win=s:NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, a)
	setl nomod
	com! -buffer WidenRegion :call s:WidenRegion(0)
	call s:NrrwRgnAuCmd()

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
    endif
endfun

fu! s:WidenRegion(vmode) "{{{1
	let nrw_buf  = bufnr('')
	let orig_win = bufwinnr(b:orig_buf)
	let cont     = getline(1,'$')
	call s:SaveRestoreRegister(1)
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
	else "linewise selection because we started the NarrowRegion with the command NarrowRegion(0)
	    exe ':silent :'.b:startline[0].','.b:endline[0].'d _'
	    call append((b:startline[0]-1),cont)
	endif
	call s:SaveRestoreRegister(0)
	"exe ':silent :bd!' nrw_buf
endfu

fu! s:SaveRestoreRegister(mode) "{{{1
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
	let o_lz=&lz
	set lz
	let b:vmode=a:mode
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that will later be overwritten
	setl noma
	let orig_buf=bufnr('')
	call s:SaveRestoreRegister(1)

	call s:Init()
	let ft=&l:ft
	let b:startline = [ getpos("'<")[1], virtcol("'<") ]
	let b:endline   = [ getpos("'>")[1], virtcol("'>") ]
	norm gv"ay
	let win=s:NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	silent put a
	silent 0d _
	setl nomod
	com! -buffer WidenRegion :call s:WidenRegion(1)
	call s:NrrwRgnAuCmd()
	call s:SaveRestoreRegister(0)

	" restore settings
	let &l:ft = ft
	let &lz   = o_lz
endfu

fu! s:NrrwRgnAuCmd() "{{{1
    aug NrrwRgn
	    au!
	    au BufWriteCmd <buffer> :call s:WriteNrrwRgn(1)
	    au BufWipeout,BufDelete <buffer> :call s:WriteNrrwRgn()
    aug end
endfun

"Mappings "{{{1
" Delete old mappings
"silent! xunmap <Plug>NrrwrgnDo
"silent! xunmap <sid>VisualNrrwRgn
"silent! xunmap ,nr

com! -range NarrowRegion :exe ":" . <line1> . ',' . <line2> . "call s:NrrwRgn()"
if !hasmapto('<Plug>NrrwrgnDo')
	xmap <unique> <Leader>nr <Plug>NrrwrgnDo
endif
xnoremap <unique> <script> <Plug>NrrwrgnDo <sid>VisualNrrwRgn
xnoremap <sid>VisualNrrwRgn :<c-u>call <sid>VisualNrrwRgn(visualmode())<cr>

    
" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\"
