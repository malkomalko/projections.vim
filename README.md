# projections.vim

Projections.vim is based on [rails.vim](https://github.com/tpope/vim-rails) projections, but allows you to use them for any language and project.

## Table of Contents

- Installation
  - [Install using Pathogen](#install-using-pathogen)
  - [Install using Vundle](#install-using-vundle)
- Usage
  - [Setup your projections config](#setup-your-projections-config)
  - [Special template placeholders](#special-template-placeholders)
  - [Commands](#commands)
  - [Templates and Layouts](#templates-and-layouts)

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

## Setup your projections config

The plugin looks for a `projections.json` file in the root of your project (cwd).  No commands will be installed if it can't find a projections.json file.  Pasted below is a trivial example.

    {
      "libs/models/*.js": {
        "command": "models",
        "alternate": "spec/models/%s.js",
        "related": "libs/controllers/%s_controller.js",
        "reverse_layout": true,
        "template": "model",
        "template_alternate": "spec",
        "template_related": "controller"
      },
      "templates": {
        "model": "function(){\n  console.log('model: %s,%S,%h,%p,%i,%f,%%')\n}\n",
        "spec":  "function(){\n  console.log('spec: %s,%S,%h,%p,%i,%f,%%')\n}\n",
        "controller":  "function(){\n  console.log('controller: %s,%S,%h,%p,%i,%f,%%')\n}\n"
      }
    }

This json config is used to search for file patterns based off the key.  In this case any file matching `libs/models/*.js`.

The `"command"` key defines the name of the `{command}`.  In this case it defines `:Emodels` amongst other commands.  See below for the full command list.

The `"alternate"` and `"related"` key is used for a pattern for the all Alternate and Related commands like `:A` and `:R`.  See below for the full alternate and related command list.

The `"template"`, `"template_alternate"`, and `"template_related"` keys all define the template key in the special root level `"templates"` key.  Templates are described further down.

The `"reverse_layout"` key defines whether the alternate/related file will appear on the left side when running layout commands.

## Special template placeholders

This command:

    :Emodels foo/bar_baz

Yields these template placeholders:

    %s => foo/bar_baz   (orig)
    %S => BarBaz        (camel case)
    %h => Bar baz       (humanized)
    %p => bar_bazes     (pluralized)
    %i => bar_baz       (singularize)
    %f => bar_baz       (file part)
    %% => %             (literal %)

## Commands

Opening files:

    :Emodels foo/bar_baz

    :E{command} {file}   (open file)
    :S{command} {file}   (open file in split)
    :T{command} {file}   (open file in tab)
    :V{command} {file}   (open file in vert split)

Opening alternate/related files:

    :A      (open alternate file)
    :AS     (open alternate file in split)
    :AT     (open alternate file in tab)
    :AV     (open alternate file in vert split)

    :R      (open related file)
    :RS     (open related file in split)
    :RT     (open related file in tab)
    :RV     (open related file in vert split)

## Templates and Layouts

`projections.vim` allows you to create files based off of templates.  To create a file, just add a `!` to the end of your command.

    :Emodels apple!

    {
      "libs/models/*.js": {
        "command": "models",
        "template": "model"
      },
      "templates": {
        "model": "function(){\n  console.log('model: %s,%S,%h,%p,%i,%f,%%')\n}\n"
      }
    }

This will grab the template from the `templates.model` key.  Awesome!

`projections.vim` also allows you to open up a layout.  A layout is a side by side view in a new tab placing your file and alternate/related file.  Think of opening up a spec and file in a split.

This is opened in a new tab so it doesn't brake your existing window structure.  It's just a quick `:tabc` away to go back to your work.

You have two choices for opening up a layout:

    :AL   (open up the alternate layout)
    :RV   (open up the related layout)

It will give you an error if it can't find an alternate or related layout.

If by chance you gave it a `template_alternate` or `template_related`, if the file does not exist, it will create it for you based off the template.  Rock and roll!

As previously stated, you can also have the alternate or related file open up on the left side of the split with:

    "reverse_layout": true

## License

Copyright (c) Tim Pope and Robert Malko.  Distributed under the same terms as Vim itself.
See `:help license`.