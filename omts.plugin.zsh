# omts - Oh My Theme Selector
#
# An interactive theme picker for Oh My Zsh. Because it is a function that runs
# inside your *current* shell (not a separate program), it can load each theme
# as you move through the list: the preview is your real prompt and, when you
# confirm, nothing needs reloading.
#
#   omts                 open the selector
#   omts list            list all themes
#   omts current         print the active theme
#   omts set <theme>     apply a theme now and save it to ~/.zshrc
#   omts update          switch to the latest release and reload it
#   omts help

typeset -g OMTS_VERSION=0.2.0
typeset -g _OMTS_DIR=${0:A:h}

# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------

_omts_check() {
  if [[ -z $ZSH || ! -d $ZSH/themes ]] || (( ! $+functions[omz] )); then
    print -u2 "omts: Oh My Zsh does not appear to be loaded in this shell."
    print -u2 "      Source this file from ~/.zshrc *after* 'source \$ZSH/oh-my-zsh.sh'"
    print -u2 "      (or enable it as a plugin: plugins=(... omts))."
    return 1
  fi
}

# Fills $reply with every theme name (custom ones included), sorted.
_omts_themes() {
  local -a custom builtin
  local cdir=${ZSH_CUSTOM:-$ZSH/custom}
  builtin=("$ZSH"/themes/*.zsh-theme(-.N:t:r))
  custom=("$cdir"/**/*.zsh-theme(-.N:r:gs:"$cdir"/themes/:::gs:"$cdir"/:::))
  reply=(${(iou)custom} ${(iou)builtin})
  reply=(${(iou)reply})
}

# Write ZSH_THEME="<name>" into .zshrc (follows symlinks, keeps a backup,
# refuses to write a file with syntax errors). Never reloads the shell.
_omts_persist() {
  local name=$1
  local zdot=${ZDOTDIR:-$HOME}
  local zshrc=${${:-$zdot/.zshrc}:A}
  local tmp=$zshrc.omts.new

  if [[ ! -f $zshrc || ! -w $zshrc ]]; then
    print -u2 "omts: cannot write to $zshrc"
    return 1
  fi

  command cp -p "$zshrc" "$tmp" || return 1

  if command grep -Eq '^[[:space:]]*ZSH_THEME=' "$zshrc"; then
    OMTS_T=$name command awk '
      !done && /^[ \t]*ZSH_THEME=/ { print "ZSH_THEME=\"" ENVIRON["OMTS_T"] "\""; done=1; next }
      { print }' "$zshrc" >| "$tmp"
  else
    OMTS_T=$name command awk '
      !done && /^[ \t]*(source|\.)[ \t].*oh-my-zsh\.sh/ { print "ZSH_THEME=\"" ENVIRON["OMTS_T"] "\""; done=1 }
      { print }
      END { if (!done) print "ZSH_THEME=\"" ENVIRON["OMTS_T"] "\"" }' "$zshrc" >| "$tmp"
  fi

  if (( $? != 0 )) || ! command zsh -n "$tmp" 2>/dev/null; then
    command rm -f "$tmp"
    print -u2 "omts: refusing to write $zshrc (the edited file did not parse)"
    return 1
  fi

  if command cmp -s "$zshrc" "$tmp"; then
    command rm -f "$tmp"
    print -P "%F{green}✓%f ${name} is already saved in ${zshrc/#$HOME/~}"
    return 0
  fi

  command cp -p "$zshrc" "$zshrc.omts.bak" && command mv -f "$tmp" "$zshrc" || return 1
  print -P "%F{green}✓%f Saved %B${name}%b to ${zshrc/#$HOME/~} (backup: ${zshrc:t}.omts.bak)"
}

# Switch the plugin checkout to the latest tagged release (vX.Y.Z), then
# reload it into this shell.
_omts_update() {
  local dir=$_OMTS_DIR oldrev old latest
  if ! command git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    print -u2 "omts: $dir is not a git checkout, so it can't self-update"
    return 1
  fi
  if ! command git -C "$dir" fetch --tags --force -q origin; then
    print -u2 "omts: could not reach the remote (no network?)"
    return 1
  fi
  latest=$(command git -C "$dir" tag --list 'v[0-9]*' --sort=-v:refname | head -n 1)
  if [[ -z $latest ]]; then
    print -u2 "omts: no releases found"
    return 1
  fi
  oldrev=$(command git -C "$dir" rev-parse HEAD)
  old=$(command git -C "$dir" describe --tags --always)
  if [[ $oldrev == $(command git -C "$dir" rev-parse "$latest^{commit}") ]]; then
    print -P "%F{green}✓%f omts is already on the latest release (%B$latest%b)"
    return 0
  fi
  if ! command git -C "$dir" checkout -q "$latest" 2>/dev/null; then
    print -u2 "omts: could not switch to $latest (local changes in $dir?)"
    return 1
  fi
  command git -C "$dir" log --format='  %h %s' "$oldrev..$latest"
  source "$dir/omts.plugin.zsh"
  print -P "%F{green}✓%f Updated %B$old%b → %B$latest%b and reloaded omts in this shell"
}

# --------------------------------------------------------------------------
# live selector
# --------------------------------------------------------------------------

# Remember everything a theme may touch, so Esc can put it all back.
# Uses $_snap (caller's local).
_omts_snapshot() {
  local n
  _snap=()
  for n in PROMPT PS2 PS3 PS4 RPROMPT SPROMPT ZSH_THEME RANDOM_THEME \
           precmd_functions preexec_functions chpwd_functions \
           ${(k)parameters[(I)ZSH_THEME_*]}; do
    (( $+parameters[$n] )) && _snap+=("$(typeset -p $n)")
  done
}

_omts_clear_theme_vars() {
  unset RPROMPT
  local -a stale
  stale=(${(k)parameters[(I)ZSH_THEME_*]})
  (( $#stale )) && unset $stale
}

_omts_restore() {
  _omts_clear_theme_vars
  unset RANDOM_THEME
  local l
  for l in "${_snap[@]}"; do
    eval "${l/#typeset /typeset -g }"
  done
}

# Load one theme into this shell, starting from a clean slate so the leftovers
# of the previously previewed theme don't leak into it.
_omts_apply() {
  _omts_clear_theme_vars
  precmd_functions=($base_precmd)
  preexec_functions=($base_preexec)
  chpwd_functions=($base_chpwd)
  omz theme use "$1" >/dev/null 2>&1
  applied=$1
  # themes built on vcs_info & co. fill in their data from a precmd hook
  local f
  for f in ${precmd_functions:|base_precmd}; do
    (( $+functions[$f] )) && $f >/dev/null 2>&1
  done
}

# Fills $plines with the rendered PROMPT (and RPROMPT) of the loaded theme.
_omts_render() {
  local out rp
  () {
    setopt localoptions promptsubst extendedglob
    out=${(%%)PROMPT}
    rp=${(%%)RPROMPT}
    # drop terminal-title (OSC) sequences some themes embed in the prompt
    out=${out//$'\e]'[^$'\a\e']#($'\a'|$'\e\\')/}
    rp=${rp//$'\e]'[^$'\a\e']#($'\a'|$'\e\\')/}
  } 2>/dev/null
  plines=("${(@f)out}")
  [[ -n $rp ]] && plines+=("${D}right:${Z} $rp")
  (( $#plines > 4 )) && plines=(${plines[-4,-1]})
}

_omts_draw() {
  local sz=$(command stty size 2>/dev/null </dev/tty)
  rows=${sz% *} cols=${sz#* }
  [[ $rows == <-> ]] || rows=24
  [[ $cols == <-> ]] || cols=80

  R=$(( rows - 9 ))
  (( R < 3 )) && R=3

  (( idx < top )) && top=$idx
  (( idx >= top + R )) && top=$(( idx - R + 1 ))
  (( top > $#visible - R + 1 )) && top=$(( $#visible - R + 1 ))
  (( top < 1 )) && top=1

  _omts_render

  local buf="${E}[H"
  buf+="${B} Oh My Theme Selector${Z}${D}  ·  moving the selection loads the theme live${Z}${E}[K"$'\n'
  buf+=" ${D}filter:${Z} ${filter}${D}▏${Z}  ${D}${$(( $#visible ? idx : 0 ))} of ${#visible}${Z}${E}[K"$'\n'

  # slim scrollbar beside the list, only when the list is longer than the window
  local -i total=$#visible thumb=0 tpos=0
  if (( total > R )); then
    thumb=$(( R * R / total )); (( thumb < 1 )) && thumb=1
    tpos=$(( (top - 1) * (R - thumb) / (total - R) ))
  fi

  local i name plain bar
  for (( i = top; i < top + R; i++ )); do
    bar=
    if (( total > R )); then
      (( i - top >= tpos && i - top < tpos + thumb )) && bar=" ${B}┃${Z}" || bar=" ${D}│${Z}"
    fi
    if (( i <= total )); then
      name=${visible[i]}
      plain="   ${name}"
      plain=${(r:W:)plain}
      if (( i == idx )); then
        if [[ $name == $orig ]]; then
          buf+="${RV}${plain[1]}${G}●${RV}${plain[3,-1]}${Z}${bar}${E}[K"$'\n'
        else
          buf+="${RV}${plain}${Z}${bar}${E}[K"$'\n'
        fi
      elif [[ $name == $orig ]]; then
        buf+="${plain[1]}${G}●${Z}${plain[3,-1]}${bar}${E}[K"$'\n'
      else
        buf+="${plain}${bar}${E}[K"$'\n'
      fi
    else
      buf+="${E}[K"$'\n'
    fi
  done

  (( $#visible )) || buf+="${D} no theme matches \"$filter\"${Z}${E}[K"$'\n'
  buf+="${D} ↑/↓ PgUp/PgDn move · type to filter · Enter keep & save · Esc cancel   ${G}●${Z}${D} = saved${Z}${E}[K"$'\n'
  buf+="${E}[K"$'\n'
  buf+="${B} Preview — ${applied}${Z}${E}[K"$'\n'
  local l
  for l in "${plines[@]}"; do
    buf+="${l}${Z}${E}[K"$'\n'
  done
  buf+="${E}[J"
  print -rn -- "$buf"
}

# Sets $key (and $ch for printable characters).
_omts_readkey() {
  local k k2 k3 rest
  key= ch=
  read -rsk 1 k || { key=eof; return 1 }
  case $k in
    $'\e')
      if read -rsk 1 -t 0.05 k2; then
        if [[ $k2 == '[' || $k2 == 'O' ]]; then
          read -rsk 1 -t 0.05 k3
          case $k3 in
            A) key=up ;;
            B) key=down ;;
            H) key=home ;;
            F) key=end ;;
            <->)
              read -rsk 1 -t 0.05 rest
              case $k3$rest in
                5~) key=pgup ;;
                6~) key=pgdn ;;
                1~|7~) key=home ;;
                4~|8~) key=end ;;
                *) key=other ;;
              esac ;;
            *) key=other ;;
          esac
        else
          key=other
        fi
      else
        key=esc
      fi ;;
    $'\n'|$'\r') key=enter ;;
    $'\x7f'|$'\b') key=bs ;;
    $'\x03') key=esc ;;
    $'\x0e') key=down ;;
    $'\x10') key=up ;;
    $'\x15') key=clear ;;
    [[:print:]]) key=char ch=$k ;;
    *) key=other ;;
  esac
  return 0
}

_omts_refilter() {
  local lf=${(L)filter} t
  visible=()
  for t in $themes; do
    [[ ${(L)t} == *"$lf"* ]] && visible+=($t)
  done
  idx=${visible[(Ie)$applied]}
  (( idx )) || idx=1
  top=1
}

_omts_tui() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    print -u2 "omts: an interactive terminal is required (try 'omts set <theme>')"
    return 1
  fi
  _omts_check || return 1

  local -a themes visible plines _snap
  _omts_themes
  themes=($reply)
  (( $#themes )) || { print -u2 "omts: no themes found in $ZSH/themes"; return 1 }
  visible=($themes)

  local -a base_precmd base_preexec base_chpwd
  base_precmd=($precmd_functions)
  base_preexec=($preexec_functions)
  base_chpwd=($chpwd_functions)

  local E=$'\e' B=$'\e[1m' D=$'\e[2m' RV=$'\e[7m' G=$'\e[32m' Z=$'\e[0m'
  local orig=$ZSH_THEME applied=$ZSH_THEME filter= key ch chosen=
  local rows cols R idx=1 top=1 i
  local -i W=0
  for i in $themes; do (( $#i > W )) && W=$#i; done
  W+=5
  i=${themes[(Ie)$orig]}
  (( i )) && idx=$i

  _omts_snapshot

  # alternate screen, hidden cursor, no line wrapping (long prompts get clipped)
  print -rn -- $'\e[?1049h\e[?25l\e[?7l'
  {
    while true; do
      _omts_draw
      _omts_readkey || break
      case $key in
        up)    (( $#visible )) && { (( idx > 1 )) && (( idx-- )) || idx=$#visible } ;;
        down)  (( $#visible )) && { (( idx < $#visible )) && (( idx++ )) || idx=1 } ;;
        pgup)  idx=$(( idx - R )); (( idx < 1 )) && idx=1 ;;
        pgdn)  idx=$(( idx + R )); (( idx > $#visible )) && idx=$#visible; (( idx < 1 )) && idx=1 ;;
        home)  idx=1 ;;
        end)   (( idx = $#visible > 0 ? $#visible : 1 )) ;;
        bs)    filter=${filter%?}; _omts_refilter ;;
        clear) filter=; _omts_refilter ;;
        char)  filter+=$ch; _omts_refilter ;;
        enter) (( $#visible )) && { chosen=${visible[idx]}; break } ;;
        esc)   break ;;
      esac
      if (( $#visible )) && [[ ${visible[idx]} != $applied ]]; then
        _omts_apply ${visible[idx]}
      fi
    done
  } always {
    print -rn -- $'\e[?7h\e[?25h\e[?1049l'
    [[ -n $chosen ]] || _omts_restore
  }

  if [[ -z $chosen ]]; then
    print -P "%F{yellow}✗%f cancelled — still using %B${ZSH_THEME}%b"
    return 0
  fi
  _omts_persist "$chosen"
}

# --------------------------------------------------------------------------
# entry point
# --------------------------------------------------------------------------

omts() {
  case ${1:-select} in
    select|"")
      _omts_tui ;;
    list|ls)
      _omts_check || return 1
      _omts_themes
      local t
      for t in $reply; do
        [[ $t == $ZSH_THEME ]] && print -P "%F{green}●%f $t" || print "  $t"
      done ;;
    current)
      print -r -- "$ZSH_THEME" ;;
    set)
      _omts_check || return 1
      if [[ -z $2 ]]; then
        print -u2 "usage: omts set <theme>"
        return 1
      fi
      _omts_themes
      if (( ! ${reply[(Ie)$2]} )); then
        print -u2 "omts: theme '$2' not found (see 'omts list')"
        return 1
      fi
      omz theme use "$2" && _omts_persist "$2" ;;
    update|upgrade)
      _omts_update ;;
    help|-h|--help)
      cat <<'EOF'
omts - Oh My Theme Selector

  omts                 open the interactive selector (themes load live)
  omts list            list all themes, marking the active one
  omts current         print the active theme
  omts set <theme>     apply a theme now and save it to ~/.zshrc
  omts update          switch to the latest release and reload it
  omts help            show this help
EOF
      ;;
    *)
      print -u2 "omts: unknown command '$1' (try 'omts help')"
      return 1 ;;
  esac
}

# tab completion
if (( $+functions[compdef] )); then
  _omts_complete() {
    local -a cmds=(select list current set update help)
    if (( CURRENT == 2 )); then
      _describe 'command' cmds
    elif [[ $words[2] == set ]]; then
      _omts_themes
      compadd -a reply
    fi
  }
  compdef _omts_complete omts
fi
