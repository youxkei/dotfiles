#!/usr/bin/env bash
# PreToolUse/PostToolUse guard: nothing an agent does leaves work that cannot be got back.
#
# **One guard rather than two, because there was only ever one subject.** This began as
# `guard-outside-repo.sh`, whose name said *where* it looked — and then it refused `rm` everywhere,
# working tree included, because *which paths are safe to delete* was the judgement that had failed. A
# second guard grew beside it for scripted edits of source and for destructive git, and its name said
# *what* it looked at while it too refused things anywhere. Two names, neither true of its own contents.
# What both were about is the same property, and it is this file's name: a write or a delete whose old
# content nothing can produce again.
#
# What it refuses, and what each one is for:
#
# **`rm` and its aliases, everywhere.** `trash` does the same job and leaves the mistake in the trash, to be
# restored from there. Not because deleting inside the working tree is the hazard — it rarely is — but
# because a delete that cannot be undone should not rest on getting a path judgement right every time.
# `rmdir`, `unlink`, `shred` and the cmd/PowerShell spellings are the same command wearing another name.
#
# **A destructive verb or a redirection whose target is outside the roots a session may destroy in.** Those
# roots are the working tree, `/tmp` and the scratchpad. Outside them the files are the user's and none of it
# is reproducible from the repo — a deployed binary, a live config, a log holding a capture that cost them
# half an hour. A destructive verb (`mv`, `shred`, `truncate`, `dd of=`, `find -delete`) is denied when ANY
# path in the same command lies outside, including paths it does not target: an `rm -f` on a log, folded into
# a build-deploy-test one-liner, is how the first of these rules came to be written. A redirection is judged
# by its target alone, so reading an outside file into a repo file stays fine, and so does copying a built
# binary out to a deploy directory — which is the one write out there that has to work.
#
# **A program editing source.** Source is edited with Edit and Write. An Edit is recorded as the exact text
# before and the exact text after, so hours of uncommitted work can be replayed from the transcript when
# something destroys the file; a script is recorded as a *program*, whose effect depends on what the file held
# when it ran, and replaying it proves nothing. That is the whole reason: recoverability, not tidiness. The
# rule was written down, restated in a project's CLAUDE.md and said out loud twice in one session, and the
# `python3 - <<PY … replace(…)` kept coming back — so it is refused here instead.
#
# Whether an arbitrary program writes a file is undecidable, so this does not try: it refuses the *shapes*,
# each of which is syntax — `sed -i`, `perl -i`, `ed`, `patch`, `git apply`, a redirection or `tee` over
# source, `cp`/`mv` over source, and an interpreter whose own text holds `open(…,'w')`, `write_text`,
# `writelines`, `fileinput`, `os.replace`. Free to write with any tool: `/tmp`, the scratchpad, and whatever
# a repository's own ignore list calls disposable, which is where `target/` and every log in it come from.
#
# **Destructive git on work that is in no commit.** `git checkout -- <path>`, `git restore`, `git stash`,
# `git reset --hard` and `git clean` discard what no commit holds, and no `trash` stands behind them: a file
# holding ~3400 uncommitted lines was lost to exactly this, reverting a two-line change that an Edit would
# have put back. Refused while the tree they would discard from is dirty.
#
# **Posting to GitHub, which no delete unsends.** `gh issue create`, `gh pr create` and the comment verbs
# publish under the user's own account, and the watchers are notified the moment the call returns — so deleting
# the issue afterwards takes back the page and nothing else. It is the same property as the rest of this file,
# an effect nothing can produce away again, and it is here because it happened: an issue and its comments went
# up on the user's repository on this agent's own judgement, and the first they knew of it was asking why.
# Reading is untouched, and so is acting on what already exists — closing an issue is what an instruction to
# close one asks for.
#
# **And the half that needs no intent at all.** Before every Bash call this writes down the sha1 of every
# file the repository cannot get back on its own — dirty against HEAD, or untracked and not ignored — and
# copies each under its own state directory. After the call it compares. So a program that slips through the
# shapes above is named the moment it happens, with the old content still on disk to put back. Detecting the
# *effect* is decidable where detecting the intent is not.
#
# **It never asks, only allows or denies.** A prompt hands the judgement back to the user on every
# occurrence, which is the wrong trade when the recoverable route (`trash`, `Edit`) is right there. Nor does
# it guard Write / Edit themselves — those show their diff as they happen and leave the old content in the
# transcript, so an unwanted change there is visible and reversible without a hook in the way.
#
# Exits 0 always; a decision travels in the JSON on stdout. A guard that failed closed on its own bug would
# block every Bash call in every session on this machine. Its tests: guard-unrecoverable-tests/run-cases.sh.
set -uo pipefail

# Git Bash on Windows spells one directory three ways — `C:\x` as Claude Code and Windows programs write it,
# `C:/x` as git prints it, `/c/x` as the shell does — and every path here is compared as a string, so each one
# is brought to the shell's spelling before it is compared. Elsewhere a drive letter is WSL's mount of it.
case $(uname -s) in
MINGW* | MSYS* | CYGWIN*) msys=yes ;;
*) msys= ;;
esac
unix_path() {
  if [ -n "$msys" ] && [ -n "$1" ]; then
    cygpath -u -- "$1" 2>/dev/null || printf '%s' "$1"
  else
    printf '%s' "$1"
  fi
}
tmpdir=$(unix_path "${TMPDIR:-}")
config_dir=$(unix_path "${CLAUDE_CONFIG_DIR:-$HOME/.claude}")

payload=$(cat 2>/dev/null) || exit 0
tool=$(jq -r '.tool_name // empty' <<<"$payload" 2>/dev/null) || exit 0
event=$(jq -r '.hook_event_name // "PreToolUse"' <<<"$payload" 2>/dev/null)

cwd=$(unix_path "$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null)")
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=$PWD
repo=$(unix_path "$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)")
if [ -n "$repo" ]; then
  in_repo=yes
else
  # Somewhere with no history at all. `$repo` still names the root of what may be destroyed, but nothing
  # here may consult git about a path, and a directory that is not a checkout holds no uncommitted work.
  repo=$cwd
  in_repo=
fi

session=$(jq -r '.session_id // "none"' <<<"$payload" 2>/dev/null)
STATE=$config_dir/hooks/state/$session
KEPT=$STATE/kept
LIST=$STATE/list.tsv

# Roots an agent may destroy in: the working tree and the throwaway directories.
ALLOWED=("$repo" /tmp /var/tmp /dev)
[ -n "$tmpdir" ] && ALLOWED+=("$tmpdir")

decide() { # decision, reason
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}

deny() { # what, path
  decide deny "Denied: $1 outside the repository — $2 is not under $repo.

Files out there are the user's and are not reproducible from this repo: a deployed binary, a live
config, a log holding a session they cannot re-run. Delete and overwrite only inside the working
tree, /tmp, or the scratchpad. Copying a build artifact out to a deploy directory is fine and is
not what this stopped. If something outside really has to go, \`trash\` it rather than \`rm\` it —
that is recoverable, and it asks first — or leave it to the user. And keep a destructive command
out of a build/deploy one-liner even when its own target is inside."
}

refuse() { # what the command does, the path it does it to
  decide deny "Denied: $1 — $2 is source, and source is edited with Edit and Write.

An Edit is recorded as the exact text before and the exact text after, so hours of uncommitted work can be
replayed from the transcript when something destroys the file. A script is recorded as a *program*, whose
effect depends on what the file held when it ran: replaying it proves nothing. That is not a style
preference — it is the one route back, and a session that took this shortcut 65 times could not use it.

Everything under target/, /tmp and the scratchpad is yours to write with any tool — and that is where a
generated file, a report or a log belongs. This stops only writes into files somebody would have to recover."
}

# Absolute, normalized form of a path token, with the Windows spellings in the shell's.
resolve() {
  local t=$1
  t=${t#[\"\']}
  t=${t%[\"\']}
  # Drop an operand or long-option prefix (`of=`, `--config=`) so what gets resolved is the path.
  # Without this an absolute path arrives looking relative and lands inside the repo by accident.
  case $t in
  *=*) case ${t%%=*} in */*) ;; *) t=${t#*=} ;; esac ;;
  esac
  case $t in
  '~') t=$HOME ;;
  '~/'*) t=$HOME/${t#\~/} ;;
  [A-Za-z]:[/\\]*) # D:\deploy\x, C:/tmp/x
    if [ -n "$msys" ]; then
      t=$(unix_path "$t")
    else
      local drive=${t:0:1}
      t=/mnt/$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]')/$(printf '%s' "${t:3}" | tr '\\' /)
    fi
    ;;
  '\\'*) t=$(printf '%s' "$t" | tr '\\' /) ;; # UNC, e.g. \\wsl$\...
  esac
  [ "${t:0:1}" = / ] || t=$cwd/$t
  realpath -m -- "$t" 2>/dev/null || printf '%s' "$t"
}

# The scratch directory the harness hands a background job — `$CLAUDE_JOB_DIR/tmp` — which it deletes with the
# job. A job is told to put its temporary files there rather than in `/tmp`, so a guard that refused a write
# into it would refuse the very thing that instruction asks for. Matched as a pattern rather than listed as a
# root because the job's id is in the middle of it, and only that `tmp` is disposable: the rest of a job's
# directory is the harness's own record of it.
scratch_of_a_job() {
  local jobs=$config_dir/jobs
  case $1 in "$jobs"/*/tmp | "$jobs"/*/tmp/*) return 0 ;; esac
  return 1
}

inside_allowed() {
  local p=$1 root
  scratch_of_a_job "$p" && return 0
  for root in "${ALLOWED[@]}"; do
    [ -n "$root" ] || continue
    case $p in "$root" | "$root"/*) return 0 ;; esac
  done
  return 1
}

looks_like_path() {
  case $1 in
  -*) return 1 ;;
  '~' | '~/'*) return 0 ;;
  */* | *\\*) return 0 ;;
  esac
  return 1
}

# The command with every `>`, `<`, `;`, `&` and `|` that stands inside quotes turned into a space, for the scans
# that read redirections and a command's stages rather than words. A `|` left in a quoted grep pattern split
# `grep -E 'a|install ok' NOTES.md` into a stage that installs over NOTES.md.
#
# **A `>` inside quotes is text, not a redirection**, and telling them apart is the difference between a guard
# and a nuisance: `jq -n --arg c "cargo tree > deps.txt"` names a redirect it does not make, and an awk
# program (`$1>$2?"a":"b"`) names one that was never a path. The old guard sidestepped this by only judging
# redirections that leave the working tree — a bare filename was skipped, being inside it by construction —
# but a redirection *into source* is bare by nature, so the quotes have to be dealt with instead of ducked.
#
# Only the operators go, and not the spans holding them: a target may be quoted itself, and blanking the
# whole span took `echo x > "$OUT/y.txt"` down to a redirection with nothing after it — the one shape that
# has to be refused for naming a path only the shell can resolve.
#
# A backslash outside single quotes takes the next character as it stands, as the shell does: `\"` inside a
# double-quoted argument does not close it, and outside one does not open one. Reading it as a quote closed
# `-m="… \"<subject>\" …"` early and refused a message that only named a redirection, and opened one at
# `echo \" > src/lib.rs`, blanking the redirection that line does make.
bare() {
  printf '%s' "$1" | awk '
    { out = ""; q = ""
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        if (q != "\047" && c == "\\") {
          n = substr($0, ++i, 1)
          out = out c ((n ~ /[<>;&|]/) ? " " : n)
          continue
        }
        if (q == "") { if (c == "\"" || c == "\047") q = c }
        else if (c == q) q = ""
        else if (c ~ /[<>;&|]/) c = " "
        out = out c
      }
      print out }'
}

# A token whose value this script cannot know, so neither can it know what the command deletes.
unexpanded() {
  case $1 in
  '$?' | '$!' | '$$' | '$#' | '$'[0-9]) return 1 ;;
  *'$'*) return 0 ;;
  esac
  return 1
}

# Where inside a tree a program may write, which is `target/` and the logs and nothing else.
#
# **Not what the repository ignores**, which is what this used to ask and is a different question:
# a repository may ignore `/scripts` while its `deploy.sh` and `release.sh` are hand-written and in no
# commit — and, being ignored, in no jj snapshot either, so the transcript is the only copy of them there has
# ever been. An ignore list says *what git leaves alone*, not *what nothing would have to recover*.
#
# **And not the output directories either**, which is the second half of the same mistake: `node_modules` is
# ignored and is minutes of network away, and what comes back is whatever the registry and the lockfile agree on
# today rather than what was there. `dist`, `.venv` and a cache are the same trade. So they are source here, and
# the tool that owns each of them — `npm`, `cargo clean` — is what empties it.
#
# `target/` and `*.log` stay because they are where this session is *told* to put things: a command's whole
# output in a file before it is filtered, a report, a scratch script. `.jj` is deliberately absent — the
# operation log is the recovery route itself.
disposable_in_a_tree() {
  case $1 in
  */target/*) return 0 ;;
  *.log | *.tmp) return 0 ;;
  esac
  return 1
}

# Source is everything but the throwaway roots, which is the shape the `rm` refusal above settled on: it
# does not ask which repository a path belongs to, because a script writing another repository's source, or
# a file under `~/.claude`, is the same shortcut with the same recovery problem. Free is what a session is
# meant to destroy and recreate — `/tmp`, the scratchpad, the job's own `tmp`, and what a build wrote.
#
# **A checkout is asked about before the roots are**, because inside one it is what a build wrote that is
# disposable and not where the checkout sits: a working tree under `/tmp` holds changes that only its own
# history could produce again, and this guard's tests run against exactly that — a fixture repository
# under $TMPDIR, whose `src/lib.rs` every source-edit case aims at.
is_source() {
  local p root
  p=$(resolve "$1")
  scratch_of_a_job "$p" && return 1
  if [ -n "$in_repo" ]; then
    case $p in
    "$repo"/.git/*) return 1 ;;
    "$repo"/*)
      disposable_in_a_tree "$p" && return 1
      return 0
      ;;
    esac
  fi
  for root in /tmp /var/tmp /dev "$tmpdir"; do
    [ -n "$root" ] || continue
    case $p in "$root" | "$root"/*) return 1 ;; esac
  done
  return 0
}

# The files a repository could not get back on its own: dirty against HEAD, or untracked and not ignored.
# A clean tracked file is in a commit, so nothing here has to hold a copy of it.
#
# **Asked of git even where the session's own version control is `jj`.** Two reasons, and neither is a preference:
# a hook may not change what it is watching, and every jj command snapshots the working copy — a snapshot per
# Bash call would bury the operation log the recovery route runs through. And this same guard runs in repositories
# that have no `.jj` at all. `git status --porcelain` mutates nothing and is there in both.
at_risk() {
  (
    cd "$repo" 2>/dev/null || exit 0
    git status --porcelain --untracked-files=all 2>/dev/null | while read -r _ path; do
      [ -n "${path:-}" ] || continue
      [ -f "$path" ] && printf '%s\n' "$path"
    done
  )
}

keep_them() { # the pre-image, for a call that turns out to have destroyed something
  mkdir -p "$KEPT" 2>/dev/null || exit 0
  : >"$LIST.new"
  while IFS= read -r path; do
    sum=$(cd "$repo" && sha1sum -- "$path" 2>/dev/null | cut -d' ' -f1)
    [ -n "$sum" ] || continue
    printf '%s\t%s\n' "$sum" "$path" >>"$LIST.new"
    [ -f "$KEPT/$sum" ] || cp -- "$repo/$path" "$KEPT/$sum" 2>/dev/null
  done < <(at_risk)
  mv -f "$LIST.new" "$LIST" 2>/dev/null
  exit 0
}

check_them() { # what a call turned out to change, said where the model will read it
  [ -f "$LIST" ] || exit 0
  gone=""
  while IFS=$'\t' read -r sum path; do
    [ -n "${path:-}" ] || continue
    now=$(cd "$repo" && sha1sum -- "$path" 2>/dev/null | cut -d' ' -f1)
    [ "$now" = "$sum" ] && continue
    gone="$gone
  $path — the content it had is kept at $KEPT/$sum"
  done <"$LIST"
  [ -n "$gone" ] || exit 0
  jq -n --arg c "That Bash call changed files this repository cannot get back on its own, and none of it
went through Edit or Write:$gone

If the change was wanted, nothing is wrong — carry on. If it was not, the pre-image above is the file as it
stood before the call, and the way to put it back is to read it and Edit the difference in. What made this
worth catching: \`git checkout\` on a file holding thousands of uncommitted lines threw them away, and
scripted edits are recorded as programs rather than as content, so the transcript could not replay them." \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
  exit 0
}

[ "$tool" = Bash ] || exit 0
[ "$event" = PostToolUse ] && check_them

cmd=$(jq -r '.tool_input.command // empty' <<<"$payload" 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

# `dd` is matched only with an `of=` operand: two letters bounded by punctuation also spell an awk
# array (`dd[d]++`), and a guard that reads that as the disk writer denies ordinary text processing.
DELETES='(^|[^A-Za-z0-9_.-])(rm|rmdir|unlink|shred|truncate|mv|mkfs[^[:space:]]*)([^A-Za-z0-9_.-]|$)|(^|[^A-Za-z0-9_.-])dd[[:space:]][^;&|]*of=|-delete([^A-Za-z0-9_.-]|$)|-exec[[:space:]]+rm'
DELETES_WIN='(^|[^A-Za-z0-9_.-])(del|erase|rd|remove-item|move-item|clear-content|set-content|add-content|out-file|new-item)([^A-Za-z0-9_.-]|$)'

if grep -Eq -- '(^|[^A-Za-z0-9_.-])(rm|rmdir|unlink|shred)([^A-Za-z0-9_.-]|$)' <<<"$cmd" ||
  grep -Eqi -- '(^|[^A-Za-z0-9_.-])(del|erase|rd|remove-item)([^A-Za-z0-9_.-]|$)' <<<"$cmd"; then
  decide deny "Denied: \`rm\` (and rmdir/unlink/shred/del/rd/Remove-Item) is not available in this
session at all — inside the repository as much as outside.

Use \`trash\` instead: same arguments, and the file goes to the trash, where it can be restored. For build output prefer the tool that owns it — \`cargo clean\`, \`git clean\`.
If a real \`rm\` is genuinely required, it is the user's to run."
fi

# `trash` is recoverable wherever it points, which is the whole reason it is the way to delete here: the
# trash still holds the file. Nothing to ask about, so nothing is asked — and the pre-image is still written
# down, or the PostToolUse after it would compare against an older call's and name an Edit made since.
if grep -Eq -- '(^|[^A-Za-z0-9_.-])(trash|trash-put|gio[[:space:]]+trash)([^A-Za-z0-9_.-]|$)' <<<"$cmd"; then
  keep_them
fi

if grep -Eq -- "$DELETES" <<<"$cmd" || grep -Eqi -- "$DELETES_WIN" <<<"$cmd"; then
  read -ra toks <<<"$(tr ';&|()<>\n\t' '        ' <<<"$cmd")"
  for tok in "${toks[@]}"; do
    # A path only the shell can expand cannot be checked here. Spell it out rather than guess.
    unexpanded "$tok" &&
      decide deny "This command moves or truncates something, and $tok is a path this guard cannot
resolve — only the shell knows what it expands to. Write the path out literally and run it again."
    looks_like_path "$tok" || continue
    p=$(resolve "$tok")
    inside_allowed "$p" || deny "a delete or move in a command that names a path" "$p"
  done
fi

# --- a program editing source ----------------------------------------------------------------------------
if grep -Eq -- '(^|[^A-Za-z0-9_.-])(sed[[:space:]]+(-[A-Za-z]*i|--in-place)|perl[[:space:]]+-[A-Za-z]*i|ed[[:space:]]+-s|ex[[:space:]]+-s|patch|dos2unix|unix2dos|sponge)([^A-Za-z0-9_.-]|$)' <<<"$cmd" ||
  grep -Eq -- '(^|[^A-Za-z0-9_.-])git[[:space:]]+apply([^A-Za-z0-9_.-]|$)' <<<"$cmd"; then
  while read -r tok; do
    is_source "$tok" && refuse "that is an in-place edit by a program" "$(resolve "$tok")"
  done < <(grep -oE '[^[:space:];&|<>"'\''=]+\.(rs|toml|md|sh|py|ya?ml|json|ps1|c|h|txt|lock)\b' <<<"$cmd")
fi

# The path and the write may be lines apart in a heredoc, so the two are looked for in the whole command
# rather than in one expression: an interpreter that both names source and writes *something* is one whose
# intent is not worth guessing at.
if grep -Eq -- '(^|[^A-Za-z0-9_.-])(python3?|ruby|node|perl|php)([^A-Za-z0-9_.-]|$)' <<<"$cmd" &&
  grep -Eq -- "open\([^)]*['\"]w|write_text|writelines|\.write\(|fileinput|shutil\.(copy|move)|os\.(replace|rename)" <<<"$cmd"; then
  while read -r tok; do
    is_source "$tok" && refuse "that is a script writing a file" "$(resolve "$tok")"
  done < <(grep -oE "[^[:space:];&|<>\"'=(]+\.(rs|toml|md|sh|py|ya?ml|json|ps1|c|h)\b" <<<"$cmd")
fi

# A redirection is judged by its target alone: reading an outside file into a repo file is fine, and a
# report or a log written under target/ or /tmp is what the "put the whole output in a file first" rule asks
# for. What is refused is a redirection landing on source.
while read -r target; do
  target=${target##*[\>[:space:]]}
  [ -n "$target" ] || continue
  case $target in [\&\(]* | [0-9]) continue ;; esac
  unexpanded "$target" &&
    decide deny "This command redirects output into $target, a path this guard cannot resolve —
only the shell knows what it expands to. Write the redirection target out literally and run it again."
  p=$(resolve "$target")
  is_source "$target" && refuse "that redirection writes over source" "$p"
  # Only a target naming a directory can leave the working tree — a bare filename is relative to the cwd,
  # which is inside it.
  looks_like_path "$target" || continue
  inside_allowed "$p" || deny "a redirection writing" "$p"
done < <(grep -oE '>>?[[:space:]]*["'\'']?[^[:space:];&|<>]+' <<<"$(bare "$cmd")")

# `cp`, `mv`, `install` and `tee` write where they are pointed: the last path for the first three, every path
# for `tee`. Only a destination that is source is refused — copying source *out* to target/ is how a recovery
# works.
#
# **Read as words rather than by extension.** What this matched before was a path ending in one of a dozen
# extensions, and `tee .venv/pyvenv.cfg` went through it: there is no list of every extension a file may have,
# and the one thing that is knowable here is which argument the command writes to.
#
# A stage at a time, because the destination is the last path of *that* stage: `cp a b | tee c` has two. And the
# command has to be the stage's own head — `cargo install --path .` names `.` as a last argument and installs
# nothing over it.
while IFS= read -r stage; do
  read -ra words <<<"$stage" || continue
  [ "${#words[@]}" -gt 0 ] || continue
  # A wrapper in front of the command is still that command's stage.
  while [ "${#words[@]}" -gt 1 ]; do
    case ${words[0]} in
    sudo | env | command | nohup | time | xargs) words=("${words[@]:1}") ;;
    *) break ;;
    esac
  done
  case ${words[0]##*/} in
  cp | mv | install | tee) ;;
  *) continue ;;
  esac
  writes_them_all=
  [ "${words[0]##*/}" = tee ] && writes_them_all=yes
  paths=()
  for word in "${words[@]:1}"; do
    case $word in -* | '') continue ;; esac
    paths+=("$word")
  done
  [ "${#paths[@]}" -gt 0 ] || continue
  [ -n "$writes_them_all" ] || paths=("${paths[*]: -1}")
  for target in "${paths[@]}"; do
    p=$(resolve "$target")
    # **Inside the tree only**, because the one write out there that has to work is this very command: a built
    # binary copied to the directory it is run from. What guards that side is the rule below — a `.log` out there
    # is a session nobody can re-run — and the redirection scan, which judges every target wherever it lands.
    case $p in "$repo"/*) ;; *) continue ;; esac
    is_source "$target" && refuse "that writes over source" "$p"
  done
done < <(tr ';&|' '\n' <<<"$(bare "$cmd")")

# Logs outside the repo are append-only evidence; `cp` over one erases a session.
if grep -Eqi -- '(^|[^A-Za-z0-9_.-])(cp|copy|copy-item|tee|install|sed[[:space:]]+-i)([^A-Za-z0-9_.-]|$)' <<<"$cmd"; then
  while read -r logtok; do
    p=$(resolve "$logtok")
    inside_allowed "$p" || deny "overwriting a log" "$p"
  done < <(grep -oE '[^[:space:];&|<>"'\'']*\.log\b' <<<"$cmd")
fi

# --- destructive git on work that is in no commit --------------------------------------------------------
#
# The subcommands that only report are left alone: `git stash list` and `git stash show` read the stash, and
# `git clean` given `-n` deletes nothing by definition. Denying those costs a session the only cheap way to
# see what a destructive command *would* take.
if { grep -Eq -- '(^|[^A-Za-z0-9_.-])git[[:space:]]+([^;&|]*[[:space:]])?(checkout|restore|stash|clean)([^A-Za-z0-9_.-]|$)' <<<"$cmd" ||
  grep -Eq -- '(^|[^A-Za-z0-9_.-])git[[:space:]]+([^;&|]*[[:space:]])?reset[^;&|]*--hard' <<<"$cmd"; } &&
  ! grep -Eq -- 'git[[:space:]]+([^;&|]*[[:space:]])?stash[[:space:]]+(list|show)([^A-Za-z0-9_.-]|$)' <<<"$cmd" &&
  ! grep -Eq -- 'git[[:space:]]+([^;&|]*[[:space:]])?clean[^;&|]*(^|[[:space:]])(-[A-Za-z]*n[A-Za-z]*|--dry-run)([[:space:]]|$)' <<<"$cmd"; then
  # Which tree it would discard from: the one `-C` names where it names one, since a clean tree here says
  # nothing about the one being reached into.
  elsewhere=$(grep -oE -- 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+' <<<"$cmd" | tail -1 | sed -E 's/.*-C[[:space:]]+//')
  if [ -n "$elsewhere" ]; then
    there=$(unix_path "$(cd "$(resolve "$elsewhere")" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)")
    [ -n "$there" ] && repo=$there
  fi
  if [ -n "$(at_risk)" ]; then
    decide deny "Denied: that git command discards work, and $repo has changes that are in no commit — so
what it would discard cannot be got back from anywhere.

\`git checkout -- <path>\`, \`git restore\`, \`git stash\`, \`git reset --hard\` and \`git clean\` belong to the
same family as \`rm\`, and no \`trash\` stands behind them: a file holding thousands of uncommitted lines was
lost to exactly this, reverting a two-line change that an Edit would have put back.

Version control here is \`jj\`, so there is nothing this command is needed for: \`jj diff\` shows what changed,
\`jj restore --from <rev> <paths>\` puts named paths back, and \`jj undo\` / \`jj op restore <id>\` walk the
operation log. A git command destroying a file between two jj commands is recoverable only as far as the last
snapshot, which is what makes this the wrong tool rather than a faster one — and a path the repository ignores
is in no snapshot at all.

To undo an edit of your own, Edit it back — the transcript holds what it was. To be rid of the whole tree's
changes, that is the user's call to make and theirs to run."
  fi
fi

# --- posting to GitHub, which no delete unsends -----------------------------------------------------------
#
# The verbs that put something *new* in front of other people: an issue, a pull request, a release, a gist, a
# comment, a review. `gh api` with a write method is the same thing through the back door, and a rule that let
# it through would be a rule about spelling.
#
# **Reading is untouched, and so is acting on what already exists.** `gh issue view`, `gh issue list`, `gh pr
# diff` and a GET through `gh api` say nothing to anybody; `gh issue close`, `edit`, `reopen` and `delete` act
# on a page that is already up, and refusing those would refuse the instruction that asks for one.
if grep -Eq -- '(^|[^A-Za-z0-9_.-])gh[[:space:]]+([^;&|]*[[:space:]])?(issue|pr|release|gist)[[:space:]]+(create|comment|review)([^A-Za-z0-9_.-]|$)' <<<"$cmd" ||
  { grep -Eq -- '(^|[^A-Za-z0-9_.-])gh[[:space:]]+([^;&|]*[[:space:]])?api([^A-Za-z0-9_.-]|$)' <<<"$cmd" &&
    { grep -Eq -- '(-X|--method)[[:space:]]*(POST|PATCH|PUT|DELETE)' <<<"$cmd" ||
      { grep -Eq -- '(^|[[:space:]])(-f|-F|--field|--raw-field)[[:space:]]' <<<"$cmd" &&
        ! grep -Eq -- '(-X|--method)[[:space:]]*GET' <<<"$cmd"; }; }; }; then
  decide deny "Denied: that publishes something new under the user's own account, and no delete unsends it.

An issue, a pull request, a release, a gist, a comment or a review notifies whoever is watching the moment
the call returns — the page can be taken down afterwards and the mail cannot. An issue and its comments
already went up on a repository this way, on nothing but this agent's own judgement.

So write what you would have posted into your reply instead, where the user reads it and decides, and hand
them the command if they want it up. Reading is not what this stopped: \`gh issue view\`, \`gh issue list\`,
\`gh pr diff\` and a GET through \`gh api\` are all still yours. So is acting on a page that already exists —
\`gh issue close\` is what an instruction to close an issue asks for."
fi

# Launching the installed copy of a binary this repo builds, rather than the build under target/, is how a
# trial run ends up writing into the operator's log and config beside that copy. It destroys nothing, so it
# is allowed — but the reminder goes into the model's context, where the choice is actually made, instead of
# into a prompt for the user.
while read -r exetok; do
  p=$(resolve "$exetok")
  inside_allowed "$p" && continue
  [ -n "$(find "$repo/target" -type f -name "$(basename "$p")" -print -quit 2>/dev/null)" ] &&
    jq -n --arg c "$p is the installed copy of a binary this repo also builds under target/. It
keeps its log, config and state beside itself, so a trial run started there writes into the
operator's files. Unless that copy is deliberately the subject, run the one under target/ with a
config of its own." '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}' &&
    keep_them
done < <(grep -oE '(^|[;&|(`]|\$\()[[:space:]]*["'\'']?[^[:space:];&|<>"'\'']*\.[Ee][Xx][Ee]|[A-Za-z]:[\\/][^[:space:];&|<>"'\'']*\.[Ee][Xx][Ee]' <<<"$cmd" | sed -E 's/^[^A-Za-z0-9_.~\/\\-]*[[:space:]]*//; s/^["'\'']//')

keep_them
