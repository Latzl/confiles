" vimrc
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

nnoremap <leader>h :nohlsearch<CR>

" which key
nnoremap <silent> <leader> :WhichKey '<Space>'<CR>
let g:which_key_map = {}
autocmd VimEnter * call which_key#register('<Space>', "g:which_key_map")
" wipe leaving no name buffer after guide buffer leaving
autocmd FileType which_key setlocal bufhidden=wipe

let g:which_key_sep = ':'

" window
nnoremap <leader>c :close<CR>
let g:which_key_map.c = 'close window'
let g:which_key_map.w = { 'name': 'window' }
let g:which_key_map.w.m = 'maximize'
nnoremap <leader>wm <C-W>_<C-W><Bar>
let g:which_key_map.w.r = 'resize mode'
let g:winresizer_start_key = '<leader>wr'

nnoremap <C-W><C-H> <C-W>h<C-W>_<C-W><Bar>
nnoremap <C-W><C-J> <C-W>j<C-W>_<C-W><Bar>
nnoremap <C-W><C-K> <C-W>k<C-W>_<C-W><Bar>
nnoremap <C-W><C-L> <C-W>l<C-W>_<C-W><Bar>

" tab
let g:which_key_map.t = { 'name': 'tab' }
nnoremap <leader>tn :tabnew<CR>
let g:which_key_map.t.n = 'new tab'


" buffer
let g:which_key_map.b = { 'name': 'buffer' }
nnoremap <leader>bs :Buffers<CR>
let g:which_key_map.b.s = 'switch'

" misc
let g:which_key_map.m = { 'name': 'misc' }
nnoremap <leader>mr :source $MYVIMRC<CR>
let g:which_key_map.m.r = 'reload vimrc'
nnoremap <leader>mp :set invpaste paste?<CR>
let g:which_key_map.m.p = 'toggle paste mode'
nnoremap <leader>mh :Helptags<CR>
let g:which_key_map.m.h = 'help tags'
nnoremap <leader>mn :set number! relativenumber!<CR>
let g:which_key_map.m.n = 'toggle num rnum'
nnoremap <leader>mw :set wrap!<CR>
let g:which_key_map.m.w = 'toggle wordwrap'

let g:which_key_map.p = 'paste'
nnoremap <leader>p "0p
vnoremap <leader>p "0p
