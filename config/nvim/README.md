# Neovim Configuration

## Design

Configuring neovim is set up to rely on a single script that is easy to copy paste onto a machine.
It attempts to modify as little as possible while producing a nice working environment.
We do not modify the default bindings, because vim is everywhere, and I want to be able to work successfully on an unconfigured machine, out of the box. Quality of life improvements are made as additions, not rebinding existing keys.
The only plugins that are allowed are ones where they can be installed by simply cloning the repo in the correct place and then modifying init.lua. No package managers.
