# HTT Templating Support

This plugin provides syntax highlighting support for the HTT templating language.
See [HTT Project Page](https://github.com/jwdevantier/htt) for more information.

If you want VSCode support, see [htt-vscode](https://github.com/jwdevantier/htt-vscode).

## Setup

With lazy, you would add the following entry:
```lua
{
    "jwdevantier/htt-nvim",
    config = function()
        require("htt").setup()
    end
},
```

Adjust accordingly, just be sure to run the setup() function.
There is no ftdetect hook in the plugin, I could not make it work, hence run the
setup function to have an autocmd installed that will be applied on opening/editing *.htt files
