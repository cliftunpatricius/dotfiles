# dotfiles

* [Introduction](#introduction)
* [Features](#features)
* [Linting](#linting)
* [Testing](#testing)
* [Usage](#usage)

## Introduction

It was the best of terminals, it was the worst of terminals...

My own digital ramblings about a sane CLI experience across various platforms (oh, and that thing they call a GUI as well...).

## Features

* dot files
* preferred packages and corresponding configurations (`ssh`, `newsboat`, etc.)
* preferred os-specific customizations
* automatic downloading of other repositories, when a `~/code/.my_repos` file is present
* `vi` mode, `vi` mode, `vi` mode

## Linting

From the root directory of this repository, execute:

```sh
grep -ril '^#!/bin/sh' . | grep -Ev '^\./\.git' | xargs shellcheck -ax
```

## Testing

One can execute the following before and after the [usage](#usage) steps to compare:

```sh
find "${HOME}" -type l -exec file {} \; | grep -E "to[[:space:]]+'${HOME}/dotfiles/" | sort | column -t
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

1. Clone this repo as `"${HOME}"/dotfiles` and `cd` into it.
1. (__!!!DESTRUCTIVE!!!__) Symlink _both_ dotfiles _and_ corresponding executables (and their libraries): `./install.sh`
1. Leaving the current shell running, open a new one and test things out

