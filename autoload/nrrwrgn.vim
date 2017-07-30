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
	if !hasmapto('<sid>ToggleWindowSize')
		nnoremap <buffer><unique><script><silent><expr> <Plug>NrrwrgnWinIncr <sid>ToggleWindowSize()
	endif
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
