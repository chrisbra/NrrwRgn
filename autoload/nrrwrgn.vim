" NrrwRgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:	   0.8
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Tue, 18 May 2010 23:17:35 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3075 
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"			   The VIM LICENSE applies to histwin.vim 
"			   (see |copyright|) except use "NrrwRgn.vim" 
"			   instead of "Vim".
"			   No warranty, express or implied.
"	 *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3075 8 :AutoInstall: NrrwRgn.vim
"
" Functions:

fun! s:WarningMsg(msg)"{{{1
	echohl WarningMsg
	let msg = "NarrowRegion: " . a:msg
	if exists(":unsilent") == 2
		unsilent echomsg msg
	else
		echomsg msg
	endif
	echohl Normal
	let v:errmsg = msg
endfun "}}}
fun! <sid>Init()"{{{1
	    if !exists("s:instn")
			let s:instn=1
		else
			let s:instn+=1
		endif
		"if !exists("s:nrrw_winname")
		let s:nrrw_winname='Narrow_Region'
		"endif
		if bufname('') != s:nrrw_winname
			if !exists("s:orig_buffer")
				let s:orig_buffer={}
			endif
			if !get(s:orig_buffer, bufnr(''),0)
				let s:orig_buffer[s:instn] = bufnr('')
			endif
			"let s:orig_buffer = bufnr('')
		endif

		" Customization
		let s:nrrw_rgn_vert = (exists("g:nrrw_rgn_vert")  ? g:nrrw_rgn_vert   : 0)
		let s:nrrw_rgn_wdth = (exists("g:nrrw_rgn_wdth")  ? g:nrrw_rgn_wdth   : 20)
		let s:nrrw_rgn_hl   = (exists("g:nrrw_rgn_hl")    ? g:nrrw_rgn_hl     : "WildMenu")
		let s:nrrw_rgn_nohl = (exists("g:nrrw_rgn_nohl")  ? g:nrrw_rgn_nohl   : 0)
		let s:nrrw_rgn_win  = (exists("g:nrrw_rgn_sepwin")? g:nrrw_rgn_sepwin : 0)
		
endfun 

fun! <sid>NrwRgnWin() "{{{1
	    if s:nrrw_rgn_win
			let s:nrrw_winname .= '_' . empty(bufname('')) ? bufnr('') : bufname('')
		endif
		let nrrw_win = bufwinnr('^'.s:nrrw_winname.'$')
		if nrrw_win != -1
			exe ":noa " . nrrw_win . 'wincmd w'
			silent %d _
			noa wincmd p
		else
			execute s:nrrw_rgn_wdth . (s:nrrw_rgn_vert?'v':'') . "sp " . s:nrrw_winname
			setl noswapfile buftype=acwrite bufhidden=wipe foldcolumn=0 nobuflisted winfixwidth winfixheight
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
	" that might later be overwritten
	setl noma
	let orig_buf=bufnr('')

	" initialize Variables
	call <sid>Init()
	let ft=&l:ft
	let b:startline = [ a:firstline, 0 ]
	let b:endline   = [ a:lastline, 0 ]
	if exists("b:matchid")
		" if you call :NarrowRegion several times, without widening 
		" the previous region, b:matchid might already be defined so
		" make sure, the previous highlighting is removed.
		call matchdelete(b:matchid)
	endif
	if !s:nrrw_rgn_nohl
		let b:matchid =  matchadd(s:nrrw_rgn_hl, <sid>GeneratePattern(b:startline, b:endline, 'V')) "set the highlighting
	endif
	let a=getline(b:startline[0], b:endline[0])
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	call setline(1, a)
	setl nomod
	com! -buffer WidenRegion :call nrrwrgn#WidenRegion(0) |sil bd!
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
		if exists("b:matchid")
			call matchdelete(b:matchid)
			unlet b:matchid
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
		if b:endline[0]==line('$')
			let delete_last_line=1
		else
			let delete_last_line=0
		endif
	    exe ':silent :'.b:startline[0].','.b:endline[0].'d _'
	    call append((b:startline[0]-1),cont)
		let  b:endline[0] = b:startline[0] + len(cont) -1
		if delete_last_line
			:$d _
		endif
	endif
	call <sid>SaveRestoreRegister(0)
	let  @/=s:o_s
	" jump back to narrowed window
	exe ':noa' . bufwinnr(nrw_buf) . 'wincmd w'
	if s:instn>0
		let s:instn-=1
	endif
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

fu! nrrwrgn#VisualNrrwRgn(mode) "{{{1
	if empty(a:mode)
		" in case, visual mode wasn't entered, visualmode()
		" returns an empty string and in that case, we finish
		" here
		call s:WarningMsg("There was no region visually selected!")
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
	if exists("b:matchid")
		" if you call :NarrowRegion several times, without widening 
		" the previous region, b:matchid might already be defined so
		" make sure, the previous highlighting is removed.
		call matchdelete(b:matchid)
	endif
	if !s:nrrw_rgn_nohl
		let b:matchid =  matchadd(s:nrrw_rgn_hl, <sid>GeneratePattern(b:startline, b:endline, b:vmode))
	endif
	"let b:startline = [ getpos("'<")[1], virtcol("'<") ]
	"let b:endline   = [ getpos("'>")[1], virtcol("'>") ]
	norm gv"ay
	let win=<sid>NrwRgnWin()
	exe ':noa ' win 'wincmd w'
	let b:orig_buf = orig_buf
	silent put a
	silent 0d _
	setl nomod
	com! -buffer WidenRegion :call nrrwrgn#WidenRegion(1)|sil bd!
	call <sid>NrrwRgnAuCmd()
	call <sid>SaveRestoreRegister(0)

	" restore settings
	let &l:ft = ft
	let &lz   = o_lz
endfu

fu! <sid>NrrwRgnAuCmd() "{{{1
	if s:nrrw_rgn_win
		exe "aug NrrwRgn" . s:instn
	else
		exe "aug NrrwRgn"
	endif
	    au!
	    au BufWriteCmd <buffer> nested :call s:WriteNrrwRgn(1)
	    au BufWipeout,BufDelete <buffer> nested :call s:WriteNrrwRgn()
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

" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdl=0
