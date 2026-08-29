---
name: jj-new
description: Opening the next jj change — when a piece of work is a new one and whose call that is, why an empty `@` always wants `jj desc -m` and never `jj new -m`, what `jj new -m` does to the working copy and to a bookmark, and how to fold changes back into one where they were opened too eagerly. Use when starting work that may want a change of its own, when asked to open, cut or start a new change, when a follow-up request arrives inside work already in flight, when the working copy is an empty change needing a line, and when a stack has to be folded back down.
---

# Opening the next change

`jj new -m "<line>"` opens a change and makes it the working copy. That is the whole of cutting a
branch in jj: no bookmark, no name, no worktree — `@` and its parents are the line of work. How jj
itself works is the `jj` skill; what this one is about is *when* another change is opened and who
decides.

**And `jj new` is the wrong command on an empty `@`, always: that change is `jj desc -m`'s.** Nothing
about the work makes an exception — an empty working copy is a change to describe and not a change to
open one on top of. `## Opening one` has why.

## The decision is the user's

**A follow-up asked for inside a piece of work is that same piece of work.** A feature the user is
iterating on — "now make it also do X", "that broke, fix it", "check it on the real thing" — is one
change until they say otherwise, however many turns it takes and however many files it grows to.

**So do not open one on your own judgement.** Open a change when

- the user says to, in whatever words: *new change for this*, *別のchangeで*, *cut a change*;
- or the work is plainly about something the change's own line does not cover — a different
  feature, a repository-wide rename, a fix to something the current work never touched.

**And when in doubt, keep working in the change.** The cost is asymmetric: a change that grew is one
line to rewrite (`jj desc -m`), where a piece of work spread over three changes is a fold the user has
to notice and ask for. Nothing in a diffstat says which of the two a request is.

## Opening one

**Where `@` is empty, describe it rather than opening another.** A change with nothing worked in it is
already the change to work in — that is where `jj squash` leaves the working copy, where a change
opened a moment ago and not yet worked in stands, and where an abandoned or rebased-away change leaves
it:

```sh
jj desc -m "<one line saying what this piece of work is going to be>"
```

`jj new` there stacks a second change on the empty one **and the empty one stays**: in jj 0.44 an
empty `@` is still in the log after a `jj new` on top of it, whether it carries a message or not. What
that leaves is a change nobody meant, under the work, for `jj abandon` to take out later. So it is what
`@` holds that chooses between the two commands and not whether the work is new, and that is one
question:

```sh
jj log -r @ --no-graph -T 'if(empty, "empty — jj desc -m", "worked in — jj new -m")'
```

Where `@` holds work:

```sh
jj new -m "<one line saying what this piece of work is going to be>"
```

The line goes in **at the start**, before the work: it is a working note, free to rewrite as the work
takes shape (`jj desc -m`), and it is what makes a `jj log` of a stack readable while it is being
worked in. What that line has to *be* by the time it is published is the repository's commit-message
convention — read its `CLAUDE.md` / `CONTRIBUTING`.

**`jj new` moves no bookmark.** The setting that would make it advance one,
`experimental-advance-branches`, is not used here and is per-repository, so
`jj config list experimental-advance-branches` is worth asking in a repository whose config is
unknown: where it is on, `jj new` advances a bookmark sitting on `@-` onto the change just left
behind, putting it on work nobody asked to publish, and `jj undo` takes the operation and the advance
back together.

A bookmark already sitting on `@` is untouched either way — the state `jj push` leaves behind, see the
`jj` skill — so after a `jj new` it is on `@-`, and the change just opened is the one nothing points
at.

## Folding changes back into one

Where changes were opened that should not have been, squash them **adjacent pair by adjacent pair**,
newest first, keeping the destination's message:

```sh
jj log -r 'trunk()..@' --no-graph \
  -T 'change_id.shortest(8) ++ " " ++ bookmarks ++ " " ++ description.first_line() ++ "\n"'
jj squash --from <newest> --into <the one under it> -u   # -u: keep the destination's message
jj squash --from <that one> --into <the first> -u
jj edit <the first>                                      # work in it again
```

`trunk()` names the published line, so the revset needs no bookmark spelled out and works in a
repository whose trunk is `master`.

**Adjacent, because skipping a change conflicts.** `jj squash --from <newest> --into <the first>`
over a middle change that touched the same files leaves conflict markers and a broken working copy —
`jj undo` puts that back. Squashing the pair immediately above each other never has that problem, and
two squashes reach the same place.

**`jj edit` at the end, and check for an empty change.** Squashing the working copy away leaves `@` on
a fresh empty change; `jj edit <the first>` puts the working copy back in the folded change so the
work carries on there, and `jj log` says whether an empty one is left over to abandon.

**A fold is not a divide.** Squashing changes together needs nothing but these commands; taking one
apart needs a diff editor for any two pieces of work that share a file, and that is the user's to
drive.
