# qs-activity.zsh — ActivSpot Live Activities shell hook.
#
# Source from ~/.zshrc. Any foreground command that runs longer than
# $QS_ACTIVITY_MIN_SEC (default 10 s) surfaces in the Dynamic Island as a
# live activity with a running timer; on finish it flashes green (exit 0)
# or red (non-zero) with the exit code and duration.
#
# How: preexec drops a marker file and forks a detached herald that waits
# out the threshold, then heartbeats JSON into /tmp/qs_live_activity while
# the marker exists. precmd removes the marker and publishes the end event.
# Only one foreground command runs per shell, so marker-per-pid is safe.

[[ -o interactive ]] || return 0
zmodload zsh/datetime 2>/dev/null || return 0
autoload -Uz add-zsh-hook

: ${QS_ACTIVITY_MIN_SEC:=10}

# Interactive / long-lived TUIs that should never become activities
typeset -ga _QSA_IGNORE
_QSA_IGNORE=(nvim vim vi nano micro helix hx ssh mosh et htop btop top less
             more man watch tmux zellij screen fzf lazygit gitui ranger yazi
             lf mc nnn journalctl tail claude python ipython bpython node
             irb ghci julia R gdb lldb weechat irssi mutt neomutt aerc cava
             pulsemixer alsamixer ncmpcpp mpv vlc)

typeset -g _qsa_id="" _qsa_start=0 _qsa_marker="" _qsa_min=0

_qsa_jesc() {
    local s="$1"
    s=${s//\\/\\\\}; s=${s//\"/\\\"}
    s=${s//$'\n'/ }; s=${s//$'\t'/ }
    print -rn -- "$s"
}

_qsa_preexec() {
    local cmd="$1"
    local first="${${(z)cmd}[1]:t}"
    [[ -n "$first" ]] || return
    # sudo/env/time wrappers: judge by the wrapped command
    if [[ "$first" == (sudo|env|time|nice|doas) ]]; then
        first="${${(z)cmd}[2]:t}"
    fi
    (( ${_QSA_IGNORE[(Ie)$first]} )) && return

    _qsa_start=$EPOCHSECONDS
    _qsa_id="sh-$$-${EPOCHREALTIME//./}"
    _qsa_marker="/tmp/qs_sh_act_$$"
    print -rn -- "1" > "$_qsa_marker"

    # Detached herald: silent unless the command outlives the threshold
    (
        local esc id=$_qsa_id start=$_qsa_start marker=$_qsa_marker
        esc=$(_qsa_jesc "$cmd")
        (( ${#esc} > 64 )) && esc="${esc[1,63]}…"
        sleep $QS_ACTIVITY_MIN_SEC
        while [[ -f "$marker" ]]; do
            printf '{"id":"%s","icon":"","title":"%s","subtitle":"running · %ds","progress":-1,"ttlMs":8000,"kind":"shell"}\n' \
                "$id" "$esc" $(( EPOCHSECONDS - start )) >> /tmp/qs_live_activity
            sleep 2
        done
    ) &!
}

_qsa_precmd() {
    local rc=$?
    [[ -n "$_qsa_marker" ]] || return 0
    rm -f "$_qsa_marker" 2>/dev/null
    local el=$(( EPOCHSECONDS - _qsa_start ))
    if (( el >= QS_ACTIVITY_MIN_SEC )); then
        if (( rc == 0 )); then
            printf '{"id":"%s","event":"end","status":"ok","subtitle":"done in %ds"}\n' \
                "$_qsa_id" "$el" >> /tmp/qs_live_activity
        else
            printf '{"id":"%s","event":"end","status":"fail","subtitle":"exit %d · after %ds"}\n' \
                "$_qsa_id" "$rc" "$el" >> /tmp/qs_live_activity
        fi
    fi
    _qsa_marker=""; _qsa_id=""
    return 0
}

add-zsh-hook preexec _qsa_preexec
add-zsh-hook precmd  _qsa_precmd
