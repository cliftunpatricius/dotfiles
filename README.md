# dotfiles

- [Introduction](#introduction)
- [Features](#features)
- [Linting](#linting)
- [Testing](#testing)
- [Usage](#usage)
- [Acknowledgements](#acknowledgements)

## Introduction

It was the best of terminals, it was the worst of terminals...

My own digital ramblings about a sane CLI experience across various platforms
(oh, and that thing they call a GUI as well...).

My main, concrete guides:
- OpenBSD
- POSIX

## Features

Cross-platform (Mostly. "It may be that. You never can tell with bees."):
- dotfiles
- `vi` mode, `vi` mode, `vi` mode
- keyboard re-mapping of Caps_Lock to Control
- `tmux` with custom status bar and `vi`-like bindings
- `spleen` font
- packages and configurations
- cloning of other repositories, given a `~/code/.my_repos`

OpenBSD
- CWM
- _fancy_ use of `xlock`,`xidle`, `xcetera...`

## Linting

From the root directory of this repository, execute:

```sh
grep -ril '^#!/bin/sh' . |
	grep -Ev '^\./\.git' |
	xargs shellcheck -ax
```

## Testing

One can execute the following before and after the [usage](#usage) steps to compare:

```sh
find "${HOME}" -type l -exec file {} \; |
	grep -E "to[[:space:]]+'${HOME}/dotfiles/" |
	sort |
	column -t
```

## Usage

1. Install `git`
     - `macOS` is a special scenario:

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

1. Install `shellcheck` for linting the shell scripts
1. Clone this repo as `"${HOME}"/dotfiles` and `cd` into it
1. (__!!!DESTRUCTIVE!!!__) Symlink _both_ dotfiles _and_ corresponding
   executables (and their libraries): `./install.sh`
1. Leaving the current shell running, open a new one and test things out

## Acknowledgements

Beyond official documentation, I have been greatly inspired by the following
examples (though I prefer classic, usually built-in, tools over newer tools):
- https://missing.csail.mit.edu/
- https://www.c0ffee.net/blog/openbsd-on-a-laptop/
- [ThePrimeagen's workstation setup tutorial](https://frontendmasters.com/courses/developer-productivity-v2/bash-environment-setup-script/) (I have only watched the free preview), [ThePrimeagen](https://www.youtube.com/@ThePrimeagen), [ThePrimeTimeagen](https://www.youtube.com/@ThePrimeTimeagen)
- https://astro-gr.org/openbsd/

Potential sources of future inspiration:
- https://linkarzu.com/posts/macos/prime-workflow/
