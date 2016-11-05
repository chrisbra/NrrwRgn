" Vimball Archiver by Charles E. Campbell
UseVimball
finish
plugin/NrrwRgn.vim	[[[1
90
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
autoload/nrrwrgn.vim	[[[1
1572
" nrrwrgn.vim - Narrow Region plugin for Vim
" -------------------------------------------------------------
" Version:		0.33
" Maintainer:	Christian Brabandt <cb@256bit.org>
" Last Change:	Thu, 15 Jan 2015 20:52:29 +0100
" Script:		http://www.vim.org/scripts/script.php?script_id=3075
" Copyright:	(c) 2009-2015 by Christian Brabandt
"				The VIM LICENSE applies to NrrwRgn.vim
"				(see |copyright|) except use "NrrwRgn.vim"
"				instead of "Vim".
"				No warranty, express or implied.
"				*** *** Use At-Your-Own-Risk! *** ***
" GetLatestVimScripts: 3075 33 :AutoInstall: NrrwRgn.vim
"
" Functions:

let s:numeric_sort = v:version > 704 || v:version == 704 && has("patch341")
let s:getcurpos    = exists('*getcurpos')
let s:window_type = {"source": 0, "target": 1}

fun! <sid>WarningMsg(msg) abort "{{{1
	let msg = "NarrowRegion: ". a:msg
	echohl WarningMsg
	if exists(":unsilent") == 2
		unsilent echomsg msg
	else
		echomsg msg
	endif
	sleep 1
	echohl Normal
	let v:errmsg = msg
endfun

fun! <sid>Init() abort "{{{1
	if !exists("s:opts")
		" init once
		let s:opts = []
	endif
	if !exists("s:instn")
		let s:instn=1
		if !exists("g:nrrw_custom_options") || empty(g:nrrw_custom_options)
			let s:opts=<sid>Options('local to buffer')
		endif
	else
		" Prevent accidently overwriting windows with instn_id set
		" back to an already existing instn_id
		let s:instn = (s:instn==0 ? 1 : s:instn)
		while (has_key(s:nrrw_rgn_lines, s:instn))
			let s:instn+=1
		endw
	endif
	call <sid>SetupHooks()
	if !exists("s:nrrw_rgn_lines")
		let s:nrrw_rgn_lines = {}
	endif
	let s:nrrw_rgn_lines[s:instn] = {}
	" show some debugging messages
	let s:nrrw_winname='NrrwRgn'

	" Customization
	let s:nrrw_rgn_vert = get(g:, 'nrrw_rgn_vert', 0)
	let s:nrrw_rgn_wdth = get(g:, 'nrrw_rgn_wdth', 20)
	let s:nrrw_rgn_hl   = get(g:, 'nrrw_rgn_hl', 'WildMenu')
	let s:nrrw_rgn_nohl = get(g:, 'nrrw_rgn_nohl', 0)
	let s:debug         = (exists("s:debug") ? s:debug : 0)
	let s:float         = has('float')
	let s:syntax        = has('syntax')
	if v:version < 704
		call s:WarningMsg('NrrwRgn needs Vim > 7.4 or it might not work correctly')
	endif
endfun

fun! <sid>SetupHooks() abort "{{{1
	if !exists("s:nrrw_aucmd")
		let s:nrrw_aucmd = {}
	endif
	if exists("b:nrrw_aucmd_create")
		let s:nrrw_aucmd["create"] = b:nrrw_aucmd_create
	endif
	if exists("b:nrrw_aucmd_close")
		let s:nrrw_aucmd["close"] = b:nrrw_aucmd_close
	endif
	if get(g:, 'nrrw_rgn_write_on_sync', 0)
		let b:nrrw_aucmd_written = get(b:, 'nrrw_aucmd_written', ''). '|:w'
	endif
endfun

fun! <sid>NrrwRgnWin(bang) abort "{{{1
	" Create new scratch window
	if has_key(s:nrrw_rgn_lines, s:instn) &&
		\ has_key(s:nrrw_rgn_lines[s:instn], 'multi')
		let bufname = 'multi'
	else
		let bufname = matchstr(substitute(expand('%:t:r'), ' ', '_', 'g'), '^.\{0,8}')
	endif
	let nrrw_winname = s:nrrw_winname. '_'. bufname . '_'. s:instn
	let nrrw_win = bufwinnr('^'.nrrw_winname.'$')
	if nrrw_win != -1
		exe ":noa ". nrrw_win. 'wincmd w'
		" just in case, a global nomodifiable was set
		" disable this for the narrowed window
		setl ma noro
		silent %d _
	else
		if !exists('g:nrrw_topbot_leftright')
			let g:nrrw_topbot_leftright = 'topleft'
		endif
		let nrrw_rgn_direction = (s:nrrw_rgn_vert ? 'vsp' : 'sp')
		if get(g:, 'nrrw_rgn_equalalways', &equalalways)
			let cmd=printf(':noa %s %s %s', g:nrrw_topbot_leftright,
										  \ nrrw_rgn_direction,
										  \ nrrw_winname)
		else
			let nrrw_rgn_size = (s:nrrw_rgn_vert ? winwidth(0) : winheight(0))/2
			let cmd=printf(':noa %s %d%s %s', g:nrrw_topbot_leftright,
											\ nrrw_rgn_size,
											\ nrrw_rgn_direction,
											\ nrrw_winname)
		endif
		if !a:bang
			exe cmd
		else
			try
				enew
				if bufexists(s:nrrw_winname. '_'. s:instn)
					" avoid E95
					exe 'bw' s:nrrw_winname. '_'. s:instn
				endif
				exe 'f' s:nrrw_winname. '_'. s:instn
			catch /^Vim\%((\a\+)\)\=:E37/	" catch error E37
				" Fall back and use a new window
				exe cmd
			endtry
		endif

		" just in case, a global nomodifiable was set
		" disable this for the narrowed window
		setl ma noro
		" Just in case
		silent %d _
		" Set up some options like 'bufhidden', 'noswapfile',
		" 'buftype', 'bufhidden', when enabling Narrowing.
		call <sid>NrrwSettings(1)
		let nrrw_win = bufwinnr("")
	endif
	" focus: target
	" set window variables
	let w:nrrw_rgn_id = s:instn
	let w:nrrw_rgn_id_type = s:window_type["target"]
	if !a:bang
		noa wincmd p
		" focus: source window
		let w:nrrw_rgn_id = s:instn
		let w:nrrw_rgn_id_type = s:window_type["source"]
		noa wincmd p
		" focus: target window
	endif
	" We are in the narrowed buffer now!
	return nrrw_win
endfun
fun! <sid>CleanRegions() abort "{{{1
	 let s:nrrw_rgn_line={}
	 unlet! s:nrrw_rgn_buf
endfun

fun! <sid>CompareNumbers(a1,a2) abort "{{{1
	return (a:a1+0) == (a:a2+0) ? 0 : (a:a1+0) > (a:a2+0) ? 1 : -1
endfun

fun! <sid>ParseList(dict) "{{{1
	" for a given list of line numbers, return those line numbers
	" in a format start:end for continous items, else [start, next]
	" returns a dict of dict: dict[buf][1]=[1,10], dict[buf][2]=[15,20]
	let outdict = {}
    let i=1
	let list = a:dict
	for buf in sort(keys(a:dict), (s:numeric_sort ? 'n' : '<sid>CompareNumbers'))
		let result = {}
		let start  = 0
		let temp   = 0
		let item   = 0
		for item in sort(list[buf], (s:numeric_sort ? 'n' : "<sid>CompareNumbers"))
			if start==0
				let start=item
			elseif temp!=item-1
				if has_key(result, i)
					let i+=1
				endif
				let result[i]=[start,temp]
				let start=item
			endif
			let temp=item
		endfor
		if empty(result)
			" add all items from the list to the result
			" list consists only of consecutive items
			let result[i] = [list[buf][0], list[buf][-1]]
		endif
		" Make sure the last item is included in the selection
		if get(result, i, 0)[0] && result[i][1] != item
			let i+=1
			let result[i]=[start,item]
		endif
		let outdict[buf] = result
		let i+=1
	endfor
	return outdict
endfun

fun! <sid>GoToWindow(buffer, instn, type) abort "{{{1
	" find correct window and switch to it
	" should be called from correct tab page
	for win in range(1,winnr('$'))
		exe ':noa '. win. 'wincmd w'
		if get(w:, 'nrrw_rgn_id', 0) == a:instn && get(w:, 'nrrw_rgn_id_type', -1) == a:type
			break
		endif
	endfor
	if bufnr('') == a:buffer
		return
	else
		exe ":noa ". a:buffer. "b"
	endif
endfun

fun! <sid>WriteNrrwRgn(...) abort "{{{1
	" if argument is given, write narrowed buffer back
	" else destroy the narrowed window
	let nrrw_instn = exists("b:nrrw_instn") ? b:nrrw_instn : s:instn
	if exists("b:orig_buf") && (bufwinnr(b:orig_buf) == -1) &&
		\ !<sid>BufInTab(b:orig_buf) &&
		\ !bufexists(b:orig_buf)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
	if exists("a:1") && a:1
		" Write the buffer back to the original buffer
		let _wsv = winsaveview()
		setl nomod
		exe ":WidenRegion"
		if bufname('') !~# 'NrrwRgn' && bufwinnr(s:nrrw_winname. '_'. s:instn) > 0
			exe ':noa'. bufwinnr(s:nrrw_winname. '_'. s:instn). 'wincmd w'
		endif
		" prevent E315
		call winrestview(_wsv)
	else
		call <sid>StoreLastNrrwRgn(nrrw_instn)
		" b:orig_buf might not exists (see issue #2)
		let winnr = (exists("b:orig_buf") ? bufwinnr(b:orig_buf) : 0)
		" Best guess
		if bufname('') =~# 'NrrwRgn' && winnr == -1 && exists("b:orig_buf") &&
					\ bufexists(b:orig_buf)
			exe ':noa '. b:orig_buf. 'b'
		elseif bufname('') =~# 'NrrwRgn' && winnr > 0
			exe ':noa'. winnr. 'wincmd w'
		endif
		" close narrowed buffer
		call <sid>NrrwRgnAuCmd(nrrw_instn)
	endif
endfun

fun! <sid>SaveRestoreRegister(values) abort "{{{1
	if empty(a:values)
		" Save
		let reg  =  ['a', getreg('a'), getregtype('a') ]
		let fold =  [ &fen, &l:fdm ]
		if &fen
			setl nofoldenable
		endif
		let visual = [getpos("'<"), getpos("'>")]
		return  [ reg, fold, visual ]
	else
		" Restore
		call call('setreg', a:values[0])
		if a:values[1][0]
			let [&l:fen, &l:fdm]=a:values[1]
		endif
		call setpos("'<", a:values[2][0])
		call setpos("'>", a:values[2][1])
	endif
endfun

fun! <sid>UpdateOrigWin() abort "{{{
	" Tries to keep the original windo in the same viewport, that
	" is currently being edited in the narrowed window
	if !get(g:, 'nrrw_rgn_update_orig_win', 0)
		return
	endif
	if bufname('') !~# 'NrrwRgn'
		return
	else
		let instn = b:nrrw_instn
	endif
	if !has_key(s:nrrw_rgn_lines[instn], 'multi')
		return
	endif
	if exists("b:orig_buf") && (bufwinnr(b:orig_buf) == -1) &&
		\ !<sid>BufInTab(b:orig_buf) &&
		\ !bufexists(b:orig_buf)
		" Buffer does not exists anymore (shouldn't happen)
		return
	endif
	let cur_win = winnr()
	try
		if !exists("b:nrrw_rgn_prev_pos")
			let b:nrrw_rgn_prev_pos = getpos(".")
		endif
		if b:nrrw_rgn_prev_pos[0] == line('.')
			return
		endif
		" Try to update the original window
		let start = search(' Start NrrwRgn\d\+', 'bcWn')
		if start == 0
			" not found
			return
		endif
		let region = matchstr(getline(start),
			\ ' Start NrrwRgn\zs\d\+\ze')+0
		let offset = line('.') - start
		exe ":noa" bufwinnr(b:orig_buf). 'wincmd w'
		let pos = s:nrrw_rgn_lines[instn].multi[region]
		if pos[0] + offset > pos[1]
			" safety check
			let offset = pos[1] - pos[0]
		endif
		call cursor(pos[0]+offset, pos[1])
		redraw
	finally
		exe ":noa" cur_win "wincmd w"
		let b:nrrw_rgn_prev_pos = getpos(".")
	endtry
endfun!

fun! <sid>SetupBufWriteCmd(instn) "{{{1
	if !exists("#NrrwRgn".a:instn."#BufWriteCmd#<buffer>")
		if s:debug
			echo "Setting up BufWriteCmd!"
		endif
		au BufWriteCmd <buffer> nested :call s:WriteNrrwRgn(1)
	endif
endfu
fun! <sid>SetupBufWinLeave(instn) "{{{1
	if !exists("#NrrwRgn".a:instn."#BufWinLeave#<buffer>") &&
	\ exists("b:orig_buf") && bufloaded(b:orig_buf)
		au BufWinLeave <buffer> :call s:NRBufWinLeave(b:nrrw_instn)
	endif
endfu
fun! <sid>NRBufWinLeave(instn) "{{{1
	let nrw_buf  = bufnr('')
	let orig_win = winnr()
	let instn    = a:instn
	let orig_buf = b:orig_buf
	let orig_tab = tabpagenr()
	call <sid>JumpToBufinTab(<sid>BufInTab(orig_buf), orig_buf, instn, s:window_type["source"])
	if !&modifiable
		set modifiable
	endif
	call s:DeleteMatches(instn)
	call <sid>JumpToBufinTab(orig_tab, nrw_buf, instn, s:window_type["target"])
endfu

fun! <sid>NrrwRgnAuCmd(instn) abort "{{{1
	" If a:instn==0, then enable auto commands
	" else disable auto commands for a:instn
	if !a:instn
		exe "aug NrrwRgn". b:nrrw_instn
		au!
		"au BufWriteCmd <buffer> nested :call s:WriteNrrwRgn(1)
		" don't clean up on BufWinLeave autocommand, that breaks
		" :b# and returning back to that buffer later (see issue #44)
		au BufWipeout,BufDelete <buffer> nested
					\ :call s:WriteNrrwRgn()
		au CursorMoved <buffer> :call s:UpdateOrigWin()
		" When switching buffer in the original buffer,
		" make sure the highlighting of the narrowed buffer will
		" be removed"
		call s:SetupBufWinLeave(b:nrrw_instn)
		call s:SetupBufWriteCmd(b:nrrw_instn)
		aug end
		au BufWinEnter <buffer> call s:SetupBufWriteCmd(b:nrrw_instn)
	else
		exe "aug NrrwRgn".  a:instn
		au!
		aug end
		exe "aug! NrrwRgn". a:instn

		if !has_key(s:nrrw_rgn_lines, a:instn)
			" narrowed buffer was already cleaned up
			call <sid>DeleteMatches(a:instn)
			call s:WarningMsg("Window was already cleaned up. Nothing to do.")
			return
		endif

		" make the original buffer modifiable, if possible
		let buf = s:nrrw_rgn_lines[a:instn].orig_buf
		if !getbufvar(buf, '&l:ma') && !getbufvar(buf, 'orig_buf_ro')
			call setbufvar(s:nrrw_rgn_lines[a:instn].orig_buf, '&ma', 1)
		endif

		if s:debug
			echo printf("bufnr: %d a:instn: %d\n", bufnr(''), a:instn)
			echo "bwipe " s:nrrw_winname. '_'. a:instn
		endif
		if (!has_key(s:nrrw_rgn_lines[a:instn], 'disable') ||
		\  (has_key(s:nrrw_rgn_lines[a:instn], 'disable') &&
		\	!s:nrrw_rgn_lines[a:instn].disable ))
			" Skip to original window and remove highlighting
			call <sid>GoToWindow(buf, a:instn, s:window_type["source"])
			call <sid>DeleteMatches(a:instn)
			unlet! w:nrrw_rgn_id w:nrrw_rgn_id_type
			call <sid>CleanUpInstn(a:instn)
		endif
	endif
endfun

fun! <sid>CleanUpInstn(instn) abort "{{{1
	if s:instn>=1 && has_key(s:nrrw_rgn_lines, a:instn)
		unlet s:nrrw_rgn_lines[a:instn]
		let s:instn-=1
	endif
endfu

fun! <sid>StoreLastNrrwRgn(instn) abort "{{{1
	" Only store the last region, when the narrowed instance is still valid
	if !has_key(s:nrrw_rgn_lines, a:instn)
		call <sid>WarningMsg("Error storing the last Narrowed Window, it's invalid!")
		return
	endif

	let s:nrrw_rgn_lines['last'] = []
	if !exists("b:orig_buf")
		let orig_buf = s:nrrw_rgn_lines[a:instn].orig_buf
	else
		let orig_buf = b:orig_buf
	endif
	if has_key(s:nrrw_rgn_lines[a:instn], 'multi')
		call add(s:nrrw_rgn_lines['last'], [ orig_buf,
			\ s:nrrw_rgn_lines[a:instn]['multi']])
	else
		" Linewise narrowed region, pretend it was done like a visual
		" narrowed region
		let s:nrrw_rgn_lines['last'] = [ [ orig_buf,
		\ s:nrrw_rgn_lines[a:instn].start[1:]],
		\ [ orig_buf, s:nrrw_rgn_lines[a:instn].end[1:]]]
		call add(s:nrrw_rgn_lines['last'],
					\ has_key(s:nrrw_rgn_lines[a:instn], 'vmode') ?
					\ s:nrrw_rgn_lines[a:instn].vmode : 'V')
	endif
endfu

fun! <sid>RetVisRegionPos() abort "{{{1
	let a = getpos("'<")
	let b = getpos("'>")
	let a[2] = virtcol("'<")
	let b[2] = virtcol("'>")
	return [a, b]
endfun

fun! <sid>GeneratePattern(startl, endl, mode) abort "{{{1
	" This is just a best guess, the highlighted block could still be wrong
	" There are basically two ways, highlighting works in block mode:
	"	1) only highlight the block
	"	2) highlighty from the beginnning until the end of lines (happens,
	"	   intermediate lines are shorter than block width)
	if exists("s:curswant") && s:curswant == 2147483647 &&
			\ a:startl[0] > 0 && a:startl[1] > 0 && a:mode ==# ''
		unlet! s:curswant
		return '\%>'. (a:startl[0]-1). 'l\&\%>'. (a:startl[1]-1).
			\ 'v\&\%<'. (a:endl[0]+1). 'l'
	elseif a:mode ==# '' && a:startl[0] > 0 && a:startl[1] > 0
		return '\%>'. (a:startl[0]-1). 'l\&\%>'. (a:startl[1]-1).
			\ 'v\&\%<'. (a:endl[0]+1). 'l\&\%<'. (a:endl[1]+1). 'v'
	elseif a:mode ==# 'v' && a:startl[0] > 0 && a:startl[1] > 0
		" Easy way: match within a line
		if a:startl[0] == a:endl[0]
			return '\%'.a:startl[0]. 'l\%>'.(a:startl[1]-1).'v.*\%<'.(a:endl[1]+1).'v'
		else
		" Need to generate concat 3 patterns:
		"  1) from startline, startcolumn till end of line
		"  2) all lines between startline and end line
		"  3) from start of endline until end column
		"
		" example: Start at line 1 col. 6 until line 3 column 12:
		" \%(\%1l\%>6v.*\)\|\(\%>1l\%<3l.*\)\|\(\%3l.*\%<12v\)
		return  '\%(\%'.  (a:startl[0]). 'l\%>'.   (a:startl[1]-1). 'v.*\)\|'.
			\	'\%(\%>'. (a:startl[0]). 'l\%<'.   (a:endl[0]).     'l.*\)\|'.
			\   '\%(\%'.  (a:endl[0]).   'l.*\%<'. (a:endl[1]+1).   'v\)'
		endif
	elseif a:startl[0] > 0
		return '\%>'. (a:startl[0]-1). 'l\&\%<'. (a:endl[0]+1). 'l'
	else
		return ''
	endif
endfun

fun! <sid>Options(search) abort "{{{1
	" return buffer local options (generated from $VIMRUNTIME/doc/options.txt

	return
	\ ['autoindent', 'autoread', 'balloonexpr', 'binary', 'bomb',
	\  'cindent', 'cinkeys', 'cinoptions', 'cinwords', 'commentstring',
	\  'complete', 'completefunc', 'copyindent', 'cryptmethod', 'define',
	\  'dictionary', 'endofline', 'equalprg', 'errorformat', 'expandtab',
	\  'fileencoding', 'filetype', 'formatoptions', 'formatlistpat',
	\  'formatexpr', 'iminsert', 'imsearch', 'include', 'includeexpr',
	\  'indentexpr', 'indentkeys', 'infercase', 'key', 'keymap', 'lisp',
	\  'makeprg', 'matchpairs', 'nrformats', 'omnifunc', 'osfiletype',
	\  'preserveindent', 'quoteescape', 'shiftwidth', 'shortname', 'smartindent',
	\  'softtabstop', 'spellcapcheck', 'spellfile', 'spelllang', 'suffixesadd',
	\  'synmaxcol', 'syntax', 'tabstop', 'textwidth', 'thesaurus', 'wrapmargin']

	" old function, only used to generate above list
	let c=[]
	let buf=bufnr('')
	try
		" empty search pattern
		if empty(a:search)
			return c
		endif
		silent noa sview $VIMRUNTIME/doc/options.txt
		" for whatever reasons $VIMRUNTIME/doc/options.txt
		" does not exist, return empty list
		if line('$') == 1
			return c
		endif
		keepj 0
		let reg_a=[]
		call add(reg_a, 'a')
		call add(reg_a,getreg('a'))
		call add(reg_a, getregtype('a'))
		let @a=''
		exe "silent :g/". '\v'.escape(a:search, '\\/'). "/-y A"
		let b=split(@a, "\n")
		call call('setreg', reg_a)
		"call setreg('a', reg_a[0], reg_a[1])
		call filter(b, 'v:val =~ "^''"')
		" the following options should be set
		let filter_opt='\%(modifi\%(ed\|able\)\|readonly\|swapfile\|'.
				\ 'buftype\|bufhidden\|foldcolumn\|buflisted\|undofile\)'
		call filter(b, 'v:val !~ "^''".filter_opt."''"')
		for item in b
			let item=substitute(item, '''', '', 'g')
			call add(c, split(item, '\s\+')[0])
		endfor
	finally
		if fnamemodify(bufname(''),':p') ==
			\expand("$VIMRUNTIME/doc/options.txt")
			noa bwipe
		endif
		exe "noa "	bufwinnr(buf) "wincmd  w"
		return c
	endtry
endfun

fun! <sid>GetOptions(opt) abort "{{{1
	if exists("g:nrrw_custom_options") && !empty(g:nrrw_custom_options)
		let result = g:nrrw_custom_options
	else
		let result={}
		for item in a:opt
			try
				exe "let result[item]=&l:".item
			catch
				" no-op, just silence the error
			endtry
		endfor
	endif
	return result
endfun

fun! <sid>SetOptions(opt) abort "{{{1
	if type(a:opt) == type({})
		for [option, result] in items(a:opt)
			exe "let &l:". option " = " string(result)
		endfor
	endif
	setl nomod noro
endfun

fun! <sid>CheckProtected() abort "{{{1
	" Protect the original window, unless the user explicitly defines not to
	" protect it
	if exists("g:nrrw_rgn_protect") && g:nrrw_rgn_protect =~? 'n'
		return
	endif
	let b:orig_buf_ro=0
	if !&l:ma || &l:ro
		let b:orig_buf_ro=1
		call s:WarningMsg("Buffer is protected, won't be able to write the changes back!")
	else
		" Protect the original buffer,
		" so you won't accidentally modify those lines,
		" that might later be overwritten
		setl noma
	endif
endfun

fun! <sid>HasMatchID(instn) abort "{{{1
	if exists("s:nrrw_rgn_lines[a:instn].matchid")
		let id = s:nrrw_rgn_lines[a:instn].matchid
		for val in getmatches()
			if match(id, val.id) > -1
				return 1
			endif
		endfor
	endif
	return 0
endfun

fun! <sid>DeleteMatches(instn) abort "{{{1
	if exists("s:nrrw_rgn_lines[a:instn].matchid")
		" if you call :NarrowRegion several times, without widening
		" the previous region, b:matchid might already be defined so
		" make sure, the previous highlighting is removed.
		for item in s:nrrw_rgn_lines[a:instn].matchid
			if item > 0
				" If the match has been deleted, discard the error
				try
					call matchdelete(item)
					call remove(s:nrrw_rgn_lines[a:instn].matchid, 0)
				catch
					" id not found ignore
				endtry
			endif
		endfor
	endif
endfun

fun! <sid>HideNrrwRgnLines() abort "{{{1
	let char1 = <sid>ReturnComments()[0]
	let char1 = escape(char1, '"\\')
	let cmd='syn match NrrwRgnStart "^'.char1.' Start NrrwRgn\d\+$"'
	exe cmd
	let cmd='syn match NrrwRgnEnd "^'.char1.' End NrrwRgn\d\+$"'
	exe cmd
	exe 'syn region NrrwRgn '.
		\ ' start="^\ze'. char1.' Start NrrwRgn"'.
		\ '  skip="'.char1.' Start NrrwRgn\(\d\+\)\_.\{-}End NrrwRgn\1$"'.
		\ '   end="^$" fold transparent'
	hi default link NrrwRgnStart Comment
	hi default link NrrwRgnEnd Comment
	setl fdm=syntax
endfun

fun! <sid>ReturnCommentFT() abort "{{{1
	if !empty(&l:commentstring)
		return substitute(&l:commentstring, '%s', ' ', '')
	else
		return "# "
	endif
endfun

fun! <sid>WidenRegionMulti(content, instn) abort "{{{1
	" for single narrowed windows, the original narrowed buffer will be closed,
	" so don't renew the highlighting and clean up (later in
	" nrrwrgn#WidenRegion)
	if empty(s:nrrw_rgn_lines[a:instn].multi)
		return
	endif
	" we are not yet in the correct buffer, start loading it
	let _hid  = &hidden
	set hidden
	let c_win = winnr()
	let c_buf = bufnr('')
	" let's pretend, splitting windows is always possible .... :(
	noa new
	let s_win = winnr()
	for buf in sort(keys(s:nrrw_rgn_lines[a:instn].multi), '<sid>CompareNumbers')
		exe "noa ". (buf+0). "b"
		let _list = []
		for item in ['ma', 'ro']
			call add(_list, printf("let &l:%s=%s", item, get(g:, '&l:'.item)))
		endfor
		setl ma noro
		let output= []
		let list  = []
		let [c_s, c_e] =  <sid>ReturnComments()
		let lastline = line('$')
		" We must put the regions back from top to bottom,
		" otherwise, changing lines in between messes up the
		" list of lines that still need to put back from the
		" narrowed buffer to the original buffer
		for key in sort(keys(s:nrrw_rgn_lines[a:instn].multi[buf]),
			\ (s:numeric_sort ? 'n' : "<sid>CompareNumbers"))
			let adjust   = line('$') - lastline
			let range    = s:nrrw_rgn_lines[a:instn].multi[buf][key]
			let last     = (len(range)==2) ? range[1] : range[0]
			let first    = range[0]
			let pattern  = printf("%s %%s %s %s %s%s", c_s, "NrrwRgn".key,
					\ "buffer:", simplify(bufname(buf+0)), c_e)
			let indexs   = index(a:content, printf(pattern, 'Start')) + 1
			let indexe   = index(a:content, printf(pattern, 'End')) - 1
			if indexs <= 0 || indexe < -1
				call s:WarningMsg("Skipping Region ". key)
				continue
			endif
			" Adjust line numbers. Changing the original buffer, might also 
			" change the regions we have remembered. So we must adjust these
			" numbers.
			" This only works, if we put the regions from top to bottom!
			let first += adjust
			let last  += adjust
			if last == line('$') &&  first == 1
				let delete_last_line=1
			else
				let delete_last_line=0
			endif
			exe ':silent :'. first. ','. last. 'd _'
			call append((first-1), a:content[indexs : indexe])
			" Recalculate the start and end positions of the narrowed window
			" so subsequent calls will adjust the region accordingly
			let  last = first + len(a:content[indexs : indexe]) - 1
			if last > line('$')
				let last = line('$')
			endif
			if !has_key(s:nrrw_rgn_lines[a:instn].multi, 'single')
				" original narrowed buffer is going to be closed
				" so don't renew the matches
				call <sid>AddMatches(<sid>GeneratePattern([first, 0 ],
							\ [last, 0], 'V'), a:instn)
			endif
			if delete_last_line
				silent! $d _
			endif
		endfor
		for item in _list
			exe item
		endfor
	endfor
	if !_hid
		set nohidden
	endif
	" remove scratch window
	exe ":noa ".s_win."wincmd c"
endfun

fun! <sid>AddMatches(pattern, instn) abort "{{{1
	if !s:nrrw_rgn_nohl || empty(a:pattern)
		if !exists("s:nrrw_rgn_lines[a:instn].matchid")
			let s:nrrw_rgn_lines[a:instn].matchid=[]
		endif
		call add(s:nrrw_rgn_lines[a:instn].matchid,
					\matchadd(s:nrrw_rgn_hl, a:pattern))
	endif
endfun

fun! <sid>BufInTab(bufnr) abort "{{{1
	" returns tabpage of buffer a:bufnr
	for tab in range(1,tabpagenr('$'))
		if !empty(filter(tabpagebuflist(tab), 'v:val == a:bufnr'))
			return tab
		endif
	endfor
	return 0
endfun

fun! <sid>JumpToBufinTab(tab,buf,instn,type) abort "{{{1
	" Type is s:window_type["source"] or s:window_type["target"] and checks for
	" w:nrrw_rgn_source_win or w:nrrw_rgn_target_win variable
	if a:tab && a:tab != tabpagenr()
		exe "noa tabn" a:tab
	endif
	call <sid>GoToWindow(a:buf, a:instn, a:type)
endfun

fun! <sid>RecalculateLineNumbers(instn, adjust) abort "{{{1
	" This only matters, if the original window isn't protected
	if !exists("g:nrrw_rgn_protect") || g:nrrw_rgn_protect !~# 'n'
		return
	endif

	for instn in filter(keys(s:nrrw_rgn_lines), 'v:val != a:instn')
		" Skip narrowed instances, when they are before
		" the region, we are currently putting back
		if s:nrrw_rgn_lines[instn].start[1] <=
		\ s:nrrw_rgn_lines[a:instn].start[1]
			" Skip this instn
			continue
		else
			let s:nrrw_rgn_lines[instn].start[1] += a:adjust
			let s:nrrw_rgn_lines[instn].end[1]   += a:adjust

			if s:nrrw_rgn_lines[instn].start[1] < 1
				let s:nrrw_rgn_lines[instn].start[1] = 1
			endif
			if s:nrrw_rgn_lines[instn].end[1] < 1
				let s:nrrw_rgn_lines[instn].end[1] = 1
			endif
			call <sid>DeleteMatches(instn)
			call <sid>AddMatches(<sid>GeneratePattern(
				\s:nrrw_rgn_lines[instn].start[1:2],
				\s:nrrw_rgn_lines[instn].end[1:2],
				\'V'), instn)
		endif
	endfor
endfun

fun! <sid>NrrwSettings(on) abort "{{{1
	if a:on
		setl noswapfile buftype=acwrite foldcolumn=0
		setl nobuflisted
		let instn = matchstr(bufname(''), '_\zs\d\+$')+0
		if has_key(s:nrrw_rgn_lines, s:instn)
			if  !&hidden && !has_key(s:nrrw_rgn_lines[instn], "single")
				setl bufhidden=wipe
			else
				setl bufhidden=delete
			endif
		endif
	else
		setl swapfile buftype= bufhidden= buflisted
	endif
endfun

fun! <sid>SetupBufLocalCommands() abort "{{{1
	com! -buffer -bang WidenRegion :call nrrwrgn#WidenRegion(<bang>0)
	com! -buffer NRSyncOnWrite  :call nrrwrgn#ToggleSyncWrite(1)
	com! -buffer NRNoSyncOnWrite :call nrrwrgn#ToggleSyncWrite(0)
endfun

fun! <sid>SetupBufLocalMaps(bang) abort "{{{1
	if !hasmapto('<Plug>NrrwrgnWinIncr', 'n')
		nmap <buffer> <Leader><Space> <Plug>NrrwrgnWinIncr
	endif
	if !hasmapto('NrrwRgnIncr')
		nmap <buffer><unique> <Plug>NrrwrgnWinIncr NrrwRgnIncr
	endif
	nnoremap <buffer><silent><script><expr> NrrwRgnIncr <sid>ToggleWindowSize()
	if a:bang && winnr('$') == 1
		" Map away :q and :q! in single window mode, so that :q won't
		" accidently quit vim.
		cabbr <buffer> q  <c-r>=(getcmdtype()==':'&&getcmdpos()==1 ? ':bd' : ':q')<cr>
		cabbr <buffer> q! <c-r>=(getcmdtype()==':'&&getcmdpos()==1 ? ':bd!' : ':q!')<cr>
	endif
endfun

fun! <sid>NrrwDivNear(n, d) abort "{{{1
	let m = a:n % a:d
	let q = a:n / a:d
	let r = m*2 >= a:d ? 1 : 0
	return q + r
endfun

fun! <sid>NrrwDivCeil(n, d) abort "{{{1
	let q = a:n / a:d
	let r = q*a:d == a:n ? 0 : 1
	return q + r
endfun

fun! <sid>IsAbsPos(pos) abort "{{{1
	if s:syntax
		return a:pos =~ '^\%(to\%[pleft]\|bo\%[tright]\)$'
	else
		return len(a:pos) >= 2 && ('topleft' =~ '^' . a:pos || 'botright' =~ '^' . a:pos)
	endif
endfun

fun! <sid>GetTotalSizesFromID(id) abort "{{{1
	let sizes = [0,0]
	let l:count = 0
	for window in range(1, winnr('$'))
		let nrrw_rgn_id = getwinvar(window, 'nrrw_rgn_id', 0)
		if nrrw_rgn_id == a:id
			let sizes[0] += winwidth(window)
			let sizes[1] += winheight(window)
			let l:count += 1
		endif
	endfor
	if l:count < 1 || l:count > 2
		throw "Invalid NrrwRgn window ID count of '" . l:count . "'"
	endif
	return sizes
endfun

fun! <sid>GetTotalSizes(window) abort "{{{1
	let nrrw_rgn_id = getwinvar(a:window, 'nrrw_rgn_id', 0)
	if nrrw_rgn_id > 0
		return <sid>GetTotalSizesFromID(nrrw_rgn_id)
	else
		throw "Expected NrrwRgn window ID"
	endif
endfun

fun! <sid>GetRelVSizes(window, lines) abort "{{{1
	if <sid>IsAbsPos(get(g:, 'nrrw_topbot_leftright', ''))
		let lines_parent = &lines
	else
		let lines_parent = <sid>GetTotalSizes(a:window)[1]
	endif
	if s:float
		let nrrw_rgn_rel_max = get(g:, 'nrrw_rgn_rel_max', 80)/100.0
		let nrrw_rgn_rel_min = get(g:, 'nrrw_rgn_rel_min', 10)/100.0
		let ratio = 1.0*a:lines/lines_parent
		if ratio < nrrw_rgn_rel_min
			let ratio = nrrw_rgn_rel_min
		elseif ratio > nrrw_rgn_rel_max
			let ratio = nrrw_rgn_rel_max
		endif
		let size_max = min([lines_parent, float2nr(ceil(nrrw_rgn_rel_max*lines_parent))])
		let size_min = min([lines_parent, float2nr(ceil(nrrw_rgn_rel_min*lines_parent))])
		let size_tgt = min([lines_parent, float2nr(ceil(ratio*lines_parent))])
	else
		let nrrw_rgn_rel_max = get(g:, 'nrrw_rgn_rel_max', 80)
		let nrrw_rgn_rel_min = get(g:, 'nrrw_rgn_rel_min', 10)
		let percentage = <sid>NrrwDivNear(a:lines*100, lines_parent)
		if percentage < nrrw_rgn_rel_min
			let percentage = nrrw_rgn_rel_min
		elseif percentage > nrrw_rgn_rel_max
			let percentage = nrrw_rgn_rel_max
		endif
		let size_max = min([lines_parent, <sid>NrrwDivCeil(nrrw_rgn_rel_max*lines_parent, 100)])
		let size_min = min([lines_parent, <sid>NrrwDivCeil(nrrw_rgn_rel_min*lines_parent, 100)])
		let size_tgt = min([lines_parent, <sid>NrrwDivCeil(percentage*lines_parent, 100)])
	endif
	let size_alt = (size_tgt >= size_max ? size_min : size_max)
	return [size_tgt, size_alt]
endfun

fun! <sid>GetRelHSizes(window) abort "{{{1
	if <sid>IsAbsPos(get(g:, 'nrrw_topbot_leftright', ''))
		let columns_parent = &columns
	else
		let columns_parent = <sid>GetTotalSizes(a:window)[0]
	endif
	let nrrw_rgn_rel_max = get(g:, 'nrrw_rgn_rel_max', 80)
	let nrrw_rgn_rel_min = get(g:, 'nrrw_rgn_rel_min', 50)
	if s:float
		let size_max = min([columns_parent, float2nr(ceil(nrrw_rgn_rel_max/100.0*columns_parent))])
		let size_min = min([columns_parent, float2nr(ceil(nrrw_rgn_rel_min/100.0*columns_parent))])
	else
		let size_max = min([columns_parent, <sid>NrrwDivCeil(nrrw_rgn_rel_max*columns_parent, 100)])
		let size_min = min([columns_parent, <sid>NrrwDivCeil(nrrw_rgn_rel_min*columns_parent, 100))])
	endif
	return [size_min, size_max]
endfun

fun! <sid>GetRelSizes(window, lines) abort "{{{1
	return (s:nrrw_rgn_vert ? <sid>GetRelHSizes(a:window) : <sid>GetRelVSizes(a:window, a:lines))
endfun

fun! <sid>GetAbsVSizes(window, lines) abort "{{{1
	let nrrw_rgn_incr = get(g:, 'nrrw_rgn_incr', 10)
	if s:nrrw_rgn_wdth > 0
		let size_min = min([s:nrrw_rgn_wdth, a:lines])
	else
		let size_min = winheight(a:window)
	endif
	let size_max = size_min + nrrw_rgn_incr
	return [size_min, size_max]
endfun

fun! <sid>GetAbsHSizes(window) abort "{{{1
	let nrrw_rgn_incr = get(g:, 'nrrw_rgn_incr', 10)
	if s:nrrw_rgn_wdth > 0
		let size_min = s:nrrw_rgn_wdth
	else
		let size_min = winwidth(a:window)
	endif
	let size_max = size_min + nrrw_rgn_incr
	return [size_min, size_max]
endfun

fun! <sid>GetAbsSizes(window, lines) abort "{{{1
	return (s:nrrw_rgn_vert ? <sid>GetAbsHSizes(a:window) : <sid>GetAbsVSizes(a:window, a:lines))
endfun

fun! <sid>GetSizes(window, lines) abort "{{{1
	let nrrw_rgn_absolute = get(g:, 'nrrw_rgn_resize_window', 'absolute') is? "absolute" ? 1 : 0
	return (nrrw_rgn_absolute ? <sid>GetAbsSizes(a:window, a:lines) : <sid>GetRelSizes(a:window, a:lines))
endfun

fun! <sid>ResizeWindow(size) abort "{{{1
	let prefix = (s:nrrw_rgn_vert ? ':vert ': ''). ':resize'
	let cmd = printf("%s %d", prefix, a:size)
	return cmd
endfu

fun! <sid>ToggleWindowSize() abort "{{{1
	" Should only be called from the narrowed window!
	" assumes a narrowed window is currently focused
	if has_key(s:nrrw_rgn_lines[b:nrrw_instn], 'single') && s:nrrw_rgn_lines[b:nrrw_instn].single
		call <sid>WarningMsg("Resizing window for single windows not supported!")
		return ''
	endif
	let nrrw_rgn_pad = get(g:, 'nrrw_rgn_pad', 0)
	let [size_tgt, size_alt] = <sid>GetSizes(winnr(), line('$') + nrrw_rgn_pad)
	let size_cur = (s:nrrw_rgn_vert ? winwidth(0) : winheight(0))
	let size_new = (size_cur == size_tgt ? size_alt : size_tgt)
	return <sid>ResizeWindow(size_new)."\n"
endfun

fun! <sid>AdjustWindowSize(bang) abort "{{{1
	" initial window sizes
	" assumes a narrowed window is currently focused
	if !a:bang
		let nrrw_rgn_pad = get(g:, 'nrrw_rgn_pad', 0)
		let size_new = <sid>GetSizes(winnr(), line('$') + nrrw_rgn_pad)[0]
		exe <sid>ResizeWindow(size_new)
	endif
endfun

fun! <sid>ReturnComments() abort "{{{1
	let cmt = <sid>ReturnCommentFT()
	let c_s = split(cmt)[0]
	let c_e = (len(split(cmt)) == 1 ? "" : " ". split(cmt)[1])
	return [c_s, c_e]
endfun

fun! nrrwrgn#NrrwRgnDoMulti(...) abort "{{{1
	let bang = (a:0 > 0 && !empty(a:1))
	if !exists("s:nrrw_rgn_line")
		call <sid>WarningMsg("You need to first select the lines to".
			\ " narrow using :NRP!")
		return
	endif
	if empty(s:nrrw_rgn_line) && !exists("s:nrrw_rgn_buf")
		call <sid>WarningMsg("No lines selected from :NRP, aborting!")
		return
	endif
	if !exists("s:nrrw_rgn_buf")
		let s:nrrw_rgn_buf =  <sid>ParseList(s:nrrw_rgn_line)
	endif
	if empty(s:nrrw_rgn_buf)
		call <sid>WarningMsg("An error occured when selecting all lines. Please report as bug")
		unlet s:nrrw_rgn_buf
		return
	endif
	let o_lz = &lz
	set lz
	let orig_buf=bufnr('')

	" initialize Variables
	call <sid>Init()
	call <sid>CheckProtected()
	let s:nrrw_rgn_lines[s:instn].start		= []
	let s:nrrw_rgn_lines[s:instn].end		= []
	let s:nrrw_rgn_lines[s:instn].multi     = s:nrrw_rgn_buf
	let s:nrrw_rgn_lines[s:instn].orig_buf  = orig_buf
	call <sid>DeleteMatches(s:instn)

	let nr=0
	let lines=[]
	let buffer=[]

	for buf in sort(keys(s:nrrw_rgn_buf), (s:numeric_sort ? 'n' : "<sid>CompareNumbers"))
		if buf !=? bufnr('%')
			exe ":noa " . buf. "b"
		endif
		let keys = keys(s:nrrw_rgn_buf[buf])
		call sort(keys, (s:numeric_sort ? 'n' : "<sid>CompareNumbers"))
		"for [ nr,lines] in items(s:nrrw_rgn_buf)
		let [c_s, c_e] =  <sid>ReturnComments()
		for nr in keys
			let lines = s:nrrw_rgn_buf[buf][nr]
			let start = lines[0]
			let end   = len(lines)==2 ? lines[1] : lines[0]
			if !bang
				call <sid>AddMatches(<sid>GeneratePattern([start,0],
					\ [end,0], 'V'), s:instn)
			endif
			call add(buffer, c_s.' Start NrrwRgn'.nr.' buffer: '.simplify(bufname("")).c_e)
			let buffer = buffer +
					\ getline(start,end) +
					\ [c_s.' End NrrwRgn'.nr. ' buffer: '.
					\ simplify(bufname("")).c_e, '']
		endfor
	endfor
	if bufnr('') !=# orig_buf
		" switch back to buffer, where we started
		exe ":noa ". orig_buf. "b"
	endif

	let local_options = <sid>GetOptions(s:opts)
	let win=<sid>NrrwRgnWin(bang)
	if bang
		let s:nrrw_rgn_lines[s:instn].single = 1
	endif
	let b:orig_buf = orig_buf
	call setline(1, buffer)
	call <sid>AdjustWindowSize(bang)
	setl nomod
	let b:nrrw_instn = s:instn
	call <sid>SetupBufLocalCommands()
	call <sid>SetupBufLocalMaps(bang)
	call <sid>NrrwRgnAuCmd(0)
	call <sid>SetOptions(local_options)
	call <sid>CleanRegions()
	call <sid>HideNrrwRgnLines()

	" restore settings
	let &lz   = o_lz
endfun

fun! nrrwrgn#NrrwRgn(mode, ...) range  abort "{{{1
	let visual = !empty(a:mode)
	" a:mode is set when using visual mode
	if visual
	" This beeps, when called from command mode
	" e.g. by using :NRV, so using :sil!
	" else exiting visual mode
		if s:getcurpos && a:mode ==# ''
			" This is an ugly hack, since there does not seem to be a
			" possibility to find out, if we  are in block-wise '$' mode or
			" not (try pressing '$' in block-wise mode)
			if !hasmapto('let s:curswant', 'v')
				xmap <expr> <Plug>NrrwrgnGetCurswant ":\<c-u>let s:curswant=".getcurpos()[4]."\n"
			endif
			" Reselect visual mode
			exe ":norm gv\<Plug>NrrwrgnGetCurswant"
		else
			exe "sil! norm! \<ESC>"
		endif
	endif
	let bang = (a:0 > 0 && !empty(a:1))
	let o_lz = &lz
	set lz
	call <sid>Init()
	if visual
		let s:nrrw_rgn_lines[s:instn].vmode=a:mode
	endif
	" Protect the original buffer,
	" so you won't accidentally modify those lines,
	" that will later be overwritten
	let orig_buf=bufnr('')
	let _opts = <sid>SaveRestoreRegister([])

	call <sid>CheckProtected()
	if visual
		let [ s:nrrw_rgn_lines[s:instn].start,
			\ s:nrrw_rgn_lines[s:instn].end ] = <sid>RetVisRegionPos()
		norm! gv"ay
		if len(split(@a, "\n", 1)) !=
			\ (s:nrrw_rgn_lines[s:instn].end[1] -
			\ s:nrrw_rgn_lines[s:instn].start[1] + 1)
			" remove trailing "\n"
			let @a=substitute(@a, '\n$', '', '')
		endif
		let a = split(@a, "\n")
	else
		let first = a:firstline
		let last  = a:lastline
		let s:nrrw_rgn_lines[s:instn].start = [ 0, first, 0, 0 ]
		let s:nrrw_rgn_lines[s:instn].end	= [ 0, last , 0, 0 ]
		let a=getline(s:nrrw_rgn_lines[s:instn].start[1],
			\ s:nrrw_rgn_lines[s:instn].end[1])
	endif
	call <sid>DeleteMatches(s:instn)
	let local_options = <sid>GetOptions(s:opts)
	let win=<sid>NrrwRgnWin(bang)
	if bang
		let s:nrrw_rgn_lines[s:instn].single = 1
	else
		" Set the highlighting
		noa wincmd p
		" Set highlighting in original window
		call <sid>AddMatches(<sid>GeneratePattern(
			\s:nrrw_rgn_lines[s:instn].start[1:2],
			\s:nrrw_rgn_lines[s:instn].end[1:2],
			\(visual ? s:nrrw_rgn_lines[s:instn].vmode : 'V')),
			\s:instn)
		if _opts[1][0]
			" reset folding
			setl foldenable
			let &l:fdm=_opts[1][1]
		endif
		" move back to narrowed window
		noa wincmd p
	endif
	let b:orig_buf = orig_buf
	let s:nrrw_rgn_lines[s:instn].orig_buf  = orig_buf
	call setline(1, a)
	call <sid>AdjustWindowSize(bang)
	let b:nrrw_instn = s:instn
	setl nomod
	call <sid>SetupBufLocalCommands()
	call <sid>SetupBufLocalMaps(bang)
	call <sid>NrrwRgnAuCmd(0)
	call <sid>SetOptions(local_options)
	if has_key(s:nrrw_aucmd, "create")
		exe s:nrrw_aucmd["create"]
	endif
	if has_key(s:nrrw_aucmd, "close")
		let b:nrrw_aucmd_close = s:nrrw_aucmd["close"]
	endif
	call <sid>SaveRestoreRegister(_opts)

	" restore settings
	let &lz   = o_lz
endfun
fun! nrrwrgn#Prepare(bang) abort "{{{1
	if !exists("s:nrrw_rgn_line") || !empty(a:bang)
		let s:nrrw_rgn_line={}
		if !empty(a:bang)
			return
		endif
	endif
	if !has_key(s:nrrw_rgn_line, bufnr('%'))
		let s:nrrw_rgn_line[bufnr('%')] = []
	endif
	call add(s:nrrw_rgn_line[bufnr('%')], line('.'))
endfun

fun! nrrwrgn#WidenRegion(force)  abort "{{{1
	" a:force: original narrowed window is going to be closed
	" so, clean up, don't renew highlighting, etc.
	let nrw_buf  = bufnr('')
	let orig_buf = b:orig_buf
	let orig_tab = tabpagenr()
	let instn    = b:nrrw_instn
	" Make sure the narrowed buffer is still valid (happens, when 2 split
	" window of the narrowed buffer is opened.
	if !has_key(s:nrrw_rgn_lines, instn)
		call <sid>WarningMsg("Error writing changes back,".
					\ "Narrowed Window invalid!")
		return
	endif
	let winnr    = winnr()
	let close    = has_key(s:nrrw_rgn_lines[instn], 'single')
	let vmode    = has_key(s:nrrw_rgn_lines[instn], 'vmode')
	" Save current state
	let nr = changenr()
	" Execute autocommands
	if has_key(s:nrrw_aucmd, "close")
		exe s:nrrw_aucmd["close"]
	endif
	let cont	 = getline(1,'$')
	if has_key(s:nrrw_aucmd, "close") && nr != changenr()
		" Restore buffer contents before the autocommand
		" (in case the window isn't closed, the user sees
		" the correct input)
		exe "undo" nr
	endif

	if !has_key(s:nrrw_rgn_lines[instn], 'multi')
		" <sid>WidenRegionMulti does take care of loading the correct buffer!
		call <sid>JumpToBufinTab(<sid>BufInTab(orig_buf), orig_buf, instn, s:window_type["source"])
		let orig_win = bufwinnr(orig_buf)
		" Should be in the right tab now!
		if (orig_win == -1)
			if bufexists(orig_buf)
				" buffer not in current window, switch to it!
				exe "noa" orig_buf "b!"
				" Make sure highlighting will be removed
				let close = (&g:hid ? 0 : 1)
			else
				call s:WarningMsg("Original buffer does no longer exist! Aborting!")
				return
			endif
		else
			exe ':noa'. orig_win. 'wincmd w'
		endif
		" Removing matches only works in the right window. So need to check,
		" the matchid actually exists, if not, try to remove it later.
		if <sid>HasMatchID(instn)
			call <sid>DeleteMatches(instn)
		endif
		if exists("b:orig_buf_ro") && b:orig_buf_ro && !a:force
			call s:WarningMsg("Original buffer protected. Can't write changes!")
			call <sid>JumpToBufinTab(orig_tab, nrw_buf, instn, s:window_type["target"])
			return
		endif
		if !&l:ma && !(exists("b:orig_buf_ro") && b:orig_buf_ro)
			setl ma
		endif
	endif
	let _opts = <sid>SaveRestoreRegister([])
	let wsv=winsaveview()
	" This is needed to adjust all other narrowed regions
	" in case we have several narrowed regions within the same buffer
	if exists("g:nrrw_rgn_protect") && g:nrrw_rgn_protect =~? 'n'
		let  adjust_line_numbers = len(cont) - 1 - (
					\s:nrrw_rgn_lines[instn].end[1] -
					\s:nrrw_rgn_lines[instn].start[1])
	endif

	" Now copy the content back into the original buffer
	" 1) Check: Multiselection
	if has_key(s:nrrw_rgn_lines[instn], 'multi')
		call <sid>WidenRegionMulti(cont, instn)
	" 2) Visual Selection
	elseif vmode
		"charwise, linewise or blockwise selection
		call setreg('a', join(cont, "\n"). "\n",
					\ s:nrrw_rgn_lines[instn].vmode)
		if s:nrrw_rgn_lines[instn].vmode == 'v' &&
			\ s:nrrw_rgn_lines[instn].end[1] -
			\ s:nrrw_rgn_lines[instn].start[1] + 1 == len(cont)
			" in characterwise selection, remove trailing \n
			call setreg('a', substitute(@a, '\n$', '', ''), 'v')
		endif
		" settable '< and '> marks
		let _v = []
		" store actual values
		let _v = [getpos("'<"), getpos("'>"), [visualmode(1)]]
		" set the mode for the gv command
		exe "norm! ". s:nrrw_rgn_lines[instn].vmode."\<ESC>"
		call setpos("'<", s:nrrw_rgn_lines[instn].start)
		call setpos("'>", s:nrrw_rgn_lines[instn].end)
		exe 'norm! gv"aP'
		if !empty(_v[2][0]) && (_v[2][0] != visualmode())
			exe 'norm!' _v[2][0]. "\<ESC>"
			call setpos("'<", _v[0])
			call setpos("'>", _v[1])
		endif
		" Recalculate the start and end positions of the narrowed window
		" so subsequent calls will adjust the region accordingly
		let [ s:nrrw_rgn_lines[instn].start,
			\s:nrrw_rgn_lines[instn].end ] = <sid>RetVisRegionPos()
		" make sure the visual selected lines did not add a new linebreak,
		" this messes up the characterwise selected regions and removes lines
		" on further writings
		if s:nrrw_rgn_lines[instn].end[1] - s:nrrw_rgn_lines[instn].start[1]
				\ + 1 >	len(cont) && s:nrrw_rgn_lines[instn].vmode == 'v'
			let s:nrrw_rgn_lines[instn].end[1] =
				\ s:nrrw_rgn_lines[instn].end[1] - 1
			let s:nrrw_rgn_lines[instn].end[2] = virtcol('$')
		endif

		" also, renew the highlighted region
		" only highlight, if we are in a different window
		" then where we started, else we might accidentally
		" set a match in the narrowed window (might happen if the
		" user typed Ctrl-W o in the narrowed window)
		if !(has_key(s:nrrw_rgn_lines[instn], 'single') || winnr != winnr())
			call <sid>AddMatches(<sid>GeneratePattern(
				\ s:nrrw_rgn_lines[instn].start[1:2],
				\ s:nrrw_rgn_lines[instn].end[1:2],
				\ s:nrrw_rgn_lines[instn].vmode),
				\ instn)
		endif
	" 3) :NR started selection
	else
		" linewise selection because we started the NarrowRegion with the
		" command NarrowRegion(0)
		"
		" if the endposition of the narrowed buffer is also the last line of
		" the buffer, the append will add an extra newline that needs to be
		" cleared.
		if s:nrrw_rgn_lines[instn].end[1]==line('$') &&
		\  s:nrrw_rgn_lines[instn].start[1] == 1
			let delete_last_line=1
		else
			let delete_last_line=0
		endif
		exe ':silent :'.s:nrrw_rgn_lines[instn].start[1].','
			\.s:nrrw_rgn_lines[instn].end[1].'d _'
		call append((s:nrrw_rgn_lines[instn].start[1]-1),cont)
		" Recalculate the start and end positions of the narrowed window
		" so subsequent calls will adjust the region accordingly
		" so subsequent calls will adjust the region accordingly
		let  s:nrrw_rgn_lines[instn].end[1] =
			\ s:nrrw_rgn_lines[instn].start[1] + len(cont) -1
		if s:nrrw_rgn_lines[instn].end[1] > line('$')
			let s:nrrw_rgn_lines[instn].end[1] = line('$')
		endif
		" only highlight, if we are in a different window
		" then where we started, else we might accidentally
		" set a match in the narrowed window (might happen if the
		" user typed Ctrl-W o in the narrowed window)
		if !(has_key(s:nrrw_rgn_lines[instn], 'single') || winnr != winnr())
			call <sid>AddMatches(<sid>GeneratePattern(
				\s:nrrw_rgn_lines[instn].start[1:2],
				\s:nrrw_rgn_lines[instn].end[1:2],
				\'V'),
				\instn)
		endif
		if delete_last_line
			silent! $d _
		endif
	endif
	" Recalculate start- and endline numbers for all other Narrowed Windows.
	" This matters, if you narrow different regions of the same file and
	" write your changes back.
	if exists("g:nrrw_rgn_protect") && g:nrrw_rgn_protect =~? 'n'
		call <sid>RecalculateLineNumbers(instn, adjust_line_numbers)
	endif
"	if close && !has_key(s:nrrw_rgn_lines[instn], 'single')
		" For narrowed windows that have been created using !,
		" don't clean up yet, or else we loose all data and can't write
		" it back later.
		" (e.g. :NR! createas a new single window, do :sp
		"  and you can only write one of the windows back, the other will
		"  become invalid, if CleanUp is executed)
"	endif
	call <sid>SaveRestoreRegister(_opts)
	" Execute "written" autocommands in the original buffer
	if exists("b:nrrw_aucmd_written")
		exe b:nrrw_aucmd_written
	endif
	call winrestview(wsv)
	"if !close && has_key(s:nrrw_rgn_lines[instn], 'single')
	if has_key(s:nrrw_rgn_lines[instn], 'single')
		" move back to narrowed buffer
		noa b #
	"elseif close
	"	call <sid>CleanUpInstn(instn)
	endif
	let bufnr = bufnr('')
	" jump back to narrowed window
	call <sid>JumpToBufinTab(orig_tab, nrw_buf, instn, s:window_type["target"])
	if bufnr('') != bufnr
		" do not set the original buffer unmodified
		setl nomod
	endif
	if a:force
		" trigger auto command
		bw
	endif
endfun

fun! nrrwrgn#UnifiedDiff() abort "{{{1
	let save_winposview=winsaveview()
	let orig_win = winnr()
	" close previous opened Narrowed buffers
	silent! windo | if bufname('')=~'^NrrwRgn' &&
			\ &diff |diffoff|q!|endif
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
		noa wincmd H
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

fun! nrrwrgn#ToggleSyncWrite(enable) abort "{{{1
	let s:nrrw_rgn_lines[b:nrrw_instn].disable = !a:enable
	" Enable syncing of bufers
	if a:enable
		" Enable Narrow settings and autocommands
		call <sid>NrrwSettings(1)
		call <sid>NrrwRgnAuCmd(0)
		setl modified
	else
		" Disable Narrow settings and autocommands
		call <sid>NrrwSettings(0)
		" b:nrrw_instn should always be available
		call <sid>NrrwRgnAuCmd(b:nrrw_instn)
	endif
endfun

fun! nrrwrgn#LastNrrwRgn(bang) abort "{{{1
	let bang = !empty(a:bang)
	if !exists("s:nrrw_rgn_lines") || !has_key(s:nrrw_rgn_lines, 'last')
		call <sid>WarningMsg("There is no last region to re-select")
		return
	endif
	let orig_buf = s:nrrw_rgn_lines['last'][0][0] + 0
	let tab = <sid>BufInTab(orig_buf)
	if tab != tabpagenr() && tab > 0
		exe "tabn" tab
	endif
	let orig_win = bufwinnr(orig_buf)
	" Should be in the right tab now!
	if (orig_win == -1)
		call s:WarningMsg("Original buffer does no longer exist! Aborting!")
		return
	endif
	if orig_win != winnr()
		exe "noa" orig_win "wincmd w"
	endif
	if len(s:nrrw_rgn_lines['last']) == 1
		" Multi Narrowed
		let s:nrrw_rgn_buf =  s:nrrw_rgn_lines['last'][0][1]
		call nrrwrgn#NrrwRgnDoMulti('')
	else
		exe "keepj" s:nrrw_rgn_lines['last'][0][1][0]
		exe "keepj norm!" s:nrrw_rgn_lines['last'][0][1][1]. '|'
		" Start visual mode
		exe "keepj norm!" s:nrrw_rgn_lines['last'][2]
		exe "keepj" s:nrrw_rgn_lines['last'][1][1][0]
		if col(s:nrrw_rgn_lines['last'][1][1][1]) == col('$') &&
		\ s:nrrw_rgn_lines['last'][2] == ''
			" Best guess
			exe "keepj $"
		else
			exe "keepj norm!" s:nrrw_rgn_lines['last'][1][1][1]. '|'
		endif
		" Call VisualNrrwRgn()
		call nrrwrgn#NrrwRgn(visualmode(), bang)
	endif
endfu
fun! nrrwrgn#NrrwRgnStatus() abort "{{{1
	if !exists("b:nrrw_instn")
		return {}
	else
		let dict={}
		try
			let cur = deepcopy(s:nrrw_rgn_lines[b:nrrw_instn])
			if has_key(cur, 'multi')
				let multi = cur.multi
			else
				let multi = []
			endif
			let dict.shortname = bufname('')
			let bufname=bufname(cur.orig_buf)
			if !empty(bufname)
				let dict.fullname  = fnamemodify(expand(bufname(cur.orig_buf)),':p')
			else
				let dict.fullname  = '[No Name]' " vim default
			endif
			let dict.multi     = has_key(cur, 'multi')
			if has_key(cur, 'multi')
				let end = keys(multi[1])[-1]
				let dict.startl= map(copy(multi), 'v:val[1][0]')
				let dict.endl  = map(copy(multi), 'v:val[end][1]')
			else
				let dict.start = cur.start
				let dict.end   = cur.end
			endif
			let dict.matchid   = cur.matchid
			let dict.visual    = has_key(cur, 'vmode') ? cur.vmode : ''
			let dict.enabled   = has_key(cur, 'disable') ? (cur.disable ? 0 : 1) : 1
			let dict.instn     = b:nrrw_instn
			unlet cur
		catch
			" oh oh, something is wrong...
			let dict={}
		endtry
		lockvar dict
		return dict
	endif
endfu

" Debugging options "{{{1
fun! nrrwrgn#Debug(enable) abort "{{{2
	if (a:enable)
		let s:debug=1
		fun! <sid>NrrwRgnDebug() abort "{{{2
			"sil! unlet s:instn
			com! NI :call <sid>WarningMsg("Instance: ".s:instn)
			com! NJ :call <sid>WarningMsg("Data: ".string(s:nrrw_rgn_lines))
			com! -nargs=1 NOutput :if exists("s:".<q-args>)|redraw!|
						\ :exe 'echo s:'.<q-args>|else|
						\ echo "s:".<q-args>. " does not exist!"|endif
		endfun
		call <sid>NrrwRgnDebug()
	else
		let s:debug=0
		delf <sid>NrrwRgnDebug
		delc NI
		delc NJ
		delc NOutput
	endif
endfun

" Modeline {{{1
" vim: noet ts=4 sts=4 fdm=marker com+=l\:\" fdl=0
doc/NarrowRegion.txt	[[[1
792
*NrrwRgn.txt*   A Narrow Region Plugin (similar to Emacs)

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.33 Thu, 15 Jan 2015 20:52:29 +0100
Copyright: (c) 2009-2015 by Christian Brabandt
           The VIM LICENSE applies to NrrwRgnPlugin.vim and NrrwRgnPlugin.txt
           (see |copyright|) except use NrrwRgnPlugin instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.

==============================================================================
1. Contents                                    *NarrowRegion*  *NrrwRgnPlugin*

        1.  Contents.....................................: |NrrwRgnPlugin|
        2.  NrrwRgn Manual...............................: |NrrwRgn-manual|
        2.1   NrrwRgn Howto..............................: |NR-HowTo|
        2.2   NrrwRgn Multi..............................: |NR-multi-example|
        2.3   NrrwRgn Configuration......................: |NrrwRgn-config|
        2.4   NrrwRgn public functions...................: |NrrwRgn-func|
        3.  NrrwRgn Tips.................................: |NrrwRgn-tips|
        4.  NrrwRgn Feedback.............................: |NrrwRgn-feedback|
        5.  NrrwRgn History..............................: |NrrwRgn-history|

==============================================================================
2. NrrwRgn Manual                                       *NrrwRgn-manual*

Functionality

This plugin is based on a discussion in comp.editors (see the thread at
http://groups.google.com/group/comp.editors/browse_frm/thread/0f562d97f80dde13)

Narrowing means focussing on a region and making the rest inaccessible. You
simply select the region, call |:NarrowRegion| and the selected part will open
in a new scratch buffer. The rest of the file will be protected, so you won't
accidentally modify that buffer. In the new buffer, you can do a global
replace, search or anything else to modify that part. When you are finished,
simply write that buffer (e.g. by |:w|) and your modifications will be put in
the original buffer making it accessible again. Use |:q!| or |:bw!| to abort
your changes and return back to the original window.

NrrwRgn allows you to either select a line based selection using an Ex-command
or you can simply use any visual selected region and press your preferred key
combination to open that selection in a new buffer.

This plugin defines the following commands:

                                                        *:NarrowRegion* *:NR*
:[range]NR[!]
:[range]NarrowRegion[!]     When [range] is omitted, select only the current
                            line, else use the lines in the range given and
                            open it in a new Scratch Window.
                            If the current line is selected and is on a folded
                            region, select the whole folded text.
                            Whenever you are finished modifying that region
                            simply write the buffer.
                            If ! is given, open the narrowed buffer not in a
                            split buffer but in the current window.

                                                        *:NarrowWindow* *:NW*
:NW[!]
:NarrowWindow[!]            Select only the range that is visible the current
                            window and open it in a new Scratch Window.
                            Whenever you are finished modifying that region
                            simply write the buffer.
                            If ! is given, open the narrowed buffer not in a
                            split buffer but in the current window (works best
                            with 'hidden' set).

                                                                *:WidenRegion*
:WidenRegion[!]             This command is only available in the narrowed
                            scratch window. If the buffer has been modified,
                            the contents will be put back on the original
                            buffer. If ! is specified, the window will be
                            closed, otherwise it will remain open.

                                                                        *:NRV*
:NRV[!]                     Opened the narrowed window for the region that was
                            last selected in visual mode
                            If ! is given, open the narrowed buffer not in a
                            split buffer but in the current window (works best
                            with 'hidden' set).

                                                                        *:NUD*

:NUD                        When viewing unified diffs, this command opens
                            the current chunk in 2 Narrowed Windows in
                            |diff-mode| The current chunk is determined as the
                            one, that the cursor is at. This command does not
                            make sense if editing a different file format (or
                            even different diff format)

                                                                  *:NRPrepare*
:[range]NRPrepare[!]
:[range]NRP[!]              You can use this command, to mark several lines
                            that will later be put into a Narrowed Window
                            using |:NRM|.
                            If the ! is used, all earlier selected lines will
                            be cleared first.

                                                                  *:NRMulti*
:NRMulti
:NRM[!]                     This command takes all lines, that have been
                            marked by |:NRP| and puts them together in a new
                            narrowed buffer.
                            When you write your changes back, all separate
                            lines will be put back at their origin.
                            This command also clears the list of marked lines,
                            that was created with |NRP|.
                            See also |NR-multi-example|.
                            If ! is given, open the narrowed buffer not in a
                            split buffer but in the current window (works best
                            with 'hidden' set).

                                                    *:NRSyncOnWrite* *:NRS*
:NRSyncOnWrite
:NRS                        Enable synching the buffer content back to the
                            original buffer when writing.
                            (this is the default).

                                                    *:NRNoSyncOnWrite* *:NRN*
:NRNoSyncOnWrite
:NRN                        Disable synching the buffer content back to the
                            original buffer when writing. When set, the
                            narrowed buffer behaves like an ordinary buffer
                            that you can write in the filesystem.
                            (this is the default).
                            Note: You can still use |:WidenRegion| to write
                            the changes back to the original buffer.

                                                                    *:NRL*

:NRL[!]                     Reselect the last selected region again and open
                            in a narrowed window.
                            If ! is given, open the narrowed buffer not in a
                            split buffer but in the current window (works best
                            with 'hidden' set).


2.1 NrrwRgn HowTo                                                *NR-HowTo*
-----------------

Use the commands provided above to select a certain region to narrow. You can
also start visual mode and have the selected region being narrowed. In this
mode, NarrowRegion allows you to block select |CTRL-V| , character select |v|
or linewise select |V| a region. Then press <Leader>nr where <Leader> by
default is set to '\', unless you have set it to something different (see
|<Leader>| for information how to change this) and the selected range will
open in a new scratch buffer. This key combination only works in |Visual-mode|
If instead of <Leader>nr you use <Leader>Nr in visual mode, the selection will
be opened in the current window, replacing the original buffer.

(Alternatively, you can use the normal mode mapping <Leader>nr and the region
over which you move will be opened in a new Narrowed window).

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
chunk, run |:NUD| and the 2 Narrowed Windows in diff mode will update.

2.2 NrrwRgn Multi                                    *NR-multi-example*
-----------------

Using the commands |:NRP| and |:NRM| allows to select a range of lines, that
will be put into a narrowed buffer together. This might sound confusing, but
this allows to apply a filter before making changes. For example before
editing your config file, you decide to strip all comments for making big
changes but when you write your changes back, these comments will stay in your
file. You would do it like this: >
    :v/^#/NRP
    :NRMulti
<
Now a Narrowed Window will open, that contains only the configuration lines.
Each block of independent region will be separated by a string like

# Start NarrowRegion1
.....
# End NarrowRegion1

This is needed, so the plugin later knows, which region belongs where in the
original place. Blocks you don't want to change, you can safely delete, they
won't be written back into your original file. But other than that, you
shouldn't change those separating lines.

When you are finished, simply write your changes back.

==============================================================================

2.3 NrrwRgn Configuration                                    *NrrwRgn-config*
-------------------------

NarrowRegion can be customized by setting some global variables. If you'd
like to open the narrowed window as a vertical split buffer, simply set the
variable g:nrrw_rgn_vert to 1 in your |.vimrc| >

    let g:nrrw_rgn_vert = 1
<
(default: 0)
------------------------------------------------------------------------------

If you'd like to specify a certain width/height for you scratch buffer, then
set the variable g:nrrw_rgn_wdth in your |.vimrc| . This variable defines the
height or the nr of columns, if you have also set g:nrrw_rgn_vert. >

    let g:nrrw_rgn_wdth = 30
<
(default: 20)

Note: if the newly created narrowed window is smaller than this, it will be
resized to fit (plus an additional padding that can be specified using the
g:nrrw_rgn_pad variable (default: 0), to not leave unwanted space around (not
for single narrowed windows, e.g. when the '!' attribute was used).

------------------------------------------------------------------------------

Resizing the narrowed window can happen either by some absolute values or by a
relative percentage. The variable g:nrrw_rgn_resize_window determines what
kind of resize will occur. If it is set to "absolute", the resizing will be
done by absolute lines or columns (depending on whether a horizontal or
vertical split has been done). If it is set to "relative" the window will be
resized by a percentage.  Set it like this in your |.vimrc| >

    let g:nrrw_rgn_resize_window = 'absolute'
<
(default: absolute)

The percentages for increasing the window size can further be specified by
seting the following variables:

default:
g:nrrw_rgn_rel_min: 10 (50 for vertical splits)
g:nrrw_rgn_rel_max: 80

------------------------------------------------------------------------------

It is possible to specify an increment value, by which the narrowed window can
be increased. This is allows to easily toggle between the normal narrowed
window size and an even increased size (think of zooming). 

You can either specify a relative or absolute zooming value. An absolute
resize will happen, if the variable g:nrrw_rgn_resize_window is set to
"absolute" or it is unset (see above).

If absolute resizing should happen you have to either specify columns, if the
Narrowed window is a vertical split window or lines, if a horizontal split has
been done.

Example, to increase the narrowed window by 30 lines or columns if
(g:nrrw_rgn_vert is also set [see above]), set in your |.vimrc| >

    let g:nrrw_rgn_incr = 30
<
(default: 10, if g:nrrw_rgn_resize_window is "absolute")

Note: When using the '!' attribute for narrowing (e.g. the selection will be
opened in a new window that takes the complete screen size), no resizeing will
happen
------------------------------------------------------------------------------

If you'd like to change the key combination that toggles incrementing the
Narrowed Window size, you can put this in your |.vimrc| >

   nmap <F3> <Plug>NrrwrgnWinIncr
<
(default: <Leader><Space>)

This will let you use the <F3> key to toggle the window size of the Narrowed
Window. Note: This mapping is only in the narrowed window active.

The amount of how much to increase can be further refined by setting the
g:nrrw_rgn_incr for an absolute increase of by setting the variables
g:nrrw_rgn_rel_min and g:nrrw_rgn_rel_max

Whether an absolute or relative increase will be performed, is determined by
the g:nrrw_rgn_resize_window variable (see above).
------------------------------------------------------------------------------

By default, NarrowRegion highlights the region that has been selected
using the WildMenu highlighting (see |hl-WildMenu|). If you'd like to use a
different highlighting, set the variable g:nrrw_rgn_hl to your preferred
highlighting Group. For example to have the region highlighted like a search
result, you could put that in your |.vimrc| >

    let g:nrrw_rgn_hl = 'Search'
<
(default: WildMenu)

If you want to turn off the highlighting (because this can be distracting), you
can set the global variable g:nrrw_rgn_nohl to 1 in your |.vimrc| >

    let g:nrrw_rgn_nohl = 1
<
(default: 0)
------------------------------------------------------------------------------

If you'd like to change the key combination that starts the Narrowed Window
for your selected range, you could put this in your |.vimrc| >

   xmap <F3> <Plug>NrrwrgnDo
<
This will let <F3> open the Narrow-Window, but only if you have pressed it in
Visual Mode. It doesn't really make sense to map this combination to any other
mode, unless you want it to Narrow your last visually selected range.

(default: <Leader>nr)
------------------------------------------------------------------------------

If you'd like to specify the options that you want to have set for the
narrowed window, you can set the g:nrrw_custom_options setting, in your
|.vimrc| e.g. >

   let g:nrrw_custom_options={}
   let g:nrrw_custom_options['filetype'] = 'python'
>
This will only apply those options to the narrowed buffer. You need to take
care that all options you need will apply.

------------------------------------------------------------------------------

If you don't like that your narrowed window opens above the current window,
define the g:nrrw_topbot_leftright variable to your taste, e.g. >

  let g:nrrw_topbot_leftright = 'botright'
<
Now, all narrowed windows will appear below the original window. If not
specified, the narrowed window will appear above/left of the original window.

(default: topleft)
------------------------------------------------------------------------------

If you want to use several independent narrowed regions of the same buffer
that you want to write at the same time, protecting the original buffer is not
really useful. Therefore, set the g:nrrw_rgn_protect variable, e.g. in your
|.vimrc| >

   let g:nrrw_rgn_protect = 'n'
<
This can be useful if you diff different regions of the same file, and want
to be able to put back the changes at different positions. Please note that
you should take care not to change any part that will later be influenced
when writing the narrowed region back.

Note: Don't use overlapping regions! Your changes will probably not be put
back correctly and there is no guard against losing data accidentally. NrrwRgn
tries hard to adjust the highlighting and regions as you write your changes
back into the original buffer, but it can't guarantee that this will work and
might fail silently. Therefore, this feature is experimental!

(default: y)
------------------------------------------------------------------------------

If you are using the |:NRMulti| command and want to have the original window
update to the position of where the cursor is in the narrowed window, you can
set the variable g:nrrw_rgn_update_orig_win, e.g. in your |.vimrc| >

   let g:nrrw_rgn_update_orig_win = 1
<
Now the cursor in the original window will always update when the position
changes in the narrowed window (using a |CursorMoved| autocommand).
Note: that this might slow down scrolling and cursor movement a bit.

(default: 0)
------------------------------------------------------------------------------

By default, NarrowRegion plugin defines the two mappings <Leader>nr in visual
mode and normal mode and <Leader>Nr only in visual mode. If you have your own
mappings defined, than NarrowRegion will complain about the key already being
defined. Chances are, this will be quite annoying to you, so you can disable
mappings those keys by defining the following variables in your |.vimr| >

  :let g:nrrw_rgn_nomap_nr = 1
  :let g:nrrw_rgn_nomap_Nr = 1

(default: 0)
----------------------------------------------------------------------------
                                                 *NrrwRgn-hook*  *NR-hooks*

NarrowRegion can execute certain commands, when creating the narrowed window
and when closing the narrowed window. For this, you can set 2 buffer-local
variables that specify what commands to execute, which will hook into the
execution of the Narrow Region plugin.

For example, suppose you have a file, containing columns separated data (CSV
format) which you want to modify and you also have the CSV filetype plugin
(http://www.vim.org/scripts/script.php?script_id=2830) installed and you want
to modify the CSV data which should be visually arranged like a table in the
narrowed window.

Therefore you want the command |:ArrangeColumn| to be executed in the new
narrowed window upon entering it, and when writing the changes back, you want
the command |:UnArrangeColumn| to be executed just before putting the
changes back. So you set those two variables in your original buffer: >

    let b:nrrw_aucmd_create = "set ft=csv|%ArrangeCol"
    let b:nrrw_aucmd_close  = "%UnArrangeColumn"
<
This will execute the commands in the narrowed window: >

    :set ft=csv
    :%ArrangeCol

and before writing the changes back, it'll execute: >

    :%UnArrangeCol

Note: These hooks are executed in the narrowed window (i.e. after creating the
narrowed window and its content and before writing the changes back to the
original buffer).

A third hook 'b:nrrw_aucmd_written' is provided, when the data is written back
in the original window. This allows to execute scripts, whenever the data is
written back in the original window. For example, consider you want to write
the original buffer whenever the narrowed window is written back to the
original window. You can therefore set: >
    
    :let b:nrrw_aucmd_written = ':update'
<
This will write the original buffer, whenever it was modified after writing
the changes from the narrowed window back.

2.4 NrrwRgn functions                                    *NrrwRgn-func*
---------------------
The NrrwRgn plugin defines a public function in its namespace that can be used
to query its status.
                                                        *nrrwrgn#NrrwRgnStatus()*
nrrwrgn#NrrwRgnStatus()
    Returns a dict with the following keys:
        'shortname':    The displayed buffer name
        'fullname':     The complete buffer name of the original buffer
        'multi':        1 if it is a multi narrowed window (|:NRMulti|),
                        0 otherwise.
        'startl':       List of start lines for a multi narrowed window
                        (only present, if 'multi' is 1)
        'endl':         List of end lines for a multi narrowed window
                        (only present, if 'multi' is 1)
        'start':        Start position (only present if 'multi' is 0)
        'end':          End position (only present if 'multi' is 0)
        'visual':       Visual Mode, if it the narrowed window was started
                        from a visual selected region (empty otherwise).
        'enabled':      Whether syncing the buffer is enabled (|:NRS|)
                            
    If not executed in a narrowed window, returns an empty dict.
=============================================================================
3. NrrwRgn Tips                                           *NrrwRgn-tips*

To have the filetype in the narrowed window set, you can use this function: >

  command! -nargs=* -bang -range -complete=filetype NN
              \ :<line1>,<line2> call nrrwrgn#NrrwRgn('',<q-bang>)
              \ | set filetype=<args>
<
This lets you select a region, call :NN sql and the selected region will get
the sql filetype set.

(Contributed by @fourjay, thanks!)

=============================================================================
4. NrrwRgn Feedback                                        *NrrwRgn-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3075

You can also follow the development of the plugin at github:
http://github.com/chrisbra/NrrwRgn

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

If you like the plugin, write me an email (look in the third line for my mail
address). And if you are really happy, vote for the plugin and consider
looking at my Amazon whishlist: http://www.amazon.de/wishlist/2BKAHE8J7Z6UW

=============================================================================
5. NrrwRgn History                                          *NrrwRgn-history*

0.34: (unreleased) {{{1
- merge Github Pull #34 (https://github.com/chrisbra/NrrwRgn/pull/34, by
  Pyrohh, thanks!)
- resize narrowed window to actual size, this won't leave the a lot of 
  empty lines in the narrowed window.
- don't switch erroneously to the narrowed window on writing
  (https://github.com/chrisbra/NrrwRgn/issues/35, reported by Yclept Nemo
  thanks!)
- Always write the narrowed scratch window back on |:w| instead of only when
  it was modified (https://github.com/chrisbra/NrrwRgn/issues/37, reported by
  Konfekt, thanks!)
- Do not resize window, if :NR! was used (patch by leonidborisenko from
  https://github.com/chrisbra/NrrwRgn/pull/38 thanks!)
- Various improvements for Window resizing, partly by Yclept Nemo, thanks!
- Fixed error for undefined function and cursor movement in wrong window
  (issue https://github.com/chrisbra/NrrwRgn/issues/42 reported by adelarsq,
  thanks!)
- Don't set the original buffer to be modified in single-window mode (issue
  https://github.com/chrisbra/NrrwRgn/issues/43, reported by agguser, thanks!)
- Don't clean up on BufWinLeave autocommand, so that switching buffers will
  not destroy the BufWriteCmd (issue https://github.com/chrisbra/NrrwRgn/issues/44,
  reported by agguser, thanks!)
- remove highlighting after closing narrowed buffer
  (also issue https://github.com/chrisbra/NrrwRgn/issues/45,
  reported by Serabe, thanks!)
- do not map <Leader>nr and <Leader>Nr if g:nrrw_rgn_nomap_<key> is set
  (issue https://github.com/chrisbra/NrrwRgn/issues/52, reported by
  digitalronin, thanks!)
- correctly highlight in block-wise visual mode, if '$' has been pressed.

0.33: Jan 16, 2015 {{{1
- set local options later, so that FileType autocommands don't trigger to
  early
- make sure, shortening the buffer name handles multibyte characters
  correctly.
- new public function |nrrwrgn#NrrwRgnStatus()|
- <Leader>nr also mapped as operator function (so the region over which you
  move will be opened in the narrowed window
- highlighting wrong when char-selecting within a line
- needs Vim 7.4
- mention how to abort the narrowed window (suggested by David Fishburn,
  thanks!)
- Execute hooks after the options for the narrowed window have been set
  (issue #29, reported by fmorales, thanks!)
- <Leader><Space> Toggles the Narrowed Window Size (idea by David Fishburn,
  thanks!)
- New hook b:nrrw_aucmd_written, to be executed, whenever the narrowed info
  has been written back into the original buffer.
- g:nrrw_rgn_write_on_sync is being deprecated in favor of using the newly
  "written" hook
- error on writing back multi narrowed window (issue #30, reported by
  aleprovencio https://github.com/chrisbra/NrrwRgn/issues/30, thanks!)
- document autoresize function (g:nrrw_rgn_autoresize_win)
- error when calling Incr Function, Make it override over global mapping.
  (issue #31, reported by zc he https://github.com/chrisbra/NrrwRgn/issues/31, thanks!)
- |:NRP| didn't work as documented (reported by David Fishburn, thanks!)
- fix small syntax error in autoload file (issue #32, reported by itchyny
  (https://github.com/chrisbra/NrrwRgn/issues/32, thanks!)
- check, that dict key is available before accessing it (issue #33, reported by SirCorion
  (https://github.com/chrisbra/NrrwRgn/issues/33, thanks!)

0.32: Mar 27, 2014 {{{1
- hooks could corrupt the narrowed buffer, if it wasn't closed (reported by
  jszakemeister https://github.com/chrisbra/NrrwRgn/issues/19, thanks!)
- Don't parse $VIMRUNTIME/doc/options.txt for finding out buffer-local options
  (reported by AguirreIF https://github.com/chrisbra/NrrwRgn/issues/21,
  thanks!), instead include a fix set of option names to set when opening the
  narrowed buffer.
- Switching buffers in the original narrowed buffer, may confuse NrrwRgn.
- Code cleanup (no more separate functions for visual and normal mode)
- fix issue 22 (characterwise narrowing was brocken in last commit, reported
  by Matthew Boehm in https://github.com/chrisbra/NrrwRgn/issues/22, thanks!)
- in characterwise visual selection, trailing \n is not stripped when writing
  (reported by Matthew Boehm in https://github.com/chrisbra/NrrwRgn/23,
  thanks!)
- highlighting was wrong for characterwise visual selections
- update original window for multi narrowed regions (
  https://github.com/chrisbra/NrrwRgn/24, reported by Dane Summers, thanks!),
  use the g:nrrw_rgn_update_orig_win variable to enable
- error when narrowed window was moved to new tab and trying to quit
  (https://github.com/chrisbra/NrrwRgn/2, reported by Mario Ricalde, thanks!)
- better default names for the narrowed window
  (https://github.com/chrisbra/Nrrwrgn/28, reported by Mario Ricalde, thanks!)
- when setting g:nrrw_rgn_write_on_sync the original file will be saved,
  whenever the narrowed window is written back
  (https://github.com/chrisbra/26, reported by Mario Ricalde, thanks!)
- Some more error handling when using |:WidenRegion|
- Make sure highlighting is removed when using |:WidenRegion|

0.31: Feb 16, 2013 {{{1
- NRM threw some errors (reported by pydave in
  https://github.com/chrisbra/NrrwRgn/issues/17, thanks!)
- don't create swapfiles (reported by ping, thanks!)

0.30: Jan 25, 2013 {{{1
- |NRL| throws erros, when used without having first narrowed a region
- |NRV!| not allowed (reported by ping, thanks!)
- when using single window narrowing, :w would jump back to the original
  window. Only do this, when 'hidden' is not set (reported by ping, thanks!)
- when narrowing a region, the last visual selected region wasn't correctly
  restored (reported by ping, thanks!)
- some code cleanup
- recursive narrowing was broken, fix it (reported by ping, thanks!)

0.29: Aug 20, 2012 {{{1
- Use ! to have the narrowed buffer not opened in a new window (suggested by
  Greg Sexton thanks!, issue #8
  https://github.com/chrisbra/NrrwRgn/issues/8)
- Fix mappings for visual mode (https://github.com/chrisbra/NrrwRgn/issues/9,
  reported by Sung Pae, thanks!)
- Fix problem with setting the filetype
  (https://github.com/chrisbra/NrrwRgn/issues/10, reported by Hong Xu,
  thanks!)
- Fix some minor problems, when using ! mode
0.28: Jun 03, 2012 {{{1
- Plugin did not store last narrowed region when narrowed window was moved to
  another tabpage (reported by Ben Fritz, thanks!)

0.27: May 17, 2012 {{{1
- When using |:NR| on a line that is folded, include the whole folded region
  in the Narrowed window.
- Better filetype detection for comments
- Error handling, when doing |:NRM| without doing |:NRP| first
- Use |:NRP!| to clear the old selection
- Don't load the autoload script when sourcing the plugin script
  (reported by Sergey Khorev, thanks!)
- Vim 7.3.449 introduced E855, prevent this error.
- |:NRL|
- |NRM| did not correctly parse the list of lines provided by |:NRP|
- highlighted pattern for blockwise visual narrowed regions was wrong
- Saving blockwise visual selected regions back, could corrupt the contents

0.26: Jan 02, 2012 {{{1

- Fix issue https://github.com/chrisbra/NrrwRgn/issues/7
  (reported by Alessio B., thanks!)


0.25: Nov 08, 2011 {{{1

- updated documentation (patch by Jean, thanks!)
- make it possible, to not sync the narrowed buffer back by disabling
  it using |:NRSyncOnWrite| |:NRNoSyncOnWrite|

0.24: Oct 24, 2011 {{{1

- error on vim.org page, reuploaded version 0.22 as 0.24

0.23: Oct 24, 2011 {{{1

- (wrongly uploaded to vim.org)

0.22: Oct 24, 2011 {{{1

- Allow customization via the use of hooks (|NR-hooks|)

0.21: July 26, 2011 {{{1

- Fix undefined variable adjust_line_numbers
  https://github.com/chrisbra/NrrwRgn/issues/5 (reported by jmcantrell,
  thanks!)

0.20: July 25, 2011 {{{1
- allow customization via the g:nrrw_topbot_leftright variable (Thanks Herbert
  Sitz!)
- allow what options will be applied using the g:nrrw_custom_options dict
  (suggested by Herbert Sitz. Thanks!)
- NRV didn't hightlight the region that was selected (reported by Herbert
  Sitz, thanks!)
- use the g:nrrw_rgn_protect variable, to prevent that the original buffer
  will be protected. This is useful, if you narrow several regions of the same
  buffer and want to write those changes indepentently (reported by kolyuchiy
  in https://github.com/chrisbra/NrrwRgn/issues/3, Thanks!)
- fix an error with not correctly deleting the highlighted region, that was
  discovered when reporting issue 3 (see above). (Reported by kolyuchiy,
  thanks!)
- Catch errors, when setting window local options. (Patch by Sung Pae,
  Thanks!)

0.19: May 22, 2011 {{{1
- fix issue 2 from github https://github.com/chrisbra/NrrwRgn/issues/2
  (Widening does not work, if the narrowed windows have been moved to a new
  tabspace). Reported by vanschelven, thanks!

0.18: December 10, 2010 {{{1
- experimental feature: Allow to Narrow several different regions at once
  using :g/pattern/NRP and afterwards calling :NRM
  (This only works linewise. Should that be made possible for any reagion?)
- disable folds, before writing changes back, otherwise chances are, you'll
  lose more data then wanted
- code cleanup

0.17: November 23, 2010 {{{1
- cache the options, that will be set (instead of parsing
  $VIMRUNTIME/doc/options.txt every time) in the Narrowed Window
- getting the options didn't work, when using an autocommand like this:
  autocmd BufEnter * cd %:p:h
  (reported by Xu Hong, Thanks!)
- :q didn't clean up the Narrowed Buffer correctly. Fix this
- some code cleanup

0.16: November 16, 2010 {{{1
- Bugfix: copy all local options to the narrowed window (reported by Xu Hong,
  Thanks!)

0.15: August 26, 2010 {{{1
- Bugfix: minor documentation update (reported by Hong Xu, Thanks!)

0.14: August 26, 2010 {{{1
- Bugfix: :only in the original buffer resulted in errors (reported by Adam
  Monsen, Thanks!)

0.13: August 22, 2010 {{{1
- Unified Diff Handling (experimental feature)

0.12: July 29, 2010 {{{1

- Version 0.11, wasn't packaged correctly and the vimball file
  contained some garbage. (Thanks Dennis Hostetler!)

0.11: July 28, 2010 {{{1

- Don't set 'winfixwidth' and 'winfixheight' (suggested by Charles Campbell)

0.10: May 20, 2010 {{{1

- Restore cursor position using winrestview() and winsaveview()
- fix a bug, that prevented the use of visual narrowing
- Make sure when closing the narrowed buffer, the content will be written to
  the right original region
- use topleft for opening the Narrowed window
- check, that the original buffer is still available
- If you Narrow the complete buffer using :NRV and write the changes back, an
  additional trailing line is inserted. Remove that line.
- When writing the changes back, update the highlighting.

0.9: May 20, 2010 {{{1

- It is now possible to Narrow a window recursively. This allows to have
  several narrowed windows, and allows for example to only diff certain
  regions (as was suggested in a recent thread at the vim_use mailinglist:
  http://groups.google.com/group/vim_use/msg/05d7fd9bd1556f0e) therefore, the
  use for the g:nrrw_rgn_sepwin variable isn't necessary anymore.
- Small documentation updates

0.8: May 18, 2010 {{{1

- the g:nrrw_rgn_sepwin variable can be used to force separate Narrowed
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

0.7: May 17, 2010 {{{1

- really use the black hole register for deleting the old buffer contents in
  the narrowed buffer (suggestion by esquifit in
  http://groups.google.com/group/comp.editors/msg/3eb3e3a7c68597db)
- make autocommand nesting, so the highlighting will be removed when writing
  the buffer contents.
- Use g:nrrw_rgn_nohl variable to disable highlighting (as this can be
  disturbing).

0.6: May 04, 2010 {{{1

- the previous version had problems restoring the orig buffer, this version
  fixes it (highlighting and setl ma did not work correctly)

0.5: May 04, 2010 {{{1

- The mapping that allows for narrowing a visually selected range, did not
  work.  (Fixed!)
- Make :WidenRegion work as expected (close the widened window) (unreleased)

0.4: Apr 28, 2010 {{{1

- Highlight narrowed region in the original buffer
- Save and Restore search-register
- Provide shortcut commands |:NR|
- Provide command |:NW| and |:NarrowWindow|
- Make plugin autoloadable
- Enable GLVS (see |:GLVS|)
- Provide Documenation (:h NarrowRegion)
- Distribute Plugin as vimball |pi_vimball.txt|

0.3: Apr 28, 2010 {{{1

- Initial upload
- development versions are available at the github repository
- put plugin on a public repository (http://github.com/chrisbra/NrrwRgn)

  }}}
==============================================================================
Modeline:
vim:tw=78:ts=8:ft=help:et:fdm=marker:fdl=0:norl
