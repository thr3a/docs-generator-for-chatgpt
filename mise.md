

# environments.md

# Environments

Use mise to specify environment variables used for different projects. Create a `mise.toml` file
in the root of your project directory:

```toml
[env]
NODE_ENV = 'production'
```

To clear an env var, set it to `false`:

```toml
[env]
NODE_ENV = false # unset a previously set NODE_ENV
```

You can also use the CLI to get/set env vars:

```sh
$ mise set NODE_ENV=development
$ mise set NODE_ENV
development
$ mise set
key       value        source
NODE_ENV  development  mise.toml
$ mise unset NODE_ENV
```

## `env._` directives

`env._.*` define special behavior for setting environment variables. (e.g.: reading env vars
from a file). Since nested environment variables do not make sense,
we make use of this fact by creating a key named "\_" which is a
TOML table for the configuration of these directives.

### `env._.file`

In `mise.toml`: `env._.file` can be used to specify a [dotenv](https://dotenv.org) file to load.
It can be a string or array and uses relative or absolute paths:

```toml
[env]
_.file = '.env'
```

_This uses [dotenvy](https://crates.io/crates/dotenvy) under the hood. If you have problems with
the way `env._.file` works, you will likely need to post an issue there,
not to mise since there is not much mise can do about the way that crate works.\_

Or set [`MISE_ENV_FILE=.env`](/configuration#mise-env-file) to automatically load dotenv files in any
directory.

### `env._.path`

`PATH` is treated specially, it needs to be defined as a string/array in `mise.path`:

```toml
[env]
_.path = [
    # adds an absolute path
    "~/.local/share/bin",
    # adds a path relative to the mise.toml, not PWD
    "./node_modules/.bin",
]
```

### `env._.source`

Source an external bash script and pull exported environment variables out of it:

```toml
[env]
_.source = "./script.sh"
```

::: info
This **must** be a script that runs in bash as if it were executed like this:

```sh
source ./script.sh
```

The shebang will be **ignored**. See [#1448](https://github.com/jdx/mise/issues/1448)
for a potential alternative that would work with binaries or other script languages.
:::

## Plugin-provided `env._` Directives

Plugins can provide their own `env._` directives. See [mise-env-sample](https://github.com/jdx/mise-env-sample) for an example of one.

## Multiple `env._` Directives

It may be necessary to use multiple `env._` directives, however TOML fails with this syntax
because it has 2 identical keys in a table:

```toml
[env]
_.source = "./script_1.sh"
_.source = "./script_2.sh" # invalid // [!code error]
```

For this use-case, you can optionally make `[env]` an array-of-tables instead by using `[[env]]` instead:

```toml
[[env]]
_.source = "./script_1.sh"
[[env]]
_.source = "./script_2.sh"
```

It works identically but you can have multiple tables.

## Templates

Environment variable values can be templates, see [Templates](/templates) for details.

```toml
[env]
LD_LIBRARY_PATH = "/some/path:{{env.LD_LIBRARY_PATH}}"
```

## Using env vars in other env vars

You can use the value of an environment variable in later env vars:

```toml
[env]
MY_PROJ_LIB = "{{config_root}}/lib"
LD_LIBRARY_PATH = "/some/path:{{env.MY_PROJ_LIB}}"
```

Of course the ordering matters when doing this.

# ide-integration.md

# IDE Integration

IDEs work better with shims than they do environment variable modifications. The simplest way is
to add the mise shim directory to PATH.

For IntelliJ and VSCode—and likely others, you can modify your default shell's profile
script. Your default shell can be found with:

- macos – `dscl . -read /Users/$USER UserShell`
- linux – `getent passwd $USER | cut -d: -f7`

You can change your default shell with `chsh -s /path/to/shell` but you may need
to first add it to `/etc/shells`.

Once you know the right one, modify the appropriate file:

::: code-group

```zsh
# ~/.zprofile
eval "$(mise activate zsh --shims)"
```

```bash
# ~/.bash_profile or ~/.bash_login or ~/.profile
eval "$(mise activate bash --shims)"
```

```fish
# ~/.config/fish/config.fish
if status is-interactive
  mise activate fish | source
else
  mise activate fish --shims | source
end
```

:::

This assumes that `mise` is on PATH. If it is not, you'll need to use the absolute path (
e.g.: `eval "$($HOME/.local/bin/mise activate zsh)"`).

:::: tip
Conditionally using shims is also possible. Some programs will set a `TERM_PROGRAM` environment
variable, which may be used to determine which activation strategy to use.

Here is an example using VSCode:

::: code-group

```zsh
# ~/.zprofile
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  eval "$($HOME/.local/bin/mise activate zsh --shims)"
elif; then
  eval "$($HOME/.local/bin/mise activate zsh)"
fi
```

```bash
# ~/.bash_profile or ~/.bash_login or ~/.profile
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  eval "$($HOME/.local/bin/mise activate bash --shims)"
elif; then
  eval "$($HOME/.local/bin/mise activate bash)"
fi
```

:::
::::

This won't work for all of mise's functionality. For example, arbitrary env vars in `[env]` will
only be set
if a shim is executed. For this we need tighter integration with the IDE and a custom plugin. If you
feel
ambitious, take a look at existing direnv extensions for your IDE and see if you can modify it to
work for mise.
Direnv and mise work similarly and there should be a direnv extension that can be used as a starting
point.

## Vim

```vim
" Prepend mise shims to PATH
let $PATH = $HOME . '/.local/share/mise/shims:' . $PATH
```

## Neovim

```lua
-- Prepend mise shims to PATH
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH
```

## emacs

- Traditional shims way

```lisp
;; CLI tools installed by Mise
;; See: https://www.emacswiki.org/emacs/ExecPath
(setenv "PATH" (concat (getenv "PATH") ":/home/user/.local/share/mise/shims"))
(setq exec-path (append exec-path '("/home/user/.local/share/mise/shims")))
```

- Use with package [mise.el](https://github.com/liuyinz/mise.el)

```lisp
(require 'mise)
(add-hook 'after-init-hook #'global-mise-mode)
```

## Xcode

Xcode projects can run system commands from script build phases and schemes. Since Xcode sandboxes
the execution of the script using the tool `/usr/bin/sandbox-exec`, don't expect Mise and the
automatically-activated tools to work out of the box. First, you'll need to
add `$(SRCROOT)/mise.toml` to the list of **Input files**. This is necessary for Xcode to allow
reads to that file. Then, you can use `mise activate` to activate the tools you need:

```bash
# -C ensures that Mise loads the configuration from the Mise configuration
# file in the project's root directory.
eval "$($HOME/.local/bin/mise activate -C $SRCROOT bash --shims)"

swiftlint
```

## JetBrains Editors (IntelliJ, RustRover, PyCharm, WebStorm, RubyMine, GoLand, etc)

Some JetBrains IDEs have direct support for mise, others have support for asdf which can be used by
first symlinking the mise tool directory which is the
same layout as asdf:

```sh
ln -s ~/.local/share/mise ~/.asdf
```

Then they should show up on in Project Settings:

![project settings](https://github.com/jdx/mise-docs/assets/216188/b34a0e3f-7af8-45c9-85b8-2c72bd1dc226)

Or in the case of node (possibly other languages), it's under "Languages & Frameworks":

![languages & frameworks](https://github.com/jdx/mise-docs/assets/216188/9926be1c-ab88-451a-8ace-edf2dac564b5)

## VSCode

While modifying `~/.zprofile` is likely the easiest solution, you can also set
the tools in `launch.json`:

```json
{
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Launch Program",
      "program": "${file}",
      "args": [],
      "osx": {
        "runtimeExecutable": "mise"
      },
      "linux": {
        "runtimeExecutable": "mise"
      },
      "runtimeArgs": ["x", "--", "node"]
    }
  ]
}
```

## [YOUR IDE HERE]

I am not a heavy IDE user. I use JetBrains products but I don't actually
like to execute code directly inside of them often so I don't have much
personal advice to offer for IDEs generally. That said, people often
ask about how to get their IDE to work with mise so if you've done this
for your IDE, please consider sending a PR to this page with some
instructions (however rough they are, starting somewhere is better than
nothing).

Also if you've found a setup that you prefer to what is listed here consider
adding it as a suggestion.

# installing-mise.md

# Installing Mise

If you are new to `mise`, follow the [Getting Started](/getting-started) guide first.

## Installation Methods

This page lists various ways to install `mise` on your system.

### <https://mise.run>

Note that it isn't necessary for `mise` to be on `PATH`. If you run the activate script in your
shell's rc
file, mise will automatically add itself to `PATH`.

```sh
curl https://mise.run | sh

# or with options
curl https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh
```

Options:

- `MISE_DEBUG=1` – enable debug logging
- `MISE_QUIET=1` – disable non-error output
- `MISE_INSTALL_PATH=/some/path` – change the binary path (default: `~/.local/bin/mise`)
- `MISE_VERSION=v2024.5.17` – install a specific version

If you want to verify the install script hasn't been tampered with:

```sh
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0x7413A06D
curl https://mise.jdx.dev/install.sh.sig | gpg --decrypt > install.sh
# ensure the above is signed with the mise release key
sh ./install.sh
```

or if you're allergic to `| sh`:

::: code-group

```sh [macos-arm64]
curl https://mise.jdx.dev/mise-latest-macos-arm64 > ~/.local/bin/mise
chmod +x ~/.local/bin/mise
```

```sh [macos-x64]
curl https://mise.jdx.dev/mise-latest-macos-x64 > ~/.local/bin/mise
chmod +x ~/.local/bin/mise
```

```sh [linux-x64]
curl https://mise.jdx.dev/mise-latest-linux-x64 > ~/.local/bin/mise
chmod +x ~/.local/bin/mise
```

```sh [linux-arm64]
curl https://mise.jdx.dev/mise-latest-linux-arm64 > ~/.local/bin/mise
chmod +x ~/.local/bin/mise
```

:::

It doesn't matter where you put it. So use `~/bin`, `/usr/local/bin`, `~/.local/bin` or whatever.

Supported os/arch:

- `macos-x64`
- `macos-arm64`
- `linux-x64`
- `linux-x64-musl`
- `linux-arm64`
- `linux-arm64-musl`
- `linux-armv6`
- `linux-armv6-musl`
- `linux-armv7`
- `linux-armv7-musl`

If you need something else, compile it with `cargo install mise` (see below).

### apk

For Alpine Linux:

```sh
apk add mise
```

_mise lives in
the [community repository](https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/community/mise/APKBUILD)._

### apt

For installation on Ubuntu/Debian:

::: code-group

```sh [amd64]
apt update -y && apt install -y gpg sudo wget curl
sudo install -dm 755 /etc/apt/keyrings
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
sudo apt update
sudo apt install -y mise
```

```sh [arm64]
apt update -y && apt install -y gpg sudo wget curl
sudo install -dm 755 /etc/apt/keyrings
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=arm64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
sudo apt update
sudo apt install -y mise
```

:::

### aur

For Arch Linux:

```sh
git clone https://aur.archlinux.org/mise.git
cd mise
makepkg -si
```

### Cargo

Build from source with Cargo:

```sh
cargo install mise
```

Do it faster with [cargo-binstall](https://github.com/cargo-bins/cargo-binstall):

```sh
cargo install cargo-binstall
cargo binstall mise
```

Build from the latest commit in main:

```sh
cargo install mise --git https://github.com/jdx/mise --branch main
```

### dnf

For Fedora, CentOS, Amazon Linux, RHEL and other dnf-based distributions:

```sh
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://mise.jdx.dev/rpm/mise.repo
dnf install -y mise
```

### Docker

```sh
docker run jdxcode/mise x node@20 -- node -v
```

### Homebrew

```sh
brew install mise
```

### npm

mise is available on npm as a precompiled binary. This isn't a Node.js package—just distributed
via npm. This is useful for JS projects that want to setup mise via `package.json` or `npx`.

```sh
npm install -g @jdxcode/mise
```

Use npx if you just want to test it out for a single command without fully installing:

```sh
npx @jdxcode/mise exec python@3.11 -- python some_script.py
```

### GitHub Releases

Download the latest release from [GitHub](https://github.com/jdx/mise/releases).

```sh
curl -L https://github.com/jdx/mise/releases/download/v2024.1.0/mise-v2024.1.0-linux-x64 > /usr/local/bin/mise
chmod +x /usr/local/bin/mise
```

### MacPorts

```sh
sudo port install mise
```

### nix

For the Nix package manager, at release 23.05 or later:

```sh
nix-env -iA mise
```

You can also import the package directly using
`mise-flake.packages.${system}.mise`. It supports all default Nix
systems.

### yum

```sh
yum install -y yum-utils
yum-config-manager --add-repo https://mise.jdx.dev/rpm/mise.repo
yum install -y mise
```

### Windows

Download the latest release from [GitHub](https://github.com/jdx/mise/releases) and add the binary
to your PATH.

If your shell does not support `mise activate`, you would want to edit PATH to include the shims directory (by default: `%LOCALAPPDATA%\mise\shims`).

Note that Windows support is very minimal for now.

## Shells

### Bash

```sh
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
```

### Zsh

```sh
echo 'eval "$(mise activate zsh)"' >> "${ZDOTDIR-$HOME}/.zshrc"
```

### Fish

```sh
echo 'mise activate fish | source' >> ~/.config/fish/config.fish
```

::: tip
For homebrew and possibly other installs mise is automatically activated so
this is not necessary.

See [`MISE_FISH_AUTO_ACTIVATE=1`](/configuration#mise_fish_auto_activate1) for more information.
:::

### Nushell

Nu
does [not support `eval`](https://www.nushell.sh/book/how_nushell_code_gets_run.html#eval-function)
Install Mise by appending `env.nu` and `config.nu`:

```nushell
'
let mise_path = $nu.default-config-dir | path join mise.nu
^mise activate nu | save $mise_path --force
' | save $nu.env-path --append
"\nuse ($nu.default-config-dir | path join mise.nu)" | save $nu.config-path --append
```

If you prefer to keep your dotfiles clean you can save it to a different directory then
update `$env.NU_LIB_DIRS`:

```nushell
"\n$env.NU_LIB_DIRS ++= ($mise_path | path dirname | to nuon)" | save $nu.env-path --append
```

### Xonsh

Since `.xsh` files are [not compiled](https://github.com/xonsh/xonsh/issues/3953) you may shave a
bit off startup time by using a pure Python import: add the code below to, for
example, `~/.config/xonsh/mise.py` config file and `import mise` it in `~/.config/xonsh/rc.xsh`:

```python
from pathlib         import Path
from xonsh.built_ins import XSH

ctx = XSH.ctx
mise_init = subprocess.run([Path('~/bin/mise').expanduser(),'activate','xonsh'],capture_output=True,encoding="UTF-8").stdout
XSH.builtins.execx(mise_init,'exec',ctx,filename='mise')
```

Or continue to use `rc.xsh`/`.xonshrc`:

```sh
echo 'execx($(~/bin/mise activate xonsh))' >> ~/.config/xonsh/rc.xsh # or ~/.xonshrc
```

Given that `mise` replaces both shell env `$PATH` and OS environ `PATH`, watch out that your configs
don't have these two set differently (might
throw `os.environ['PATH'] = xonsh.built_ins.XSH.env.get_detyped('PATH')` at the end of a config to
make sure they match)

### Elvish

Add following to your `rc.elv`:

```shell
var mise: = (eval &ns=[&] &on-end=$put~ (mise activate elvish | slurp))
mise:activate
```

Optionally alias `mise` to `mise:mise` for seamless integration of `mise {activate,deactivate,shell}`:

```shell
fn mise {|@args| mise:mise $@args }
```

### Something else?

Adding a new shell is not hard at all since very little shell code is
in this project.
[See here](https://github.com/jdx/mise/tree/main/src/shell) for how
the others are implemented. If your shell isn't currently supported
I'd be happy to help you get yours integrated.

## Autocompletion

The [`mise completion`](/cli/completion.html) command can generate autocompletion scripts for your shell.
This requires `usage` to be installed. If you don't have it, install it with:

```shell
mise use -g usage
```

Then, run the following commands to install the completion script for your shell:

::: code-group

```sh [bash]
# This requires bash-completion to be installed
mkdir -p /etc/bash_completion.d/
mise completion bash > /etc/bash_completion.d/mise
```

```sh [zsh]
# This requires zsh to be configured. If you e.g. use oh-my-zsh, it should work out of the box.
mkdir -p /usr/local/share/zsh/site-functions
mise completion zsh  > /usr/local/share/zsh/site-functions/_mise
```

```sh [fish]
mise completion fish > ~/.config/fish/completions/mise.fish
```

:::

Then source your shell's rc file or restart your shell.

## Uninstalling

Use `mise implode` to uninstall mise. This will remove the mise binary and all of its data. Use
`mise implode --help` for more information.

Alternatively, manually remove the following directories to fully clean up:

- `~/.local/share/mise` (can also be `MISE_DATA_DIR` or `XDG_DATA_HOME/mise`)
- `~/.local/state/mise` (can also be `MISE_STATE_DIR` or `XDG_STATE_HOME/mise`)
- `~/.config/mise` (can also be `MISE_CONFIG_DIR` or `XDG_CONFIG_HOME/mise`)
- on Linux: `~/.cache/mise` (can also be `MISE_CACHE_DIR` or `XDG_CACHE_HOME/mise`)
- on macOS: `~/Library/Caches/mise` (can also be `MISE_CACHE_DIR`)

# settings.md

# Settings

<script setup>
import Settings from '/components/settings.vue';
</script>

The following is a list of all of mise's settings. These can be set via `mise settings key=value`,
by directly modifying `~/.config/mise/config.toml` or local config, or via environment variables.

Some of them also can be set via global CLI flags.

<Settings :level="2" />

# file-tasks.md

# File Tasks

In addition to defining tasks through the configuration, they can also be defined as standalone script files in one of the following directories:

- `mise-tasks/:task_name`
- `.mise-tasks/:task_name`
- `mise/tasks/:task_name`
- `.mise/tasks/:task_name`
- `.config/mise/tasks/:task_name`

Here is an example of a file task that builds a Rust CLI:

```bash
#!/usr/bin/env bash
#MISE description="Build the CLI"
cargo build
```

Ensure that the file is executable, otherwise mise will not be able to detect it.

:::tip
The `mise:description` comment is optional but recommended. It will be used in the output of `mise tasks`.
The other configuration for "script" tasks is supported in this format so you can specify things like the
following-note that this is parsed a TOML table:

```bash
#MISE alias="b"
#MISE sources=["Cargo.toml", "src/**/*.rs"]
#MISE outputs=["target/debug/mycli"]
#MISE env={RUST_BACKTRACE = "1"}
#MISE depends=["lint", "test"]
```

Assuming that file was located in `.mise/tasks/build`, it can then be run with `mise run build` (or with its alias: `mise run b`).
This script can be edited with by running `mise task edit build` (using $EDITOR). If it doesn't exist it will be created.
These are convenient for quickly making new scripts. Having the code in a bash file and not TOML helps make it work
better in editors since they can do syntax highlighting and linting more easily. They also still work great for non-mise users—though
of course they'll need to find a different way to install their dev tools the tasks might use.
:::

## Task Grouping

File tasks in `.mise/tasks`, `mise/tasks`, or `.config/mise/tasks` can be grouped into
sub-directories which will automatically apply prefixes to their names
when loaded.

### Example

With a folder structure like below:

```text
.mise
└── tasks
    ├── build
    └── test
        ├── integration
        └── units
```

Running `mise tasks` will give the below output:

```text
$ mise tasks
Name              Description Source
build                         .../.mise/tasks/build
test:integration              .../.mise/tasks/test/integration
test:units                    .../.mise/tasks/test/units
```

## Arguments

[usage](https://usage.jdx.dev) spec can be used within these files to provide argument parsing, autocompletion,
documentation when running mise and can be exported to markdown. Essentially this turns tasks into
fully-fledged CLIs.

:::tip
The `usage` CLI is not required to execute mise tasks with the usage spec.
However, for completions to work, the `usage` CLI must be installed and available in the PATH.
:::

Here is an example of a file task that builds a Rust CLI using some of the features of usage:

```bash
#!/usr/bin/env bash
set -e

#USAGE flag "-c --clean" help="Clean the build directory before building"
#USAGE flag "-p --profile <profile>" help="Build with the specified profile" {
#USAGE   choices "debug" "release"
#USAGE }
#USAGE flag "-u --user <user>" help="The user to build for"
#USAGE complete "user" run="mycli users"
#USAGE arg "<target>" help="The target to build"

if [ "$usage_clean" = "true" ]; then
  cargo clean
fi

cargo build --profile "${usage_profile:-debug}" --target "$usage_target"
```

Completions will now be enabled for your task. In this example, `mise run build --profile <tab><tab>`
will show `debug` and `release` as options. The `--user` flag will also show completions generated by the output of `mycli users`.

(Note that cli and markdown help for tasks is not yet implemented in mise as of this writing but that is planned.)

# toml-tasks.md

# TOML-based Tasks

Tasks can be defined in `mise.toml` files in different ways:

```toml
[tasks.cleancache]
run = "rm -rf .cache"
hide = true # hide this task from the list

[tasks.clean]
depends = ['cleancache']
run = "cargo clean" # runs as a shell command

[tasks.build]
description = 'Build the CLI'
run = "cargo build"
alias = 'b' # `mise run b`

[tasks.test]
description = 'Run automated tests'
run = [# multiple commands are run in series
    'cargo test',
    './scripts/test-e2e.sh',
]
dir = "{{cwd}}" # run in user's cwd, default is the project's base directory

[tasks.lint]
description = 'Lint with clippy'
env = { RUST_BACKTRACE = '1' } # env vars for the script
# specify a shell command to run the script with (default is 'sh -c')
shell = 'bash -c'
# you can specify a multiline script instead of individual commands
run = """
#!/usr/bin/env bash
cargo clippy
"""

[tasks.ci] # only dependencies to be run
description = 'Run CI tasks'
depends = ['build', 'lint', 'test']

[tasks.release]
description = 'Cut a new release'
file = 'scripts/release.sh' # execute an external script
```

## Arguments

By default, arguments are passed to the last script in the `run` array. So if a task was defined as:

```toml
[tasks.test]
run = ['cargo test', './scripts/test-e2e.sh']
```

Then running `mise run test foo bar` will pass `foo bar` to `./scripts/test-e2e.sh` but not to
`cargo test`.

You can also define arguments using templates:

```toml
[tasks.test]
run = [
    'cargo test {{arg(name="cargo_test_args", var=true)}}',
    './scripts/test-e2e.sh {{option(name="e2e_args")}}',
]
```

Then running `mise run test foo bar` will pass `foo bar` to `cargo test`.
`mise run test --e2e-args baz` will pass `baz` to `./scripts/test-e2e.sh`.
If any arguments are defined with templates then mise will not pass the arguments to the last script
in the `run` array.

:::tip
Using templates to define arguments will make them work with completion and help messages.
:::

### Positional Arguments

These are defined in scripts with <span v-pre>`{{arg()}}`</span>. They are used for positional
arguments where the order matters.

Example:

```toml
[tasks.test]
run = 'cargo test {{arg(name="file")}}'
# execute: mise run test my-test-file
# runs: cargo test my-test-file
```

- `i`: The index of the argument. This can be used to specify the order of arguments. Defaults to
  the order they're defined in the scripts.
- `name`: The name of the argument. This is used for help/error messages.
- `var`: If `true`, multiple arguments can be passed.
- `default`: The default value if the argument is not provided.

### Options

These are defined in scripts with <span v-pre>`{{option()}}`</span>. They are used for named
arguments where the order doesn't matter.

Example:

```toml
[tasks.test]
run = 'cargo test {{option(name="file")}}'
# execute: mise run test --file my-test-file
# runs: cargo test my-test-file
```

- `name`: The name of the argument. This is used for help/error messages.
- `var`: If `true`, multiple values can be passed.
- `default`: The default value if the option is not provided.

### Flags

Flags are like options except they don't take values. They are defined in scripts with <span v-pre>
`{{flag()}}`</span>.

Example:

```toml
[tasks.echo]
run = 'echo {{flag(name=("myflag")}}'
# execute: mise run echo --myflag
# runs: echo true
```

- `name`: The name of the flag. This is used for help/error messages.

The value will be `true` if the flag is passed, and `false` otherwise.

## Windows

You can specify an alternate command to run on Windows by using the `run_windows` key:

```toml
[tasks.test]
run = 'cargo test'
run_windows = 'cargo test --features windows'
```

# index.md

# Tasks

You can define tasks in `mise.toml` files or as standalone shell scripts. These are useful for
things like running linters, tests, builders, servers, and other tasks that are specific to a
project. Of
course, tasks launched with mise will include the mise environment—your tools and env vars defined
in `mise.toml`.

Here's my favorite features about mise's task runner:

- building dependencies in parallel—by default with no configuration required
- last-modified checking to avoid rebuilding when there are no changes—requires minimal config
- `mise watch` to automatically rebuild on changes—no configuration required, but it helps
- ability to write tasks as actual bash script files and not inside yml/json/toml strings that lack
  syntax highlighting and linting/checking support

## Task Environment Variables

- `root` - the root of the project, defaults to the directory of the `mise.toml` file

## Task Configuration

You can configure how tasks are used in mise with the `[task_config]` section of `mise.toml`:

```toml
[task_config]

# add toml files containing toml tasks, or file tasks to include when looking for tasks
includes = [
    "tasks.toml", # a task toml file
    "mytasks"     # a directory containing file tasks
]
```

If using a toml file for tasks, the file should be the same format as the `[tasks]` section of
`mise.toml` but without the `[task]` prefix:

```toml
task1 = "echo task1"
task2 = "echo task2"
task3 = "echo task3"

[task4]
run = "echo task4"
```

## Vars

Vars are variables that can be shared between tasks like environment variables but they are not
passed as environment variables to the scripts. They are defined in the `vars` section of the
`mise.toml` file.

```toml
[vars]
e2e_args = '--headless'

[tasks.test]
run = './scripts/test-e2e.sh {{vars.e2e_args}}'
```

Like most configuration in mise, vars can be defined across several files. So for example, you could
put some vars in your global mise config `~/.config/mise/config.toml`, use them in a task at
`~/src/work/myproject/mise.toml`. You can also override those vars in "later" config files such
as `~/src/work/myproject/mise.local.toml` and they will be used inside tasks of any config file.

As of this writing vars are only supported in TOML tasks. I want to add support for file tasks, but
I don't want to turn all file tasks into tera templates just for this feature.

# running-tasks.md

# Running Tasks

See available tasks with `mise tasks`. To show tasks hidden with property `hide=true`, use the option `--hidden`.

List dependencies of tasks with `mise task deps [tasks]...`.

Run a task with `mise task run`, `mise run`, or just `mise r`.
You might even want to make a shell alias like `alias mr='mise run --'` since this is likely a common command.

By default, tasks will execute with a maximum of 4 parallel jobs. Customize this with the `--jobs` option,
`jobs` setting or `MISE_JOBS` environment variable. The output normally will be by line, prefixed with the task
label. By printing line-by-line we avoid interleaving output from parallel executions. However, if
--jobs == 1, the output will be set to `interleave`.

To just print stdout/stderr directly, use `--interleave`, the `task_output` setting, or `MISE_TASK_OUTPUT=interleave`.

Stdin is not read by default. To enable this, set `raw = true` on the task that needs it. This will prevent
it running in parallel with any other task-a RWMutex will get a write lock in this case.

Extra arguments will be passed to the task, for example, if we want to run in release mode:

```bash
mise run build --release
```

If there are multiple commands, the args are only passed to the last command.

:::tip
You can define arguments/flags for tasks which will provide validation, parsing, autocomplete, and documentation.

- [Arguments in File Tasks](/tasks/file-tasks#arguments)
- [Arguments in TOML Tasks](/tasks/toml-tasks#arguments)

Autocomplete will work automatically for tasks if the `usage` CLI is installed and mise completions are working.

Markdown documentation can be generated with [`mise generate task-docs`](/cli/generate/task-docs).
:::

Multiple tasks/arguments can be separated with this `:::` delimiter:

```bash
mise run build arg1 arg2 ::: test arg3 arg4
```

mise will run the task named "default" if no task is specified—and you've created one named "default". You can also alias a different task to "default".

```bash
mise run
```

## Task Grouping

Tasks can be grouped semantically by using name prefixes separated with `:`s.
For example all testing related tasks may begin with `test:`. Nested grouping
can also be used to further refine groups and simplify pattern matching.
For example running `mise run test:**:local` will match`test:units:local`,
`test:integration:local` and `test:e2e:happy:local`
(See [Wildcards](#wildcards) for more information).

## Wildcards

Glob style wildcards are supported when running tasks or specifying tasks
dependencies.

Available Wildcard Patterns:

- `?` matches any single character
- `*` matches 0 or more characters
- `**` matches 0 or more groups
- `{glob1,glob2,...}` matches any of the comma-separated glob patterns
- `[ab,...]` matches any of the characters or ranges `[a-z]`
- `[!ab,...]` matches any character not in the character set

### Examples

`mise run generate:{completions,docs:*}`

And with dependencies:

```toml
[tasks."lint:eslint"] # using a ":" means we need to add quotes
run = "eslint ."
[tasks."lint:prettier"]
run = "prettier --check ."
[tasks.lint]
depends = ["lint:*"]
wait_for = ["render"] # does not add as a dependency, but if it is already running, wait for it to finish
```

## Running on file changes

It's often handy to only execute a task if the files it uses changes. For example, we might only want
to run `cargo build` if an ".rs" file changes. This can be done with the following config:

```toml
[tasks.build]
description = 'Build the CLI'
run = "cargo build"
sources = ['Cargo.toml', 'src/**/*.rs'] # skip running if these files haven't changed
outputs = ['target/debug/mycli']
```

Now if `target/debug/mycli` is newer than `Cargo.toml` or any ".rs" file, the task will be skipped. This uses last modified timestamps.
It wouldn't be hard to add checksum support.

## Watching files

Run a task when the source changes with `mise watch`:

```bash
mise watch -t build
```

Currently this just shells out to watchexec-which you can install however you want including with mise: `mise use -g watchexec@latest`.
This may change in the future.

Arguments to `mise watch` will be forwarded onto watchexec. For example, to print diagnostic info:

```bash
mise watch -t build -- --print-events --verbose
```

See watchexec's help with `watchexec --help` or `mise watch -- --help` to see
all of the options.

# templates.md

# Templates

Templates in mise provide a powerful way to configure different aspects of
your environment and project settings.
You can define and use templates in the following locations:

- `.tool-versions` files
- Most `mise.toml` configuration values
  - The `mise.toml` file itself is not templated and must be valid toml
- _(Submit a ticket if you want to see it used elsewhere!)_

## Template Rendering

Mise uses [tera](https://keats.github.io/tera/docs/) to provide the template feature.
In the template, there are 3 kinds of delimiters:

- <span v-pre>`{{`</span> and <span v-pre>`}}`</span> for expressions
- <span v-pre>`{%`</span> and <span v-pre>`%}`</span> for statements
- <span v-pre>`{#`</span> and <span v-pre>`#}`</span> for comments

Additionally, use `raw` block to skip rendering tera delimiters:

<div v-pre>

```
{% raw %}
  Hello {{ name }}
{% endraw %}
```

</div>

This will become <span v-pre>`Hello {{name}}`</span>.

Tera supports [literals](https://keats.github.io/tera/docs/#literals), including:

- booleans: `true` (or `True`) and `false` (or `False`)
- integers
- floats
- strings: text delimited by `""`, `''` or <code>\`\`</code>
- arrays: a comma-separated list of literals and/or ident surrounded by
  `[` and `]` (trailing comma allowed)

You can render a variable by using the <span v-pre>`{{ name }}`</span>.
For complex attributes, use:

- dot `.`, e.g. <span v-pre>`{{ product.name }}`</span>
- square brackets `[]`, e.g. <span v-pre>`{{ product["name"] }}`</span>

Tera also supports powerful [expressions](https://keats.github.io/tera/docs/#expressions):

- mathematical expressions
  - `+`
  - `-`
  - `/`
  - `*`
  - `%`
- comparisons
  - `==`
  - `!=`
  - `>=`
  - `<=`
  - `<`
  - `>`
- logic
  - `and`
  - `or`
  - `not`
- concatenation `~`, e.g. <code v-pre>{{ "hello " ~ 'world' ~ \`!\` }</code>
- in checking, e.g. <span v-pre>`{{ some_var in [1, 2, 3] }}`</span>

Tera also supports control structures such as <span v-pre>`if`</span> and
<span v-pre>`for`</span>. Read more [here](https://keats.github.io/tera/docs/#control-structures).

### Tera Filters

You can modify variables using [filters](https://keats.github.io/tera/docs/#filters).
You can filter a variable by a pipe symbol (`|`) and may have named arguments
in parentheses. You can also chain multiple filters.
e.g. <span v-pre>`{{ "Doctor Who" | lower | replace(from="doctor", to="Dr.") }}`</span>
will output `Dr. who`.

### Tera Functions

[Functions](https://keats.github.io/tera/docs/#functions) provide
additional features to templates.

### Tera Tests

You can also uses [tests](https://keats.github.io/tera/docs/#tests) to examine variables.

```
{% if my_number is not odd %}
  Even
{% endif %}
```

## Mise Template Features

Mise provides additional variables, functions, filters and tests on top of tera features.

### Variables

Mise exposes several [variables](https://keats.github.io/tera/docs/#variables).
These variables offer key information about the current environment:

- `env: HashMap<String, String>` – Accesses current environment variables as
  a key-value map.
- `cwd: PathBuf` – Points to the current working directory.
- `config_root: PathBuf` – Locates the directory containing your `.mise.toml` file
  or the `.mise` configuration folder.
- `mise_bin: String` - Points to the path to the current mise executable
- `mise_pid: String` - Points to the pid of the current mise process
- `xdg_cache_home: PathBuf` - Points to the directory of XDG cache home
- `xdg_config_home: PathBuf` - Points to the directory of XDG config home
- `xdg_data_home: PathBuf` - Points to the directory of XDG data home
- `xdg_state_home: PathBuf` - Points to the directory of XDG state home

### Functions

Tera offers many [built-in functions](https://keats.github.io/tera/docs/#built-in-functions).
`[]` indicates an optional function argument.
Some functions:

- `range(end, [start], [step_by])` - Returns an array of integers created
  using the arguments given.
  - `end: usize`: stop before `end`, mandatory
  - `start: usize`: where to start from, defaults to `0`
  - `step_by: usize`: with what number do we increment, defaults to `1`
- `now([timestamp], [utc])` - Returns the local datetime as string or
  the timestamp as integer.
  - `timestamp: bool`: whether to return the timestamp instead of the datetime
  - `utc: bool`: whether to return the UTC datetime instead of
    the local one
  - Tip: use date filter to format date string.
    e.g. <span v-pre>`{{ now() | date(format="%Y") }}`</span> gets the current year.
- `throw(message)` - Throws with the message.
- `get_random(end, [start])` - Returns a random integer in a range.
  - `end: usize`: upper end of the range
  - `start: usize`: defaults to 0
- `get_env(name, [default])`: Returns the environment variable value by name.
  Prefer `env` variable than this function.
  - `name: String`: the name of the environment variable
  - `default: String`: a default value in case the environment variable is not found.
    Throws when can't find the environment variable and `default` is not set.

Tera offers more functions. Read more on [tera documentation](https://keats.github.io/tera/docs/#functions).

Mise offers additional functions:

- `exec(command) -> String` – Runs a shell command and returns its output as a string.
- `arch() -> String` – Retrieves the system architecture, such as `x86_64` or `arm64`.
- `os() -> String` – Returns the name of the operating system,
  e.g. linux, macos, windows.
- `os_family() -> String` – Returns the operating system family, e.g. `unix`, `windows`.
- `num_cpus() -> usize` – Gets the number of CPUs available on the system.
- `choice(n, alphabet)` - Generate a string of `n` with random sample with replacement
  of `alphabet`. For example, `choice(64, HEX)` will generate a random
  64-character lowercase hex string.

A example of function using `exec`:

```toml
[alias.node.versions]
current = "{{ exec(command='node --version') }}"
```

### Filters

Tera offers many [built-in filters](https://keats.github.io/tera/docs/#built-in-filters).
`[]` indicates an optional filter argument.
Some filters:

- `str | lower -> String` – Converts a string to lowercase.
- `str | upper -> String` – Converts a string to uppercase.
- `str | capitalize -> String` – Converts a string with all its characters lowercased
  apart from the first char which is uppercased.
- `str | replace(from, to) -> String` – Replaces a string with all instances of
  `from` to `to`. e.g., <span v-pre>`{{ name | replace(from="Robert", to="Bob")}}`</span>
- `str | title -> String` – Capitalizes each word inside a sentence.
  e.g., <span v-pre>`{{ "foo bar" | title }}`</span> becomes `Foo Bar`.
- `str | trim -> String` – Removes leading and trailing whitespace.
- `str | trim_start -> String` – Removes leading whitespace.
- `str | trim_end -> String` – Removes trailing whitespace.
- `str | truncate -> String` – Truncates a string to the indicated length.
- `str | first -> String` – Returns the first element in an array or string.
- `str | last -> String` – Returns the last element in an array or string.
- `str | join(sep) -> String` – Joins an array of strings with a separator,
  such as <span v-pre>`{{ ["a", "b", "c"] | join(sep=", ") }}`</span>
  to produce `a, b, c`.
- `str | length -> usize` – Returns the length of a string or array.
- `str | reverse -> String` – Reverses the order of characters in a string or
  elements in an array.
- `str | urlencode -> String` – Encodes a string to be safely used in URLs,
  converting special characters to percent-encoded values.
- `str | map(attribute) -> Array` – Extracts an attribute from each object
  in an array.
- `str | concat(with) -> Array` – Appends values to an array.
- `str | abs -> Number` – Returns the absolute value of a number.
- `str | filesizeformat -> String` – Converts an integer into
  a human-readable file size (e.g., 110 MB).
- `str | date(format) -> String` – Converts a timestamp to
  a formatted date string using the provided format,
  such as <span v-pre>`{{ ts | date(format="%Y-%m-%d") }}`</span>.
  Find a list of time format on [`chrono` documentation][chrono-doc].
- `str | split(pat) -> Array` – Splits a string by the given pattern and
  returns an array of substrings.
- `str | default(value) -> String` – Returns the default value
  if the variable is not defined or is empty.

Tera offers more filters. Read more on [tera documentation](https://keats.github.io/tera/docs/#built-in-filters).

#### Hash

- `str | hash([len]) -> String` – Generates a SHA256 hash for the input string.
  - `len: usize`: truncates the hash string to the given size
- `path | hash_file([len]) -> String` – Returns the SHA256 hash of the file
  at the given path.
  - `len: usize`: truncates the hash string to the given size

#### Path Manipulation

- `path | canonicalize -> String` – Converts the input path into
  absolute input path version. Throws if path doesn't exist.
- `path | basename -> String` – Extracts the file name from a path,
  e.g. `/foo/bar/baz.txt` becomes `baz.txt`.
- `path | file_size -> String` – Returns the size of a file in bytes.
- `path | dirname -> String` – Returns the directory path for a file,
  e.g. `/foo/bar/baz.txt` becomes `/foo/bar`.
- `path | basename -> String` – Returns the base name of a file,
  e.g. `/foo/bar/baz.txt` becomes `baz.txt`.
- `path | extname -> String` – Returns the extension of a file,
  e.g. `/foo/bar/baz.txt` becomes `.txt`.
- `path | file_stem -> String` – Returns the file name without the extension,
  e.g. `/foo/bar/baz.txt` becomes `baz`.
- `path | file_size -> String` – Returns the size of a file in bytes.
- `path | last_modified -> String` – Returns the last modified time of a file.
- `path[] | join_path -> String` – Joins an array of paths into a single path.

For example, you can use `split()`, `concat()`, and `join_path` filters to
construct a file path:

```toml
[env]
PROJECT_CONFIG = "{{ config_root | concat(with='bar.txt') | join_path }}"
```

#### String Manipulation

- `str | quote -> String` – Quotes a string. Converts `'` to `\'` and
  then quotes str, e.g `'it\'s str'`.
- `str | kebabcase -> String` – Converts a string to kebab-case
- `str | lowercamelcase -> String` – Converts a string to lowerCamelCase
- `str | uppercamelcase -> String` – Converts a string to UpperCamelCase
- `str | shoutycamelcase -> String` – Converts a string to ShoutyCamelCase
- `str | snakecase -> String` – Converts a string to snake_case
- `str | shoutysnakecase -> String` – Converts a string to SHOUTY_SNAKE_CASE

### Tests

Tera offers many [built-in tests](https://keats.github.io/tera/docs/#built-in-tests).
Some tests:

- `defined` - Returns `true` if the given variable is defined.
- `string` - Returns `true` if the given variable is a string.
- `number` - Returns `true` if the given variable is a number.
- `starting_with` - Returns `true` if the given variable is a string and starts with
  the arg given.
- `ending_with` - Returns `true` if the given variable is a string and ends with
  the arg given.
- `containing` - Returns `true` if the given variable contains the arg given.
- `matching` - Returns `true` if the given variable is a string and matches the regex
  in the argument.

Tera offers more tests. Read more on [tera documentation](https://keats.github.io/tera/docs/#built-in-tests).

Mise offers additional tests:

- `if path is dir` – Checks if the provided path is a directory.
- `if path is file` – Checks if the path points to a file.
- `if path is exists` – Checks if the path exists.

### Example Templates

#### A Node.js Project

```toml
min_version = "2024.9.5"

[env]
# Use the project name derived from the current directory
PROJECT_NAME = "{{ cwd | basename }}"

# Set up the path for node module binaries
BIN_PATH = "{{ cwd }}/node_modules/.bin"

NODE_ENV = "{{ env.NODE_ENV | default(value='development') }}"

[tools]
# Install Node.js using the specified version
node = "{{ env['NODE_VERSION'] | default(value='lts') }}"

# Install npm packages globally if needed
"npm:typescript" = "latest"
"npm:eslint" = "latest"
"npm:jest" = "latest"

# Install npm dependencies
[tasks.install]
alias = "i"
run = "npm install"

# Run the development server
[tasks.start]
alias = "s"
run = "npm run start"

# Run linting
[tasks.lint]
alias = "l"
run = "eslint src/"

# Run tests
[tasks.test]
alias = "t"
run = "jest"

# Build the project
[tasks.build]
alias = "b"
run = "npm run build"

# Print project info
[tasks.info]
run = '''
echo "Project: $PROJECT_NAME"
echo "NODE_ENV: $NODE_ENV"
'''
```

#### A Python Project with virtualenv

```toml
min_version = "2024.9.5"

[env]
# Use the project name derived from the current directory
PROJECT_NAME = "{{ cwd | basename }}"

# Automatic virtualenv activation
_.python.venv = { path = ".venv", create = true }

[tools]
# Install the specified Python version
python = "{{ get_env(name='PYTHON_VERSION', default='3.11') }}"

# Install dependencies
[tasks.install]
alias = "i"
run = "pip install -r requirements.txt"

# Run the application
[tasks.run]
run = "python app.py"

# Run tests
[tasks.test]
run = "pytest tests/"

# Lint the code
[tasks.lint]
run = "ruff src/"

# Print environment information
[tasks.info]
run = '''
echo "Project: $PROJECT_NAME"
echo "Virtual Environment: $VIRTUAL_ENV"
'''
```

#### A C++ Project with CMake

```toml
min_version = "2024.9.5"

[env]
# Project information
PROJECT_NAME = "{{ cwd | basename }}"

# Build directory
BUILD_DIR = "{{ cwd }}/build"

[tools]
# Install CMake and make
cmake = "latest"
make = "latest"

# Configure the project
[tasks.configure]
run = "mkdir -p $BUILD_DIR && cd $BUILD_DIR && cmake .."

# Build the project
[tasks.build]
alias = "b"
run = "cd $BUILD_DIR && make"

# Clean the build directory
[tasks.clean]
alias = "c"
run = "rm -rf $BUILD_DIR"

# Run the application
[tasks.run]
alias = "r"
run = "$BUILD_DIR/bin/$PROJECT_NAME"

# Print project info
[tasks.info]
run = '''
echo "Project: $PROJECT_NAME"
echo "Build Directory: $BUILD_DIR"
'''
```

#### A Ruby on Rails Project

```toml
min_version = "2024.9.5"

[env]
# Project information
PROJECT_NAME = "{{ cwd | basename }}"

[tools]
# Install Ruby with the specified version
ruby = "{{ get_env(name='RUBY_VERSION', default='3.3.3') }}"

# Install gem dependencies
[tasks."bundle:install"]
run = "bundle install"

# Run the Rails server
[tasks.server]
alias = "s"
run = "rails server"

# Run tests
[tasks.test]
alias = "t"
run = "rails test"

# Lint the code
[tasks.lint]
alias = "l"
run = "rubocop"
```

[chrono-doc]: https://docs.rs/chrono/0.4.38/chrono/format/strftime/index.html

# troubleshooting.md

# Troubleshooting

## `mise activate` doesn't work in `~/.profile`, `~/.bash_profile`, `~/.zprofile`

`mise activate` should only be used in `rc` files. These are the interactive ones used when
a real user is using the terminal. (As opposed to being executed by an IDE or something). The prompt
isn't displayed in non-interactive environments so PATH won't be modified.

For non-interactive setups, consider using shims instead which will route calls to the correct
directory by looking at `PWD` every time they're executed. You can also call `mise exec` instead of
expecting things to be directly on PATH. You can also run `mise env` in a non-interactive shell,
however that
will only setup the global tools. It won't modify the environment variables when entering into a
different project.

Also see the [shebang](/tips-and-tricks#shebang) example for a way to make scripts call mise to get
the runtime.
That is another way to use mise without activation.

## mise is failing or not working right

First try setting `MISE_DEBUG=1` or `MISE_TRACE=1` and see if that gives you more information.
You can also set `MISE_LOG_FILE_LEVEL=debug MISE_LOG_FILE=/path/to/logfile` to write logs to a file.

If something is happening with the activate hook, you can try disabling it and
calling `eval "$(mise hook-env)"` manually.
It can also be helpful to use `mise env` which will just output environment variables that would be
set.
Also consider using [shims](/dev-tools/shims.md) which can be more compatible.

If runtime installation isn't working right, try using the `--raw` flag which will install things in
series and connect stdin/stdout/stderr directly to the terminal. If a plugin is trying to interact
with you for some reason this will make it work.

Of course check the version of mise with `mise --version` and make sure it is the latest.
Use `mise self-update`
to update it. `mise cache clean` can be used to wipe the internal cache and `mise implode` can be
used
to remove everything except config.

Before submitting a ticket, it's a good idea to test what you were doing with asdf. That way we can
rule
out if the issue is with mise or if it's with a particular plugin. For example,
if `mise install python@latest`
doesn't work, try running `asdf install python latest` to see if it's an issue with asdf-python.

Lastly, there is `mise doctor` which will show diagnostic information and any warnings about issues
detected with your setup. If you submit a bug report, please include the output of `mise doctor`.

## The wrong version of a tool is being used

Likely this means that mise isn't first in PATH—using shims or `mise activate`. You can verify if
this is the case by calling `which -a`, for example, if node@20.0.0 is being used but mise specifies
node@22.0.0, first make sure that mise has this version installed and active by running `mise ls node`.
It should not say missing and have the correct "Requested" version:

```bash
$ mise ls node
Plugin  Version  Config Source       Requested
node    22.0.0  ~/.mise/config.toml  22.0.0
```

If `node -v` isn't showing the right version, make sure mise is activated by running `mise doctor`.
It should not have a "problem" listed about mise not being activated. Lastly, run `which -a node`.
If the directory listed is not a mise directory, then mise is not first in PATH. Whichever node is
being run first needs to have its directory set before mise is. Typically this means setting PATH for
mise shims at the end of bashrc/zshrc.

If using `mise activate`, you have another option of enabling `MISE_ACTIVATE_AGGRESSIVE=1` which will
have mise always prepend its tools to be first in PATH. If you're using something that also modifies
paths dynamically like `mise activate` does, this may not work because the other tool may be modifying
PATH after mise does.

If nothing else, you can run things with [`mise x --`](/cli/exec) to ensure that the correct version is being used.

## New version of a tool is not available

There are 2 places that versions are cached so a brand new release might not appear right away.

The first is that the mise CLI caches versions for. The cache can be cleared with `mise cache clear`.

The second uses the mise-versions.jdx.dev host as a centralized
place to list all of the versions of most plugins. This is intended to speed up mise and also
get around GitHub rate limits when querying for new versions. Check that repo for your plugin to
see if it has an updated version. This service can be disabled by
setting `MISE_USE_VERSIONS_HOST=0`.

## Windows problems

Very basic support for windows is currently available, however because Windows can't support asdf
plugins, they must use core and vfox only—which means only a handful of tools are available on
Windows.

As of this writing, env var management and task execution are not yet supported on Windows.

## mise isn't working when calling from tmux or another shell initialization script

`mise activate` will not update PATH until the shell prompt is displayed. So if you need to access a
tool provided by mise before the prompt is displayed you can either
[add the shims to your PATH](getting-started.html#2-add-mise-shims-to-path) e.g.

```bash
export PATH="$HOME/.local/share/mise/shims:$PATH"
python --version # will work after adding shims to PATH
```

Or you can manually call `hook-env`:

```bash
eval "$(mise activate bash)"
eval "$(mise hook-env)"
python --version # will work only after calling hook-env explicitly
```

For more information, see [What does `mise activate` do?](/faq#what-does-mise-activate-do)

## Is mise secure?

Providing a secure supply chain is incredibly important. mise already provides a more secure
experience when compared to asdf. Security-oriented evaluations and contributions are welcome.
We also urge users to look after the plugins they use, and urge plugin authors to look after
the users they serve.

For more details see [SECURITY.md](https://github.com/jdx/mise/blob/main/SECURITY.md).

## 403 Forbidden when installing a tool

You may get an error like one of the following:

```text
HTTP status client error (403 Forbidden) for url
403 API rate limit exceeded for
```

This can happen if the tool is hosted on GitHub, and you've hit the API rate limit. This is especially
common running mise in a CI environment like GitHub Actions. If you don't have a `GITHUB_TOKEN`
set, the rate limit is quite low. You can fix this by creating a GitHub token (which needs no scopes)
by going to <https://github.com/settings/tokens> and setting it as an environment variable. You can
use any of the following (in order of preference):

- `MISE_GITHUB_TOKEN`
- `GITHUB_TOKEN`
- `GITHUB_API_TOKEN`

# profiles.md

# Profiles

It's possible to have separate `mise.toml` files in the same directory for different
environments like `development` and `production`. To enable, either set the `-P,--profile` option or `MISE_PROFILE` environment
variable to an environment like `development` or `production`. mise will then look for a `mise.{MISE_PROFILE}.toml` file
in the current directory, parent directories and the `MISE_CONFIG_DIR` directory.

mise will also look for "local" files like `mise.local.toml` and `mise.{MISE_PROFILE}.local.toml`
in the current directory and parent directories.
These are intended to not be committed to version control.
(Add `mise.local.toml` and `mise.*.local.toml` to your `.gitignore` file.)

The priority of these files goes in this order (top overrides bottom):

- `mise.{MISE_PROFILE}.local.toml`
- `mise.local.toml`
- `mise.{MISE_PROFILE}.toml`
- `mise.toml`

You can also use paths like `mise/config.{MISE_PROFILE}.toml` or `.config/mise.{MISE_PROFILE}.toml` Those rules
follow the order in [Configuration](./configuration.md).

Use `mise config` to see which files are being used.

::: warning
Note that currently modifying `MISE_DEFAULT_CONFIG_FILENAME` to something other than `mise.toml`
will not work with this feature. For now, it will disable it entirely. This may change in the
future.
:::

# direnv.md

# direnv

[direnv](https://direnv.net) and mise both manage environment variables based on directory. Because
they both analyze
the current environment variables before and after their respective "hook" commands are run, they
can sometimes conflict with each other.

If you have an issue, it's likely to do with the ordering of PATH. This means it would
really only be a problem if you were trying to manage the same tool with direnv and mise. For
example,
you may use `layout python` in an `.envrc` but also be maintaining a `.tool-versions` file with
python
in it as well.

A more typical usage of direnv would be to set some arbitrary environment variables, or add
unrelated
binaries to PATH. In these cases, mise will not interfere with direnv.

## mise inside of direnv (`use mise` in `.envrc`)

::: warning
Update 2024-01-21: after `use mise` has been out for a while, the general impression I have is that
while it technically functions fine,
not many people use it because the DX is notably worse than either switching to mise entirely
or using `mise activate` alongside direnv.

The project direction of mise has changed since this was written and the new direction is for it
to be capable of replacing direnv completely for any use-case. This likely won't end up as a drop-in
replacement for direnv like with asdf, but solving the same problems in different ways.
See [environments](/environments.html)
for more details.

I have had virtually no reports of problems with `use mise` in the year it has been out.
This could be because virtually no one is using it, or it has been surprisingly stable. I genuinely
don't know which. If you try it or use it regularly let me know.

While I have no immediate plans or reasons to do this now, I could see this functionality being
the target of a future deprecation. Not because it's a maintenance burden, but because it just
hasn't
seemed like a particularly useful solution and it may help focus mise on the functionality that does
work for users.
:::

If you do encounter issues with `mise activate`, or just want to use direnv in an alternate way,
this is a simpler setup that's less likely to cause issues—at the cost of functionality.

This may be required if you want to use direnv's `layout python` with mise. Otherwise there are
situations where mise will override direnv's PATH. `use mise` ensures that direnv always has
control.

To do this, first use `mise` to build a `use_mise` function that you can use in `.envrc` files:

```sh
mise direnv activate > ~/.config/direnv/lib/use_mise.sh
```

Now in your `.envrc` file add the following:

```sh
use mise
```

direnv will now call mise to export its environment variables. You'll need to make sure to
add `use_mise`
to all projects that use mise (or use direnv's `source_up` to load it from a subdirectory). You can
also add `use mise` to `~/.config/direnv/direnvrc`.

Note that in this method direnv typically won't know to refresh `.tool-versions` files
unless they're at the same level as a `.envrc` file. You'll likely always want to have
a `.envrc` file next to your `.tool-versions` for this reason. To make this a little
easier to manage, I encourage _not_ actually using `.tool-versions` at all, and instead
setting environment variables entirely in `.envrc`:

```sh
export MISE_NODE_VERSION=20.0.0
export MISE_PYTHON_VERSION=3.11
```

Of course if you use `mise activate`, then these steps won't have been necessary and you can use
mise
as if direnv was not used.

If you continue to struggle, you can also try using the [shims method](dev-tools/shims.md).

### Do you need direnv?

While making mise compatible with direnv is, and will always be a major goal of this project, I also
want mise to be capable of replacing direnv if needed. This is why mise includes support for
managing
env vars and [virtualenv](lang/python.md#automatic-virtualenv-activation)
for python using `mise.toml`.

# contact.md

# Contact

`mise` is mostly built and maintained by me, [Jeff Dickey](https://jdx.dev). The goal is
to make local development of software easy and consistent across languages. I
have spent many years building dev tools and thinking about the problems that `mise`
addresses.

I try to use the first-person in these docs since the reality is it's generally me
writing them and I think it makes it more interesting having a bit of my personality
in the text.

This project is simply a labor of love. I am making it because I want to make
your life as a developer easier. I hope you find it useful. Feedback is a massive
driver for me. If you have anything positive or negative to say-even if it's just
to say hi-please reach out to me either on [Twitter](https://twitter.com/jdxcode),
[Mastodon](https://fosstodon.org/@jdx), [Discord](https://discord.gg/UBa7pJUN7Z),
or `jdx at this domain`.

# faq.md

# FAQs

## I don't want to put a `.tool-versions`/`mise.toml` file into my project since git shows it as an untracked file

Use [`mise.local.toml`](https://mise.jdx.dev/configuration.html#mise-toml) and put that into your global gitignore file. This file should never be committed.

Or you can make git ignore these files in 3 different ways:

- Adding `.tool-versions` to project's `.gitignore` file. This has the downside that you need to
  commit the change to the ignore file.
- Adding `.tool-versions` to project's `.git/info/exclude`. This file is local to your project so
  there is no need to commit it.
- Adding `.tool-versions` to global gitignore (`core.excludesFile`). This will cause git to
  ignore `.tool-versions` files in all projects. You can explicitly add one to a project if needed
  with `git add --force .tool-versions`.

## What is the difference between "nodejs" and "node" (or "golang" and "go")?

These are aliased. For example, `mise use nodejs@14.0` is the same as `mise install node@14.0`. This
means it is not possible to have these be different plugins.

This is for convenience so you don't need to remember which one is the "official" name. However if
something with the aliasing is acting up, submit a ticket or just stick to using "node" and "go".
Under the hood, when mise reads a config file or takes CLI input it will swap out "nodejs" and
"golang".

While this change is rolling out, there is some migration code that will move installs/plugins from
the "nodejs" and "golang" directories to the new names. If this runs for you you'll see a message
but it should not run again unless there is some kind of problem. In this case, it's probably
easiest to just
run
`rm -rf ~/.local/share/mise/installs/{golang,nodejs} ~/.local/share/mise/plugins/{golang,nodejs}`.

Once most users have migrated over this migration code will be removed.

## What does `mise activate` do?

It registers a shell hook to run `mise hook-env` every time the shell prompt is displayed.
`mise hook-env` checks the current env vars (most importantly `PATH` but there are others like
`GOROOT` or `JAVA_HOME` for some tools) and adds/removes/updates the ones that have changed.

For example, if you `cd` into a different directory that has `java 18` instead of `java 17`
specified, just before the next prompt is displayed the shell runs: `eval "$(mise hook-env)"`
which will execute something like this in the current shell session:

```sh
export JAVA_HOME=$HOME/.local/share/installs/java/18
export PATH=$HOME/.local/share/installs/java/18/bin:$PATH
```

In reality updating `PATH` is a bit more complex than that because it also needs to remove java-17,
but you get the idea.

You may think that is excessive to run `mise hook-env` every time the prompt is displayed
and it should only run on `cd`, however there are plenty of
situations where it needs to run without the directory changing, for example if `.tool-versions` or
`mise.toml` was just edited in the current shell.

Because it runs on prompt display, if you attempt to use `mise activate` in a
non-interactive session (like a bash script), it will never call `mise hook-env` and in effect will
never modify PATH because it never displays a prompt. For this type of setup, you can either call
`mise hook-env` manually every time you wish to update PATH, or use [shims](/dev-tools/shims.md)
instead (preferred).
Or if you only need to use mise for certain commands, just prefix the commands with
[`mise x --`](./cli/exec).
For example, `mise x -- npm test` or `mise x -- ./my_script.sh`.

`mise hook-env` will exit early in different situations if no changes have been made. This prevents
adding latency to your shell prompt every time you run a command. You can run `mise hook-env`
yourself
to see what it outputs, however it is likely nothing if you're in a shell that has already been
activated.

`mise activate` also creates a shell function (in most shells) called `mise`.
This is a trick that makes it possible for `mise shell`
and `mise deactivate` to work without wrapping them in `eval "$(mise shell)"`.

## Windows support?

Very basic support for windows is currently available, however because Windows can't support the asdf
backend, windows can use core, aqua, or vfox backends though.

As of this writing, env var management and task execution are not yet supported on Windows.

## How do I use mise with http proxies?

Short answer: just set `http_proxy` and `https_proxy` environment variables. These should be
lowercase.

This may not work with all plugins if they are not configured to use these env vars.
If you're having a proxy-related issue installing something specific you should post an issue on the
plugin's repository.

## How do the shorthand plugin names map to repositories?

e.g.: how does `mise plugin install elixir` know to fetch <https://github.com/asdf-vm/asdf-elixir>?

We maintain [an index](https://github.com/mise-plugins/registry) of shorthands that mise uses as a
base.
This is regularly updated every time that mise has a release. This repository is stored directly
into
the codebase [here](https://github.com/jdx/mise/blob/main/registry.toml).

## Does "node@20" mean the newest available version of node?

It depends on the command. Normally, for most commands and inside of config files, "node@20" will
point to the latest _installed_ version of node-20.x. You can find this version by running
`mise latest --installed node@20` or by seeing what the `~/.local/share/mise/installs/node/20`
symlink
points to:

```sh
$ ls -l ~/.local/share/mise/installs/node/20
[...] /home/jdx/.local/share/mise/installs/node/20 -> node-v20.0.0-linux-x64
```

There are some exceptions to this, such as the following:

- `mise install node@20`
- `mise latest node@20`
- `mise upgrade node@20`

These will use the latest _available_ version of node-20.x. This generally makes sense because you
wouldn't want to install a version that is already installed.

## How do I migrate from asdf?

First, just install mise with `mise activate` like in the getting started guide and remove asdf from
your
shell rc file.

Then you can just run `mise install` in a directory with an asdf `.tool-versions` file and it will
install the runtimes. You could attempt to avoid this by copying the internal directory from asdf
over
to mise with `cp -r ~/.asdf ~/.local/share/mise`. That _should_ work because they use the same
structure,
however this isn't officially supported or regularly tested. Alternatively you can
set `MISE_DATA_DIR=~/.asdf`
and see what happens.

## How compatible is mise with asdf?

mise should be able to read/install any `.tool-versions` file used by asdf. Any asdf plugin
should be usable in mise. The commands in mise are slightly
different, such as `mise install node@20.0.0` vs `asdf install node 20.0.0`—this is done so
multiple tools can be specified at once. However, asdf-style syntax is still supported: (`mise
install node 20.0.0`). This is the case for most commands, though the help for the command may
say that asdf-style syntax is supported.

When in doubt, just try asdf syntax and see if it works. If it doesn't open a ticket. It may
not be possible to support every command identically, but
we should attempt to make things as consistent as possible.

This isn't important for usability reasons so much as making it so plugins continue to work that
call asdf commands.

If you need to switch to/from asdf or work in a project with asdf users, you can set
[`MISE_ASDF_COMPAT=1`](/configuration#mise_asdf_compat1). That prevents
mise from writing `.tool-versions` files that will not be
compatible with asdf. Also consider using `mise.toml` instead which won't conflict with asdf
setups.

## How do I disable/force CLI color output?

mise uses [console.rs](https://docs.rs/console/latest/console/fn.colors_enabled.html) which
honors the [clicolors spec](https://bixense.com/clicolors/):

- `CLICOLOR != 0`: ANSI colors are supported and should be used when the program isn’t piped.
- `CLICOLOR == 0`: Don’t output ANSI color escape codes.
- `CLICOLOR_FORCE != 0`: ANSI colors should be enabled no matter what.

## Is mise secure?

Providing a secure supply chain is incredibly important. mise already provides a more secure
experience when compared to asdf. Security-oriented evaluations and contributions are welcome.
We also urge users to look after the plugins they use, and urge plugin authors to look after
the users they serve.

For more details see [SECURITY.md](https://github.com/jdx/mise/blob/main/SECURITY.md).

# errors.md

# Errors

TODO

# uninstall.md

# `mise uninstall`

- **Usage**: `mise uninstall [-a --all] [-n --dry-run] [INSTALLED_TOOL@VERSION]...`
- **Aliases**: `remove`, `rm`

Removes installed tool versions

This only removes the installed version, it does not modify mise.toml.

## Arguments

### `[INSTALLED_TOOL@VERSION]...`

Tool(s) to remove

## Flags

### `-a --all`

Delete all installed versions

### `-n --dry-run`

Do not actually delete anything

Examples:

    # will uninstall specific version
    $ mise uninstall node@18.0.0

    # will uninstall the current node version (if only one version is installed)
    $ mise uninstall node

    # will uninstall all installed versions of node
    $ mise uninstall --all node@18.0.0 # will uninstall all node versions

# get.md

# `mise settings get`

- **Usage**: `mise settings get [-l --local] <KEY>`

Show a current setting

This is the contents of a single entry in ~/.config/mise/config.toml

Note that aliases are also stored in this file
but managed separately with `mise aliases get`

## Arguments

### `<KEY>`

The setting to show

## Flags

### `-l --local`

Use the local config file instead of the global one

Examples:

    $ mise settings get legacy_version_file
    true

# set.md

# `mise settings set`

- **Usage**: `mise settings set [-l --local] <KEY> <VALUE>`
- **Aliases**: `create`

Add/update a setting

This modifies the contents of ~/.config/mise/config.toml

## Arguments

### `<KEY>`

The setting to set

### `<VALUE>`

The value to set

## Flags

### `-l --local`

Use the local config file instead of the global one

Examples:

    mise settings legacy_version_file=true

# add.md

# `mise settings add`

- **Usage**: `mise settings add [-l --local] <KEY> <VALUE>`

Adds a setting to the configuration file

Used with an array setting, this will append the value to the array.
This modifies the contents of ~/.config/mise/config.toml

## Arguments

### `<KEY>`

The setting to set

### `<VALUE>`

The value to set

## Flags

### `-l --local`

Use the local config file instead of the global one

Examples:

    mise settings add disable_hints python_multi

# unset.md

# `mise settings unset`

- **Usage**: `mise settings unset [-l --local] <KEY>`
- **Aliases**: `rm`, `remove`, `delete`, `del`

Clears a setting

This modifies the contents of ~/.config/mise/config.toml

## Arguments

### `<KEY>`

The setting to remove

## Flags

### `-l --local`

Use the local config file instead of the global one

Examples:

    mise settings unset legacy_version_file

# ls.md

# `mise settings ls`

- **Usage**: `mise settings ls [-l --local] [--names] [KEY]`
- **Aliases**: `list`

Show current settings

This is the contents of ~/.config/mise/config.toml

Note that aliases are also stored in this file
but managed separately with `mise aliases`

## Arguments

### `[KEY]`

List keys under this key

## Flags

### `-l --local`

Use the local config file instead of the global one

### `--names`

Only display key names for each setting

Examples:

    $ mise settings ls
    legacy_version_file = false
    ...

    $ mise settings ls python
    default_packages_file = "~/.default-python-packages"
    ...

# trust.md

# `mise trust`

- **Usage**: `mise trust [FLAGS] [CONFIG_FILE]`

Marks a config file as trusted

This means mise will parse the file with potentially dangerous
features enabled.

This includes:

- environment variables
- templates
- `path:` plugin versions

## Arguments

### `[CONFIG_FILE]`

The config file to trust

## Flags

### `-a --all`

Trust all config files in the current directory and its parents

### `--ignore`

Do not trust this config and ignore it in the future

### `--untrust`

No longer trust this config, will prompt in the future

### `--show`

Show the trusted status of config files from the current directory and its parents.
Does not trust or untrust any files.

Examples:

    # trusts ~/some_dir/mise.toml
    $ mise trust ~/some_dir/mise.toml

    # trusts mise.toml in the current or parent directory
    $ mise trust

# get.md

# `mise alias get`

- **Usage**: `mise alias get <PLUGIN> <ALIAS>`

Show an alias for a plugin

This is the contents of an alias.&lt;PLUGIN> entry in ~/.config/mise/config.toml

## Arguments

### `<PLUGIN>`

The plugin to show the alias for

### `<ALIAS>`

The alias to show

Examples:

    $ mise alias get node lts-hydrogen
    20.0.0

# set.md

# `mise alias set`

- **Usage**: `mise alias set <ARGS>…`
- **Aliases**: `add`, `create`

Add/update an alias for a plugin

This modifies the contents of ~/.config/mise/config.toml

## Arguments

### `<PLUGIN>`

The plugin to set the alias for

### `<ALIAS>`

The alias to set

### `<VALUE>`

The value to set the alias to

Examples:

    mise alias set node lts-jod 22.0.0

# unset.md

# `mise alias unset`

- **Usage**: `mise alias unset <PLUGIN> <ALIAS>`
- **Aliases**: `rm`, `remove`, `delete`, `del`

Clears an alias for a plugin

This modifies the contents of ~/.config/mise/config.toml

## Arguments

### `<PLUGIN>`

The plugin to remove the alias from

### `<ALIAS>`

The alias to remove

Examples:

    mise alias unset node lts-jod

# ls.md

# `mise alias ls`

- **Usage**: `mise alias ls [--no-header] [TOOL]`
- **Aliases**: `list`

List aliases
Shows the aliases that can be specified.
These can come from user config or from plugins in `bin/list-aliases`.

For user config, aliases are defined like the following in `~/.config/mise/config.toml`:

    [alias.node.versions]
    lts = "22.0.0"

## Arguments

### `[TOOL]`

Show aliases for &lt;TOOL>

## Flags

### `--no-header`

Don't show table header

Examples:

    $ mise aliases
    node  lts-jod      22

# prune.md

# `mise prune`

- **Usage**: `mise prune [FLAGS] [PLUGIN]...`

Delete unused versions of tools

mise tracks which config files have been used in ~/.local/state/mise/tracked-configs
Versions which are no longer the latest specified in any of those configs are deleted.
Versions installed only with environment variables `MISE_<PLUGIN>_VERSION` will be deleted,
as will versions only referenced on the command line `mise exec <PLUGIN>@<VERSION>`.

## Arguments

### `[PLUGIN]...`

Prune only versions from this plugin(s)

## Flags

### `-n --dry-run`

Do not actually delete anything

### `--configs`

Prune only tracked and trusted configuration links that point to non-existent configurations

### `--tools`

Prune only unused versions of tools

Examples:

    $ mise prune --dry-run
    rm -rf ~/.local/share/mise/versions/node/20.0.0
    rm -rf ~/.local/share/mise/versions/node/20.0.1

# settings.md

# `mise settings`

- **Usage**: `mise settings [--names] [-l --local] [KEY] [VALUE] <SUBCOMMAND>`

Manage settings

## Arguments

### `[KEY]`

Setting name to get/set

### `[VALUE]`

Setting value to set

## Global Flags

### `-l --local`

Use the local config file instead of the global one

## Flags

### `--names`

Only display key names for each setting

## Subcommands

- [`mise settings add [-l --local] <KEY> <VALUE>`](/cli/settings/add.md)
- [`mise settings get [-l --local] <KEY>`](/cli/settings/get.md)
- [`mise settings ls [-l --local] [--names] [KEY]`](/cli/settings/ls.md)
- [`mise settings set [-l --local] <KEY> <VALUE>`](/cli/settings/set.md)
- [`mise settings unset [-l --local] <KEY>`](/cli/settings/unset.md)

Examples:
    # list all settings
    $ mise settings

    # get the value of the setting "always_keep_download"
    $ mise settings always_keep_download

    # set the value of the setting "always_keep_download" to "true"
    $ mise settings always_keep_download=true

    # set the value of the setting "node.mirror_url" to "https://npm.taobao.org/mirrors/node"
    $ mise settings node.mirror_url https://npm.taobao.org/mirrors/node

# info.md

# `mise tasks info`

- **Usage**: `mise tasks info [-J --json] <TASK>`

Get information about a task

## Arguments

### `<TASK>`

Name of the task to get information about

## Flags

### `-J --json`

Output in JSON format

Examples:

    $ mise tasks info
    Name: test
    Aliases: t
    Description: Test the application
    Source: ~/src/myproj/mise.toml

    $ mise tasks info test --json
    {
      "name": "test",
      "aliases": "t",
      "description": "Test the application",
      "source": "~/src/myproj/mise.toml",
      "depends": [],
      "env": {},
      "dir": null,
      "hide": false,
      "raw": false,
      "sources": [],
      "outputs": [],
      "run": [
        "echo \"testing!\""
      ],
      "file": null,
      "usage_spec": {}
    }

# deps.md

# `mise tasks deps`

- **Usage**: `mise tasks deps [--hidden] [--dot] [TASKS]...`

Display a tree visualization of a dependency graph

## Arguments

### `[TASKS]...`

Tasks to show dependencies for
Can specify multiple tasks by separating with spaces
e.g.: mise tasks deps lint test check

## Flags

### `--hidden`

Show hidden tasks

### `--dot`

Display dependencies in DOT format

Examples:

    # Show dependencies for all tasks
    $ mise tasks deps

    # Show dependencies for the "lint", "test" and "check" tasks
    $ mise tasks deps lint test check

    # Show dependencies in DOT format
    $ mise tasks deps --dot

# run.md

# `mise tasks run`

- **Usage**: `mise tasks run [FLAGS] [TASK] [ARGS]...`
- **Aliases**: `r`

Run task(s)

This command will run a tasks, or multiple tasks in parallel.
Tasks may have dependencies on other tasks or on source files.
If source is configured on a tasks, it will only run if the source
files have changed.

Tasks can be defined in mise.toml or as standalone scripts.
In mise.toml, tasks take this form:

    [tasks.build]
    run = "npm run build"
    sources = ["src/**/*.ts"]
    outputs = ["dist/**/*.js"]

Alternatively, tasks can be defined as standalone scripts.
These must be located in `mise-tasks`, `.mise-tasks`, `.mise/tasks`, `mise/tasks` or
`.config/mise/tasks`.
The name of the script will be the name of the tasks.

    $ cat .mise/tasks/build<<EOF
    #!/usr/bin/env bash
    npm run build
    EOF
    $ mise run build

## Arguments

### `[TASK]`

Tasks to run
Can specify multiple tasks by separating with `:::`
e.g.: mise run task1 arg1 arg2 ::: task2 arg1 arg2

**Default:** `default`

### `[ARGS]...`

Arguments to pass to the tasks. Use ":::" to separate tasks

## Flags

### `-C --cd <CD>`

Change to this directory before executing the command

### `-n --dry-run`

Don't actually run the tasks(s), just print them in order of execution

### `-f --force`

Force the tasks to run even if outputs are up to date

### `-p --prefix`

Print stdout/stderr by line, prefixed with the tasks's label
Defaults to true if --jobs > 1
Configure with `task_output` config or `MISE_TASK_OUTPUT` env var

### `-i --interleave`

Print directly to stdout/stderr instead of by line
Defaults to true if --jobs == 1
Configure with `task_output` config or `MISE_TASK_OUTPUT` env var

### `-t --tool... <TOOL@VERSION>`

Tool(s) to run in addition to what is in mise.toml files e.g.: node@20 python@3.10

### `-j --jobs <JOBS>`

Number of tasks to run in parallel
[default: 4]
Configure with `jobs` config or `MISE_JOBS` env var

### `-r --raw`

Read/write directly to stdin/stdout/stderr instead of by line
Configure with `raw` config or `MISE_RAW` env var

### `--no-timings`

Hides elapsed time after each task completes

Default to always hide with `MISE_TASK_TIMINGS=0`

Examples:

    # Runs the "lint" tasks. This needs to either be defined in mise.toml
    # or as a standalone script. See the project README for more information.
    $ mise run lint

    # Forces the "build" tasks to run even if its sources are up-to-date.
    $ mise run build --force

    # Run "test" with stdin/stdout/stderr all connected to the current terminal.
    # This forces `--jobs=1` to prevent interleaving of output.
    $ mise run test --raw

    # Runs the "lint", "test", and "check" tasks in parallel.
    $ mise run lint ::: test ::: check

    # Execute multiple tasks each with their own arguments.
    $ mise tasks cmd1 arg1 arg2 ::: cmd2 arg1 arg2

# edit.md

# `mise tasks edit`

- **Usage**: `mise tasks edit [-p --path] <TASK>`

Edit a tasks with $EDITOR

The tasks will be created as a standalone script if it does not already exist.

## Arguments

### `<TASK>`

Tasks to edit

## Flags

### `-p --path`

Display the path to the tasks instead of editing it

Examples:

    mise tasks edit build
    mise tasks edit test

# ls.md

# `mise tasks ls`

- **Usage**: `mise tasks ls [FLAGS]`

List available tasks to execute
These may be included from the config file or from the project's .mise/tasks directory
mise will merge all tasks from all parent directories into this list.

So if you have global tasks in `~/.config/mise/tasks/*` and project-specific tasks in
~/myproject/.mise/tasks/*, then they'll both be available but the project-specific
tasks will override the global ones if they have the same name.

## Flags

### `--no-header`

Do not print table header

### `-x --extended`

Show all columns

### `--hidden`

Show hidden tasks

### `--sort <COLUMN>`

Sort by column. Default is name.

**Choices:**

- `name`
- `alias`
- `description`
- `source`

### `--sort-order <SORT_ORDER>`

Sort order. Default is asc.

**Choices:**

- `asc`
- `desc`

### `-J --json`

Output in JSON format

Examples:

    mise tasks ls

# backends.md

# `mise backends`

- **Usage**: `mise backends <SUBCOMMAND>`
- **Aliases**: `b`

Manage backends

## Subcommands

- [`mise backends ls`](/cli/backends/ls.md)

# prune.md

# `mise cache prune`

- **Usage**: `mise cache prune [--dry-run] [-v --verbose...] [PLUGIN]...`
- **Aliases**: `p`

Removes stale mise cache files

By default, this command will remove files that have not been accessed in 30 days.
Change this with the MISE_CACHE_PRUNE_AGE environment variable.

## Arguments

### `[PLUGIN]...`

Plugin(s) to clear cache for e.g.: node, python

## Flags

### `--dry-run`

Just show what would be pruned

### `-v --verbose...`

Show pruned files

# clear.md

# `mise cache clear`

- **Usage**: `mise cache clear [PLUGIN]...`
- **Aliases**: `c`

Deletes all cache files in mise

## Arguments

### `[PLUGIN]...`

Plugin(s) to clear cache for e.g.: node, python

# latest.md

# `mise latest`

- **Usage**: `mise latest [-i --installed] <TOOL@VERSION>`

Gets the latest available version for a plugin

Supports prefixes such as `node@20` to get the latest version of node 20.

## Arguments

### `<TOOL@VERSION>`

Tool to get the latest version of

## Flags

### `-i --installed`

Show latest installed instead of available version

Examples:

    $ mise latest node@20  # get the latest version of node 20
    20.0.0

    $ mise latest node     # get the latest stable version of node
    20.0.0

# get.md

# `mise config get`

- **Usage**: `mise config get [-f --file <FILE>] [KEY]`

Display the value of a setting in a mise.toml file

## Arguments

### `[KEY]`

The path of the config to display

## Flags

### `-f --file <FILE>`

The path to the mise.toml file to edit

If not provided, the nearest mise.toml file will be used

Examples:

    $ mise toml get tools.python
    3.12

# set.md

# `mise config set`

- **Usage**: `mise config set [-f --file <FILE>] [-t --type <TYPE>] <KEY> <VALUE>`

Set the value of a setting in a mise.toml file

## Arguments

### `<KEY>`

The path of the config to display

### `<VALUE>`

The value to set the key to

## Flags

### `-f --file <FILE>`

The path to the mise.toml file to edit

If not provided, the nearest mise.toml file will be used

### `-t --type <TYPE>`

**Choices:**

- `infer`
- `string`
- `integer`
- `float`
- `bool`
- `list`

Examples:

    $ mise config set tools.python 3.12
    $ mise config set settings.always_keep_download true
    $ mise config set env.TEST_ENV_VAR ABC
    $ mise config set settings.disable_tools --type list node,rust

    # Type for `settings` is inferred
    $ mise config set settings.jobs 4

# generate.md

# `mise config generate`

- **Usage**: `mise config generate [-o --output <OUTPUT>]`
- **Aliases**: `g`

[experimental] Generate a mise.toml file

## Flags

### `-o --output <OUTPUT>`

Output to file instead of stdout

Examples:

    mise cf generate > mise.toml
    mise cf generate --output=mise.toml

# ls.md

# `mise config ls`

- **Usage**: `mise config ls [--no-header] [-J --json]`

List config files currently in use

## Flags

### `--no-header`

Do not print table header

### `-J --json`

Output in JSON format

Examples:

    mise config ls

# uninstall.md

# `mise plugins uninstall`

- **Usage**: `mise plugins uninstall [-p --purge] [-a --all] [PLUGIN]...`
- **Aliases**: `remove`, `rm`

Removes a plugin

## Arguments

### `[PLUGIN]...`

Plugin(s) to remove

## Flags

### `-p --purge`

Also remove the plugin's installs, downloads, and cache

### `-a --all`

Remove all plugins

Examples:

    mise uninstall node

# install.md

# `mise plugins install`

- **Usage**: `mise plugins install [FLAGS] [NEW_PLUGIN] [GIT_URL]`
- **Aliases**: `i`, `a`, `add`

Install a plugin

note that mise automatically can install plugins when you install a tool
e.g.: `mise install node@20` will autoinstall the node plugin

This behavior can be modified in ~/.config/mise/config.toml

## Arguments

### `[NEW_PLUGIN]`

The name of the plugin to install
e.g.: node, ruby
Can specify multiple plugins: `mise plugins install node ruby python`

### `[GIT_URL]`

The git url of the plugin

## Flags

### `-f --force`

Reinstall even if plugin exists

### `-a --all`

Install all missing plugins
This will only install plugins that have matching shorthands.
i.e.: they don't need the full git repo url

### `-v --verbose...`

Show installation output

Examples:

    # install the node via shorthand
    $ mise plugins install node

    # install the node plugin using a specific git url
    $ mise plugins install node https://github.com/mise-plugins/rtx-nodejs.git

    # install the node plugin using the git url only
    # (node is inferred from the url)
    $ mise plugins install https://github.com/mise-plugins/rtx-nodejs.git

    # install the node plugin using a specific ref
    $ mise plugins install node https://github.com/mise-plugins/rtx-nodejs.git#v1.0.0

# link.md

# `mise plugins link`

- **Usage**: `mise plugins link [-f --force] <NAME> [DIR]`
- **Aliases**: `ln`

Symlinks a plugin into mise

This is used for developing a plugin.

## Arguments

### `<NAME>`

The name of the plugin
e.g.: node, ruby

### `[DIR]`

The local path to the plugin
e.g.: ./mise-node

## Flags

### `-f --force`

Overwrite existing plugin

Examples:

    # essentially just `ln -s ./mise-node ~/.local/share/mise/plugins/node`
    $ mise plugins link node ./mise-node

    # infer plugin name as "node"
    $ mise plugins link ./mise-node

# update.md

# `mise plugins update`

- **Usage**: `mise plugins update [-j --jobs <JOBS>] [PLUGIN]...`
- **Aliases**: `up`, `upgrade`

Updates a plugin to the latest version

note: this updates the plugin itself, not the runtime versions

## Arguments

### `[PLUGIN]...`

Plugin(s) to update

## Flags

### `-j --jobs <JOBS>`

Number of jobs to run in parallel
Default: 4

Examples:

    mise plugins update            # update all plugins
    mise plugins update node       # update only node
    mise plugins update node#beta  # specify a ref

# ls-remote.md

# `mise plugins ls-remote`

- **Usage**: `mise plugins ls-remote [-u --urls] [--only-names]`
- **Aliases**: `list-remote`, `list-all`

List all available remote plugins

The full list is here: <https://github.com/jdx/mise/blob/main/registry.toml>

Examples:

    mise plugins ls-remote

## Flags

### `-u --urls`

Show the git url for each plugin e.g.: <https://github.com/mise-plugins/mise-poetry.git>

### `--only-names`

Only show the name of each plugin by default it will show a "*" next to installed plugins

# ls.md

# `mise plugins ls`

- **Usage**: `mise plugins ls [-u --urls]`
- **Aliases**: `list`

List installed plugins

Can also show remotely available plugins to install.

## Flags

### `-u --urls`

Show the git url for each plugin
e.g.: <https://github.com/asdf-vm/asdf-nodejs.git>

Examples:

    $ mise plugins ls
    node
    ruby

    $ mise plugins ls --urls
    node    https://github.com/asdf-vm/asdf-nodejs.git
    ruby    https://github.com/asdf-vm/asdf-ruby.git

# direnv.md

# `mise direnv`

- **Usage**: `mise direnv <SUBCOMMAND>`

Output direnv function to use mise inside direnv

See <https://mise.jdx.dev/direnv.html> for more information

Because this generates the legacy files based on currently installed plugins,
you should run this command after installing new plugins. Otherwise
direnv may not know to update environment variables when legacy file versions change.

## Subcommands

- [`mise direnv activate`](/cli/direnv/activate.md)

# doctor.md

# `mise doctor`

- **Usage**: `mise doctor`
- **Aliases**: `dr`

Check mise installation for possible problems

Examples:

    $ mise doctor
    [WARN] plugin node is not installed

# tool.md

# `mise tool`

- **Usage**: `mise tool [FLAGS] <BACKEND>`

Gets information about a tool

## Arguments

### `<BACKEND>`

Tool name to get information about

## Flags

### `-J --json`

Output in JSON format

### `--backend`

Only show backend field

### `--installed`

Only show installed versions

### `--active`

Only show active versions

### `--requested`

Only show requested versions

### `--config-source`

Only show config source

### `--tool-options`

Only show tool options

Examples:

    $ mise tool node
    Backend:            core
    Installed Versions: 20.0.0 22.0.0
    Active Version:     20.0.0
    Requested Version:  20
    Config Source:      ~/.config/mise/mise.toml
    Tool Options:       [none]

# usage.md

# `mise usage`

Generate a usage CLI spec

See <https://usage.jdx.dev> for more information

# ls.md

# `mise backends ls`

- **Usage**: `mise backends ls`
- **Aliases**: `list`

List built-in backends

Examples:

    $ mise backends ls
    cargo
    go
    npm
    pipx
    spm
    ubi

# activate.md

# `mise activate`

- **Usage**: `mise activate [--shims] [-q --quiet] [SHELL_TYPE]`

Initializes mise in the current shell session

This should go into your shell's rc file.
Otherwise, it will only take effect in the current session.
(e.g. ~/.zshrc, ~/.bashrc)

This is only intended to be used in interactive sessions, not scripts.
mise is only capable of updating PATH when the prompt is displayed to the user.
For non-interactive use-cases, use shims instead.

Typically this can be added with something like the following:

    echo 'eval "$(mise activate)"' >> ~/.zshrc

However, this requires that "mise" is in your PATH. If it is not, you need to
specify the full path like this:

    echo 'eval "$(/path/to/mise activate)"' >> ~/.zshrc

Customize status output with `status` settings.

## Arguments

### `[SHELL_TYPE]`

Shell type to generate the script for

**Choices:**

- `bash`
- `elvish`
- `fish`
- `nu`
- `xonsh`
- `zsh`

## Flags

### `--shims`

Use shims instead of modifying PATH
Effectively the same as:

    PATH="$HOME/.local/share/mise/shims:$PATH"

### `-q --quiet`

Suppress non-error messages

Examples:

    eval "$(mise activate bash)"
    eval "$(mise activate zsh)"
    mise activate fish | source
    execx($(mise activate xonsh))

# outdated.md

# `mise outdated`

- **Usage**: `mise outdated [FLAGS] [TOOL@VERSION]...`

Shows outdated tool versions

See `mise upgrade` to upgrade these versions.

## Arguments

### `[TOOL@VERSION]...`

Tool(s) to show outdated versions for
e.g.: node@20 python@3.10
If not specified, all tools in global and local configs will be shown

## Flags

### `-l --bump`

Compares against the latest versions available, not what matches the current config

For example, if you have `node = "20"` in your config by default `mise outdated` will only
show other 20.x versions, not 21.x or 22.x versions.

Using this flag, if there are 21.x or newer versions it will display those instead of 20.x.

### `-J --json`

Output in JSON format

### `--no-header`

Don't show table header

Examples:

    $ mise outdated
    Plugin  Requested  Current  Latest
    python  3.11       3.11.0   3.11.1
    node    20         20.0.0   20.1.0

    $ mise outdated node
    Plugin  Requested  Current  Latest
    node    20         20.0.0   20.1.0

    $ mise outdated --json
    {"python": {"requested": "3.11", "current": "3.11.0", "latest": "3.11.1"}, ...}

# watch.md

# `mise watch`

- **Usage**: `mise watch [-t --task... <TASK>] [-g --glob... <GLOB>] [ARGS]...`
- **Aliases**: `w`

Run task(s) and watch for changes to rerun it

This command uses the `watchexec` tool to watch for changes to files and rerun the specified task(s).
It must be installed for this command to work, but you can install it with `mise use -g watchexec@latest`.

## Arguments

### `[ARGS]...`

Extra arguments

## Flags

### `-t --task... <TASK>`

Tasks to run

### `-g --glob... <GLOB>`

Files to watch
Defaults to sources from the tasks(s)

Examples:

    $ mise watch -t build
    Runs the "build" tasks. Will re-run the tasks when any of its sources change.
    Uses "sources" from the tasks definition to determine which files to watch.

    $ mise watch -t build --glob src/**/*.rs
    Runs the "build" tasks but specify the files to watch with a glob pattern.
    This overrides the "sources" from the tasks definition.

    $ mise run -t build --clear
    Extra arguments are passed to watchexec. See `watchexec --help` for details.

# install.md

# `mise install`

- **Usage**: `mise install [FLAGS] [TOOL@VERSION]...`
- **Aliases**: `i`

Install a tool version

Installs a tool version to `~/.local/share/mise/installs/<PLUGIN>/<VERSION>`
Installing alone will not activate the tools so they won't be in PATH.
To install and/or activate in one command, use `mise use` which will create a `mise.toml` file
in the current directory to activate this tool when inside the directory.
Alternatively, run `mise exec <TOOL>@<VERSION> -- <COMMAND>` to execute a tool without creating config files.

Tools will be installed in parallel. To disable, set `--jobs=1` or `MISE_JOBS=1`

## Arguments

### `[TOOL@VERSION]...`

Tool(s) to install e.g.: node@20

## Flags

### `-f --force`

Force reinstall even if already installed

### `-j --jobs <JOBS>`

Number of jobs to run in parallel
[default: 4]

### `--raw`

Directly pipe stdin/stdout/stderr from plugin to user Sets --jobs=1

### `-v --verbose...`

Show installation output

This argument will print plugin output such as download, configuration, and compilation output.

Examples:

    mise install node@20.0.0  # install specific node version
    mise install node@20      # install fuzzy node version
    mise install node         # install version specified in mise.toml
    mise install              # installs everything specified in mise.toml

# implode.md

# `mise implode`

- **Usage**: `mise implode [--config] [-n --dry-run]`

Removes mise CLI and all related data

Skips config directory by default.

## Flags

### `--config`

Also remove config directory

### `-n --dry-run`

List directories that would be removed without actually removing them

# set.md

# `mise set`

- **Usage**: `mise set [--file <FILE>] [-g --global] [ENV_VARS]...`

Set environment variables in mise.toml

By default, this command modifies `mise.toml` in the current directory.

## Arguments

### `[ENV_VARS]...`

Environment variable(s) to set
e.g.: NODE_ENV=production

## Flags

### `--file <FILE>`

The TOML file to update

Defaults to MISE_DEFAULT_CONFIG_FILENAME environment variable, or `mise.toml`.

### `-g --global`

Set the environment variable in the global config file

Examples:

    $ mise set NODE_ENV=production

    $ mise set NODE_ENV
    production

    $ mise set
    key       value       source
    NODE_ENV  production  ~/.config/mise/config.toml

# which.md

# `mise which`

- **Usage**: `mise which [FLAGS] <BIN_NAME>`

Shows the path that a tool's bin points to.

Use this to figure out what version of a tool is currently active.

## Arguments

### `<BIN_NAME>`

The bin to look up

## Flags

### `--plugin`

Show the plugin name instead of the path

### `--version`

Show the version instead of the path

### `-t --tool <TOOL@VERSION>`

Use a specific tool@version
e.g.: `mise which npm --tool=node@20`

Examples:

    $ mise which node
    /home/username/.local/share/mise/installs/node/20.0.0/bin/node

    $ mise which node --plugin
    node

    $ mise which node --version
    20.0.0

# use.md

# `mise use`

- **Usage**: `mise use [FLAGS] [TOOL@VERSION]...`
- **Aliases**: `u`

Installs a tool and adds the version it to mise.toml.

This will install the tool version if it is not already installed.
By default, this will use a `mise.toml` file in the current directory.

Use the `--global` flag to use the global config file instead.

## Arguments

### `[TOOL@VERSION]...`

Tool(s) to add to config file

e.g.: node@20, cargo:ripgrep@latest npm:prettier@3
If no version is specified, it will default to @latest

Tool options can be set with this syntax:

    mise use ubi:BurntSushi/ripgrep[exe=rg]

## Flags

### `-f --force`

Force reinstall even if already installed

### `--fuzzy`

Save fuzzy version to config file

e.g.: `mise use --fuzzy node@20` will save 20 as the version
this is the default behavior unless `MISE_PIN=1` or `MISE_ASDF_COMPAT=1`

### `-g --global`

Use the global config file (`~/.config/mise/config.toml`) instead of the local one

### `-e --env <ENV>`

Modify an environment-specific config file like .mise.&lt;env>.toml

### `-j --jobs <JOBS>`

Number of jobs to run in parallel
[default: 4]

### `--raw`

Directly pipe stdin/stdout/stderr from plugin to user Sets `--jobs=1`

### `--remove... <PLUGIN>`

Remove the plugin(s) from config file

### `-p --path <PATH>`

Specify a path to a config file or directory

If a directory is specified, it will look for `mise.toml` (default) or `.tool-versions` if `MISE_ASDF_COMPAT=1`

### `--pin`

Save exact version to config file
e.g.: `mise use --pin node@20` will save 20.0.0 as the version
Set `MISE_PIN=1` or `MISE_ASDF_COMPAT=1` to make this the default behavior

Examples:

    # set the current version of node to 20.x in mise.toml of current directory
    # will write the fuzzy version (e.g.: 20)
    $ mise use node@20

    # set the current version of node to 20.x in ~/.config/mise/config.toml
    # will write the precise version (e.g.: 20.0.0)
    $ mise use -g --pin node@20

    # sets .mise.local.toml (which is intended not to be committed to a project)
    $ mise use --env local node@20

    # sets .mise.staging.toml (which is used if MISE_ENV=staging)
    $ mise use --env staging node@20

# config.md

# `mise config`

- **Usage**: `mise config [--no-header] [-J --json] <SUBCOMMAND>`
- **Aliases**: `cfg`

Manage config files

## Flags

### `--no-header`

Do not print table header

### `-J --json`

Output in JSON format

## Subcommands

- [`mise config generate [-o --output <OUTPUT>]`](/cli/config/generate.md)
- [`mise config get [-f --file <FILE>] [KEY]`](/cli/config/get.md)
- [`mise config ls [--no-header] [-J --json]`](/cli/config/ls.md)
- [`mise config set [-f --file <FILE>] [-t --type <TYPE>] <KEY> <VALUE>`](/cli/config/set.md)

# env.md

# `mise env`

- **Usage**: `mise env [FLAGS] [TOOL@VERSION]...`
- **Aliases**: `e`

Exports env vars to activate mise a single time

Use this if you don't want to permanently install mise. It's not necessary to
use this if you have `mise activate` in your shell rc file.

## Arguments

### `[TOOL@VERSION]...`

Tool(s) to use

## Flags

### `-J --json`

Output in JSON format

### `-D --dotenv`

Output in dotenv format

### `-s --shell <SHELL>`

Shell type to generate environment variables for

**Choices:**

- `bash`
- `elvish`
- `fish`
- `nu`
- `xonsh`
- `zsh`

Examples:

    eval "$(mise env -s bash)"
    eval "$(mise env -s zsh)"
    mise env -s fish | source
    execx($(mise env -s xonsh))

# version.md

# `mise version`

- **Usage**: `mise version`
- **Aliases**: `v`

Display the version of mise

Displays the version, os, architecture, and the date of the build.

If the version is out of date, it will display a warning.

Examples:

    mise version
    mise --version
    mise -v
    mise -V

# tasks.md

# `mise tasks`

- **Usage**: `mise tasks [FLAGS] <SUBCOMMAND>`
- **Aliases**: `t`

Manage tasks

## Flags

### `--no-header`

Do not print table header

### `-x --extended`

Show all columns

### `--hidden`

Show hidden tasks

### `--sort <COLUMN>`

Sort by column. Default is name.

**Choices:**

- `name`
- `alias`
- `description`
- `source`

### `--sort-order <SORT_ORDER>`

Sort order. Default is asc.

**Choices:**

- `asc`
- `desc`

### `-J --json`

Output in JSON format

## Subcommands

- [`mise tasks deps [--hidden] [--dot] [TASKS]...`](/cli/tasks/deps.md)
- [`mise tasks edit [-p --path] <TASK>`](/cli/tasks/edit.md)
- [`mise tasks info [-J --json] <TASK>`](/cli/tasks/info.md)
- [`mise tasks ls [FLAGS]`](/cli/tasks/ls.md)
- [`mise tasks run [FLAGS] [TASK] [ARGS]...`](/cli/tasks/run.md)

Examples:

    mise tasks ls

# alias.md

# `mise alias`

- **Usage**: `mise alias [-p --plugin <PLUGIN>] [--no-header] <SUBCOMMAND>`
- **Aliases**: `a`

Manage aliases

## Flags

### `-p --plugin <PLUGIN>`

filter aliases by plugin

### `--no-header`

Don't show table header

## Subcommands

- [`mise alias get <PLUGIN> <ALIAS>`](/cli/alias/get.md)
- [`mise alias ls [--no-header] [TOOL]`](/cli/alias/ls.md)
- [`mise alias set <ARGS>…`](/cli/alias/set.md)
- [`mise alias unset <PLUGIN> <ALIAS>`](/cli/alias/unset.md)

# generate.md

# `mise generate`

- **Usage**: `mise generate <SUBCOMMAND>`
- **Aliases**: `gen`

[experimental] Generate files for various tools/services

## Subcommands

- [`mise generate git-pre-commit [FLAGS]`](/cli/generate/git-pre-commit.md)
- [`mise generate github-action [FLAGS]`](/cli/generate/github-action.md)
- [`mise generate task-docs [FLAGS]`](/cli/generate/task-docs.md)

# completion.md

# `mise completion`

- **Usage**: `mise completion [SHELL]`

Generate shell completions

## Arguments

### `[SHELL]`

Shell type to generate completions for

**Choices:**

- `bash`
- `fish`
- `zsh`

Examples:

    mise completion bash > /etc/bash_completion.d/mise
    mise completion zsh  > /usr/local/share/zsh/site-functions/_mise
    mise completion fish > ~/.config/fish/completions/mise.fish

# bin-paths.md

# `mise bin-paths`

- **Usage**: `mise bin-paths`

List all the active runtime bin paths

# plugins.md

# `mise plugins`

- **Usage**: `mise plugins [FLAGS] <SUBCOMMAND>`
- **Aliases**: `p`

Manage plugins

## Flags

### `-c --core`

The built-in plugins only
Normally these are not shown

### `--user`

List installed plugins

This is the default behavior but can be used with --core
to show core and user plugins

### `-u --urls`

Show the git url for each plugin
e.g.: <https://github.com/asdf-vm/asdf-nodejs.git>

## Subcommands

- [`mise plugins install [FLAGS] [NEW_PLUGIN] [GIT_URL]`](/cli/plugins/install.md)
- [`mise plugins link [-f --force] <NAME> [DIR]`](/cli/plugins/link.md)
- [`mise plugins ls [-u --urls]`](/cli/plugins/ls.md)
- [`mise plugins ls-remote [-u --urls] [--only-names]`](/cli/plugins/ls-remote.md)
- [`mise plugins uninstall [-p --purge] [-a --all] [PLUGIN]...`](/cli/plugins/uninstall.md)
- [`mise plugins update [-j --jobs <JOBS>] [PLUGIN]...`](/cli/plugins/update.md)

# reshim.md

# `mise reshim`

- **Usage**: `mise reshim [-f --force]`

Creates new shims based on bin paths from currently installed tools.

This creates new shims in ~/.local/share/mise/shims for CLIs that have been added.
mise will try to do this automatically for commands like `npm i -g` but there are
other ways to install things (like using yarn or pnpm for node) that mise does
not know about and so it will be necessary to call this explicitly.

If you think mise should automatically call this for a particular command, please
open an issue on the mise repo. You can also setup a shell function to reshim
automatically (it's really fast so you don't need to worry about overhead):

    npm() {
      command npm "$@"
      mise reshim
    }

Note that this creates shims for _all_ installed tools, not just the ones that are
currently active in mise.toml.

## Flags

### `-f --force`

Removes all shims before reshimming

Examples:

    $ mise reshim
    $ ~/.local/share/mise/shims/node -v
    v20.0.0

# link.md

# `mise link`

- **Usage**: `mise link [-f --force] <TOOL@VERSION> <PATH>`
- **Aliases**: `ln`

Symlinks a tool version into mise

Use this for adding installs either custom compiled outside mise or built with a different tool.

## Arguments

### `<TOOL@VERSION>`

Tool name and version to create a symlink for

### `<PATH>`

The local path to the tool version
e.g.: ~/.nvm/versions/node/v20.0.0

## Flags

### `-f --force`

Overwrite an existing tool version if it exists

Examples:

    # build node-20.0.0 with node-build and link it into mise
    $ node-build 20.0.0 ~/.nodes/20.0.0
    $ mise link node@20.0.0 ~/.nodes/20.0.0

    # have mise use the python version provided by Homebrew
    $ brew install node
    $ mise link node@brew $(brew --prefix node)
    $ mise use node@brew

# sync.md

# `mise sync`

- **Usage**: `mise sync <SUBCOMMAND>`

Add tool versions from external tools to mise

## Subcommands

- [`mise sync node [FLAGS]`](/cli/sync/node.md)
- [`mise sync python <--pyenv>`](/cli/sync/python.md)

# github-action.md

# `mise generate github-action`

- **Usage**: `mise generate github-action [FLAGS]`

[experimental] Generate a GitHub Action workflow file

This command generates a GitHub Action workflow file that runs a mise task like `mise run ci`
when you push changes to your repository.

## Flags

### `-n --name <NAME>`

the name of the workflow to generate

### `-t --task <TASK>`

The task to run when the workflow is triggered

### `-w --write`

write to .github/workflows/$name.yml

Examples:

    mise generate github-action --write --task=ci
    git commit -m "feat: add new feature"
    git push # runs `mise run ci` on GitHub

# task-docs.md

# `mise generate task-docs`

- **Usage**: `mise generate task-docs [FLAGS]`

Generate documentation for tasks in a project

## Flags

### `-I --index`

write only an index of tasks, intended for use with `--multi`

### `-i --inject`

inserts the documentation into an existing file

This will look for a special comment, &lt;!-- mise-tasks -->, and replace it with the generated documentation.
It will replace everything between the comment and the next comment, &lt;!-- /mise-tasks --> so it can be
run multiple times on the same file to update the documentation.

### `-m --multi`

render each task as a separate document, requires `--output` to be a directory

### `-o --output <OUTPUT>`

writes the generated docs to a file/directory

### `-r --root <ROOT>`

root directory to search for tasks

### `-s --style <STYLE>`

**Choices:**

- `simple`
- `detailed`

Examples:

    mise generate task-docs

# git-pre-commit.md

# `mise generate git-pre-commit`

- **Usage**: `mise generate git-pre-commit [FLAGS]`
- **Aliases**: `pre-commit`

[experimental] Generate a git pre-commit hook

This command generates a git pre-commit hook that runs a mise task like `mise run pre-commit`
when you commit changes to your repository.

## Flags

### `--hook <HOOK>`

Which hook to generate (saves to .git/hooks/$hook)

### `-t --task <TASK>`

The task to run when the pre-commit hook is triggered

### `-w --write`

write to .git/hooks/pre-commit and make it executable

Examples:

    mise generate git-pre-commit --write --task=pre-commit
    git commit -m "feat: add new feature" # runs `mise run pre-commit`

# unset.md

# `mise unset`

- **Usage**: `mise unset [-f --file <FILE>] [-g --global] [KEYS]...`

Remove environment variable(s) from the config file.

By default, this command modifies `mise.toml` in the current directory.

## Arguments

### `[KEYS]...`

Environment variable(s) to remove
e.g.: NODE_ENV

## Flags

### `-f --file <FILE>`

Specify a file to use instead of `mise.toml`

### `-g --global`

Use the global config file

Examples:

    # Remove NODE_ENV from the current directory's config
    $ mise unset NODE_ENV

    # Remove NODE_ENV from the global config
    $ mise unset NODE_ENV -g

# run.md

# `mise run`

- **Usage**: `mise run [FLAGS]`
- **Aliases**: `r`

Run task(s)

This command will run a tasks, or multiple tasks in parallel.
Tasks may have dependencies on other tasks or on source files.
If source is configured on a tasks, it will only run if the source
files have changed.

Tasks can be defined in mise.toml or as standalone scripts.
In mise.toml, tasks take this form:

    [tasks.build]
    run = "npm run build"
    sources = ["src/**/*.ts"]
    outputs = ["dist/**/*.js"]

Alternatively, tasks can be defined as standalone scripts.
These must be located in `mise-tasks`, `.mise-tasks`, `.mise/tasks`, `mise/tasks` or
`.config/mise/tasks`.
The name of the script will be the name of the tasks.

    $ cat .mise/tasks/build<<EOF
    #!/usr/bin/env bash
    npm run build
    EOF
    $ mise run build

## Flags

### `-C --cd <CD>`

Change to this directory before executing the command

### `-n --dry-run`

Don't actually run the tasks(s), just print them in order of execution

### `-f --force`

Force the tasks to run even if outputs are up to date

### `-p --prefix`

Print stdout/stderr by line, prefixed with the tasks's label
Defaults to true if --jobs > 1
Configure with `task_output` config or `MISE_TASK_OUTPUT` env var

### `-i --interleave`

Print directly to stdout/stderr instead of by line
Defaults to true if --jobs == 1
Configure with `task_output` config or `MISE_TASK_OUTPUT` env var

### `-t --tool... <TOOL@VERSION>`

Tool(s) to run in addition to what is in mise.toml files e.g.: node@20 python@3.10

### `-j --jobs <JOBS>`

Number of tasks to run in parallel
[default: 4]
Configure with `jobs` config or `MISE_JOBS` env var

### `-r --raw`

Read/write directly to stdin/stdout/stderr instead of by line
Configure with `raw` config or `MISE_RAW` env var

### `--no-timings`

Hides elapsed time after each task completes

Default to always hide with `MISE_TASK_TIMINGS=0`

Examples:

    # Runs the "lint" tasks. This needs to either be defined in mise.toml
    # or as a standalone script. See the project README for more information.
    $ mise run lint

    # Forces the "build" tasks to run even if its sources are up-to-date.
    $ mise run build --force

    # Run "test" with stdin/stdout/stderr all connected to the current terminal.
    # This forces `--jobs=1` to prevent interleaving of output.
    $ mise run test --raw

    # Runs the "lint", "test", and "check" tasks in parallel.
    $ mise run lint ::: test ::: check

    # Execute multiple tasks each with their own arguments.
    $ mise tasks cmd1 arg1 arg2 ::: cmd2 arg1 arg2

# current.md

# `mise current`

**Usage**: `mise current [PLUGIN]`

Shows current active and installed runtime versions

This is similar to `mise ls --current`, but this only shows the runtime
and/or version. It's designed to fit into scripts more easily.

## Arguments

### `[PLUGIN]`

Plugin to show versions of e.g.: ruby, node, cargo:eza, npm:prettier, etc

Examples:

    # outputs `.tool-versions` compatible format
    $ mise current
    python 3.11.0 3.10.0
    shfmt 3.6.0
    shellcheck 0.9.0
    node 20.0.0

    $ mise current node
    20.0.0

    # can output multiple versions
    $ mise current python
    3.11.0 3.10.0

# self-update.md

# `mise self-update`

- **Usage**: `mise self-update [FLAGS] [VERSION]`

Updates mise itself.

Uses the GitHub Releases API to find the latest release and binary.
By default, this will also update any installed plugins.
Uses the `GITHUB_API_TOKEN` environment variable if set for higher rate limits.

This command is not available if mise is installed via a package manager.

## Arguments

### `[VERSION]`

Update to a specific version

## Flags

### `-f --force`

Update even if already up to date

### `--no-plugins`

Disable auto-updating plugins

### `-y --yes`

Skip confirmation prompt

# activate.md

# `mise direnv activate`

- **Usage**: `mise direnv activate`

Output direnv function to use mise inside direnv

See <https://mise.jdx.dev/direnv.html> for more information

Because this generates the legacy files based on currently installed plugins,
you should run this command after installing new plugins. Otherwise
direnv may not know to update environment variables when legacy file versions change.

Examples:

    mise direnv activate > ~/.config/direnv/lib/use_mise.sh
    echo 'use mise' > .envrc
    direnv allow

# cache.md

# `mise cache`

- **Usage**: `mise cache <SUBCOMMAND>`

Manage the mise cache

Run `mise cache` with no args to view the current cache directory.

## Subcommands

- [`mise cache clear [PLUGIN]...`](/cli/cache/clear.md)
- [`mise cache prune [--dry-run] [-v --verbose...] [PLUGIN]...`](/cli/cache/prune.md)

# deactivate.md

# `mise deactivate`

- **Usage**: `mise deactivate`

Disable mise for current shell session

This can be used to temporarily disable mise in a shell session.

Examples:

    mise deactivate

# upgrade.md

# `mise upgrade`

- **Usage**: `mise upgrade [FLAGS] [TOOL@VERSION]...`
- **Aliases**: `up`

Upgrades outdated tools

By default, this keeps the range specified in mise.toml. So if you have node@20 set, it will
upgrade to the latest 20.x.x version available. See the `--bump` flag to use the latest version
and bump the version in mise.toml.

This will update mise.lock if it is enabled, see <https://mise.jdx.dev/configuration/settings.html#lockfile>

## Arguments

### `[TOOL@VERSION]...`

Tool(s) to upgrade
e.g.: node@20 python@3.10
If not specified, all current tools will be upgraded

## Flags

### `-n --dry-run`

Just print what would be done, don't actually do it

### `-i --interactive`

Display multiselect menu to choose which tools to upgrade

### `-j --jobs <JOBS>`

Number of jobs to run in parallel
[default: 4]

### `-l --bump`

Upgrades to the latest version available, bumping the version in mise.toml

For example, if you have `node = "20.0.0"` in your mise.toml but 22.1.0 is the latest available,
this will install 22.1.0 and set `node = "22.1.0"` in your config.

It keeps the same precision as what was there before, so if you instead had `node = "20"`, it
would change your config to `node = "22"`.

### `--raw`

Directly pipe stdin/stdout/stderr from plugin to user Sets --jobs=1

Examples:

    # Upgrades node to the latest version matching the range in mise.toml
    $ mise upgrade node

    # Upgrades node to the latest version and bumps the version in mise.toml
    $ mise upgrade node --bump

    # Upgrades all tools to the latest versions
    $ mise upgrade

    # Upgrades all tools to the latest versions and bumps the version in mise.toml
    $ mise upgrade --bump

    # Just print what would be done, don't actually do it
    $ mise upgrade --dry-run

    # Upgrades node and python to the latest versions
    $ mise upgrade node python

    # Show a multiselect menu to choose which tools to upgrade
    $ mise upgrade --interactive

# ls-remote.md

# `mise ls-remote`

- **Usage**: `mise ls-remote [--all] [TOOL@VERSION] [PREFIX]`

List runtime versions available for install.

Note that the results may be cached, run `mise cache clean` to clear the cache and get fresh results.

## Arguments

### `[TOOL@VERSION]`

Tool to get versions for

### `[PREFIX]`

The version prefix to use when querying the latest version
same as the first argument after the "@"

## Flags

### `--all`

Show all installed plugins and versions

Examples:

    $ mise ls-remote node
    18.0.0
    20.0.0

    $ mise ls-remote node@20
    20.0.0
    20.1.0

    $ mise ls-remote node 20
    20.0.0
    20.1.0

# python.md

# `mise sync python`

- **Usage**: `mise sync python <--pyenv>`

Symlinks all tool versions from an external tool into mise

For example, use this to import all pyenv installs into mise

## Flags

### `--pyenv`

Get tool versions from pyenv

Examples:

    pyenv install 3.11.0
    mise sync python --pyenv
    mise use -g python@3.11.0 - uses pyenv-provided python

# node.md

# `mise sync node`

- **Usage**: `mise sync node [FLAGS]`

Symlinks all tool versions from an external tool into mise

For example, use this to import all Homebrew node installs into mise

## Flags

### `--brew`

Get tool versions from Homebrew

### `--nvm`

Get tool versions from nvm

### `--nodenv`

Get tool versions from nodenv

Examples:

    brew install node@18 node@20
    mise sync node --brew
    mise use -g node@18 - uses Homebrew-provided node

# ls.md

# `mise ls`

- **Usage**: `mise ls [FLAGS] [PLUGIN]...`
- **Aliases**: `list`

List installed and active tool versions

This command lists tools that mise "knows about".
These may be tools that are currently installed, or those
that are in a config file (active) but may or may not be installed.

It's a useful command to get the current state of your tools.

## Arguments

### `[PLUGIN]...`

Only show tool versions from [PLUGIN]

## Flags

### `-c --current`

Only show tool versions currently specified in a mise.toml

### `-g --global`

Only show tool versions currently specified in the global mise.toml

### `-i --installed`

Only show tool versions that are installed (Hides tools defined in mise.toml but not installed)

### `-o --offline`

Don't fetch information such as outdated versions

### `-J --json`

Output in JSON format

### `-m --missing`

Display missing tool versions

### `--prefix <PREFIX>`

Display versions matching this prefix

### `--no-header`

Don't display headers

Examples:

    $ mise ls
    node    20.0.0 ~/src/myapp/.tool-versions latest
    python  3.11.0 ~/.tool-versions           3.10
    python  3.10.0

    $ mise ls --current
    node    20.0.0 ~/src/myapp/.tool-versions 20
    python  3.11.0 ~/.tool-versions           3.11.0

    $ mise ls --json
    {
      "node": [
        {
          "version": "20.0.0",
          "install_path": "/Users/jdx/.mise/installs/node/20.0.0",
          "source": {
            "type": "mise.toml",
            "path": "/Users/jdx/mise.toml"
          }
        }
      ],
      "python": [...]
    }

# exec.md

# `mise exec`

- **Usage**: `mise exec [FLAGS] [TOOL@VERSION]... [COMMAND]...`
- **Aliases**: `x`

Execute a command with tool(s) set

use this to avoid modifying the shell session or running ad-hoc commands with mise tools set.

Tools will be loaded from mise.toml, though they can be overridden with &lt;RUNTIME> args
Note that only the plugin specified will be overridden, so if a `mise.toml` file
includes "node 20" but you run `mise exec python@3.11`; it will still load node@20.

The "--" separates runtimes from the commands to pass along to the subprocess.

## Arguments

### `[TOOL@VERSION]...`

Tool(s) to start e.g.: node@20 python@3.10

### `[COMMAND]...`

Command string to execute (same as --command)

## Flags

### `-c --command <C>`

Command string to execute

### `-j --jobs <JOBS>`

Number of jobs to run in parallel
[default: 4]

### `--raw`

Directly pipe stdin/stdout/stderr from plugin to user Sets --jobs=1

Examples:

    $ mise exec node@20 -- node ./app.js  # launch app.js using node-20.x
    $ mise x node@20 -- node ./app.js     # shorter alias

    # Specify command as a string:
    $ mise exec node@20 python@3.11 --command "node -v && python -V"

    # Run a command in a different directory:
    $ mise x -C /path/to/project node@20 -- node ./app.js

# registry.md

# `mise registry`

- **Usage**: `mise registry [-b --backend <BACKEND>] [--hide-aliased] [NAME]`

List available tools to install

This command lists the tools available in the registry as shorthand names.

For example, `poetry` is shorthand for `asdf:mise-plugins/mise-poetry`.

## Arguments

### `[NAME]`

Show only the specified tool's full name

## Flags

### `-b --backend <BACKEND>`

Show only tools for this backend

### `--hide-aliased`

Hide aliased tools

Examples:

    $ mise registry
    node    core:node
    poetry  asdf:mise-plugins/mise-poetry
    ubi     cargo:ubi-cli

    $ mise registry poetry
    asdf:mise-plugins/mise-poetry

# shell.md

# `mise shell`

- **Usage**: `mise shell [FLAGS] [TOOL@VERSION]...`
- **Aliases**: `sh`

Sets a tool version for the current session.

Only works in a session where mise is already activated.

This works by setting environment variables for the current shell session
such as `MISE_NODE_VERSION=20` which is "eval"ed as a shell function created by `mise activate`.

## Arguments

### `[TOOL@VERSION]...`

Tool(s) to use

## Flags

### `-j --jobs <JOBS>`

Number of jobs to run in parallel
[default: 4]

### `--raw`

Directly pipe stdin/stdout/stderr from plugin to user Sets --jobs=1

### `-u --unset`

Removes a previously set version

Examples:

    $ mise shell node@20
    $ node -v
    v20.0.0

# where.md

# `mise where`

- **Usage**: `mise where <TOOL@VERSION>`

Display the installation path for a tool

The tool must be installed for this to work.

## Arguments

### `<TOOL@VERSION>`

Tool(s) to look up
e.g.: ruby@3
if "@&lt;PREFIX>" is specified, it will show the latest installed version
that matches the prefix
otherwise, it will show the current, active installed version

Examples:

    # Show the latest installed version of node
    # If it is is not installed, errors
    $ mise where node@20
    /home/jdx/.local/share/mise/installs/node/20.0.0

    # Show the current, active install directory of node
    # Errors if node is not referenced in any .tool-version file
    $ mise where node
    /home/jdx/.local/share/mise/installs/node/20.0.0

# demo.md

# 30 Second Demo

The following shows using mise to install different versions
of [node](https://nodejs.org).
Note that calling `which node` gives us a real path to node, not a shim.

[![demo](https://github.com/jdx/mise/blob/main/docs/demo.gif?raw=true)](https://github.com/jdx/mise/blob/main/docs/demo.gif)

# README.md

# mise-docs

This repository contains the documentation website for the runtime executor [mise](https://github.com/jdx/mise). The website is powered by [VitePress](https://vitepress.dev/).

# bun.md

# Bun

The following are instructions for using the bun mise core plugin. This is used when there isn't a
git plugin installed named "bun".

The code for this is inside the mise repository at
[`./src/plugins/core/bun.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/bun.rs).

## Usage

The following installs bun and makes it the global default:

```sh
mise use -g bun@0.7     # install bun 0.7.x
mise use -g bun@latest  # install latest bun
```

See available versions with `mise ls-remote bun`.

# go.md

# Go

The following are instructions for using the go mise core plugin. This is used when there isn't a
git plugin installed named "go".

If you want to use [asdf-golang](https://github.com/kennyp/asdf-golang)
then use `mise plugins install go GIT_URL`.

The code for this is inside the mise repository at
[`./src/plugins/core/go.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/go.rs).

## Usage

The following installs the latest version of go-1.21.x (if some version of 1.21.x is not already
installed) and makes it the global default:

```sh
mise use -g go@1.21
```

Minor go versions 1.20 and below require specifying `prefix` before the version number because the
first version of each series was released without a `.0` suffix, making 1.20 an exact version match:

```sh
mise use -g go@prefix:1.20
```

## Settings

Set these with `mise settings set [VARIABLE] [VALUE]` or by setting the environment variable.

### `go_default_packages_file`

- Type: `string`
- Env: `MISE_GO_DEFAULT_PACKAGES_FILE`
- Default: `~/.default-go-packages`

Packages list to install with `go install` after installing a Go version.

### `go_download_mirror`

- Type: `string`
- Env: `MISE_GO_DOWNLOAD_MIRROR`
- Default: `https://dl.google.com/go`

URL to download go sdk tarballs from.

### `go_repo`

- Type: `string`
- Env: `MISE_GO_REPO`
- Default: `https://github.com/golang/go`

Used to get latest go version from GitHub releases.

### `go_set_gobin`

- Type: `bool | null`
- Env: `MISE_GO_SET_GOBIN`
- Default: `null`

Sets `GOBIN` to `~/.local/share/mise/go/installs/[VERSION]/bin`. This causes CLIs installed via
`go install` to have shims created for it which will have env vars from mise such as GOROOT set.

If not using shims or not using `go install` with tools that require GOROOT, it can probably be
safely disabled. See the [go backend](https://mise.jdx.dev/dev-tools/backends/) for the preferred
method to install Go CLIs.

### `go_set_gopath` <Badge type="warning" text="deprecated" />

- Type: `bool`
- Env: `MISE_GO_SET_GOPATH`
- Default: `false`

Sets `GOPATH` to `~/.local/share/mise/go/installs/[VERSION]/packages`. This retains behavior from
asdf and older mise versions. There is no known reason for this to be enabled but it is available
(for now) just in case anyone relies on it.

### `go_skip_checksum`

- Type: `bool`
- Env: `MISE_GO_SKIP_CHECKSUM`
- Default: `false`

Skips checksum verification of downloaded go tarballs.

## Default packages

mise can automatically install a default set of packages right after installing a new go version.
To enable this feature, provide a `$HOME/.default-go-packages` file that lists one packages per
line, for example:

```text
github.com/Dreamacro/clash # allows comments
github.com/jesseduffield/lazygit
```

## `.go-version` file support

mise uses a `.tool-versions` or `mise.toml` file for auto-switching between software versions.
However it can also read go-specific version files named `.go-version`.

# python.md

# Python

The following are instructions for using the python mise core plugin. The core plugin will be used
so long as no plugin is manually
installed named "python" using `mise plugins install python [GIT_URL]`.

The code for this is inside of the mise repository
at [`./src/plugins/core/python.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/python.rs).

## Usage

The following installs the latest version of python-3.11.x and makes it the global
default:

```sh
mise use -g python@3.11
```

You can also use multiple versions of python at the same time:

```sh
$ mise use -g python@3.10 python@3.11
$ python -V
3.10.0
$ python3.11 -V
3.11.0
```

## Settings

`python-build` already has
a [handful of settings](https://github.com/pyenv/pyenv/tree/master/plugins/python-build), in
additional to that python in mise has a few extra configuration variables.

Set these with `mise settings set [VARIABLE] [VALUE]` or by setting the environment variable.

<script setup>
import Settings from '/components/settings.vue';
</script>
<Settings child="python" :level="3" />

## Default Python packages

mise can automatically install a default set of Python packages with pip right after installing a
Python version. To enable this feature, provide a `$HOME/.default-python-packages` file that lists
one package per line, for example:

```text
ansible
pipenv
```

You can specify a non-default location of this file by setting a `MISE_PYTHON_DEFAULT_PACKAGES_FILE`
variable.

## Precompiled python binaries

By default, mise will
download [precompiled binaries](https://github.com/indygreg/python-build-standalone)
for python instead of compiling them with python-build. This makes installing python much faster.

In addition to being faster, it also means you don't have to install all of the system dependencies
either.

That said, there are
some [quirks](https://github.com/indygreg/python-build-standalone/blob/main/docs/quirks.rst)
with the precompiled binaries to be aware of.

If you'd like to disable these binaries, set `mise settings python.compile=1`.

These binaries may not work on older CPUs however you may opt into binaries which
are more compatible with older CPUs by setting `MISE_PYTHON_PRECOMPILED_ARCH` with
a different version. See <https://gregoryszorc.com/docs/python-build-standalone/main/running.html> for
more information
on this option. Set it to "x86_64" for the most compatible binaries.

## python-build

Optionally, mise
uses [python-build](https://github.com/pyenv/pyenv/tree/master/plugins/python-build) (part of pyenv)
to compile python runtimes,
you need to ensure
its [dependencies](https://github.com/pyenv/pyenv/wiki#suggested-build-environment) are installed
before installing python with
python-build.

## Troubleshooting errors with Homebrew

If you normally use Homebrew and you see errors regarding OpenSSL,
your best bet might be using the following command to install Python:

```sh
CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
mise install python@latest;
```

Homebrew installs its own OpenSSL version, which may collide with system-expected ones.
You could even add that to your
`.profile`,
`.bashrc`,
`.zshrc`...
to avoid setting them every time

Additionally, if you encounter issues with python-build,
you may benefit from unlinking pkg-config prior to install
([reason](https://github.com/pyenv/pyenv/issues/2823#issuecomment-1769081965)).

```sh
brew unlink pkg-config
mise install python@latest
brew link pkg-config
```

Thus the entire script would look like:

```sh
brew unlink pkg-config
CFLAGS="-I$(brew --prefix openssl)/include" \
  LDFLAGS="-L$(brew --prefix openssl)/lib" \
  mise install python@latest
brew link pkg-config
```

## Automatic virtualenv activation

Python comes with virtualenv support built in, use it with `mise.toml` configuration like
one of the following:

```toml
[tools]
python = "3.11" # [optional] will be used for the venv

[env]
_.python.venv = ".venv" # relative to this file's directory
_.python.venv = "/root/.venv" # can be absolute
_.python.venv = "{{env.HOME}}/.cache/venv/myproj" # can use templates
_.python.venv = { path = ".venv", create = true } # create the venv if it doesn't exist
```

The venv will need to be created manually with `python -m venv /path/to/venv` unless `create=true`.

## Installing free-threaded python

Free-threaded python can be installed via python-build by running the following:

```bash
MISE_PYTHON_COMPILE=1 PYTHON_BUILD_FREE_THREADING=1 mise install
```

Currently, they are not supported with precompiled binaries.

# zig.md

# Zig

The following are instructions for using the zig mise core plugin.

The code for this is inside the mise repository at
[`./src/plugins/core/zig.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/zig.rs).

## Usage

The following installs zig and makes it the global default:

```sh
mise use -g zig@0.13     # install zig 0.13.x
mise use -g zig@latest  # install latest zig
```

See available versions with `mise ls-remote zig`.

# rust.md

# Rust

Rust is not currently offered as a core plugin. In fact, I don't think you
should actually use mise for rust development. Rust has an official version
manager called [`rustup`](https://rustup.rs/) that is better than what any of
the current mise plugins offer.

You install [rustup](https://rustup.rs/) with the following:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

That said, rust is still one of the most popular languages to use in mise.
A lot of users have success with it so if you'd like to keep all of your
languages configured the same, don't feel like using mise is a bad idea either. Especially if you're only a casual rust user.

If you're a relatively heavy rust user making use of things like channel
overrides, components, and cross-compiling, then I think you really should
just be using rustup though. The experience will be better.

If one day we could figure out a way to provide an equivalent experience with
mise, we could revisit this. We have discussed potentially using mise as a
"front-end" to rustup where there is one rustup install that mise just manages
so you could do something like this:

```toml
[tools]
rust = "nightly"
```

Where that would basically be equivalent to:

```sh
rustup override set nightly
```

Frankly though, this isn't high on my priority list. Use rustup. It's great.

Kudos for writing rust too btw, I've really enjoyed it so far—this is my first rust project.

## Default crates

mise can automatically install a default set of creates right after installing a new rust version.
To enable this feature, provide a `$HOME/.default-cargo-crates` file that lists one crate per line, for
example:

```text
cargo-edit
stylua
```

# node.md

# Node

The following are instructions for using the node mise core plugin. This is used when there isn't a
git plugin installed named "node".

If you want to use [asdf-nodejs](https://github.com/asdf-vm/asdf-nodejs)
then run `mise plugins install node https://github.com/asdf-vm/asdf-nodejs`

The code for this is inside the mise repository at [`./src/plugins/core/node.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/node.rs).

## Usage

The following installs the latest version of node-20.x and makes it the global
default:

```sh
mise use -g node@20
```

## Requirements

See [BUILDING.md](https://github.com/nodejs/node/blob/main/BUILDING.md#building-nodejs-on-supported-platforms) in node's documentation for
required system dependencies.

## Settings

<script setup>
import Settings from '/components/settings.vue';
</script>
<Settings child="node" :level="3" />

### Environment Variables

- `MISE_NODE_VERIFY` [bool]: Verify the downloaded assets using GPG. Defaults to `true`.
- `MISE_NODE_NINJA` [bool]: Use ninja instead of make to compile node. Defaults to `true` if installed.
- `MISE_NODE_CONCURRENCY` [uint]: How many jobs should be used in compilation. Defaults to half the computer cores
- `MISE_NODE_DEFAULT_PACKAGES_FILE` [string]: location of default packages file, defaults to `$HOME/.default-npm-packages`
- `MISE_NODE_CFLAGS` [string]: Additional CFLAGS options (e.g., to override -O3).
- `MISE_NODE_CONFIGURE_OPTS` [string]: Additional `./configure` options.
- `MISE_NODE_MAKE_OPTS` [string]: Additional `make` options.
- `MISE_NODE_MAKE_INSTALL_OPTS` [string]: Additional `make install` options.
- `MISE_NODE_COREPACK` [bool]: Installs the default corepack shims after installing any node version that ships with [corepack](https://github.com/nodejs/corepack).

::: info
TODO: these env vars should be migrated to compatible settings in the future.
:::

## Default node packages

mise-node can automatically install a default set of npm packages right after installing a node version. To enable this feature, provide a `$HOME/.default-npm-packages` file that lists one package per line, for example:

```text
lodash
request
express
```

You can specify a non-default location of this file by setting a `MISE_NODE_DEFAULT_PACKAGES_FILE` variable.

## `.nvmrc` and `.node-version` support

mise uses a `.tool-versions` or `mise.toml` file for auto-switching between software versions. To ease migration, you can have also have it read an existing `.nvmrc` or `.node-version` file to find out what version of Node.js should be used. This will be used if `node` isn't defined in `.tool-versions`/`.mise.toml`.

## "nodejs" -> "node" Alias

You cannot install/use a plugin named "nodejs". If you attempt this, mise will just rename it to
"node". See the [FAQ](https://github.com/jdx/mise#what-is-the-difference-between-nodejs-and-node-or-golang-and-go)
for an explanation.

## Unofficial Builds

Nodejs.org offers a set of [unofficial builds](https://unofficial-builds.nodejs.org/) which are
compatible with some platforms that are not supported by the official binaries. These are a nice alternative to
compiling from source for these platforms.

To use, first set the mirror url to point to the unofficial builds:

```sh
mise settings node.mirror_url=https://unofficial-builds.nodejs.org/download/release/
```

If your goal is to simply support an alternative arch/os like linux-loong64 or linux-armv6l, this is
all that is required. Node also provides flavors such as musl or glibc-217 (an older glibc version
than what the official binaries are built with).

To use these, set `node.flavor`:

```sh
mise settings node.flavor=musl
mise settings node.flavor=glibc-217
```

# deno.md

# Deno

The following are instructions for using the deno mise core plugin. This is used when there isn't a
git plugin installed named "deno".

If you want to use [asdf-deno](https://github.com/asdf-community/asdf-deno)
then run `mise plugins install deno https://github.com/asdf-community/asdf-deno`.

The code for this is inside the mise repository at
[`./src/plugins/core/deno.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/deno.rs).

## Usage

The following installs deno and makes it the global default:

```sh
mise use -g deno@1       # install deno 1.x
mise use -g deno@latest  # install latest deno
```

See available versions with `mise ls-remote deno`.

# erlang.md

# Erlang

The following are instructions for using the erlang core plugin.
This is used when there isn't a git plugin installed named "erlang".

The code for this is inside the mise repository at
[`./src/plugins/core/erlang.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/erlang.rs).

## Usage

The following installs erlang and makes it the global default:

```sh
mise use -g erlang@26
```

See available versions with `mise ls-remote erlang`.

## kerl

The plugin uses [kerl](https://github.com/kerl/kerl) under the hood to build erlang.
See kerl's docs for information on configuring kerl.

# java.md

# Java

The following are instructions for using the java mise core plugin. This is used when there isn't a
git plugin installed named "java".

If you want to use [asdf-java](https://github.com/halcyon/asdf-java)
then use `mise plugins install java GIT_URL`.

The code for this is inside the mise repository at
[`./src/plugins/core/java.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/java.rs).

## Usage

The following installs the latest version of openjdk-21.x (if some version of openjdk-21.x is
not already installed) and makes it the global default:

```sh
mise use -g java@openjdk-21
mise use -g java@21         # alternate shorthands for openjdk-only
```

See available versions with `mise ls-remote java`.

::: warning
Note that shorthand versions (like `21` in the example) use `OpenJDK` as the vendor.
The OpenJDK versions will only be updated for a 6-month period. Updates and security patches will not be available after this short period. This also applies for LTS versions. Also see <https://whichjdk.com> for more information.
:::

## Tool Options

The following [tool-options](/dev-tools/#tool-options) are available for the `java` backend—these
go in `[tools]` in `mise.toml`.

### `release_type`

The `release_type` option allows you to specify the type of release to install. The following values
are supported:

- `ga` (default): General Availability release
- `ea`: Early Access release

```toml
[tools]
"java" = { version = "openjdk-21", release_type = "ea" }
```

## macOS JAVA_HOME Integration

Some applications in macOS rely on `/usr/libexec/java_home` to find installed Java runtimes.

To integrate an installed Java runtime with macOS run the following commands for the proper
version (e.g. openjdk-21).

```sh
sudo mkdir /Library/Java/JavaVirtualMachines/openjdk-21.jdk
sudo ln -s ~/.local/share/mise/installs/java/openjdk-21/Contents /Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents
```

> Note: Not all distributions of the Java SDK support this integration (e.g liberica).

## Legacy version files

The Java core plugin supports the legacy version files `.java-version` and `.sdkmanrc`.

For `.sdkmanrc` files, mise will try to map the vendor and version to the appropriate version
string. For example, the version `20.0.2-tem` will be mapped to `temurin-20.0.2`. Due to Azul's Zulu
versioning, the version `11.0.12-zulu` will be mapped to the major version `zulu-11`. Not all
vendors available in SDKMAN are supported by mise. The following vendors are NOT supported: `bsg` (
Bisheng), `graal` (GraalVM), `nik` (Liberica NIK).

In case an unsupported version of java is needed, some manual work is required:

1. Download the unsupported version to a directory (e.g `~/.sdkman/candidates/java/21.0.1-open`)
2. symlink the new version:

```sh
ln -s ~/.sdkman/candidates/java/21.0.1-open ~/.local/share/mise/installs/java/21.0.1-open
```

3. If on Mac:

```sh
mkdir ~/.local/share/mise/installs/java/21.0.1-open/Contents
mkdir ~/.local/share/mise/installs/java/21.0.1-open/Contents/MacOS

ln -s ~/.sdkman/candidates/java/21.0.1-open ~/.local/share/mise/installs/java/21.0.1-open/Contents/Home
cp ~/.local/share/mise/installs/java/21.0.1-open/lib/libjli.dylib ~/.local/share/mise/installs/java/21.0.1-open/Contents/MacOS/libjli.dylib
```

4. Don't forget to make sure the cache is blocked and valid, by making sure an **empty** directory **exists** for your version in the [mise cache](https://mise.jdx.dev/directories.html#cache-mise):
   e.g.

```sh
$ ls -R $MISE_CACHE_DIR/java
21.0.1-open

mise/java/21.0.1-open:
```

# ruby.md

# Ruby

The following are instructions for using the ruby mise core plugin. This is used when there isn't a
git plugin installed named "ruby".

If you want to use [asdf-ruby](https://github.com/asdf-vm/asdf-ruby)
then use `mise plugins install ruby GIT_URL`.

The code for this is inside the mise repository at
[`./src/plugins/core/ruby.rs`](https://github.com/jdx/mise/blob/main/src/plugins/core/ruby.rs).

## Usage

The following installs the latest version of ruby-3.2.x (if some version of 3.2.x is not already
installed) and makes it the global default:

```sh
mise use -g ruby@3.2
```

Behind the scenes, mise uses [`ruby-build`](https://github.com/rbenv/ruby-build) to compile ruby
from source. Ensure that you have the necessary
[dependencies](https://github.com/rbenv/ruby-build/wiki#suggested-build-environment) installed.
You can check its [README](https://github.com/rbenv/ruby-build/blob/master/README.md) for additional settings and some
troubleshooting.

## Settings

`ruby-build` already has a
[handful of settings](https://github.com/rbenv/ruby-build?tab=readme-ov-file#custom-build-configuration),
in additional to that mise has a few extra settings:

<script setup>
import Settings from '/components/settings.vue';
</script>
<Settings child="ruby" :level="3" />

## Default gems

mise can automatically install a default set of gems right after installing a new ruby version.
To enable this feature, provide a `$HOME/.default-gems` file that lists one gem per line, for
example:

```text
# supports comments
pry
bcat ~> 0.6.0 # supports version constraints
rubocop --pre # install prerelease version
```

## `.ruby-version` and `Gemfile` support

mise uses a `.tool-versions` or `mise.toml` file for auto-switching between software versions.
However it can also read ruby-specific version files `.ruby-version` or `Gemfile`
(if it specifies a ruby version).

Create a `.ruby-version` file for the current version of ruby:

```sh
ruby -v > .ruby-version
```

### Manually updating ruby-build

ruby-build should update daily, however if you find versions do not yet exist you can force an
update:

```bash
mise cache clean
mise ls-remote ruby
```

# core-tools.md

# Core Tools

`mise` comes with some plugins built into the CLI written in Rust. These are new and will improve over
time.

They can be easily overridden by installing a plugin with the same name, e.g.: `mise plugin install python https://github.com/asdf-community/asdf-python`.

You can see the core plugins with `mise plugin ls --core`.

- [Bun](/lang/bun)
- [Deno](/lang/deno)
- [Erlang](/lang/erlang) <Badge type="warning" text="experimental" />
- [Go](/lang/go)
- [Java](/lang/java)
- [NodeJS](/lang/node)
- [Python](/lang/python)
- [Ruby](/lang/ruby)

# index.md

---
# https://vitepress.dev/reference/default-theme-home-page
layout: home
title: Home

hero:
  name: mise-en-place
  tagline: |
    The front-end to your dev env
    <span class="formerly">Pronounced "MEEZ ahn plahs"</span>
  actions:
    - theme: brand
      text: Getting Started
      link: /getting-started
    - theme: alt
      text: About
      link: /about
    - theme: alt
      text: GitHub
      link: https://github.com/jdx/mise
    - theme: alt
      text: Discord
      link: https://discord.gg/UBa7pJUN7Z

features:
  - title: <a href="/dev-tools/">Dev Tools</a>
    details: mise is a polyglot tool version manager. It replaces tools like <a href="https://asdf-vm.com">asdf</a>, nvm, pyenv, rbenv, etc.
  - title: <a href="/environments.html">Environments</a>
    details: mise allows you to switch sets of env vars in different project directories. It can replace <a href="https://github.com/direnv/direnv">direnv</a>.
  - title: <a href="/tasks/">Tasks</a>
    details: mise is a task runner that can replace <a href="https://www.gnu.org/software/make">make</a>, or <a href="https://docs.npmjs.com/cli/v10/using-npm-scripts">npm scripts</a>.
---

<style>
.formerly {
    font-size: 0.7em;
    color: #666;
}
</style>

# configuration.md

# Configuration

## `mise.toml`

`mise.toml` is the config file for mise. They can be at any of the following file paths (in order of precedence, top overrides configuration of lower paths):

- `mise.local.toml` - used for local config, this should not be committed to source control
- `mise.toml`
- `mise/config.toml`
- `.config/mise.toml` - use this in order to group config files into a common directory
- `.config/mise/config.toml`

Notes:

- Paths which start with `mise` can be dotfiles, e.g.: `mise.toml` or `.mise/config.toml`.
- This list doesn't include [Profiles](/profiles) which allow for environment-specific config files like `mise.development.toml`—set with `MISE_PROFILE=development`.
- See [`LOCAL_CONFIG_FILENAMES` in `src/config/mod.rs`](https://github.com/jdx/mise/blob/main/src/config/mod.rs) for the actual code for these paths and their precedence. Some legacy paths are not listed here for brevity.

These files recurse upwards, so if you have a `~/src/work/myproj/mise.toml` file, what is defined
there will override anything set in
`~/src/work/mise.toml` or `~/.config/mise.toml`. The config contents are merged together.

:::tip
Run `mise config` to see what files mise has loaded in order of precedence.
:::

Here is what a `mise.toml` looks like:

```toml
[env]
# supports arbitrary env vars so mise can be used like direnv/dotenv
NODE_ENV = 'production'

[tools]
# specify single or multiple versions
terraform = '1.0.0'
erlang = ['23.3', '24.0']

# supports everything you can do with .tool-versions currently
node = ['16', 'prefix:20', 'ref:master', 'path:~/.nodes/14']

[alias.node.versions] # project-local aliases
# use vfox:version-fox/vfox-nodejs when running `mise i node@backend`
backend = "vfox:version-fox/vfox-nodejs"
# install node-20.x when running `mise i node@my_custom_node`
my_custom_node = '20'

[tasks.build]
run = 'echo "running build tasks"'

[plugins]
# DEPRECATED: use `alias.<PLUGIN>` instead
# specify a custom repo url
# note this will only be used if the plugin does not already exist
python = 'https://github.com/asdf-community/asdf-python'
```

`mise.toml` files are hierarchical. The configuration in a file in the current directory will
override conflicting configuration in parent directories. For example, if `~/src/myproj/mise.toml`
defines the following:

```toml
[tools]
node = '20'
python = '3.10'
```

And `~/src/myproj/backend/mise.toml` defines:

```toml
[tools]
node = '18'
ruby = '3.1'
```

Then when inside of `~/src/myproj/backend`, `node` will be `18`, `python` will be `3.10`, and `ruby`
will be `3.1`. You can check the active versions with `mise ls --current`.

You can also have environment specific config files like `.mise.production.toml`, see
[Profiles](/profiles) for more details.

### `[tools]` - Dev tools

See [Tools](/dev-tools/).

### `[env]` - Arbitrary Environment Variables

See [environments](/environments).

### `[tasks.*]` - Run files or shell scripts

See [Tasks](/tasks/).

### `[settings]` - Mise Settings

See [Settings](/configuration/settings) for the full list of settings.

### `[plugins]` - Specify Custom Plugin Repository URLs

Use `[plugins]` to add/modify plugin shortnames. Note that this will only modify
_new_ plugin installations. Existing plugins can use any URL.

```toml
[plugins]
elixir = "https://github.com/my-org/mise-elixir.git"
node = "https://github.com/my-org/mise-node.git#DEADBEEF" # supports specific gitref
```

If you simply want to install a plugin from a specific URL once, it's better to use
`mise plugin install plugin <GIT_URL>`. Add this section to `.mise.toml` if you want
to share the plugin location/revision with other developers in your project.

This is similar
to [`MISE_SHORTHANDS`](https://github.com/jdx/mise#mise_shorthands_fileconfigmiseshorthandstoml)
but doesn't require a separate file.

### `[aliases]` - Tool version aliases

The following makes `mise install node@my_custom_node` install node-20.x
this can also be specified in a [plugin](/dev-tools/aliases.md).
note adding an alias will also add a symlink, in this case:

```sh
~/.local/share/mise/installs/node/20 -> ./20.x.x
```

```toml
my_custom_node = '20'
```

### Minimum mise version

Define a minimum supported version of mise for the config file. mise will ignore config files that use too new of a version.

```toml
min_version = '2024.11.1'
```

### `mise.toml` schema

- You can find the JSON schema for `.mise.toml` [here](https://github.com/jdx/mise/blob/main/schema/mise.json).
- Most editors can use this to provide autocompletion and validation for when editing a `mise.toml` file ([VSCode](https://code.visualstudio.com/docs/languages/json#_json-schemas-and-settings), [IntelliJ](https://www.jetbrains.com/help/idea/json.html#ws_json_using_schemas), [neovim](https://github.com/b0o/SchemaStore.nvim), etc.)

## Global config: `~/.config/mise/config.toml`

mise can be configured in `~/.config/mise/config.toml`. It's like local `.mise.toml` files except
that
it is used for all directories.

```toml
[tools]
# global tool versions go here
# you can set these with `mise use -g`
node = 'lts'
python = ['3.10', '3.11']

[settings]
# plugins can read the versions files used by other version managers (if enabled by the plugin)
# for example, .nvmrc in the case of node's nvm
legacy_version_file = true                     # enabled by default (unlike asdf)
legacy_version_file_disable_tools = ['python'] # disable for specific tools

# configure `mise install` to always keep the downloaded archive
always_keep_download = false        # deleted after install by default
always_keep_install = false         # deleted on failure by default

# configure how frequently (in minutes) to fetch updated plugin repository changes
# this is updated whenever a new runtime is installed
# (note: this isn't currently implemented but there are plans to add it: https://github.com/jdx/mise/issues/128)
plugin_autoupdate_last_check_duration = '1 week' # set to 0 to disable updates

# config files with these prefixes will be trusted by default
trusted_config_paths = [
    '~/work/my-trusted-projects',
]

verbose = false       # set to true to see full installation output, see `MISE_VERBOSE`
asdf_compat = false   # set to true to ensure .tool-versions will be compatible with asdf, see `MISE_ASDF_COMPAT`
http_timeout = "30s"  # set the timeout for http requests as duration string, see `MISE_HTTP_TIMEOUT`
jobs = 4              # number of plugins or runtimes to install in parallel. The default is `4`.
raw = false           # set to true to directly pipe plugins to stdin/stdout/stderr
yes = false           # set to true to automatically answer yes to all prompts

not_found_auto_install = true # see MISE_NOT_FOUND_AUTO_INSTALL
task_output = "prefix" # see Tasks Runner for more information
paranoid = false       # see MISE_PARANOID

shorthands_file = '~/.config/mise/shorthands.toml' # path to the shorthands file, see `MISE_SHORTHANDS_FILE`
disable_default_shorthands = false # disable the default shorthands, see `MISE_DISABLE_DEFAULT_SHORTHANDS`
disable_tools = ['node']           # disable specific tools, generally used to turn off core tools

env_file = '.env' # load env vars from a dotenv file, see `MISE_ENV_FILE`

experimental = true # enable experimental features

# configure messages displayed when entering directories with config files
status = { missing_tools = "if_other_versions_installed", show_env = false, show_tools = false }
```

## System config: `/etc/mise/config.toml`

Similar to `~/.config/mise/config.toml` but for all users on the system. This is useful for
setting defaults for all users.

## `.tool-versions`

The `.tool-versions` file is asdf's config file and it can be used in mise just like `.mise.toml`.
It isn't as flexible so it's recommended to use `.mise.toml` instead. It can be useful if you
already have a lot of `.tool-versions` files or work on a team that uses asdf.

Here is an example with all the supported syntax:

```text
node        20.0.0       # comments are allowed
ruby        3            # can be fuzzy version
shellcheck  latest       # also supports "latest"
jq          1.6
erlang      ref:master   # compile from vcs ref
go          prefix:1.19  # uses the latest 1.19.x version—needed in case "1.19" is an exact match
shfmt       path:./shfmt # use a custom runtime
node        lts          # use lts version of node (not supported by all plugins)

node        sub-2:lts      # install 2 versions behind the latest lts (e.g.: 18 if lts is 20)
python      sub-0.1:latest # install python-3.10 if the latest is 3.11
```

See [the asdf docs](https://asdf-vm.com/manage/configuration.html#tool-versions) for more info on
this file format.

## Scopes

Both `.mise.toml` and `.tool-versions` support "scopes" which modify the behavior of the version:

- `ref:<SHA>` - compile from a vcs (usually git) ref
- `prefix:<PREFIX>` - use the latest version that matches the prefix. Useful for Go since `1.20`
  would only match `1.20` exactly but `prefix:1.20` will match `1.20.1` and `1.20.2` etc.
- `path:<PATH>` - use a custom compiled version at the given path. One use-case is to re-use
  Homebrew tools (e.g.: `path:/opt/homebrew/opt/node@20`).
- `sub-<PARTIAL_VERSION>:<ORIG_VERSION>` - subtracts PARTIAL_VERSION from ORIG_VERSION. This can
  be used to express something like "2 versions behind lts" such as `sub-2:lts`. Or 1 minor
  version behind the latest version: `sub-0.1:latest`.

## Legacy version files

mise supports "legacy version files" just like asdf. They're language-specific files
like `.node-version`
and `.python-version`. These are ideal for setting the runtime version of a project without forcing
other developers to use a specific tool like mise/asdf.

They support aliases, which means you can have an `.nvmrc` file with `lts/hydrogen` and it will work
in mise and nvm. Here are some of the supported legacy version files:

| Plugin    | "Legacy" (Idiomatic) Files                         |
| --------- | -------------------------------------------------- |
| crystal   | `.crystal-version`                                 |
| elixir    | `.exenv-version`                                   |
| go        | `.go-version`, `go.mod`                            |
| java      | `.java-version`, `.sdkmanrc`                       |
| node      | `.nvmrc`, `.node-version`                          |
| python    | `.python-version`                                  |
| ruby      | `.ruby-version`, `Gemfile`                         |
| terraform | `.terraform-version`, `.packer-version`, `main.tf` |
| yarn      | `.yarnrc`                                          |

In mise these are enabled by default. You can disable them
with `mise settings legacy_version_file=false`.
There is a performance cost to having these when they're parsed as it's performed by the plugin in
`bin/parse-version-file`. However these are [cached](/cache-behavior) so it's not a huge deal.
You may not even notice.

::: info
asdf calls these "legacy version files" so we do too. I think this is a bad name since it implies
that they shouldn't be used—which is definitely not the case IMO. I prefer the term "idiomatic"
version files since they're version files not specific to asdf/mise and can be used by other tools.
(`.nvmrc` being a notable exception, which is tied to a specific tool.)
:::

## Settings

See [Settings](/configuration/settings) for the full list of settings.

## Tasks

See [Tasks](/tasks/) for the full list of configuration options.

## Environment variables

mise can also be configured via environment variables. The following options are available:

### `MISE_DATA_DIR`

Default: `~/.local/share/mise` or `$XDG_DATA_HOME/mise`

This is the directory where mise stores plugins and tool installs. These are not supposed to be
shared
across machines.

### `MISE_CACHE_DIR`

Default (Linux): `~/.cache/mise` or `$XDG_CACHE_HOME/mise`
Default (macOS): `~/Library/Caches/mise` or `$XDG_CACHE_HOME/mise`

This is the directory where mise stores internal cache. This is not supposed to be shared
across machines. It may be deleted at any time mise is not running.

### `MISE_TMP_DIR`

Default: [`std::env::temp_dir()`](https://doc.rust-lang.org/std/env/fn.temp_dir.html) implementation
in rust

This is used for temporary storage such as when installing tools.

### `MISE_SYSTEM_DIR`

Default: `/etc/mise`

This is the directory where mise stores system-wide configuration.

### `MISE_GLOBAL_CONFIG_FILE`

Default: `$MISE_CONFIG_DIR/config.toml` (Usually ~/.config/mise/config.toml)

This is the path to the config file.

### `MISE_DEFAULT_TOOL_VERSIONS_FILENAME`

Set to something other than ".tool-versions" to have mise look for `.tool-versions` files but with
a different name.

### `MISE_DEFAULT_CONFIG_FILENAME`

Set to something other than `.mise.toml` to have mise look for `.mise.toml` config files with a
different name.

### `MISE_PROFILE`

Enables profile-specific config files such as `.mise.development.toml`.
Use this for different env vars or different tool versions in
development/staging/production environments. See
[Profiles](/profiles) for more on how
to use this feature.

### `MISE_ENV_FILE`

Set to a filename to read from env from a dotenv file. e.g.: `MISE_ENV_FILE=.env`.
Uses [dotenvy](https://crates.io/crates/dotenvy) under the hood.

### `MISE_${PLUGIN}_VERSION`

Set the version for a runtime. For example, `MISE_NODE_VERSION=20` will use <node@20.x> regardless
of what is set in `.tool-versions`/`.mise.toml`.

### `MISE_USE_TOML=1`

Set to `0` to default to using `.tool-verisons` in `mise local` instead of `mise.toml` for
configuration.

This is not used by `mise use` which will only use `mise.toml` unless `--path` is specified.

### `MISE_TRUSTED_CONFIG_PATHS`

This is a list of paths that mise will automatically mark as
trusted. They can be separated with `:`.

### `MISE_LOG_LEVEL=trace|debug|info|warn|error`

These change the verbosity of mise.

You can also use `MISE_DEBUG=1`, `MISE_TRACE=1`, and `MISE_QUIET=1` as well as
`--log-level=trace|debug|info|warn|error`.

### `MISE_LOG_FILE=~/mise.log`

Output logs to a file.

### `MISE_LOG_FILE_LEVEL=trace|debug|info|warn|error`

Same as `MISE_LOG_LEVEL` but for the log _file_ output level. This is useful if you want
to store the logs but not have them litter your display.

### `MISE_QUIET=1`

Equivalent to `MISE_LOG_LEVEL=warn`.

### `MISE_HTTP_TIMEOUT`

Set the timeout for http requests in seconds. The default is `30`.

### `MISE_RAW=1`

Set to "1" to directly pipe plugin scripts to stdin/stdout/stderr. By default stdin is disabled
because when installing a bunch of plugins in parallel you won't see the prompt. Use this if a
plugin accepts input or otherwise does not seem to be installing correctly.

Sets `MISE_JOBS=1` because only 1 plugin script can be executed at a time.

### `MISE_FISH_AUTO_ACTIVATE=1`

Configures the vendor_conf.d script for fish shell to automatically activate.
This file is automatically used in homebrew and potentially other installs to
automatically activate mise without configuring.

Defaults to enabled, set to "0" to disable.

# plugins.md

# Plugins

Plugins in mise extend functionality. Historically they were the only way to add new tools as the only backend was asdf the way
that backend works is every tool has its own plugin which needs to be manually installed. However now with core languages and
backends like aqua/ubi, plugins are no longer necessary to run most tools in mise.

Meanwhile, plugins have expanded beyond tools and can provide functionality like [setting env vars globally](/environments.html#plugin-provided-env-directives) without relying on a tool being installed.

Tool plugins should be avoided for security reasons. New tools will not be accepted into mise built with asdf/vfox plugins unless they are very popular and
aqua/ubi is not an option for some reason.
If you want to integrate a new tool into mise, you should either try to get it into the [aqua registry](https://mise.jdx.dev/dev-tools/backends/ubi.html)
or see if it can be installed with [ubi](https://mise.jdx.dev/dev-tools/backends/ubi.html). Then add it to the [registry](https://github.com/jdx/mise/blob/main/registry.toml).
Aqua is definitely preferred to ubi as it has better UX and more features like slsa verification and the ability to use different logic for older versions.

## asdf Plugins

mise uses asdf's plugin ecosystem under the hood. These plugins contain shell scripts like
`bin/install` (for installing) and `bin/list-all` (for listing all of the available versions).

See <https://github.com/mise-plugins/registry> for the list of built-in plugins shorthands. See asdf's
[Create a Plugin](https://asdf-vm.com/plugins/create.html) for how to create your own or just learn
more about how they work.

## vfox Plugins

Similarly, mise can also use [vfox plugins](https://mise.jdx.dev/dev-tools/backends/vfox.html). These have the advantage of working on Windows so are preferred.

## Plugin Authors

<https://github.com/mise-plugins> is a GitHub organization for community-developed plugins.
See [SECURITY.md](https://github.com/jdx/mise/blob/main/SECURITY.md) for more details on how plugins here are treated differently.

If you'd like your plugin to be hosted here please let me know (GH discussion or discord is fine)
and I'd be happy to host it for you.

## Tool Options

mise has support for "tool options" which is configuration specified in `mise.toml` to change behavior
of tools. One example of this is virtualenv on python runtimes:

```toml
[tools]
python = {version='3.11', virtualenv='.venv'}
```

This will be passed to all plugin scripts as `MISE_TOOL_OPTS__VIRTUALENV=.venv`. The user can specify
any option and it will be passed to the plugin in that format.

Currently this only supports simple strings, but we can make it compatible with more complex types
(arrays, tables) fairly easily if there is a need for it.

## Templates

Plugin custom repository values can be templates, see [Templates](/templates) for details.

```toml
[plugins]
my-plugin = "https://{{ get_env(name='GIT_USR', default='empty') }}:{{ get_env(name='GIT_PWD', default='empty') }}@github.com/foo/my-plugin.git"
```

# continuous-integration.md

# Continuous integration

You can use Mise in continuous integration environments to provision the environment with the tools the project needs.
We recommend that your project pins the tools to a specific version to ensure the environment is reproducible.

## Any CI provider

Continuous integration pipelines allow running arbitrary commands. You can use this to install Mise and run `mise install` to install the tools:

```yaml
script: |
  curl https://mise.run | sh
  mise install
```

To ensure you run the version of the tools installed by Mise, make sure you run them through the `mise x` command:

```yaml
script: |
  mise x -- npm test
```

Alternatively, you can add the [shims](/dev-tools/shims.md) directory to your `PATH`, if the CI provider allows it.

## GitHub Actions

If you use GitHub Actions, we provide a [mise-action](https://github.com/jdx/mise-action) that wraps the installation of Mise and the tools. All you need to do is to add the action to your workflow:

```yaml
name: test
on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: jdx/mise-action@v2
        with:
          version: 2023.12.0 # [default: latest] mise version to install
          install: true # [default: true] run `mise install`
          cache: true # [default: true] cache mise using GitHub's cache
          # automatically write this .tool-versions file
          experimental: true # [default: false] enable experimental features
          tool_versions: |
            shellcheck 0.9.0
          # or, if you prefer mise.toml format:
          mise_toml: |
            [tools]
            shellcheck = "0.9.0"
      - run: shellcheck scripts/*.sh
```

## GitLab CI

You can use any docker image with `mise` installed to run your CI jobs.
Here's an example using `debian-slim` as base image:
::: details

```dockerfile
FROM debian:12-slim

RUN apt-get update  \
    && apt-get -y --no-install-recommends install  \
      # install any tools you need
      sudo curl git ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://mise.run | MISE_VERSION=v... MISE_INSTALL_PATH=/usr/local/bin/mise sh
```

:::

When configuring your job, you can cache some of the [Mise directories](/directories).

```yaml
build-job:
  stage: build
  image: mise-debian-slim # Use the image you created
  variables:
    MISE_DATA_DIR: .mise/mise-data
    MISE_CACHE_DIR: .mise/mise-cache
  cache:
    - key:
        prefix: mise-
        files: ["mise.toml", "mise.lock"] # mise.lock is optional, only if using `lockfile = true`
      paths:
        - $MISE_DATA_DIR
        - $MISE_CACHE_DIR
  script:
    - mise install
    - mise exec --command 'npm build'
```

## Xcode Cloud

If you are using Xcode Cloud, you can use custom `ci_post_clone.sh` [build script](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts) to install Mise. Here's an example:

```bash
#!/bin/sh
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

mise install # Installs the tools in mise.toml
eval "$(mise activate bash --shims)" # Adds the activated tools to $PATH

swiftlint {args}
```

# cache-behavior.md

# Cache Behavior

mise makes use of caching in many places in order to be efficient. The details about how long to keep
cache for should eventually all be configurable. There may be gaps in the current behavior where
things are hardcoded, but I'm happy to add more settings to cover whatever config is needed.

Below I explain the behavior it uses around caching. If you're seeing behavior where things don't appear
to be updating, this is a good place to start.

## Plugin/Runtime Cache

Each plugin has a cache that's stored in `~/$MISE_CACHE_DIR/<PLUGIN>`. It stores
the list of versions available for that plugin (`mise ls-remote <PLUGIN>`), the legacy filenames (see below),
the list of aliases, the bin directories within each runtime installation, and the result of
running `exec-env` after the runtime was installed.

Remote versions are updated daily by default. The file is zlib messagepack, if you want to view it you can
run the following (requires [msgpack-cli](https://github.com/msgpack/msgpack-cli)).

```sh
cat ~/$MISE_CACHE_DIR/node/remote_versions.msgpack.z | perl -e 'use Compress::Raw::Zlib;my $d=new Compress::Raw::Zlib::Inflate();my $o;undef $/;$d->inflate(<>,$o);print $o;' | msgpack-cli decode
```

Note that the caching of `exec-env` may be problematic if the script isn't simply exporting
static values. The vast majority of `exec-env` scripts only export static values, but if you're
working with a plugin that has a dynamic `exec-env` submit
a ticket and we can try to figure out what to do.

Caching `exec-env` massively improved the performance of mise since it requires calling bash
every time mise is initialized. Ideally, we can keep this
behavior.

# shims.md

# Shims

::: tip
The [beginner's guide](https://dev.to/jdxcode/beginners-guide-to-rtx-ac4), and my [blog post](https://jdx.dev/posts/2024-04-13-shims-how-they-work-in-mise-en-place/) are helpful resources to dive deeper into shims.
:::

## Introduction

There are two ways for dev tools to be loaded into your shell: `mise activate` and `shims`.

- Mise's "PATH" activation method updates environment variables at each prompt by modifying `PATH`
- The "shims" method uses symlinks to the mise binary that intercept commands and load the appropriate environment

While the `PATH` design of mise works great in most cases, there are some situations where shims are
preferable. One example is when calling mise binaries from an IDE.

To support this, mise does have a shim dir that can be used. It's located at `~/.local/share/mise/shims`.

```sh
$ mise use -g node@20
$ npm install -g prettier@3.1.0
$ mise reshim # may be required if new shims need to be created after installing packages
$ ~/.local/share/mise/shims/node -v
v20.0.0
$ ~/.local/share/mise/shims/prettier -v
3.1.0
```

::: tip
`mise activate --shims` is a shorthand for adding the shims directory to PATH.
:::

::: info
`mise reshim` actually should get called automatically if you're using npm so an explicit reshim should not be necessary
in that scenario. Also, this bears repeating but: `mise reshim` just creates/removes the shims. People use it as a
"fix it" button but it really should only be necessary if `~/.local/share/mise/shims` doesn't contain something it should.

mise also runs a reshim anytime a tool is installed/updated/removed so you don't need to use it for those scenarios.

Also don't put things in there manually, mise will just delete it next reshim.
:::

## How to add mise shims to PATH

If you prefer to use shims, you can run the following to use mise without activating it.

You can use `.bashrc`/`.zshrc` instead of `.bash_profile`/`.zprofile` if you prefer to only use
mise in interactive sessions (`.bash_profile`/`.zprofile` will work in non-interactive places
like scripts or IDEs).

::: code-group

```sh [bash]
# note that bash will read from ~/.profile or ~/.bash_profile if the latter exists
# ergo, you may want to check to see which is defined on your system and only append to the existing file
echo 'export PATH="$HOME/.local/share/mise/shims:$PATH"' >> ~/.bash_profile
```

```sh [zsh]
echo 'export PATH="$HOME/.local/share/mise/shims:$PATH"' >> ~/.zprofile
```

```sh [fish]
fish_add_path ~/.local/share/mise/shims
```

:::tip
You can also run `mise activate --shims` which will do the above for you.
:::

## Shims vs PATH

In general, I recommend using PATH (`mise activate`) instead of shims for _interactive_ situations. The
way activate works is every time the prompt is displayed, mise-en-place will determine what PATH and other
env vars should be and export them. This is why it doesn't work well for non-interactive situations like
scripts. The prompt never gets displayed so you have to manually call `mise hook-env` to get mise to update
the env vars.

Also, if you run a set of commands in a single line like the following:

```sh
cd ~
cd ~/src/proj1 && node -v && cd ~/src/proj2 && node -v
```

Using `mise activate`, this will use the tools from `~`, not from `~/src/proj1` or `~/src/proj2` even
after the directory changed because the prompt never got displayed. That might be obvious to you, not sure,
what I'm trying to convey though is just think of mise running just before your prompt gets displayed—because
that literally is what is happening. It's not a magical utility that is capable of having your environment
always setup perfectly in every situation even though it might normally "feel" that way.

Note that shims _will_ work with the inline example above.

::: info
This may be fixable at least for some shells if they support a hook for directory change, however
some investigation will need to be done. See [#1294](https://github.com/jdx/mise/issues/1294) for details.
:::

### `which`

`which` is a command that I personally find great value in. shims effectively "break" `which` and
cause it to show the location of the shim. Of course `mise which` will show the location but I prefer
the "cleanliness" of running `which node` and getting back a real path with a version number inside of it.
e.g:

```sh
$ which node
/Users/jdx/.mise/installs/node/20/bin/node
```

### Env vars and shims

A downside of shims is the "mise environment" is only loaded when a shim is called. This means if you
set an environment variable in `.mise.toml`, it will only be run when a shim is called. So the following
only works under `mise activate`:

```sh
$ mise set NODE_ENV=production
$ echo $NODE_ENV
production
```

But this will work in either:

```sh
$ mise set NODE_ENV=production
$ node -p process.env.NODE_ENV
production
```

Also, `mise x|exec` and `mise r|run` can be used to get the environment even if you don't need any mise
tools:

```sh
$ mise set NODE_ENV=production
$ mise x -- bash -c "echo \$NODE_ENV"
production
$ mise r some_task_that_uses_NODE_ENV
production
```

::: tip
In general, [tasks](/tasks/) are a good way to ensure that the mise environment is always loaded so
this isn't a problem.
:::

## Hook on `cd`

Some version managers modify the behavior of `cd`. That might seem like the ideal method of making a version
manager, it has tons of gaps. It doesn't work if you use `pushd|popd` or other commands that modify PWD—though
some shells have a "chpwd" hook that would. It doesn't run if you modify the `.mise.toml` file.

The upside is that it doesn't run as frequently but since mise is written in rust the cost for executing
mise is negligible (~4-5ms).

## .zshrc/.bashrc files

rc files like `.zshrc` are unusual. It's a script but also runs only for interactive sessions. If you need
to access tools provided by mise inside of an rc file you have 2 options:

::: code-group

```sh [hook-env]
eval "$(mise activate zsh)"
eval "$(mise hook-env -s zsh)"
node some_script.js
```

```sh [shims]
eval "$(mise activate zsh --shims)" # should be first
eval "$(mise activate zsh)"
node some_script.js
```

:::

The `hook-env` option is the one I would go with. It's a bit cleaner since you won't have the shims
inside your PATH at all. If you do go with shims, it will need to be first so they get overridden.

## Performance

Truthfully, you're probably not going to notice much in the way of performance with any solution here.
However, I would like to document what the tradeoffs are since it's not as simple as "shims are slow".
In asdf they are, but that's because asdf is written in bash. In mise the cost of the shims are negligible.

First, since mise runs every time the prompt is displayed with `mise activate`, you'll pay a few ms cost
every time the prompt is displayed. Regardless of whether or not you're actively using a mise tool, you'll
pay that penalty every time you run any command. It does have some short-circuiting logic to make it faster
if there are no changes but it doesn't help much unless you have a very complex setup.

shims have basically the same performance profile but run when the shim is called. This makes some situations
better, and some worse.

If you are calling a shim from within a bash script like this:

```sh
for i in {1..500}; do
    node script.js
done
```

You'll pay the mise penalty every time you call it within the loop. However, if you did the same thing
but call a subprocess from within a shim (say, node creating a node subprocess), you will _not_ pay a new
penalty. This is because when a shim is called, mise sets up the environment with PATH for all tools and
those PATH entries will be before the shim directory.

In other words, which is better in terms of performance just depends on how you're calling mise. Really
though I think most users won't notice a 5ms lag on their terminal so I suggest `mise activate`.

## Neither shims nor PATH

[I don't actually use either of these methods](https://mise.jdx.dev/how-i-use-mise.html). There are many
ways to load the mise environment that don't require either, chiefly: `mise x|exec` and `mise r|run`.

These will both load all of the tools and env vars before executing something. I find this to be
ideal because I don't need to modify my shell rc file at all and my environment is always loaded
explicitly. I find this a "clean" way of working.

The obvious downside is that anytime I want to use `mise` I need to prefix it with `mise exec|run`,
though I alias them to `mx|mr`.

This is what I'd recommend if you're like me and prefer things to be precise over "easy". Or perhaps
if you're just wanting to use mise on a single project because that's what your team uses and prefer
not to use it to manage anything else on your system. IMO using a shell extension for that use-case
would be overkill.

Part of the reason for this is I often need to make sure I'm on my development version of mise. If you
work on mise yourself I would recommend working in a similar way and disabling `mise activate` or shims
while you are working on it.

# aliases.md

# Aliases

## Aliased Backends

Tools can be aliased so that something like `node` which normally maps to `core:node` can be changed
to something like `asdf:company/our-custom-node` instead.

```toml
[alias]
node = 'asdf:company/our-custom-node' # shorthand for https://github.com/company/our-custom-node
erlang = 'asdf:https://github.com/company/our-custom-erlang'
```

## Aliased Versions

mise supports aliasing the versions of runtimes. One use-case for this is to define aliases for LTS
versions of runtimes. For example, you may want to specify `lts-hydrogen` as the version for <node@20.x>
so you can use set it with `node lts-hydrogen` in `.tool-versions`/`mise.toml`.

User aliases can be created by adding an `alias.<PLUGIN>` section to `~/.config/mise/config.toml`:

```toml
[alias.node.versions]
my_custom_20 = '20'
```

Plugins can also provide aliases via a `bin/list-aliases` script. Here is an example showing node.js
versions:

```bash
#!/usr/bin/env bash

echo "lts-hydrogen 18"
echo "lts-gallium 16"
echo "lts-fermium 14"
```

::: info
Because this is mise-specific functionality not currently used by asdf it isn't likely to be in any
plugin currently, but plugin authors can add this script without impacting asdf users.
:::

## Templates

Alias values can be templates, see [Templates](/templates) for details.

```toml
[alias.node.versions]
current = "{{exec(command='node --version')}}"
```

# go.md

# Go Backend <Badge type="warning" text="experimental" />

You may install packages directly via [go install](https://go.dev/doc/install) even if there
isn't an asdf plugin for it.

The code for this is inside of the mise repository at [`./src/backend/go.rs`](https://github.com/jdx/mise/blob/main/src/backend/go.rs).

## Dependencies

This relies on having `go` installed. Which you can install via mise:

```sh
mise use -g go
```

::: tip
Any method of installing `go` is fine if you want to install go some other way.
mise will use whatever `go` is on PATH.
:::

## Usage

The following installs the latest version of [hivemind](https://github.com/DarthSim/hivemind) and
sets it as the active version on PATH:

```sh
$ mise use -g go:github.com/DarthSim/hivemind
$ hivemind --help
Hivemind version 1.1.0
```

# ubi.md

# Ubi Backend

You may install GitHub Releases and URL packages directly using [ubi](https://github.com/houseabsolute/ubi) backend. ubi is directly compiled into
the mise codebase so it does not need to be installed separately to be used. ubi is the preferred backend when it functions for tools as it is the
simplest and requires minimal configuration.

The code for this is inside of the mise repository at [`./src/backend/ubi.rs`](https://github.com/jdx/mise/blob/main/src/backend/ubi.rs).

## Usage

The following installs the latest version of goreleaser
and sets it as the active version on PATH:

```sh
$ mise use -g ubi:goreleaser/goreleaser
$ goreleaser --version
1.25.1
```

The version will be set in `~/.config/mise/config.toml` with the following format:

```toml
[tools]
"ubi:goreleaser/goreleaser" = "latest"
```

## Tool Options

The following [tool-options](/dev-tools/#tool-options) are available for the `ubi` backend—these
go in `[tools]` in `mise.toml`.

### `exe`

The `exe` option allows you to specify the executable name in the archive. This is useful when the
archive contains multiple executables.

If you get an error like `could not find any files named cli in the downloaded zip file`, you can
use the `exe` option to specify the executable name:

```toml
[tools]
"ubi:cli/cli" = { exe = "gh" } # github's cli
```

### `matching`

Set a string to match against the release filename when there are multiple files for your
OS/arch, i.e. "gnu" or "musl". Note that this is only used when there is more than one
matching release filename for your OS/arch. If only one release asset matches your OS/arch,
then this will be ignored.

```toml
[tools]
"ubi:BurntSushi/ripgrep" = { matching = "musl" }
```

## Supported Ubi Syntax

- **GitHub shorthand for latest release version:** `ubi:goreleaser/goreleaser`
- **GitHub shorthand for specific release version:** `ubi:goreleaser/goreleaser@1.25.1`
- **URL syntax:** `ubi:https://github.com/goreleaser/goreleaser/releases/download/v1.16.2/goreleaser_Darwin_arm64.tar.gz`

# spm.md

# SPM Backend <Badge type="warning" text="experimental" />

You may install executables managed by [Swift Package Manager](https://www.swift.org/documentation/package-manager) directly from GitHub releases.

The code for this is inside of the mise repository at [`./src/backend/spm.rs`](https://github.com/jdx/mise/blob/main/src/backend/spm.rs).

## Dependencies

This relies on having `swift` installed. You can install it according to the [instructions](https://www.swift.org/install).

> [!NOTE]
> If you have Xcode installed and selected in your system via `xcode-select`, Swift is already available through the toolchain embedded in the Xcode installation.

## Usage

The following installs the latest version of `tuist`
and sets it as the active version on PATH:

```sh
$ mise use -g spm:tuist/tuist
$ tuist --help
OVERVIEW: Generate, build and test your Xcode projects.

USAGE: tuist <subcommand>
...
```

The version will be set in `~/.config/mise/config.toml` with the following format:

```toml
[tools]
"spm:tuist/tuist" = "latest"
```

### Supported Syntax

| Description                                   | Usage                                           |
| --------------------------------------------- | ----------------------------------------------- |
| GitHub shorthand for latest release version   | `spm:tuist/tuist`                               |
| GitHub shorthand for specific release version | `spm:tuist/tuist@4.15.0`                        |
| GitHub url for latest release version         | `spm:https://github.com/tuist/tuist.git`        |
| GitHub url for specific release version       | `spm:https://github.com/tuist/tuist.git@4.15.0` |

Other syntax may work but is unsupported and untested.

# pipx.md

# pipx Backend

You may install python packages directly from:

- PyPI
- Git
- GitHub
- Http

The code for this is inside of the mise repository at [`./src/backend/pipx.rs`](https://github.com/jdx/mise/blob/main/src/backend/pipx.rs).

## Dependencies

This relies on having `pipx` installed. You can install it with or without mise.
Here is how to install `pipx` with mise:

```sh
mise use -g python
pip install --user pipx
```

Other installation instructions can be found [here](https://pipx.pypa.io/latest/installation/)

## Usage

The following installs the latest version of [black](https://github.com/psf/black)
and sets it as the active version on PATH:

```sh
$ mise use -g pipx:psf/black
$ black --version
black, 24.3.0
```

The version will be set in `~/.config/mise/config.toml` with the following format:

```toml
[tools]
"pipx:psf/black" = "latest"
```

### Supported Pipx Syntax

| Description                           | Usage                                                  |
| ------------------------------------- | ------------------------------------------------------ |
| PyPI shorthand latest version         | `pipx:black`                                           |
| PyPI shorthand for specific version   | `pipx:black@24.3.0`                                    |
| GitHub shorthand for latest version   | `pipx:psf/black`                                       |
| GitHub shorthand for specific version | `pipx:psf/black@24.3.0`                                |
| Git syntax for latest version         | `pipx:git+https://github.com/psf/black`                |
| Git syntax for a branch               | `pipx:git+https://github.com/psf/black.git@main`       |
| Https with zipfile                    | `pipx:https://github.com/psf/black/archive/18.9b0.zip` |

Other syntax may work but is unsupported and untested.

## Settings

Set these with `mise settings set [VARIABLE] [VALUE]` or by setting the environment variable listed.

<script setup>
import Settings from '/components/settings.vue';
</script>
<Settings child="pipx" :level="3" />

## Tool Options

The following [tool-options](/dev-tools/#tool-options) are available for the `pipx` backend—these
go in `[tools]` in `mise.toml`.

### `extras`

Install additional components.

```toml
[tools]
"pipx:harlequin" = { extras = "postgres,s3" }
```

### `pipx_args`

Additional arguments to pass to `pipx` when installing the package.

```toml
[tools]
"pipx:black" = { pipx_args = "--preinstall" }
```

### `uvx_args`

Additional arguments to pass to `uvx` when installing the package.

```toml
[tools]
"pipx:ansible-core" = { uvx_args = "--with ansible" }
```

# vfox.md

# Vfox Backend <Badge type="warning" text="experimental" />

[Vfox](https://github.com/version-fox/vfox) plugins may be used in mise to install tools.

The code for this is inside the mise repository at [`./src/backend/vfox.rs`](https://github.com/jdx/mise/blob/main/src/backend/vfox.rs).

## Dependencies

No dependencies are required for vfox. Vfox lua code is read via a lua interpreter built into mise.

## Usage

The following installs the latest version of cmake and sets it as the active version on PATH:

```sh
$ mise use -g vfox:version-fox/vfox-cmake
$ cmake --version
cmake version 3.21.3
```

The version will be set in `~/.config/mise/config.toml` with the following format:

```toml
[tools]
"vfox:version-fox/vfox-cmake" = "latest"
```

## Default plugin backend

If you'd like to use vfox plugins by default like on Windows, set the following settings:

```sh
mise settings asdf=false
mise settings vfox=true
```

Now you can list available plugins with `mise registry`:

```sh
$ mise registry | grep vfox:
clang          vfox:version-fox/vfox-clang
cmake          vfox:version-fox/vfox-cmake
crystal        vfox:yanecc/vfox-crystal
dart           vfox:version-fox/vfox-dart
dotnet         vfox:version-fox/vfox-dotnet
elixir         vfox:version-fox/vfox-elixir
etcd           vfox:version-fox/vfox-etcd
flutter        vfox:version-fox/vfox-flutter
golang         vfox:version-fox/vfox-golang
gradle         vfox:version-fox/vfox-gradle
groovy         vfox:version-fox/vfox-groovy
julia          vfox:ahai-code/vfox-julia
kotlin         vfox:version-fox/vfox-kotlin
kubectl        vfox:ahai-code/vfox-kubectl
maven          vfox:version-fox/vfox-maven
mongo          vfox:yeshan333/vfox-mongo
php            vfox:version-fox/vfox-php
protobuf       vfox:ahai-code/vfox-protobuf
scala          vfox:version-fox/vfox-scala
terraform      vfox:enochchau/vfox-terraform
vlang          vfox:ahai-code/vfox-vlang
```

And they will be installed when running commands such as `mise use -g cmake` without needing to
specify `vfox:cmake`.

# asdf.md

# asdf Backend

asdf is the original backend for mise. It's the default if no backend is specified,
e.g.: `mise i ripgrep` will use [asdf](https://gitlab.com/wt0f/asdf-ripgrep) but `mise i cargo:ripgrep`
will use the [cargo](./cargo) backend. You can explicitly specify the asdf backend with `mise i asdf:ripgrep`.
If you wish.

If choosing a backend to integrate a tool into mise, it's discouraged to use the asdf backend. ubi
would be the ideal choice if it can work as a single binary, otherwise aqua would be the next best choice
since it requires minimal configuration and doesn't require executing code in a plugin. Generally
vfox plugins can handle anything an asdf plugin might need to do while also being potentially able
to support windows.

There are [hundreds of plugins](https://github.com/mise-plugins/registry) available in the
[mise registry](https://github.com/mise-plugins) and you can also install plugins from git
repos or local directories.

::: warning
Take care using plugins as well as anything else you get from the internet. CLIs are
unfortunately capable of doing a lot of damage to your system if a bad actor manages to
get into your system through a plugin or other tool.
:::

## Writing asdf plugins for mise

See the asdf documentation for more information on [writing plugins](https://asdf-vm.com/plugins/create.html).

_TODO: document special features only available in mise._

# aqua.md

# Aqua Backend

[Aqua](https://aquaproj.github.io/) tools may be used natively in mise. Aqua is encouraged as a backend for new tools if they
cannot be used with ubi as aqua tools directly fetch tarballs from the vendor without requiring unsafe
code execution in a plugin.

The code for this is inside the mise repository at [`./src/backend/aqua.rs`](https://github.com/jdx/mise/blob/main/src/backend/aqua.rs).

## Usage

The following installs the latest version of ripgrep and sets it as the active version on PATH:

```sh
$ mise use -g aqua:BurntSushi/ripgrep
$ rg --version
ripgrep 14.1.1
```

The version will be set in `~/.config/mise/config.toml` with the following format:

```toml
[tools]
"aqua:BurntSushi/ripgrep" = "latest"
```

Some tools will default to use aqua if they're specified in [registry.toml](https://github.com/jdx/mise/blob/main/registry.toml)
to use the aqua backend. To see these tools, run `mise registry | grep aqua:`.

## Settings

<script setup>
import Settings from '/components/settings.vue';
</script>
<Settings child="aqua" :level="3" />

# index.md

# Backends

In addition to asdf plugins, you can also directly install CLIs with some package managers.

- [asdf](/dev-tools/backends/asdf)
- [aqua](/dev-tools/backends/aqua)
- [Cargo](/dev-tools/backends/cargo)
- [Go](/dev-tools/backends/go) <Badge type="warning" text="experimental" />
- [NPM](/dev-tools/backends/npm)
- [Pipx](/dev-tools/backends/pipx)
- [SPM](/dev-tools/backends/spm) <Badge type="warning" text="experimental" />
- [Ubi](/dev-tools/backends/ubi)
- [Vfox](/dev-tools/backends/vfox) <Badge type="warning" text="experimental" />
- [More coming soon!](https://github.com/jdx/mise/discussions/1250)

::: tip
If you'd like to contribute a new backend to mise, they're not difficult to write.
See [`./src/backend/`](https://github.com/jdx/mise/tree/main/src/backend) for examples.
:::

# npm.md

# npm Backend

You may install packages directly from [npmjs.org](https://npmjs.org/) even if there
isn't an asdf plugin for it.

The code for this is inside of the mise repository at [`./src/backend/npm.rs`](https://github.com/jdx/mise/blob/main/src/backend/npm.rs).

## Dependencies

This relies on having `npm` installed. You can install it with or without mise.
Here is how to install `npm` with mise:

```sh
mise use -g node
```

## Usage

The following installs the latest version of [prettier](https://www.npmjs.com/package/prettier)
and sets it as the active version on PATH:

```sh
$ mise use -g npm:prettier
$ prettier --version
3.1.0
```

The version will be set in `~/.config/mise/config.toml` with the following format:

```toml
[tools]
"npm:prettier" = "latest"
```

## Settings

Set these with `mise settings set [VARIABLE] [VALUE]` or by setting the environment variable listed.

<script setup>
import Settings from '/components/settings.vue';
</script>
<Settings child="npm" :level="3" />

# cargo.md

# Cargo Backend

You may install packages directly from [Cargo Crates](https://crates.io/) even if there
isn't an asdf plugin for it.

The code for this is inside the mise repository at [`./src/backend/cargo.rs`](https://github.com/jdx/mise/blob/main/src/backend/cargo.rs).

## Dependencies

This relies on having `cargo` installed. You can either install it on your
system via [rustup](https://rustup.rs/):

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Or you can install it via mise:

```sh
mise use -g rust
```

## Usage

The following installs the latest version of [eza](https://crates.io/crates/eza) and
sets it as the active version on PATH:

```sh
$ mise use -g cargo:eza
$ eza --version
eza - A modern, maintained replacement for ls
v0.17.1 [+git]
https://github.com/eza-community/eza
```

The version will be set in `~/.config/mise/config.toml` with the following format:

```toml
[tools]
"cargo:eza" = "latest"
```

### Using Git

You can install a any package from a Git repository using the `mise` command. This allows you to
install a particular tag, branch, or commit revision:

```sh
# Install a specific tag
mise use cargo:github.com/username/demo@tag:<release_tag>

# Install the latest from a branch
mise use cargo:github.com/username/demo@branch:<branch_name>

# Install a specific commit revision
mise use cargo:github.com/username/demo@rev:<commit_hash>
```

This will execute a `cargo install` command with the corresponding Git options.

## Settings

Set these with `mise settings set [VARIABLE] [VALUE]` or by setting the environment variable listed.

<script setup>
import Settings from '/components/settings.vue';
</script>
<Settings child="cargo" :level="3" />

## Tool Options

The following [tool-options](/dev-tools/#tool-options) are available for the `cargo` backend—these
go in `[tools]` in `mise.toml`.

### `features`

Install additional components (passed as `cargo install --features`):

```toml
[tools]
"cargo:cargo-edit" = { version = "latest", features = "add" }
```

### `default-features`

Disable default features (passed as `cargo install --no-default-features`):

```toml
[tools]
"cargo:cargo-edit" = { version = "latest", default-features = false }
```

### `bin`

Select the CLI bin name to install when multiple are available (passed as `cargo install --bin`):

```toml
[tools]
"cargo:github.com/username/demo" = { version = "tag:v1.0.0", bin = "demo" }
```

### `crate`

Select the crate name to install when multiple are available (passed as
`cargo install --git=<repo> <crate>`):

```toml
[tools]
"cargo:github.com/username/demo" = { version = "tag:v1.0.0", crate = "demo" }
```

### `locked`

Use Cargo.lock (passes `cargo install --locked`) when building CLI. This is the default behavior,
pass `false` to disable:

```toml
[tools]
"cargo:github.com/username/demo" = { version = "latest", locked = false }
```

# index.md

# Dev Tools

_Like [asdf](https://asdf-vm.com) (or [nvm](https://github.com/nvm-sh/nvm)
or [pyenv](https://github.com/pyenv/pyenv) but for any language) it manages dev tools like node,
python, cmake, terraform, and [hundreds more](/plugins)._

::: tip
New developer? Try reading the [Beginner's Guide](https://dev.to/jdxcode/beginners-guide-to-rtx-ac4)
for a gentler introduction.
:::

mise is a tool for managing programming language and tool versions. For example, use this to install
a particular version of Node.js and ruby for a project. Using `mise activate`, you can have your
shell automatically switch to the correct node and ruby versions when you `cd` into the project's
directory. Other projects on your machine can use a different set of versions.

mise is inspired by [asdf](https://asdf-vm.com) and uses asdf's
vast [plugin ecosystem](https://github.com/mise-plugins/registry)
under the hood. However, it is _much_ faster than asdf and has a more friendly user experience.
For more on how mise compares to asdf, [see below](./comparison-to-asdf). See plugins available for
mise with
[`mise plugins ls-remote`](/cli/plugins/ls-remote).

mise can be configured in many ways. The most typical is by `.mise.toml`, but it's also compatible
with asdf `.tool-versions` files. It can also use idiomatic version files like `.node-version` and
`.ruby-version`. See [Configuration](/configuration) for more.

- Like [direnv](https://github.com/direnv/direnv) it
  manages [environment variables](/configuration#env---arbitrary-environment-variables) for
  different project directories.
- Like [make](https://www.gnu.org/software/make/manual/make.html) it manages [tasks](/tasks/) used
  to build and test projects.

## How it works

mise hooks into your shell (with `mise activate zsh`) and sets the `PATH`
environment variable to point your shell to the correct runtime binaries. When you `cd` into a
directory containing a `.tool-versions`/`.mise.toml` file, mise will automatically set the
appropriate tool versions in `PATH`.

::: info
mise does not modify "cd". It actually runs every time the prompt is _displayed_.
See the [FAQ](/faq#what-does-mise-activate-do).
:::

After activating, every time your prompt displays it will call `mise hook-env` to fetch new
environment variables.
This should be very fast. It exits early if the directory wasn't changed or `.tool-versions`/
`.mise.toml` files haven't been modified.

Unlike asdf which uses shim files to dynamically locate runtimes when they're called, mise modifies
`PATH` ahead of time so the runtimes are called directly. This is not only faster since it avoids
any overhead, but it also makes it so commands like `which node` work as expected. This also
means there isn't any need to run `asdf reshim` after installing new runtime binaries.

You should note that mise does not directly install these tools.
Instead, it leverages plugins to install runtimes.
See [plugins](/plugins) below.

## Common commands

Here are some of the most important commands when it comes to working with dev tools. Click the
header
for each command to go to its reference documentation page to see all available flags/options and
more
examples.

### [`mise use`](/cli/use)

For some users, `mise use` might be the only command you need to learn. It will do the following:

- Install the tool's plugin if needed
- Install the specified version
- Set the version as active (it's in PATH)

`mise use node@20` will install the latest version of node-20 and create/update the
.tool-versions/.mise.toml
config file in the local directory. Anytime you're in that directory, that version of node will be
used.

`mise use -g node@20` will do the same but update the global config (~/.config/mise/config.toml) so
unless there is a config file in the local directory hierarchy, node-20 will be the default version
for
the user.

### [`mise install`](/cli/install)

`mise install` will install but not activate tools—meaning it will download/build/compile the tool
into `~/.local/share/mise/installs` but you won't be able to use it without "setting" the version
in a `.tool-versions` or `.mise-toml` file.

::: tip
If you're coming from asdf, there is no need to also run `mise plugin add` to first install
the plugin, that will be done automatically if needed. Of course, you can manually install plugins
if you wish or you want to use a plugin not in the default registry.
:::

There are many ways it can be used:

- `mise install node@20.0.0` - install a specific version
- `mise install node@20` - install the latest version matching this prefix
- `mise install node` - install whatever version of node currently specified in
  .tool-versions/.mise.toml
- `mise install` - install all plugins and tools

### `mise local|global` <Badge type="danger" text="not recommended" />

`mise local` and `mise global` are command which only modify the `.tool-versions` or `.mise.toml`
files.
These are hidden from the CLI help and remain for asdf-compatibility. The recommended approach is
to use `mise use` instead because that will do the same thing but also install the tool if it does
not already exists.

### [`mise exec`|`mise x`](/cli/exec)

`mise x` can be used for one-off commands using specific tools. e.g.: if you want to run a script
with python3.12:

```sh
mise x python@3.12 -- ./myscript.py
```

Python will be installed if it is not already. `mise x` will read local/global `.tool-versions`/
`.mise-toml` files
as well, so if you don't want to use `mise activate` or shims you can use mise by just prefixing
commands with
`mise x --`:

```sh
$ mise use node@20
$ mise x -- node -v
20.x.x
```

::: tip
If you use this a lot, an alias can be helpful:

```sh
alias mx="mise x --"
```

:::

Similarly, `mise run` can be used to [execute tasks](/tasks/) which will also activate the mise
environment with all of your tools.

## Tool Options

mise plugins may accept configuration in the form of tool options specified in `mise.toml`:

```toml
[tools]
# send arbitrary options to the plugin, passed as:
# MISE_TOOL_OPTS__FOO=bar
mytool = { version = '3.10', foo = 'bar' }
```

All tools can accept a `postinstall` option which is a shell command to run after the tool is installed:

```toml
[tools]
node = { version = '20', postinstall = 'corepack enable' }
```

Unfortunately at the time of this writing, it's not possible to specify this via the CLI in
`mise use` or other commands though. See <https://github.com/jdx/mise/issues/2309>

# comparison-to-asdf.md

# Comparison to asdf

mise can be used as a drop-in replacement for asdf. It supports the same `.tool-versions` files that
you may have used with asdf and uses asdf plugins. It will not, however, reuse existing asdf directories
(so you'll need to either reinstall them or move them), and 100% compatibility is not a design goal.

Casual users coming from asdf have generally found mise to just be a faster, easier to use asdf.

:::tip
Make sure you have a look at [environments](/environments.html) and [tasks](/tasks/) which
are major portions of mise that have no asdf equivalent.
:::

## Migrate from asdf to mise

If you're moving from asdf to mise, please review [#how-do-i-migrate-from-asdf](/faq.html#how-do-i-migrate-from-asdf) for guidance.

## UX

![CleanShot 2024-01-28 at 12 36 20@2x](https://github.com/jdx/mise-docs/assets/216188/47f381d7-1566-4b78-9260-3b85a21dd6ec)

Some commands are the same in asdf but others have been changed. Everything that's possible
in asdf should be possible in mise but may use slightly different syntax. mise has more forgiving commands,
such as using fuzzy-matching, e.g.: `mise install node@20`. While in asdf you _can_ run
`asdf install node latest:20`, you can't use `latest:20` in a `.tool-versions` file or many other places.
In `mise` you can use fuzzy-matching everywhere.

asdf requires several steps to install a new runtime if the plugin isn't installed, e.g.:

```sh
asdf plugin add node
asdf install node latest:20
asdf local node latest:20
```

In `mise` this can all be done in a single step which installs the plugin, installs the runtime,
and sets the version:

```sh
mise use node@20
```

If you have an existing `.tool-versions` file, or `.mise-toml`, you can install all plugins
and runtimes with a single command:

```sh
mise install
```

I've found asdf to be particularly rigid and difficult to learn. It also made strange decisions like
having `asdf list all` but `asdf latest --all` (why is one a flag and one a positional argument?).
`mise` makes heavy use of aliases so you don't need to remember if it's `mise plugin add node` or
`mise plugin install node`. If I can guess what you meant, then I'll try to get mise to respond
in the right way.

That said, there are a lot of great things about asdf. It's the best multi-runtime manager out there
and I've really been impressed with the plugin system. Most of the design decisions the authors made
were very good. I really just have 2 complaints: the shims and the fact it's written in Bash.

## Performance

asdf made (what I consider) a poor design decision to use shims that go between a call to a runtime
and the runtime itself. e.g.: when you call `node` it will call an asdf shim file `~/.asdf/shims/node`,
which then calls `asdf exec`, which then calls the correct version of node.

These shims have terrible performance, adding ~120ms to every runtime call. `mise activate` does not use shims and instead
updates `PATH` so that it doesn't have any overhead when simply calling binaries. These shims are the main reason that I wrote this. Note that in the demo GIF at the top of this README
that `mise` isn't actually used when calling `node -v` for this reason. The performance is
identical to running node without using mise.

I don't think it's possible for asdf to fix these issues. The author of asdf did a great writeup
of [performance problems](https://stratus3d.com/blog/2022/08/11/asdf-performance/). asdf is written
in bash which certainly makes it challenging to be performant, however I think the real problem is the
shim design. I don't think it's possible to fix that without a complete rewrite.

mise does call an internal command `mise hook-env` every time the directory has changed, but because
it's written in Rust, this is very quick—taking ~10ms on my machine. 4ms if there are no changes, 14ms if it's
a full reload.

tl;dr: asdf adds overhead (~120ms) when calling a runtime, mise adds a small amount of overhead (~5ms)
when the prompt loads.

## Command Compatibility

In nearly all places you can use the exact syntax that works in asdf, however this likely won't
show up in the help or CLI reference. If you're coming from asdf and comfortable with that way of
working you can almost always use the same syntax with mise, e.g.:

```sh
mise install node 20.0.0
mise local node 20.0.0
```

It's not recommended though. You almost always want to modify config files and install things so
`mise use node@20` saves an extra command. Also, the "@" in the command is preferred since it allows
you to install multiple tools at once: `mise use|install node@20 node@18`. Also, there are edge cases
where it's not possible—or at least very challenging—for us to definitively know which syntax is being
used and so we default to mise-style. While there aren't many of these, asdf-compatibility is done
as a "best-effort" in order to make transitioning from asdf feel familiar for those users who can
rely on their muscle memory. Ensuring asdf-syntax works with everything is not a design goal.

## Extra backends <Badge type="warning" text="experimental" />

mise has support for backends other than asdf plugins. For example you can install CLIs
directly from cargo and npm:

```sh
mise use -g cargo:ripgrep@14
mise use -g npm:prettier@3
```

# directories.md

# Directory Structure

The following are the directories that mise uses.

::: tip
If you often find yourself using these directories (as I do), I suggest setting all of them to `~/.mise` for easy access.
:::

## `~/.config/mise`

- Override: `$MISE_CONFIG_DIR`
- Default: `${XDG_CONFIG_HOME:-$HOME/.config}/mise`

This directory stores the global configuration file `~/.config/mise/config.toml`. This is intended to go into your
dotfiles repo to share across machines.

## `~/.cache/mise`

- Override: `$MISE_CACHE_DIR`
- Default: `${XDG_CACHE_HOME:-$HOME/.cache}/mise`, _macOS: `~/Library/Caches/mise`._

Stores internal cache that mise uses for things like the list of all available versions of a
plugin. Do not share this across machines. You may delete this directory any time mise isn't actively installing something.
Do this with `mise cache clear`.
See [Cache Behavior](/cache-behavior) for more information.

## `~/.local/state/mise`

- Override: `$MISE_STATE_DIR`
- Default: `${XDG_STATE_HOME:-$HOME/.local/state}/mise`

Used for storing state local to the machine such as which config files are trusted. These should not be shared across
machines.

## `~/.local/share/mise`

- Override: `$MISE_DATA_DIR`
- Default: `${XDG_DATA_HOME:-$HOME/.local/share}/mise`

This is the main directory that mise uses and is where plugins and tools are installed into.
It is nearly identical to `~/.asdf` in asdf, so much so that you may be able to get by
symlinking these together and using asdf and mise simultaneously. (Supporting this isn't a
project goal, however).

This directory _could_ be shared across machines but only if they run the same OS/arch. In general I wouldn't advise
doing so.

### `~/.local/share/mise/downloads`

This is where plugins may optionally cache downloaded assets such as tarballs. Use the
`always_keep_downloads` setting to prevent mise from removing files from here.

### `~/.local/share/mise/plugins`

mise installs plugins to this directory when running `mise plugins install`. If you are working on a
plugin, I suggest
symlinking it manually by running:

```sh
ln -s ~/src/mise-my-tool ~/.local/share/mise/plugins/my-tool
```

### `~/.local/share/mise/installs`

This is where tools are installed to when running `mise install`. For example, `mise install
node@20.0.0` will install to `~/.local/share/mise/installs/node/20.0.0`

This will also create other symlinks to this directory for version prefixes ("20" and "20.15")
and matching aliases ("lts", "latest").
For example:

```sh
$ tree ~/.local/share/mise/installs/node
20 -> ./20.15.0
20.15 -> ./20.15.0
lts -> ./20.15.0
latest -> ./20.15.0
```

### `~/.local/share/mise/shims`

This is where mise places shims. Generally these are used for IDE integration or if `mise activate`
does not work for some reason.
