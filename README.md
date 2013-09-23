# projections.vim

Projections.vim is based on [rails.vim](https://github.com/tpope/vim-rails) projections, but allows you to use them for any language and project.

## Install using Pathogen

This project uses rolling releases based on git commits, so pathogen is a
natural fit for it. If you're already using pathogen, you can skip to step 4.

1. Install [pathogen.vim] into `~/.vim/autoload/` (see [pathogen's
   readme][install-pathogen] for more information.)

[pathogen.vim]: http://www.vim.org/scripts/script.php?script_id=2332
[install-pathogen]: https://github.com/tpope/vim-pathogen#installation

2. Enable pathogen in your vimrc. Here's a bare-minimum vimrc that enables
   all the features of `projections.vim`:

   ```vim
   call pathogen#infect()
   syntax enable
   filetype plugin indent on
   ```

   If you already have a vimrc built up, just make sure it contains these calls,
   in this order.

3. Create the directory `~/.vim/bundle/`:

        mkdir ~/.vim/bundle

4. Clone the `projections.vim` repo into `~/.vim/bundle/`:

        git clone https://github.com/malkomalko/projections.vim.git ~/.vim/bundle/projections.vim/

Updating takes two steps:

1. Change into `~/.vim/bundle/projections.vim/`:

        cd ~/.vim/bundle/projections.vim

2. Pull in the latest changes:

        git pull

## Install using Vundle

1. [Install Vundle] into `~/.vim/bundle/`.

[Install Vundle]: https://github.com/gmarik/vundle#quick-start

2. Configure your vimrc for Vundle. Here's a bare-minimum vimrc that enables all
   the features of `projections.vim`:

   ```vim
   set nocompatible
   filetype off

   set rtp+=~/.vim/bundle/vundle/
   call vundle#rc()

   Bundle 'malkomalko/projections.vim'

   syntax enable
   filetype plugin indent on
   ```

   If you're adding Vundle to a built-up vimrc, just make sure all these calls
   are in there and that they occur in this order.

3. Open vim and run `:BundleInstall`.

To update, open vim and run `:BundleInstall!` (notice the bang!)

## License

Copyright (c) Tim Pope and Robert Malko.  Distributed under the same terms as Vim itself.
See `:help license`.