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

### Symlinks created in `"${HOME}"`:

```
${HOME}/.bash_profile       ->  ${HOME}/dotfiles/bash_profile
${HOME}/.bashrc             ->  ${HOME}/dotfiles/bashrc
${HOME}/.dotfiles_settings  ->  ${HOME}/dotfiles/dotfiles_settings
${HOME}/.inputrc            ->  ${HOME}/dotfiles/inputrc
${HOME}/.kshrc              ->  ${HOME}/dotfiles/kshrc
${HOME}/.lynxrc             ->  ${HOME}/dotfiles/lynxrc
${HOME}/.newsboat.d         ->  ${HOME}/dotfiles/newsboat.d
${HOME}/.profile            ->  ${HOME}/dotfiles/profile
${HOME}/.scripts            ->  ${HOME}/dotfiles/scripts
${HOME}/.shellrc            ->  ${HOME}/dotfiles/shellrc
${HOME}/.shellrc.d          ->  ${HOME}/dotfiles/shellrc.d
${HOME}/.zprofile           ->  ${HOME}/dotfiles/zprofile
${HOME}/.zshrc              ->  ${HOME}/dotfiles/zshrc
```

One can execute the following before and after the [usage](#usage) steps to compare:

```sh
find "${HOME}" -maxdepth 1 -type l -exec ls -l {} \; | awk '{print $9 " " $10 " " $11}' | sed 's|'"${HOME}"'|${HOME}|g' | sort | column -t
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

