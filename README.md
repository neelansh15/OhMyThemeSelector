<div align="center">

# omts — Oh My Theme Selector

[![Release](https://img.shields.io/github/v/release/neelansh15/OhMyThemeSelector?color=c2410c)](https://github.com/neelansh15/OhMyThemeSelector/releases)
[![License: MIT](https://img.shields.io/github/license/neelansh15/OhMyThemeSelector)](LICENSE)
[![Stars](https://img.shields.io/github/stars/neelansh15/OhMyThemeSelector?style=flat)](https://github.com/neelansh15/OhMyThemeSelector/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/neelansh15/OhMyThemeSelector)](https://github.com/neelansh15/OhMyThemeSelector/commits/main)
[![Oh My Zsh](https://img.shields.io/badge/Oh%20My%20Zsh-plugin-blue)](https://ohmyz.sh)
[![Website](https://img.shields.io/badge/website-live-brightgreen)](https://neelansh15.github.io/OhMyThemeSelector/)

</div>

An interactive theme picker for [Oh My Zsh](https://ohmyz.sh). Browse every installed theme, **see each one applied to your real prompt as you move through the list**, and save your pick to `~/.zshrc` — with no shell reload.

No more opening `.zshrc` in vim, or checking the GitHub wiki for theme names.

## How it works without a reload

`omts` is a zsh function that runs inside your current shell, not a separate program. A separate program could never change your running shell's prompt. Moving the selection runs `omz theme use <name>` in your shell, and the preview is your real prompt (git status included). Enter writes `ZSH_THEME` to your `.zshrc`. Esc restores the theme you started with.

## Install

```sh
git clone https://github.com/neelansh15/OhMyThemeSelector ~/.oh-my-zsh/custom/plugins/omts
```

Then add `omts` to the plugin list in `~/.zshrc`:

```sh
plugins=(git omts)
```

Or skip the plugin system and source the file after Oh My Zsh loads:

```sh
source /path/to/omts.plugin.zsh   # after: source $ZSH/oh-my-zsh.sh
```

Open a new shell once. After that, themes never need a reload.

## Usage

| Command | |
|---|---|
| `omts` | open the selector |
| `omts list` | list themes, marking the active one |
| `omts current` | print the active theme |
| `omts set <theme>` | apply now and save to `.zshrc` |
| `omts update` | switch to the latest [release](../../releases) and reload it in this shell |
| `omts help` | help |

In the selector:

| Key | Action |
|---|---|
| `↑` / `↓`, `Ctrl-N` / `Ctrl-P` | move (wraps around), loading the theme live |
| `PgUp` / `PgDn`, `Home` / `End` | jump |
| *type* | filter by name (`Backspace` / `Ctrl-U` to edit) |
| `Enter` | keep the theme and save it to `.zshrc` |
| `Esc` / `Ctrl-C` | cancel and restore the previous theme |

A `●` marks the theme currently saved in `.zshrc`. Custom themes in `$ZSH_CUSTOM` are included.

## What it writes

Only the `ZSH_THEME="..."` line of `~/.zshrc` (or `$ZDOTDIR/.zshrc`). If the line is missing, it is added before `source $ZSH/oh-my-zsh.sh`. Symlinked dotfiles are followed. A backup is saved as `.zshrc.omts.bak` next to it, and nothing is written if the edited file fails `zsh -n`.

## Caveats

- Previews load theme files into your running shell. omts clears `ZSH_THEME_*`, `RPROMPT` and the `precmd`/`preexec`/`chpwd` hook lists between previews and restores them on cancel. A theme that changes other global state, such as shell options or aliases, may leave traces until the next shell.
- Themes that need special fonts (agnoster, powerlevel-style glyphs) render as well as your terminal font allows.
- Requires zsh 5+ and Oh My Zsh. Terminals without alternate-screen support are not handled.

## License

MIT
