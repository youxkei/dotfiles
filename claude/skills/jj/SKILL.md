---
name: jj
description: Version control with Jujutsu (jj) — how a repository is structured, how work is described and arranged, how history is recovered, and what this machine requires on top of the tool: no git command at all, publishing being the user's alone, and what a stopping point wants. Use whenever a repo has a .jj directory, whenever a jj command is run or asked about (jj st, jj desc, jj new, jj log, jj evolog, jj op log, bookmarks, jj config, colocated git), whenever a turn is about to end on a working-copy change, and whenever reporting the state of work in such a repo. Also use when a user asks how to accomplish something they know from another version control system — switching branches, amending, rebasing, stashing, recovering lost work.
---

# Version control with jj

## What this machine wants

Everything after this section is how jj works. This section is the part that does not follow from the
tool: which of its commands are used here, and which acts are the user's alone.

### git is not used

**No git command at all where a `.jj` exists** — not `git status`, not `git diff`, not `git log`. jj
answers each of those, and in a colocated repository answers them correctly where git does not. `gh`
for what is on GitHub is not a git command and stays. Where something really has no jj spelling, say
so and ask rather than reaching for git.

**`git commit` in a colocated repository records the wrong tree and reports success.** jj 0.44 leaves
the git index inconsistent: its entries hold the working copy while its cache-tree still records
`HEAD`'s tree, so `git status` reports dozens of unmodified committed files as staged `A`, and
`git write-tree` answers `HEAD^{tree}` however much is uncommitted. What such a commit records is
HEAD's tree and none of the work. jj also **runs no git hooks**, so a project's `pre-commit` gate
fires on nothing jj does: run that project's own checks yourself before calling anything verified.

**Why jj replaces git rather than sitting beside it: every jj command snapshots the working copy
first**, so work is recoverable without any step having been taken to save it — and that granularity
is *per jj command*, which is what makes an occasional `jj st` a restore point. A git command that
discards uncommitted work destroys whatever came after the last jj command, and nothing brings that
back.

**`jj restore` with no paths discards every working-copy change** — it is not "show me what changed",
which is `jj diff`. `jj abandon` throws the change away. Both come back through `jj undo`, and
neither is to be typed without meaning it.

### `jj st` and `jj desc -m` are free, and `jj commit` is not used here

There is no committing step. `@` is a commit and every jj command takes the working copy into it, so
nothing saves the work and nothing is pending: `jj st` takes it in and says what is in it, and
`jj desc -m` writes or rewrites the message on `@` in place. Neither needs asking, neither shows anything to anybody, and `jj undo` reverses each. Writing
a message is free and repeatable, so say what a piece of work is as it starts and rewrite the line
when the work turns out to be something else.

**`jj commit` is not part of this machine's workflow.** Besides describing `@` it opens the next
change, and that is the user's call rather than a side effect of writing a message — `jj desc -m`
where a message is due, and the `jj-new` skill for when another change is opened.

### Publishing is the user's

**NEVER `jj bookmark set` / `move` / `advance` / `track`, and NEVER `jj git push` or this machine's
alias for it, `jj push`, unless the user explicitly says to.** Moving a bookmark is the act that says
which change other people get, and the push is the act of handing it to them — and `jj push` here
hands over whatever bookmark is already sitting on `@`, so it needs no bookmark move of its own to
publish work in flight.

- plan approval that includes a push authorizes only that single push; it does not carry over to
  follow-up changes
- agreeing on an approach that involves a push is NOT a push instruction; push only when explicitly
  told to (e.g. "pushして"). The user pushes themselves by default.

**`experimental-advance-branches` is not used here and is not to be turned on.** What it adds is a
bookmark that moves without being asked, and moving one is the user's act. It is a per-repository
setting, so `jj config list experimental-advance-branches` is the question to ask of a repository
whose config is unknown: where it is on, `jj new` advances such a bookmark from `@-` onto the change
just left behind, and `jj undo` takes that back along with the operation.

The push spellings, for when one is asked for: `jj git push --remote origin -b main` (`-b` is
`--bookmark`; a brand-new bookmark goes up as `jj git push --named <name>=@`, and 0.44 has no
`--allow-new`). A remote bookmark has to be tracked before it can be pushed to.

**`jj push` is an alias of this machine's.** `jj/config.toml` in the dotfiles aliases it to
`jj util exec -- jj-push`, which runs `bin/jj-push` from that same repository (`util exec` is what
lets an alias reach a script at all: jj has no equivalent of git's external subcommands, so a
`jj-push` on `PATH` is not found by `jj push` on its own). The script reads the bookmark names at `@`
and **fails when `@` carries none**, where `jj git push -r @` only warns and exits 0; it pushes those
names and does nothing else.

**A push leaves `@` where it is**, because `immutable_heads()` in that same `jj/config.toml` is
`tags() | untracked_remote_bookmarks()` — jj's builtin set without its `present(trunk())` term. Under
the builtin, pushing a bookmark that `trunk()` resolves to — jj's name for the published main line —
makes the pushed commit immutable, and jj answers a working copy turning immutable by moving `@` onto
a fresh empty commit carrying no bookmark at all. Here the commit stays mutable, so `@` does not
move, the bookmark stays on it, and the change just published is the one still being worked in — an
amend of it is allowed, and the remote then needs a force push.

**So a bookmark can be sitting on `@`.** A bookmark stays attached to its change through
every rewrite, and a snapshot rewrites `@`, so one left there follows the working copy without any
command being run. Work in flight is then under the bookmark from the start: whatever `@` grows into
is what the next push would send, and nothing but the push being the user's keeps it unpublished.
`jj st` names the bookmarks at `@` in its own header, a `*` marking one that is ahead of its remote.

### One change is one piece of work

Size a change the way a branch is sized — the piece of work a pull request would be opened for — and
write the line saying what it is going to be at the start. Nothing else marks a line of work in jj:
it needs no bookmark and no name, `@` and its parents being the line. Everything worked on goes into
the change the working copy is in, which is why a turn ending is no reason to leave it.

**Whether the next piece of work has started is the user's call and not yours.** A follow-up asked
for inside work in flight — make it also do X, that broke, check it on the real thing — is the same
piece of work, however many turns and files it grows to. The `jj-new` skill is where that decision is
written out, along with how to fold changes back into one where they were opened too eagerly.

### At a stopping point

**The baseline is `jj st`, and `jj desc -m` only where the message needs it.** `jj st` takes the work
in and says what is in the change, which is a restore point at a moment that matters. What decides
whether anything more is due is the message and never the work being finished: `jj desc -m "<line>"`
where `@` carries none or where the work has moved past the one it carries, and nothing at all where
the line still says what the change holds. Judging when a stopping point has been reached is yours —
a piece of work green, or confirmed on the real thing — and a stopping point decides nothing about
which change the work carries on in.

**One line over the whole change, and not a dissection.** Where the change was opened for this piece
of work, it is one piece of work already and there is nothing to divide. Where two pieces did land in
one, the tidying is the user's and comes later, so nothing about which files could be separated or
which piece belongs in which commit is decided at a stopping point. Splitting needs a diff editor for
any two pieces of work that share a file, which is the user's to drive.

That line is a working note: written when the change is opened, it says what the work is going to be,
which is what makes a `jj log` of several changes readable while they are being worked on. The
commit-message rules in the global instructions — the two read-backs included — are for the message
the change carries when it is **published**, and getting it there is `jj desc` on that same change in
the user's later tidying. Say what the work is in one line and move on.

**And a stopping point is never where the next change is opened.** A follow-up inside one piece of
work is that same piece of work; whose call a new change is, is in the `jj-new` skill.

### Where the work goes

Work directly on the change on top of **main** in the existing checkout. A change on top of it is the
whole of cutting a branch here: a bookmark would be a name for publishing the work and a workspace a
second working copy, and a piece of work needs neither.

## A repository is a set of changes

Every change has a **change id** that identifies it for its whole life, and a **commit id** that identifies its current content. Editing a change keeps the change id and produces a new commit id.

```
$ jj log
@  kmuzotqv 114945bb Add initial design documentation
◆  zzzzzzzz root() 00000000
```

`@` is the change being worked in right now. It is a commit like any other: it has a description, it has content, and it is recorded. Editing a file changes what `@` contains.

**Content is taken in automatically**, at the start of almost every jj command.

```
$ echo hello > a.txt
$ jj --ignore-working-copy log -r @
@  0cb92de0 (empty)                 # not taken in — this command opted out
$ jj st
Working copy changes:
A a.txt
Working copy  (@) : mznqwmrk ba4fd4d3 the work
```

Nothing has to be marked for inclusion, so nothing can be left out by accident. `jj st` is the usual way to take content in deliberately, because it reports both what was taken in and whether descendants were rebased. `--ignore-working-copy` opts out, which is useful for reading a repo while a build scatters files through it.

### Nothing is pending

`@` holds the current work and is already recorded. No step makes it durable, and none is outstanding — so when reporting finished work, describe the work. There is no working-copy status worth appending.

Mention `@`, a change id, or `jj log` output when that is the subject: the state of the repo was the question, or which change the work landed in matters to what comes next.

## Describing work

`jj desc` (alias for `jj describe`) sets a change's description. It creates nothing.

Because `@` already exists, a description can be written **before** the work — "this is what I am about to do" — and rewritten as often as the work changes shape.

```
$ jj desc -m "fix the parser"
@  sxun 3a5de1fb fix the parser
$ echo v1 > a.txt
@  sxun 06d2ff3d fix the parser                       # same change, new content
$ jj desc -m "fix the parser (it was the tokenizer)"
@  sxun e1893549 fix the parser (it was the tokenizer)
```

```
jj desc -m "..."              # describe @
jj desc -r <rev> -m "..."     # describe any change
jj desc                       # open $EDITOR, for multi-line messages
jj desc --stdin               # read the message from stdin
```

## Starting and resuming work

| Intent | Command |
|---|---|
| Begin the next piece of work | `jj new -m "..."` |
| Begin work on a particular base | `jj new <rev> -m "..."` |
| Describe `@` and begin the next change | `jj commit -m "..."` (alias `ci`) — exactly `describe` then `new`; **not used on this machine**, see above |
| Resume an existing change, becoming it | `jj edit <rev>` |

`jj new` opens a change, and `-m` says what the work in it is going to be — the same declaration as `jj desc`, made at the moment of starting. The change left behind needs nothing further. Whose call opening one is, and why an empty `@` takes `jj desc -m` instead, is the `jj-new` skill.

Its arguments are revsets, so change ids, commit ids, bookmarks, `@-`, and `root()` all work.

`jj edit` makes `@` **be** the named change, so later edits rewrite it. Its own help recommends `jj new` plus `jj squash` instead: build on top, then fold in, which leaves the original intact until you decide.

Reading another change never requires moving `@`:

```
jj file show -r <rev> <path>
jj diff -r <rev>
jj diff --from <rev> --to <rev>
```

Since `@` is a commit, work in progress has no separate place to sit, and moving away never asks you to put anything aside.

## Arranging changes

Lines of work need no names.

```
$ jj new vuxy -m "another line"
@  mvlm  another line
│ ○  zvmw  second thing
├─╯
○  vuxy  first thing
```

**Several parents make a merge.** `jj new @ main` creates a change whose parents are both.

**Changes can be spliced into an existing line.** `-A` / `--insert-after` and `-B` / `--insert-before` place a change among existing ones and rebase what followed:

```
$ jj new --insert-after vuxy -m "the forgotten bit"
Rebased 4 descendant commits.
```

| Intent | Command |
|---|---|
| Fold `@` into its parent | `jj squash` (`-r <rev>` to move from elsewhere) |
| Split one change in two | `jj split` (opens a diff editor) |
| Drop a change, rebasing descendants onto its parents | `jj abandon <rev>` |
| Push each hunk down to the mutable ancestor that last touched those lines | `jj absorb` |
| Give paths the content they have in another revision | `jj restore --from <rev> <paths>` |
| Move revisions onto different parents | `jj rebase` |

`jj abandon` produces a new change; `jj restore --changes-in` updates the existing one.

### Descendants rebase themselves

Rewriting an ancestor rewrites everything below it, automatically.

```
$ jj edit vuxy
$ echo "forgot this" > f
Rebased 5 descendant commits onto updated working copy.
```

Every descendant keeps its change id and gets a new commit id, merge commits included. Changing only a description does the same: the content of the descendants is untouched, but they are rebuilt, because the ancestor's commit id moved.

A change that has already been pushed therefore needs a force push after any rewrite. jj refuses to rewrite immutable revisions, but this machine's `immutable_heads()` holds only tags and untracked remote bookmarks (see *Publishing is the user's*), so anything pushed from here — `main` included — is mutable and rewrites without comment.

### Conflicts live in commits

A rebase does not stop at a conflict. The conflict is recorded in the change and marked `×`:

```
×  oypy c53f347d child   (conflict)
@  smtr 6db00095 base
```

```
$ jj file show -r oypy f
<<<<<<< conflict 1 of 1
+++++++ smtrsovo 6db00095 "base" (rebase destination)
line1-changed-by-base
%%%%%%% diff from: smtrsovo 6d1db00e "base" (parents of rebased revision)
\\\\\\\        to: oypyoqxn 33c0e5fd "child" (rebased revision)
-line1
+line1-changed-by-child
>>>>>>> conflict 1 of 1 ends
```

The rebase runs to completion, only the affected changes carry the mark, and resolution happens whenever it suits — `jj edit` that change and fix it, or `jj resolve` for a merge tool. Moving on and leaving it conflicted is a valid state.

## Bookmarks

A bookmark is a name attached to a change, and it is what a git remote sees as a branch. **A bookmark does not step from one change to the next**: work moves on and the name stays where it was put, so nothing is queued for pushing until one is moved. It does stay attached across a rewrite, so a bookmark left on the change the working copy is in rides every snapshot of it onto the new commit id.

```
$ jj bookmark set mybr -r @
@  vuxy mybr  first thing
$ jj new -m "second thing"
@  zvmw       second thing          # mybr stayed behind
○  vuxy mybr  first thing
$ jj bookmark move mybr --to @
Moved 1 bookmarks to zvmwlpys ... mybr* | second thing
```

`jj bookmark` also has `create`, `delete`, `forget`, `list`, `rename`, `advance`, `track`, `untrack`. `advance` moves the closest bookmarks to a target. `delete` records a deletion to propagate on the next push; `forget` drops the bookmark locally without doing so.

## Workspaces

A workspace is a working copy with a repository attached (the worktree equivalent). One repository can have several, each with **its own working-copy commit** and its own sparse patterns. Every repository starts with one, named `default` — the operation log records `add workspace 'default'` at creation.

In `jj log`, each workspace's working-copy commit is marked `<name>@`:

```
$ jj workspace add ../build
Created workspace in "../build"

$ jj log
@  ylywlorw default@ d3adeb5f  the main line
│ ○  oswkyukq build@   544da1be (empty)
├─╯
◆  zzzzzzzz root() 00000000

$ jj workspace list
build: ../build oswkyukq 544da1be (empty)
default: . ylywlorw d3adeb5f the main line
```

| Command | |
|---|---|
| `jj workspace add <dest>` | Add one. `--name` names it, `-r` gives its working-copy commit parents |
| `jj workspace list` | Each workspace's path and working-copy commit |
| `jj workspace root` | This workspace's root directory |
| `jj workspace rename` | Rename the current workspace |
| `jj workspace forget` | Stop tracking a workspace's working-copy commit |
| `jj workspace update-stale` | Bring a stale working copy up to date |

Without `-r`, the new working-copy commit shares the parents of the current workspace's `@`. With revisions, they become its parents, as if `jj new r1 r2 ...` had run there. `add` inherits the current workspace's sparse patterns unless `--sparse-patterns` says otherwise.

### One workspace never writes into another's directory

Operations rewrite commits across the whole repository, so an operation in one workspace can rewrite another workspace's working-copy commit — editing a shared ancestor is enough, since descendants rebase themselves. When that rewrite would require the other workspace's files to change, that workspace goes **stale** and refuses every command until its owner acts:

```
$ jj st
Error: The working copy is stale (not updated since operation 979522db523f).
Hint: Run `jj workspace update-stale` to update it.
```

Nothing is written to its directory in the meantime, and nothing is at risk. If the rewrite leaves that workspace's tree content identical — rebasing onto an empty change, for instance — its recorded commit is updated silently and it never goes stale.

`jj workspace update-stale` then brings the files up to date:

```
$ jj workspace update-stale
Working copy  (@) now at: qnpukwqy b0746143 w2
Added 1 files, modified 0 files, removed 0 files
Updated working copy to fresh commit b0746143e63a
```

### A stale workspace with edits of its own becomes divergent

If the stale workspace had edits that were taken in before it went stale, two operations have rewritten the same change. Reconciliation happens by 3-way merging the **view** — which commits are visible — not by merging file contents, so both versions of the change stay visible. By definition that is a divergent change:

```
$ jj workspace update-stale
Concurrent modification detected, resolving automatically.
Working copy  (@) now at: rmnpokoo/2 7c0130e9 (divergent) w3
Updated working copy to fresh commit 7c0130e9a605

$ jj log
○  rmnp a21e142b  w3            # the local edit
│ ○  rmnp 7c0130e9 ws3@ w3      # the rewritten version — @ lands here
├─╯
○  kwyn 84b54a8c default@ inserted
```

**Nothing is lost, but `@` lands on the rewritten side**, so the local edit is not in the working copy and is easy to walk past. Resolve it deliberately:

```
jj log -r '<change id>'                     # see both versions
jj diff --from <one> --to <other>
jj restore --from <other> <paths>           # bring content across
jj abandon <the one to drop>                # clear the divergence
```

`jj squash --from A --into B` is the wrong tool here: it moves A's diff against A's parent, so when both versions add the same path it reports a conflict that reflects the operation rather than the content.

### Give workspaces independent work

A workspace pays off when the lines of work are independent — a slow build or test run in one while editing continues in another. Making one workspace's `@` an ancestor of another's means every edit to the ancestor stales the descendant's workspace, which stops the other window rather than helping it.

## Recovering anything

Two histories exist, answering different questions.

### `jj evolog` — the past of one change

Every earlier version of a change, addressable as `<change id>/N`.

```
$ jj evolog
@  qmooupxv abd88e77
│  the work (revised)
│  -- operation 05adf721070f snapshot working copy
○  qmooupxv/1 2af1936b (hidden)
│  -- operation baeddbedd388 describe commit b115d012...
○  qmooupxv/2 b115d012 (hidden)
│  the work
...

$ jj file show -r qmooupxv/2 a.txt      # its content at that point
$ jj diff --from qmooupxv/2 --to @
```

### `jj op log` — every operation on the repository

Taking content in and describing a change are operations too, so the log covers everything that has happened.

```
$ jj op log --no-graph -T 'self.id().short(12) ++ "  " ++ self.description() ++ "\n"'
05adf721070f  snapshot working copy
baeddbedd388  describe commit b115d012...
e7ef633cd34c  snapshot working copy
3615c5e2b5f4  add workspace 'default'
```

```
jj op diff --op <op>          # what one operation changed
jj op restore <op>            # return the repository to that state
jj undo                       # undo the most recent operation
jj --at-op=<op> <command>     # run a command against the repository as it was
```

`jj op restore` is itself an operation, so overshooting is recoverable — the log only grows forwards, and `jj undo` walks back out.

Use `jj op restore` to go back. `--at-op` runs a command *at* a past point, which is right for reading (`log`, `file show`) but forks the operation history when combined with a command that writes.

### Nothing expires

Losing history takes two deliberate steps. From `jj util gc --help`:

> To garbage-collect old operations and the commits/objects referenced by them, run `jj op abandon ..<some old operation>` before `jj util gc`.
>
> By default, only obsolete objects and operations older than 2 weeks are pruned.

`jj util gc` alone does not remove anything the operation log still reaches, and no collection runs on its own. Left alone the operation log grows without bound, and every past version of every change stays reachable.

## Colocation with git

`jj git init` creates a colocated repository **by default** in current versions; `--no-colocate` opts out. There is no `jj init` subcommand — jj suggests configuring `aliases.init = ["git", "init"]` if you want one.

In a colocated repository `.git` exists and git commands work, but drive it through jj: `jj st`, not `git status`.

Every version jj holds is anchored by a real ref, so `git gc` will not prune them:

```
$ git for-each-ref
104cd947... commit  refs/jj/keep/104cd9472b30fd3f6f959c29f38e2dfa7c10cd5a
2af1936b... commit  refs/jj/keep/2af1936ba0a237a5c6a37811341092ee7cac48de
```

## Identity and configuration

jj reads its own configuration, not git's, so `user.name` and `user.email` must be set for jj even where git already has them. Setting them affects future commits only; `jj metaedit --update-author` fixes a change already created without them.

```
jj config set --user user.name  "..."     # user level
jj config set --user user.email "..."
jj config set --repo user.email "..."     # this repository only
jj config path --user                     # e.g. ~/.config/jj/config.toml
jj config list --include-overridden       # effective values, and what they override
```

Levels are `--user`, `--repo`, and `--workspace`, with `--config NAME=VALUE` and `--config-file PATH` overriding per invocation. `jj config edit` opens a level in an editor; `jj config get` reads one value.

A repo-level value governs that one repository and no other, so a setting or a revset alias can differ from repository to repository: `jj config list --include-overridden` is what says which values the one in hand is running with.

## Templates

`jj log` and its relatives take `-T` with a template, and `--no-graph` for output without the graph. Field names differ by command — `jj log` exposes `commit_id` where `jj evolog` exposes `commit`. A template error names the keyword that was expected.

```
jj log --no-graph -T 'change_id.short(4) ++ " " ++ commit_id.short(8) ++ " " ++ description.first_line() ++ "\n"'
```
