" ==============================================================================
" 3-30-12: cleanup, fixed many
"
"
" 3-26-12: tested on Ubuntu
" 			added autochdir
" 			added <F11>; "SaveSession()"
" 3-22-12: fixed the highlight disappearing after auto loading info
" 			enabled autoloading/autosaving; See the comment about how to setup
" 			this on WinXP
" 			added/changed F12; "SaveSessionAs()"
" 3-21-12: fixed cursor jumping after marking using 'm'
" 			extended ShowMarks function to outside, for the reason below
" 			added example of auto session+marks loading/saving
" 3-21-12: moved (activated) <F2> key mapping.
" 			made the marker tag shorter by '>'
"
" This is definitely a copy of sowmarks.vim, modified, crude
"  For now, it works similar to MS utilities
"
" Desire to configure to (the effort is shown at the end of this file):
" ^<F2>: toggle a bookmark
" <F2>: goto next bookmark
" shift-<F2>: goto prev. bookmark
" ^-shift-<F2>: clear all bookmark
" all other marker command: as it was (like m, ', `, and etc.)
"
" Functions:
"		ShowMarksToggle: Toggles a bookmark at the cursor line
"		ShowMarksClearAll: Clears all bookmarks
"		ShowMarks: To show the bookmarks, for initial loading
"       
" ==============================================================================

" Check if we should continue loading
if exists( "loaded_showmarks" )
	finish
endif
let loaded_showmarks = 1

" Bail if Vim isn't compiled with signs support.
if has( "signs" ) == 0
	echohl ErrorMsg
	echo "ShowMarks requires Vim to have +signs support."
	echohl None
	finish
endif

" ==============================================================================
" Options
"                showmarks_ignore_type (Default: "hq")
"                   Defines the buffer types to be ignored.
"                   Valid types are:
"                     h - Help            p - preview
"                     q - quickfix        r - readonly
"                     m - non-modifiable
if !exists('g:showmarks_ignore_type' ) | let g:showmarks_ignore_type  = "hq" | endif

"List of mark characters, A..Z are global
""abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.'`^<>[]{}()\""
let s:marks_global = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
let s:marks_buffer = "abcdefghijklmnopqrstuvwxyz"
let s:marks_all = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
let s:n_marks_all = strlen(s:marks_all)
let s:n_marks_global = strlen(s:marks_global)
let s:n_marks_buffer = strlen(s:marks_buffer)
"let b:last_mark = -1

let s:usc = '_'

" Highlight color
" Another might be in the _RecallSession(), take a look
hi default BookmarkCol_line ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold
hi default BookmarkCol_text ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold



" ==============================================================================

fun! s:place_a_mark(mark, line)
	"echo 'buffer name is ' bufname("%")
	let bfnm = winbufnr(0)
	let sgnm = 'SMARK_'.bfnm.'_'.a:line

	"sign is per file??
	"let id = n + (s:n_marks_all * winbufnr(0)) 	"sign is per file??
	let sid = a:line


	let s:testx = 1
	let s:smark_list{bfnm}{s:usc}{a:mark} = a:line
	let s:smark_list{bfnm}{s:usc}{a:line} = a:mark

"echo 'place_a_mark, Buffer name is ' bfnm
"echo 'line=' s:smark_list{bfnm}{s:usc}{a:mark} ' mark=' s:smark_list{bfnm}{s:usc}{a:line}
"let c=getchar()	
	exe 'sign define '.sgnm.' linehl=BookmarkCol_line'.' text='.a:mark.' texthl=BookmarkCol_text'
	exe 'sign place '.sid.' name='.sgnm.' line='.a:line.' buffer='.winbufnr(0)
	exe 'mark '.a:mark
endf



fun! s:remove_a_mark(mark)
	let bfnm = winbufnr(0)

	if(exists('s:smark_list{bfnm}{s:usc}{a:mark}'))
		let line = s:smark_list{bfnm}{s:usc}{a:mark} "contains line number
		let sgnm = 'SMARK_'.bfnm.'_'.line
"echo 'remove_a_mark line=' line ' sign=' sgnm
		" remove highlight
		"exe 'hi link '.sgnm

		exe 'sign unplace '.line.' buffer='.winbufnr(0)
		exe 'sign undefine '.sgnm
		unlet s:smark_list{bfnm}{s:usc}{a:mark}
		unlet s:smark_list{bfnm}{s:usc}{line}
		exe 'delm ' a:mark
	else
		"something must be wrong
"echo 'remove_a_mark not exists: ' a:mark
	endif
endf

fun! s:remove_a_marked_line(line)
	let bfnm = winbufnr(0)

	if(exists('s:smark_list{bfnm}{s:usc}{a:line}'))
		let marker =  s:smark_list{bfnm}{s:usc}{a:line} "contains the marker
		let sgnm = 'SMARK_'.bfnm.'_'.a:line

"echo 'remove_a_marked_line mark=' marker ' sign=' sgnm
		exe 'sign unplace '.a:line.' buffer='.winbufnr(0)
		exe 'sign undefine '.sgnm
		unlet s:smark_list{bfnm}{s:usc}{marker}
		unlet s:smark_list{bfnm}{s:usc}{a:line}
		exe 'delm ' marker
	else
"echo 'remove_a_marked_line not exists: ' a:line
	endif
endf

fun! s:sign_of_a_mark(mark)
	let bfnm = winbufnr(0)

	if(exists('s:smark_list{bfnm}{s:usc}{a:mark}'))
"echo 'sign_of_a_mark, yes'		
		let line = s:smark_list{bfnm}{s:usc}{a:mark} "contains line number
		let sgnm = 'SMARK_'.bfnm.'_'.line
		return(sgnm)
	endif
"echo 'sign_of_a_mark, no'
	return("")
endf

fun! s:line_of_marker(mark)
	let bfnm = winbufnr(0)


	if(exists('s:smark_list{bfnm}{s:usc}{a:mark}'))
"echo 'line_of_marker, yes'		
		return(s:smark_list{bfnm}{s:usc}{a:mark}) "contains marker
	endif

	return(-1)
endf

fun! s:marker_at_line(line)
	let bfnm = winbufnr(0)

	if(a:line < 1)
		return('-')
	endif

"echo 'marker_at_line =' s:smark_list{bfnm}{s:usc}{a:line}
"let c = getchar()

	if(exists('s:smark_list{bfnm}{s:usc}{a:line}'))
"echo 'marker_at_line, yes'		
		return(s:smark_list{bfnm}{s:usc}{a:line})
	endif

	return('-')
endf



"this func works for the current buffer
fun! s:_smark_cleanup()
	let n = 0

	while n < s:n_marks_all
		let c = strpart(s:marks_all, n, 1)
		let l = s:line_of_marker(c)
		let m = s:marker_at_line(l)

		"let vl = line("'".c) "vim's memory, position of mark c (if the mark is not set, 0 is returned)
		let pos = getpos("'".c) "[bufnum, lnum, col, off]
		let buf = pos[0]
		let ln = pos[1]

		if((buf != 0) && (buf != winbufnr(0)))
			let vl = -1
		else
			let vl = pos[1]
		endif


		if(vl < 1)
			"vim does not remember this
			if(l > 0)
				call s:remove_a_marked_line(l)
			endif

			if(m != '-')
				call s:remove_a_mark(m)
			endif
		else
"echo 'smark_cleanup, good vim mark ' c ' at' vl
			if((l > 0) && (m == c))
				"good mark is here
			else
"echo 'smark_cleanup, good no mark c=' c ' m=' m ' l=' l
				"something happened to damage the list
				if(l > 0)
					call s:remove_a_marked_line(l)
				endif

				if(m != '-')
					call s:remove_a_mark(m)
				endif

				call s:place_a_mark(c, vl)
			endif
		endif

		let n = n + 1
	endw
endf

fun! s:smark_cleanup()
	if   ((match(g:showmarks_ignore_type, "[Hh]") > -1) && (&buftype    == "help"    ))
	\ || ((match(g:showmarks_ignore_type, "[Qq]") > -1) && (&buftype    == "quickfix"))
	\ || ((match(g:showmarks_ignore_type, "[Pp]") > -1) && (&pvw        == 1         ))
	\ || ((match(g:showmarks_ignore_type, "[Rr]") > -1) && (&readonly   == 1         ))
	\ || ((match(g:showmarks_ignore_type, "[Mm]") > -1) && (&modifiable == 0         ))
		return
	endif

	call s:_smark_cleanup()
endf

"include vim read marks 
fun! s:_smark_setup()
	let n = 0

	while n < s:n_marks_all
		let c = strpart(s:marks_all, n, 1)
		let pos = getpos("'".c) "[bufnum, lnum, col, off]
		let buf = pos[0]
		let ln = pos[1]

		if(((buf == 0) || (buf == winbufnr(0))) && (ln > 0))
"echo 'setup placing a marker=' c ' buf=' buf ' ln=' ln
			call s:place_a_mark(c, ln)
		endif

		let n = n + 1
	endw
endf


fun! s:smark_setup()
	if   ((match(g:showmarks_ignore_type, "[Hh]") > -1) && (&buftype    == "help"    ))
	\ || ((match(g:showmarks_ignore_type, "[Qq]") > -1) && (&buftype    == "quickfix"))
	\ || ((match(g:showmarks_ignore_type, "[Pp]") > -1) && (&pvw        == 1         ))
	\ || ((match(g:showmarks_ignore_type, "[Rr]") > -1) && (&readonly   == 1         ))
	\ || ((match(g:showmarks_ignore_type, "[Mm]") > -1) && (&modifiable == 0         ))
		return
	endif

	call s:_smark_setup()

	"calling clenup may work as well
endf


"highlight is done here
fun! s:_smark_refresh()
	let n = 0

	call s:_smark_cleanup()

	while n < s:n_marks_all
		let c = strpart(s:marks_all, n, 1)

		if(s:line_of_marker(c) > 0)
			let sgnm = s:sign_of_a_mark(c)
			exe 'hi link '.sgnm.' '.sgnm

		endif

		let n = n + 1
	endw
endf


fun! s:smark_refresh()

	if   ((match(g:showmarks_ignore_type, "[Hh]") > -1) && (&buftype    == "help"    ))
	\ || ((match(g:showmarks_ignore_type, "[Qq]") > -1) && (&buftype    == "quickfix"))
	\ || ((match(g:showmarks_ignore_type, "[Pp]") > -1) && (&pvw        == 1         ))
	\ || ((match(g:showmarks_ignore_type, "[Rr]") > -1) && (&readonly   == 1         ))
	\ || ((match(g:showmarks_ignore_type, "[Mm]") > -1) && (&modifiable == 0         ))
		return
	endif

	call s:_smark_refresh()
endf




fun! s:_ShowMarksPlaceMark_do()
	let n = 0

	if(!exists('b:last_mark'))
		let b:last_mark = -1
	endif
	
	while n < s:n_marks_buffer
		let c = strpart(s:marks_buffer, n, 1)

		if(s:line_of_marker(c) < 0)
			"found a blak spot
			break
		endif

		let n = n + 1
	endw


	if(n >= s:n_marks_buffer)
		"done with all a..z, let's re-use older ones (may not really old)
		"this will become a bug someday
		let n = b:last_mark + 1

		if((n < 0) || (n >= s:n_marks_buffer))
			let n = 0
		endif
"echo 'placing n=' n 'n_marks_Buffer=' s:n_marks_buffer
"let c=getchar()
		let c = strpart(s:marks_buffer, n, 1)

		call s:remove_a_mark(c)
	endif

	let b:last_mark = n

	call s:place_a_mark(c, line("."))

	call <sid>smark_refresh()
endf


fun! s:_ShowMarksPlaceMark()
	let ln = line(".")

	if(s:marker_at_line(ln) != '-')
		echohl WarningMsg
		echo 'You have a mark there, already'
		echohl None
		return
	endif

	"exe 'norm \sm'.nr2char(getchar())
	let c = nr2char(getchar()) "the marker

"echo 'got chr=' c

	if(stridx(s:marks_all, c) >= 0)
		let pos = getpos("'".c) "[bufnum, lnum, col, off]
		let buf = pos[0]
		let ln = pos[1]

		if(((buf == 0) || (buf == winbufnr(0))) && (ln > 0))
			call s:remove_a_mark(c)
		else
			if((buf != winbufnr(0)) && (ln > 0))
				echohl WarningMsg
				echo 'The marker is in another buffer'
				echohl None
				return
			endif
		endif

		call s:place_a_mark(c, line("."))
		call <sid>smark_refresh()
	else
"echo 'oops'		
	endif
endf


fun! s:_ShowMarksClearMark_do()
	let ln = line(".")

	if(s:marker_at_line(ln) == '-')
		echohl WarningMsg
		echo 'You do not have a mark there'
		echohl None
		return
	endif

	call <sid>remove_a_marked_line(ln)
	call <sid>smark_refresh()
endf




fun! s:ShowMarksClearAll()
	let n = 0

	while n < s:n_marks_all
		let c = strpart(s:marks_all, n, 1)

		call <sid>remove_a_mark(c)

		let n = n + 1
	endw
endf

fun! s:ShowMarksToggle()
	let ln = line(".")

	if(s:marker_at_line(ln) == '-')
		call <sid>_ShowMarksPlaceMark_do()
	else
		call <sid>_ShowMarksClearMark_do()
	endif

	call <sid>smark_refresh()
endf



" Set things up
call s:smark_setup()
call s:smark_refresh()


" ==============================================================================
" Commands
command! -nargs=0 -bar ShowMarksClearAll  call s:ShowMarksClearAll()
command! -nargs=0 -bar ShowMarksToggle call s:ShowMarksToggle()
command! -nargs=0 -bar ShowMarks call s:smark_refresh()

"redirect vim mark command 'm', let it go through this util.
noremap <unique> <script> \sm m
noremap <silent> m :let ShowMarks_curline=line(".")<bar>call <sid>_ShowMarksPlaceMark()<bar>call setpos(".", ShowMarks_curline)<CR>



" -----------------------------------------------------------------------------

"goto previous lowercase mark
:map <F2> ]` 

"goto next lowercase mark
:map <S-F2> [`

:map <C-F2> :execute "ShowMarksToggle"<CR>

"clear all marks
:map <C-S-F2> :execute "ShowMarksClearAll"<CR>


" -----------------------------------------------------------------------------
"finish

" I have this part in _vimrc
" F12 saves session, double click on "_session.vis" reloads session
" those are saved in the directory-of-the-current-buffer
" loading blank doc may pose error for the first time
"
" In order to load session at double click (I am using Win XP):
" DOS> assoc .vis=vimsession
" DOS> ftype vimsession="C:\Program Files\Vim\vim72\gvim.exe" -S "%1"
"
"
" Ubuntu
"  Manually creat ~/.gvim, gvim will pickup things from there
"  my gvim local directory = ~/.gvim
"  plugin goes ~/.gvim/plugin
"  Is "/usr/shared/gvim/...." a global?
"
"  File association:
"   nautilus -> properties -> file type-> gvim -S %F or gvim -c "source %F"
" 
"

set autochdir
"autocmd BufEnter * silent! lcd %:p:h
"autocmd BufEnter * lcd %:p:h


function! _SaveSessionAs()
	let svpath = input('Path and name to save .vis: ')
	execute 'mksession!' . svpath . ".vis"
endfunction
command! -nargs=0 SaveSessionAs :call _SaveSessionAs()


function! _SaveSession()
	execute "mksession! _session.vis"
	execute "wviminfo! _viminfo.vim"
endfunction
command! -nargs=0 SaveSession :call _SaveSession()


function! _RecallSession()
	execute "rviminfo _viminfo.vim"
	execute "ShowMarks"
	hi default BookmarkCol_line ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold
	hi default BookmarkCol_text ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold
endfunction
command! -nargs=0 RecallSession :call _RecallSession()

function! _RefreshMarks()
	execute "ShowMarks"
	hi default BookmarkCol_line ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold
	hi default BookmarkCol_text ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold
endfunction
command! -nargs=0 RefreshMarks :call _RefreshMarks()

aug RecallSession
au!
autocmd VimEnter * :RecallSession
aug END

aug SaveSession
au!
autocmd VimLeave * :SaveSession
aug END

aug RefreshMarks
au!
autocmd BufWinEnter * :RefreshMarks
aug END

:map <F11> :execute "SaveSession"<CR>
:map <F12> :execute "SaveSessionAs"<CR>
" -----------------------------------------------------------------------------
finish

