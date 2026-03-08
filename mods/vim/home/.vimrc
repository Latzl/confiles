" vimrc

" pulgins 
let g:plugins = {
\	'winresizer': {
\		'full_name': 'winresizer',
\		'enable': 1,
\	},
\	'whichkey': {
\		'full_name': 'vim-which-key',
\		'enable': 1,
\	},
\}

function! s:IsPluginsExist(plugin_name)
	return !empty(globpath($HOME . '/.vim/pack/*/start/', a:plugin_name))
endfunction

function! s:InitPlugins() abort
	for [name, plugin] in items(g:plugins)
		if !s:IsPluginsExist(plugin.full_name)
			let plugin.enable = 0
		endif
		if !plugin.enable
			continue
		endif
		" dosomthing
	endfor
endfunction

call s:InitPlugins()

" basic
let g:mapleader = "\<Space>"

" code
set encoding=utf-8
set fencs=utf8,gbk,gb2312,gb18030

" display
set number
set relativenumber
set showcmd

" format
set fileformats=unix,dos
set autoindent
set smartindent
set tabstop=4
set tabstop=4
set shiftwidth=4
set backspace=2
syntax enable

" misc
set mouse=a
set clipboard=unnamed
set hlsearch
set ignorecase

set wildmode=list:longest
set background=dark

set timeoutlen=500

" remap
" base
nnoremap <leader>h :nohlsearch<CR>
" window
nnoremap <leader>c :close<CR>
nnoremap <leader>wm <C-W>_<C-W><Bar>

nnoremap <C-W><C-H> <C-W>h<C-W>_<C-W><Bar>
nnoremap <C-W><C-J> <C-W>j<C-W>_<C-W><Bar>
nnoremap <C-W><C-K> <C-W>k<C-W>_<C-W><Bar>
nnoremap <C-W><C-L> <C-W>l<C-W>_<C-W><Bar>

" tab
nnoremap <leader>tn :tabnew<CR>

" buffer
nnoremap <leader>bs :Buffers<CR>

" misc
nnoremap <leader>mr :source $MYVIMRC<CR>
nnoremap <leader>mp :set invpaste paste?<CR>
nnoremap <leader>mh :Helptags<CR>
nnoremap <leader>mn :set number! relativenumber!<CR>
nnoremap <leader>mw :set wrap!<CR>

nnoremap <leader>p "0p
vnoremap <leader>p "0p

" pulgins

" winresizer
if g:plugins.winresizer.enable

let g:winresizer_start_key = '<leader>wr'

endif

" which key
if g:plugins.whichkey.enable

" base
nnoremap <silent> <leader> :WhichKey '<Space>'<CR>
let g:which_key_map = {}
autocmd VimEnter * call which_key#register('<Space>', "g:which_key_map")
" wipe leaving no name buffer after guide buffer leaving
autocmd FileType which_key setlocal bufhidden=wipe

let g:which_key_sep = ':'

" window
let g:which_key_map.c = 'close window'
let g:which_key_map.w = { 'name': 'window' }
let g:which_key_map.w.m = 'maximize'
if g:plugins.winresizer.enable
let g:which_key_map.w.r = 'resize mode'
endif

" tab
let g:which_key_map.t = { 'name': 'tab' }
let g:which_key_map.t.n = 'new tab'

" buffer
let g:which_key_map.b = { 'name': 'buffer' }
let g:which_key_map.b.s = 'switch'

" misc
let g:which_key_map.m = { 'name': 'misc' }
let g:which_key_map.m.r = 'reload vimrc'
let g:which_key_map.m.p = 'toggle paste mode'
let g:which_key_map.m.h = 'help tags'
let g:which_key_map.m.n = 'toggle num rnum'
let g:which_key_map.m.w = 'toggle wordwrap'
let g:which_key_map.p = 'paste'

endif
