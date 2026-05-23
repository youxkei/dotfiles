# step_log prints the elapsed time since this file was sourced plus
# the delta since the previous call, prefixed with the script's
# basename. Useful for ad-hoc timing instrumentation in zsh scripts.
zmodload zsh/datetime
typeset -gF STEP_LOG_START=$EPOCHREALTIME
typeset -gF STEP_LOG_LAST=$EPOCHREALTIME
step_log() {
    local now=$EPOCHREALTIME
    printf "[%s t=%.3fs +%.3fs] %s\n" \
        "${${ZSH_ARGZERO:-$0}:t}" \
        $((now - STEP_LOG_START)) $((now - STEP_LOG_LAST)) "$1"
    STEP_LOG_LAST=$now
}
