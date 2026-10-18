#!/usr/bin/env bash
# Feed each case in cases.tsv to the guard as a hook payload and compare the decision.
#
# usage: run-cases.sh [guard] [cases]
#
# **The cases are judged inside a repository this script makes**, under $TMPDIR and thrown away after. Half of
# what the guard refuses is a write into source, and which paths those are is a question only a real working
# tree answers — `git check-ignore` is what tells `target/` from `src/`. Pointing the suite at whichever
# repository happened to be open would make the result depend on that tree's contents and on it existing at
# all; a fixture of two files and a .gitignore says the same thing and says it the same way on any machine.
#
# The fixture also has an uncommitted change on purpose: the destructive-git cases are about a tree with work
# in no commit, so a clean fixture would let `git reset --hard` through and call it correct.
set -uo pipefail

G=${1:-$(dirname "$0")/../guard-unrecoverable.sh}
CASES=${2:-$(dirname "$0")/cases.tsv}

# A guard that cannot run says nothing, and saying nothing is how it allows: every deny case would come back
# ALLOW and only the count would show it. That happened twice — an awk escape this machine's awk rejects, and
# the file left without its execute bit — so anything the guard writes on stderr, and any exit status but 0,
# fails the case it happened on rather than being read as consent.
[ -x "$G" ] || {
  printf 'the guard is not executable: %s\n' "$G"
  exit 1
}

fixture=$(mktemp -d "${TMPDIR:-/tmp}/guard-cases.XXXXXX") || exit 1
mkdir -p "$fixture/src" "$fixture/target" "$fixture/scripts"
# `/scripts` is ignored and hand-written, a shape real repositories have: an ignored file is in
# no commit and in no jj snapshot, so it is the one a guard reading the ignore list would let a program write.
printf '/target\n/scripts\n*.log\n' >"$fixture/.gitignore"
printf 'fn main() {}\n' >"$fixture/src/lib.rs"
printf '#!/usr/bin/env bash\n' >"$fixture/scripts/deploy.sh"
printf '# spec\n' >"$fixture/SPEC.md"
(
  cd "$fixture" || exit 1
  git init -q . && git add -A && git -c user.email=cases -c user.name=cases commit -qm base
) >/dev/null 2>&1
# The work in no commit: one tracked file dirty, one file untracked.
printf 'fn main() { let _ = 1; }\n' >"$fixture/src/lib.rs"
printf 'notes\n' >"$fixture/NOTES.md"

fails=0
while IFS=$'\t' read -r want tool label value; do
  [ -n "${want:-}" ] || continue
  key=file_path
  [ "$tool" = Bash ] && key=command
  jq -n --arg t "$tool" --arg k "$key" --arg v "$value" --arg cwd "$fixture" \
    '{tool_name:$t, hook_event_name:"PreToolUse", session_id:"cases", cwd:$cwd, tool_input:{($k):$v}}' |
    "$G" >"$fixture/target/out.json" 2>"$fixture/target/err.txt"
  status=$?
  got=$(jq -r '.hookSpecificOutput.permissionDecision // empty' <"$fixture/target/out.json" 2>/dev/null)
  # `ALLOW` is the guard saying nothing, which lets the call through. It is upper case so as not to be read as
  # Claude Code's own `allow`, a decision that skips the permission prompt and that the guard never returns.
  got=${got:-ALLOW}
  if [ "$status" != 0 ] || [ -s "$fixture/target/err.txt" ]; then
    printf 'BROKE exit=%-3s %s\n  %s\n' "$status" "$label" "$(head -c 200 <"$fixture/target/err.txt")"
    fails=$((fails + 1))
  elif [ "$got" = "$want" ]; then
    printf 'ok    %-8s %s\n' "$got" "$label"
  else
    printf 'FAIL  want=%-6s got=%-6s %s\n' "$want" "$got" "$label"
    fails=$((fails + 1))
  fi
done <"$CASES"

# The fixture is under $TMPDIR, which is a root anything may destroy — through `trash` where this machine has
# it, since that is the delete this session's rules leave standing.
if command -v trash >/dev/null 2>&1; then
  trash "$fixture" >/dev/null 2>&1
else
  chmod -R u+w "$fixture" 2>/dev/null
  command rm -rf -- "$fixture" 2>/dev/null
fi

printf '\n%d failing\n' "$fails"
[ "$fails" -eq 0 ]
