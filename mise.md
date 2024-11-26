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
# `mise backends`

- **Usage**: `mise backends <SUBCOMMAND>`
- **Aliases**: `b`

Manage backends

## Subcommands

- [`mise backends ls`](/cli/backends/ls.md)
# `mise bin-paths`

- **Usage**: `mise bin-paths`

List all the active runtime bin paths
# `mise cache`

- **Usage**: `mise cache <SUBCOMMAND>`

Manage the mise cache

Run `mise cache` with no args to view the current cache directory.

## Subcommands

- [`mise cache clear [PLUGIN]...`](/cli/cache/clear.md)
- [`mise cache prune [--dry-run] [-v --verbose...] [PLUGIN]...`](/cli/cache/prune.md)
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
# `mise deactivate`

- **Usage**: `mise deactivate`

Disable mise for current shell session

This can be used to temporarily disable mise in a shell session.

Examples:

    mise deactivate
# `mise direnv`

- **Usage**: `mise direnv <SUBCOMMAND>`

Output direnv function to use mise inside direnv

See <https://mise.jdx.dev/direnv.html> for more information

Because this generates the legacy files based on currently installed plugins,
you should run this command after installing new plugins. Otherwise
direnv may not know to update environment variables when legacy file versions change.

## Subcommands

- [`mise direnv activate`](/cli/direnv/activate.md)
# `mise doctor`

- **Usage**: `mise doctor`
- **Aliases**: `dr`

Check mise installation for possible problems

Examples:

    $ mise doctor
    [WARN] plugin node is not installed
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
# `mise generate`

- **Usage**: `mise generate <SUBCOMMAND>`
- **Aliases**: `gen`

[experimental] Generate files for various tools/services

## Subcommands

- [`mise generate git-pre-commit [FLAGS]`](/cli/generate/git-pre-commit.md)
- [`mise generate github-action [FLAGS]`](/cli/generate/github-action.md)
- [`mise generate task-docs [FLAGS]`](/cli/generate/task-docs.md)
# `mise implode`

- **Usage**: `mise implode [--config] [-n --dry-run]`

Removes mise CLI and all related data

Skips config directory by default.

## Flags

### `--config`

Also remove config directory

### `-n --dry-run`

List directories that would be removed without actually removing them
# `mise`

**Usage**: `mise [FLAGS] <SUBCOMMAND>`

- **Usage**: `mise [FLAGS] <SUBCOMMAND>`

## Global Flags

### `-C --cd <DIR>`

Change directory before running command

### `-P --profile <PROFILE>`

Set the profile (environment)

### `-q --quiet`

Suppress non-error messages

### `-v --verbose...`

Show extra output (use -vv for even more)

### `-y --yes`

Answer yes to all confirmation prompts

## Subcommands

- [`mise activate [--shims] [-q --quiet] [SHELL_TYPE]`](/cli/activate.md)
- [`mise alias [-p --plugin <PLUGIN>] [--no-header] <SUBCOMMAND>`](/cli/alias.md)
- [`mise alias get <PLUGIN> <ALIAS>`](/cli/alias/get.md)
- [`mise alias ls [--no-header] [TOOL]`](/cli/alias/ls.md)
- [`mise alias set <ARGS>…`](/cli/alias/set.md)
- [`mise alias unset <PLUGIN> <ALIAS>`](/cli/alias/unset.md)
- [`mise backends <SUBCOMMAND>`](/cli/backends.md)
- [`mise backends ls`](/cli/backends/ls.md)
- [`mise bin-paths`](/cli/bin-paths.md)
- [`mise cache <SUBCOMMAND>`](/cli/cache.md)
- [`mise cache clear [PLUGIN]...`](/cli/cache/clear.md)
- [`mise cache prune [--dry-run] [-v --verbose...] [PLUGIN]...`](/cli/cache/prune.md)
- [`mise completion [SHELL]`](/cli/completion.md)
- [`mise config [--no-header] [-J --json] <SUBCOMMAND>`](/cli/config.md)
- [`mise config generate [-o --output <OUTPUT>]`](/cli/config/generate.md)
- [`mise config get [-f --file <FILE>] [KEY]`](/cli/config/get.md)
- [`mise config ls [--no-header] [-J --json]`](/cli/config/ls.md)
- [`mise config set [-f --file <FILE>] [-t --type <TYPE>] <KEY> <VALUE>`](/cli/config/set.md)
- [`mise deactivate`](/cli/deactivate.md)
- [`mise direnv <SUBCOMMAND>`](/cli/direnv.md)
- [`mise direnv activate`](/cli/direnv/activate.md)
- [`mise doctor`](/cli/doctor.md)
- [`mise env [FLAGS] [TOOL@VERSION]...`](/cli/env.md)
- [`mise exec [FLAGS] [TOOL@VERSION]... [COMMAND]...`](/cli/exec.md)
- [`mise generate <SUBCOMMAND>`](/cli/generate.md)
- [`mise generate git-pre-commit [FLAGS]`](/cli/generate/git-pre-commit.md)
- [`mise generate github-action [FLAGS]`](/cli/generate/github-action.md)
- [`mise generate task-docs [FLAGS]`](/cli/generate/task-docs.md)
- [`mise implode [--config] [-n --dry-run]`](/cli/implode.md)
- [`mise install [FLAGS] [TOOL@VERSION]...`](/cli/install.md)
- [`mise latest [-i --installed] <TOOL@VERSION>`](/cli/latest.md)
- [`mise link [-f --force] <TOOL@VERSION> <PATH>`](/cli/link.md)
- [`mise ls [FLAGS] [PLUGIN]...`](/cli/ls.md)
- [`mise ls-remote [--all] [TOOL@VERSION] [PREFIX]`](/cli/ls-remote.md)
- [`mise outdated [FLAGS] [TOOL@VERSION]...`](/cli/outdated.md)
- [`mise plugins [FLAGS] <SUBCOMMAND>`](/cli/plugins.md)
- [`mise plugins install [FLAGS] [NEW_PLUGIN] [GIT_URL]`](/cli/plugins/install.md)
- [`mise plugins link [-f --force] <NAME> [DIR]`](/cli/plugins/link.md)
- [`mise plugins ls [-u --urls]`](/cli/plugins/ls.md)
- [`mise plugins ls-remote [-u --urls] [--only-names]`](/cli/plugins/ls-remote.md)
- [`mise plugins uninstall [-p --purge] [-a --all] [PLUGIN]...`](/cli/plugins/uninstall.md)
- [`mise plugins update [-j --jobs <JOBS>] [PLUGIN]...`](/cli/plugins/update.md)
- [`mise prune [FLAGS] [PLUGIN]...`](/cli/prune.md)
- [`mise registry [-b --backend <BACKEND>] [--hide-aliased] [NAME]`](/cli/registry.md)
- [`mise reshim [-f --force]`](/cli/reshim.md)
- [`mise run [FLAGS]`](/cli/run.md)
- [`mise self-update [FLAGS] [VERSION]`](/cli/self-update.md)
- [`mise set [--file <FILE>] [-g --global] [ENV_VARS]...`](/cli/set.md)
- [`mise settings [--names] [-l --local] [KEY] [VALUE] <SUBCOMMAND>`](/cli/settings.md)
- [`mise settings add [-l --local] <KEY> <VALUE>`](/cli/settings/add.md)
- [`mise settings get [-l --local] <KEY>`](/cli/settings/get.md)
- [`mise settings ls [-l --local] [--names] [KEY]`](/cli/settings/ls.md)
- [`mise settings set [-l --local] <KEY> <VALUE>`](/cli/settings/set.md)
- [`mise settings unset [-l --local] <KEY>`](/cli/settings/unset.md)
- [`mise shell [FLAGS] [TOOL@VERSION]...`](/cli/shell.md)
- [`mise sync <SUBCOMMAND>`](/cli/sync.md)
- [`mise sync node [FLAGS]`](/cli/sync/node.md)
- [`mise sync python <--pyenv>`](/cli/sync/python.md)
- [`mise tasks [FLAGS] <SUBCOMMAND>`](/cli/tasks.md)
- [`mise tasks deps [--hidden] [--dot] [TASKS]...`](/cli/tasks/deps.md)
- [`mise tasks edit [-p --path] <TASK>`](/cli/tasks/edit.md)
- [`mise tasks info [-J --json] <TASK>`](/cli/tasks/info.md)
- [`mise tasks ls [FLAGS]`](/cli/tasks/ls.md)
- [`mise tasks run [FLAGS] [TASK] [ARGS]...`](/cli/tasks/run.md)
- [`mise tool [FLAGS] <BACKEND>`](/cli/tool.md)
- [`mise trust [FLAGS] [CONFIG_FILE]`](/cli/trust.md)
- [`mise uninstall [-a --all] [-n --dry-run] [INSTALLED_TOOL@VERSION]...`](/cli/uninstall.md)
- [`mise unset [-f --file <FILE>] [-g --global] [KEYS]...`](/cli/unset.md)
- [`mise upgrade [FLAGS] [TOOL@VERSION]...`](/cli/upgrade.md)
- [`mise use [FLAGS] [TOOL@VERSION]...`](/cli/use.md)
- [`mise version`](/cli/version.md)
- [`mise watch [-t --task... <TASK>] [-g --glob... <GLOB>] [ARGS]...`](/cli/watch.md)
- [`mise where <TOOL@VERSION>`](/cli/where.md)
- [`mise which [FLAGS] <BIN_NAME>`](/cli/which.md)
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
# `mise sync`

- **Usage**: `mise sync <SUBCOMMAND>`

Add tool versions from external tools to mise

## Subcommands

- [`mise sync node [FLAGS]`](/cli/sync/node.md)
- [`mise sync python <--pyenv>`](/cli/sync/python.md)
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
# `mise usage`

Generate a usage CLI spec

See <https://usage.jdx.dev> for more information
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
