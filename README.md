# dotfiles

It was the best of terminals, it was the worst of terminals...

My own digital ramblings about a sane CLI experience across various platforms (oh, and that thing they call a GUI as well...).

## Features

* dot files
* preferred packages and corresponding configurations (`ssh`, `newsboat`, etc.)
* preferred os-specific customizations
* automatic downloading of other repositories, when a `~/code/.my_repos` file is present
* some portions can be customized by editting existing values in the `dotfiles_settings` file
* `vi` mode, `vi` mode, `vi` mode

Symlinks created in `"${HOME}"`:

```
./.bash_profile       ->  /Users/USER/dotfiles/bash_profile
./.bashrc             ->  /Users/USER/dotfiles/bashrc
./.dotfiles_settings  ->  /Users/USER/dotfiles/dotfiles_settings
./.inputrc            ->  /Users/USER/dotfiles/inputrc
./.kshrc              ->  /Users/USER/dotfiles/kshrc
./.lynxrc             ->  /Users/USER/dotfiles/lynxrc
./.newsboat.d         ->  /Users/USER/dotfiles/newsboat.d
./.profile            ->  /Users/USER/dotfiles/profile
./.scripts            ->  /Users/USER/dotfiles/scripts
./.shellrc            ->  /Users/USER/dotfiles/shellrc
./.shellrc.d          ->  /Users/USER/dotfiles/shellrc.d
./.zshrc              ->  /Users/USER/dotfiles/zshrc
```

## Usage

1. Install `git`.
     * `macOS` is a special scenario:

       ```sh
       # May want to check latest install command: https://brew.sh/
       if ! command -v brew > /dev/null 2> /dev/null
       then
           /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

           arch="$(uname -m)"
           if test "${arch}" = "arm64"
           then
               eval "$(/opt/homebrew/bin/brew shellenv)"
           elif test "${arch}" = "x86_64"
           then
               eval "$(/usr/local/bin/brew shellenv)"
           fi
       fi
       ```
1. Clone this repo as `"${HOME}/dotfiles"` and `cd` into it.
1. (__!!!DESTRUCTIVE!!!__) Create required symlinks, overwritting pre-existing files and directories where necessary: `./scripts/setup.sh`
1. Exit current shell, as instructed.
1. In a new, interactive shell, execute again to finish setup: `./scripts/setup.sh`
1. For future invocations, one can execute: `~/.scripts/setup.sh`

