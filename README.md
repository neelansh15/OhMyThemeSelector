<div align="center">

# omts — Oh My Theme Selector

**Pick your Oh My Zsh theme by seeing it.**

[![Release](https://img.shields.io/github/v/release/neelansh15/OhMyThemeSelector?style=flat-square&color=c2410c&labelColor=2b2b2b)](https://github.com/neelansh15/OhMyThemeSelector/releases)
[![Oh My Zsh](https://img.shields.io/badge/Oh%20My%20Zsh-plugin-1f6feb?style=flat-square&labelColor=2b2b2b)](https://ohmyz.sh)
[![zsh](https://img.shields.io/badge/zsh-5%2B-2ea043?style=flat-square&labelColor=2b2b2b)](https://www.zsh.org)
[![License](https://img.shields.io/github/license/neelansh15/OhMyThemeSelector?style=flat-square&color=8957e5&labelColor=2b2b2b)](LICENSE)
[![Stars](https://img.shields.io/github/stars/neelansh15/OhMyThemeSelector?style=flat-square&color=d29922&labelColor=2b2b2b)](https://github.com/neelansh15/OhMyThemeSelector/stargazers)
[![Website](https://img.shields.io/badge/website-live-0ea5e9?style=flat-square&labelColor=2b2b2b)](https://neelansh15.github.io/OhMyThemeSelector/)

[Website](https://neelansh15.github.io/OhMyThemeSelector/) · [Install](#install) · [Usage](#usage) · [FAQ](#faq)

</div>

Changing your [Oh My Zsh](https://ohmyz.sh) theme normally means opening `~/.zshrc` in an editor, finding `ZSH_THEME`, typing a name you looked up on GitHub, and reloading your shell. Then doing it all again when you don't like it.

`omts` replaces that with one command. Run `omts`, arrow through your themes, and **your real prompt changes as you move**. Press Enter to keep one.

- **Live preview.** Every theme is applied to your actual prompt, git status included. No screenshots, no guessing.
- **No reload.** Nothing needs restarting, before or after.
- **Saves for you.** Enter writes the theme to `~/.zshrc`; Esc puts your old one back.
- **Searchable.** Start typing to filter the list. Your custom themes are included.

## Install

**Requirements:** [Oh My Zsh](https://ohmyz.sh), zsh 5 or newer, and `git`.

**1. Get the plugin**

```sh
git clone https://github.com/neelansh15/OhMyThemeSelector ~/.oh-my-zsh/custom/plugins/omts
```

**2. Enable it** by adding `omts` to the plugins list in `~/.zshrc`:

```sh
plugins=(git omts)
```

**3. Open a new terminal tab** (once), then run:

```sh
omts
```

**Prefer to let an AI do it?** Paste this into Claude, ChatGPT, or any coding agent (the [website](https://neelansh15.github.io/OhMyThemeSelector/) has a **Copy agent prompt** button for the same thing):

```text
Install omts (https://github.com/neelansh15/OhMyThemeSelector) for my Oh My Zsh: git clone it into "${ZSH_CUSTOM:-$ZSH/custom}/plugins/omts" (git pull if it exists), back up ~/.zshrc, add omts to the existing plugins=(...) list without removing anything (edit the target if it's a symlink), check it with zsh -n and restore the backup if it fails, do NOT reload my shell, then tell me to open a new tab and run omts.
```

<details>
<summary>Not using the plugins list?</summary>

Source the file yourself, after Oh My Zsh loads:

```sh
source /path/to/omts.plugin.zsh   # place after: source $ZSH/oh-my-zsh.sh
```

</details>

## Usage

Run `omts` to open the selector.

| Key | What it does |
|---|---|
| `↑` `↓` (or `Ctrl-N` `Ctrl-P`) | Move through themes. Each one loads live. |
| `PgUp` `PgDn` `Home` `End` | Jump around |
| *just type* | Filter by name (`Backspace` to edit, `Ctrl-U` to clear) |
| `Enter` | Keep this theme and save it to `~/.zshrc` |
| `Esc` or `Ctrl-C` | Cancel and go back to the theme you started with |

A `●` marks the theme that is currently saved. A scrollbar and a "37 of 144" counter show where you are in the list.

### Other commands

| Command | What it does |
|---|---|
| `omts list` | List all themes and mark the active one |
| `omts current` | Print the active theme |
| `omts set <theme>` | Apply a theme and save it, without the UI |
| `omts update` | Update to the latest release (see below) |
| `omts help` | Show help |

## Updating

```sh
omts update
```

This switches the plugin to the newest [release](https://github.com/neelansh15/OhMyThemeSelector/releases), shows what changed, and reloads omts in your current shell. You don't need a new tab.

## Uninstall

1. Remove `omts` from `plugins=(...)` in `~/.zshrc`.
2. Delete the plugin: `rm -rf ~/.oh-my-zsh/custom/plugins/omts`
3. Optionally delete `~/.zshrc.omts.bak`, the backup omts made when it last saved.

Your saved theme stays in `~/.zshrc`, so your prompt won't change.

## FAQ

**What does omts change on my system?**
Only the `ZSH_THEME="..."` line in `~/.zshrc` (or `$ZDOTDIR/.zshrc`), and only when you press Enter or run `omts set`. If that line doesn't exist, it is added just before `source $ZSH/oh-my-zsh.sh`. If your `.zshrc` is a symlink (for example from a dotfiles repo), the real file is edited.

**Is it safe?**
Before writing, omts copies your file to `.zshrc.omts.bak` next to it. It also checks the edited file with `zsh -n` and refuses to write one that doesn't parse. The backup holds only the version from just before your most recent save, so keep your own copy if you want to preserve an older one.

**`omts: command not found`**
The plugin isn't loaded yet. Check that `omts` is in `plugins=(...)` and open a new terminal tab.

**`Oh My Zsh does not appear to be loaded`**
If you source `omts.plugin.zsh` by hand, do it after the `source $ZSH/oh-my-zsh.sh` line in `~/.zshrc`.

**The preview looks wrong or shows odd symbols.**
Some themes (agnoster and similar) need a patched font such as a Nerd Font or Powerline font. They will look as good as your terminal font allows.

**A theme left something behind after I cancelled.**
Between previews, omts resets `ZSH_THEME_*` variables, `RPROMPT` and the `precmd`/`preexec`/`chpwd` hooks, and restores them when you cancel. A theme that changes other global state, such as shell options or aliases, may leave traces until you open a new shell.

**How can it change my theme without reloading the shell?**
A separate program can't touch the prompt of the shell that launched it. `omts` is instead a zsh function running inside your current shell. Moving the selection runs `omz theme use <name>` there, so the preview is your real prompt, and nothing has to be restarted.

## License

[MIT](LICENSE)
