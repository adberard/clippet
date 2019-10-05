# 
# Clippet
#

clippetsFile=~${CLIPPET_FILE:~/.config/clisnippets}

# Snippets search
export FZF_SNIPPET_OPTS='--exact'
clippets-get() {
local selected num
setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
selected=($(highlight -O ansi -S sh $clippetsFile | tr "##" "##" |
  FZF_DEFAULT_OPTS="--ansi --height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS --preview-window=down:wrap --preview 'echo {} | sort | highlight -O ansi -S sh | tr \"##\" \"\n\" ' -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS  $FZF_SNIPPET_OPTS --query=${(qqq)LBUFFER} +m" $(__fzfcmd)))
  local ret=$?
  echo -n $selected
  selected=($(echo $selected | awk -F "##" '{print $1}'))
  # selected=($(cat $clippetsFile | awk 'NR==$selected{print;exit}'))
  echo -n $selected
  LBUFFER=$selected
  zle reset-prompt
  return $ret
}
zle     -N   clippets-get
bindkey '^O' clippets-get


clippets-add() {
local ret=$LBUFFER
# setopt localoptions noglobsubst noposixbuiltins pipefail 2> /dev/null
# echo "$ret" # >> $clippetsFile
cat <<< "$ret" >> $clippetsFile
echo
echo "Command added to cli snippets"

return cat <<< "$ret"
}
zle     -N   clippets-add
bindkey '^U' clippets-add

_fzf_marker_placeholder() {
  local strp pos placeholder
  strp=$(echo $BUFFER | grep -Z -P -b -o "\{\{[^\{\}]+\}\}")
  strp=$(echo "$strp" | head -1)
  pos=$(echo $strp | cut -d ":" -f1)
  placeholder=${strp#*:}
  if [[ -n "$1" ]]; then  
    BUFFER=$(echo -E $BUFFER | sed -e "s/{{//" -e "s/}}//")
    CURSOR=$(($pos + ${#placeholder} - 4))
  else
    placeholder=$(echo ${placeholder//\//\\/})
    BUFFER=$(echo -E $BUFFER | sed "s/$placeholder//")
    CURSOR=pos
  fi
}

clippets-next() {
  if echo "$BUFFER" | grep -q -P "{{"; then
    _fzf_marker_placeholder
  else
    local selected
    if selected=$(cat ${FZF_MARKER_CONF_DIR:-~/.config/clisnippets} | 
      sed -e "s/\(^[a-zA-Z0-9_-]\+\)\s/${FZF_MARKER_COMMAND_COLOR:-\x1b[38;5;255m}\1\x1b[0m /" \
          -e "s/\s*\(#\+\)\(.*\)/${FZF_MARKER_COMMENT_COLOR:-\x1b[38;5;8m}  \1\2\x1b[0m/" |
      fzf --bind 'tab:down,btab:up' --height=80% --ansi -q "$LBUFFER"); then
      LBUFFER=$(echo $selected | sed 's/\s*#.*//')
    fi
    zle redisplay
  fi
}
# match=$(echo "$BUFFER" | perl -nle 'print $& if m{\{\{.+?\}\}}' | head -n 1)
#   if [[ ! -z "$match" ]]; then
#     len=${#match}
#     match=$(echo "$match" | sed 's/"/\\"/g')
#     placeholder_offset=$(echo "$BUFFER" | python -c 'import sys;keyboard_input = raw_input if sys.version_info[0] == 2 else input; print(keyboard_input().index("'$match'"))')
#       CURSOR="$placeholder_offset"
#       BUFFER="${BUFFER[1,$placeholder_offset]}${BUFFER[$placeholder_offset+1+$len,-1]}"
#     fi

zle     -N   clippets-next
bindkey '^Y' clippets-next
