[Chezmoi](https://github.com/twpayne/chezmoi) is a nice tool, however it misses a bit the ability of organizing dotfiles and keep them in a different path, and link them to the original files.

I wanted to keep my dotfiles in a separate path in my default setup, and [organized differently](https://github.com/3v1n0/ellipses/tree/chezmoi/private_dot_ellipses), so I've written some bash scripts that are running every time you `apply` (or manually) to allow to have a [GNU `stow`-like](https://www.gnu.org/software/stow/) structure with chezmoi, and making sure that any `~/.dotted` file points to the actual chezmoi file (if not templated or encrypted), by generating "native" chezmoi symlink files.

So that when you use `chezmoi diff` you get some real diffs, for example:

```bash

# Make a directory where to keep the managed files and add to chezmoi
❯ mkdir -m700 -p ~/.ellipses/vscode/.config/Code/User/
❯ mv ~/.config/Code/User/keybindings.json ~/.ellipses/vscode/.config/Code/User/
❯ tree -R ~/.ellipses/vscode -a
~/.ellipses/vscode
└── .config
    └── Code
        └── User
            └── keybindings.json

# Adding to chezmoi, as the symlink sources
❯ chezmoi add -r ~/.ellipses/vscode/
❯ tree private_dot_ellipses
private_dot_ellipses
└── vscode
    └── private_dot_config
        └── private_Code
            └── User
                └── keybindings.json

# Add the "repo" directory to chezmoi, so that will be the symlink target dir
❯ chezmoi add ~/.config/Code/User/

# Launch the tooling
❯ bash $(chezmoi source-path)/ellipses-tools/generate-chezmoi-links.sh

# And this will generate:
❯ tree private_dot_config/ 
private_Code
└──private_dot_config
   └── User
       └── symlink_keybindings.json.tmpl

# So that diff will be:
❯ chezmoi diff
chmod 755 ~/.config/Code/User
ln -sf ~/.local/share/chezmoi/private_dot_ellipses/vscode/private_dot_config/private_Code/User/keybindings.json ~/.config/Code/User/keybindings.json
chmod 755 ~/.ellipses/vscode
chmod 700 ~/.ellipses/vscode/.config
chmod 700 ~/.ellipses/vscode/.config/Code
chmod 755 ~/.ellipses/vscode/.config/Code/User
chmod 644 ~/.ellipses/vscode/.config/Code/User/keybindings.json


# And once applied, the file points to the actual one:
❯ chezmoi apply
❯ ls ~/.config/Code/User/keybindings.json -lh 
lrwxrwxrwx 1 marco marco 114 mag 30 19:42 ~/.config/Code/User/keybindings.json -> ~/.local/share/chezmoi/private_dot_ellipses/vscode/private_dot_config/private_Code/User/keybindings.json
```

However, some configurations where we've a mix of auto-generated files we don't want to handle and other we actually want to keep track may be a bit more complicated such as shown in these examples:

<details>
<summary>my neovim config structure</summary>

```
❯ tree -L 2 ~/.ellipses/vim
~/.ellipses/vim
├── .config
│   └── nvim
│       ├── autoload
│       ├── ftplugin
│       ├── init.vim
│       ├── keybindings.vim
│       ├── pack
│       ├── pager.vim
│       ├── plugged
│       ├── theming.vim
│       ├── viminfo
│       └── wildignores.vim
├── .vim
│   ├── autoload
│   │   └── plug.vim
│   ├── init.vim -> ~/.ellipses/vim/.config/nvim/init.vim
│   ├── keybindings.vim -> ~/.ellipses/vim/.config/nvim/keybindings.vim
│   ├── .netrwhist
│   ├── pager.vim -> ~/.ellipses/vim/.config/nvim/pager.vim
│   ├── plugged
│   ├── .stignore
│   ├── theming.vim -> ~/.ellipses/vim/.config/nvim/theming.vim
│   ├── viminfo
│   ├── .viminfo
│   └── wildignores.vim -> ~/.ellipses/vim/.config/nvim/wildignores.vim
└── .vimrc -> .config/nvim/init.vim

# Generating
❯ tree -L 1 ~/.vim
~/.vim
├── autoload
├── init.vim -> ~/.ellipses/vim/.config/nvim/init.vim
├── keybindings.vim -> ~/.ellipses/vim/.config/nvim/keybindings.vim
├── pager.vim -> ~/.ellipses/vim/.config/nvim/pager.vim
├── plugged
├── theming.vim -> ~/.ellipses/vim/.config/nvim/theming.vim
├── viminfo
└── wildignores.vim -> ~/.ellipses/vim/.config/nvim/wildignores.vim

❯ tree -L 1 ~/.config/nvim
~/.config/nvim
├── init.vim -> ~/.local/share/chezmoi/private_dot_ellipses/vim/private_dot_config/private_nvim/init.vim
├── keybindings.vim -> ~/.local/share/chezmoi/private_dot_ellipses/vim/private_dot_config/private_nvim/keybindings.vim
├── pager.vim -> ~/.local/share/chezmoi/private_dot_ellipses/vim/private_dot_config/private_nvim/pager.vim
├── theming.vim -> ~/.local/share/chezmoi/private_dot_ellipses/vim/private_dot_config/private_nvim/theming.vim
└── wildignores.vim -> ~/.local/share/chezmoi/private_dot_ellipses/vim/private_dot_config/private_nvim/wildignores.vim
```
</details>

<details>
<summary>or my weechat structure, notice that `irc.conf` is encrypted and so pointing to the target dir</summary>

```
tree -L 2 ~/.ellipses/weechat ~/.ellipses/weechat/.config -a
~/.ellipses/weechat
├── .config
│   └── weechat
└── data
    ├── .ellipses-ignore
    ├── logs
    ├── urls.log
    ├── weechat.log
    └── xfer
~/.ellipses/weechat/.config
└── weechat
    ├── alias.conf
    ├── aspell.conf
    ├── autosort.conf
    ├── buffer_autoset.conf
    ├── buffers.conf
    ├── buflist.conf
    ├── charset.conf
    ├── colorize_nicks.conf
    ├── exec.conf
    ├── fifo.conf
    ├── fset.conf
    ├── irc.conf
    ├── logger.conf
    ├── logs -> ../../data/logs
    ├── lua
    ├── lua.conf
    ├── perl
    ├── perl.conf
    ├── plugins.conf
    ├── python
    ├── python.conf
    ├── relay.conf
    ├── ruby
    ├── ruby.conf
    ├── script
    ├── script.conf
    ├── sec.conf
    ├── spell.conf
    ├── trigger.conf
    ├── urlgrab.conf
    ├── urls.log -> ../../data/urls.log
    ├── weechat.conf
    ├── weechat.log -> ../../data/weechat.log
    ├── xfer -> ../../data/xfer
    └── xfer.conf

# Generates

❯ tree -L 1 ~/.weechat
~/.weechat
├── alias.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_alias.conf
├── aspell.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_aspell.conf
├── autoset.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_buffer_autoset.conf
├── autosort.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_autosort.conf
├── buffer_autoset.conf
├── buffers.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_buffers.conf
├── buflist.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_buflist.conf
├── charset.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_charset.conf
├── colorize_nicks.conf
├── exec.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_exec.conf
├── fifo.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_fifo.conf
├── fset.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_fset.conf
├── irc.conf -> ~/.ellipses/weechat/.config/weechat/irc.conf
├── logger.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_logger.conf
├── logs -> ~/.ellipses/weechat/.config/weechat/logs
├── lua -> ~/.ellipses/weechat/.config/weechat/lua
├── lua.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_lua.conf
├── nicks.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_colorize_nicks.conf
├── perl -> ~/.ellipses/weechat/.config/weechat/perl
├── perl.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_perl.conf
├── plugins.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_plugins.conf
├── python -> ~/.ellipses/weechat/.config/weechat/python
├── python.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_python.conf
├── relay.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_relay.conf
├── ruby -> ~/.ellipses/weechat/.config/weechat/ruby
├── ruby.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_ruby.conf
├── script -> ~/.ellipses/weechat/.config/weechat/script
├── script.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_script.conf
├── sec.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_sec.conf
├── spell.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_spell.conf
├── trigger.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_trigger.conf
├── urlgrab.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_urlgrab.conf
├── urls.log -> ~/.ellipses/weechat/.config/weechat/urls.log
├── weechat.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_weechat.conf
├── weechat_fifo
├── weechat.log -> ~/.ellipses/weechat/.config/weechat/weechat.log
├── xfer -> ~/.ellipses/weechat/.config/weechat/xfer
└── xfer.conf -> ~/.local/share/chezmoi/private_dot_ellipses/weechat/private_dot_config/private_weechat/private_xfer.conf
```
</details>

The basic idea is:
 - Files are structured (like in `stow`) in the `~/.ellipses/package/<path>`
      -  So if you add a `~/.ellipses/foopackage/.bardotfile`  it creates a `~/.bardotfile` link pointing to `$(chezmoi source-path)/.bardotfile`
 - If a file is a template or encrypted we just use the one in target (and so ~/.ellipses/foopackage/.bardotfile in the above example)
 - if the package contains a directory, we symlink it if there are no real files in your `$HOME`
   -  So if you add a `~/.ellipses/foopackage/.bardodir` it creates a `~/.bardotdir` link to the `~/.ellipses/foopackage/.bardodir`
- If the package contains a directory and we've it our `$HOME` and it's tracked in chezmoi we symlink all its children.
   -  So if you add a `~/.ellipses/foopackage/.bardodir/file_{1...n}` with various children, will link all the children to `$(chezmoi source-path)/.bardotdir/file_{1...n}`

So, while it implies moving the files a bit at first (but maybe another script could be to automatize the files importation), this makes things working as expected
