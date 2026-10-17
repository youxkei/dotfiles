---
name: jj-open
description: Opening the next jj change with `jj open` — when a piece of work is a new one and whose call that is, why an empty `@` always wants `jj desc -m` and never `jj open -m`, and how to fold changes back into one where they were opened too eagerly. Use when starting work that may want a change of its own, when asked to open, cut or start a new change, when a follow-up request arrives inside work already in flight, when the working copy is an empty change needing a message, and when a stack has to be folded back down.
---

# Opening the next change

`jj open -m="<subject>" -m="<body paragraph>"` opens a change right after `@`, makes it the working
copy and carries the bookmark at `@` onto it. How jj itself works is the `jj` skill; what this one is
about is *when* another change is opened and who decides.

**And `jj open` is the wrong command on an empty `@`, always: that change is `jj desc -m`'s.** Nothing
about the work makes an exception — an empty working copy is a change to describe and not a change to
open one on top of. `## Opening one` has why.

## The decision is the user's

**A follow-up asked for inside a piece of work is that same piece of work.** A feature the user is
iterating on — "now make it also do X", "that broke, fix it", "check it on the real thing" — is one
change until they say otherwise, however many turns it takes and however many files it grows to.

**So do not open one on your own judgement.** Open a change when

- the user says to, in whatever words: *new change for this*, *別のchangeで*, *cut a change*;
- or the work is plainly about something the change's own message does not cover — a different
  feature, a repository-wide rename, a fix to something the current work never touched.

**And when in doubt, keep working in the change.** The cost is asymmetric: a change that grew is one
message to rewrite (`jj desc`), where a piece of work spread over three changes is a fold the user has
to notice and ask for. Nothing in a diffstat says which of the two a request is.

## Opening one

**Where `@` is empty, describe it rather than opening another.** A change with nothing worked in it is
already the change to work in — that is where `jj squash` leaves the working copy, where a change
opened a moment ago and not yet worked in stands, and where an abandoned or rebased-away change leaves
it:

```sh
jj desc -m="<subject>" -m="<body paragraph>"
```

`jj open` there stacks a second change on the empty one **and the empty one stays**: in jj 0.44 an
empty `@` is still in the log after a `jj new` on top of it, whether it carries a message or not. What
that leaves is a change nobody meant, under the work, for `jj abandon` to take out later. So it is what
`@` holds that chooses between the two commands and not whether the work is new, and that is one
question:

```sh
jj log -r @ --no-graph -T 'if(empty, "empty — jj desc -m", "worked in — jj open -m")'
```

Where `@` holds work:

```sh
jj open -m="<subject>" -m="<body paragraph>" -m="<body paragraph>"
```

**The first `-m` is the subject, and each further `-m` is a paragraph of the body**, with a blank line
put between them. Write each as `-m="..."`: as `-m "..."` a paragraph starting with `-` is read by jj
as an option and fails.

The message goes in **at the start**, before the work, and is rewritten as the work takes shape
(`jj desc`, which takes `-m` the same way). Write it in the repository's commit-message convention —
read its `CLAUDE.md` / `CONTRIBUTING` — with a body and not a subject alone.

**Use `jj open`, not `jj new`**: a plain `jj new` leaves the bookmark behind on `@-`.

**`jj open` fails, creating nothing, when `@` carries no bookmark.** Do not fall back to a plain
`jj new` there: say that `@` has no bookmark and ask where the work belongs.

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

`trunk()` names the main line, so the revset needs no bookmark spelled out and works in a
repository whose trunk is `master`.

**Adjacent, because skipping a change conflicts.** `jj squash --from <newest> --into <the first>`
over a middle change that touched the same files leaves conflict markers and a broken working copy —
`jj undo` puts that back. Squashing the pair immediately above each other never has that problem, and
two squashes reach the same place.

**`jj edit` at the end, and check for an empty change.** Squashing the working copy away leaves `@` on
a fresh empty change; `jj edit <the first>` puts the working copy back in the folded change so the
work carries on there, and `jj log` says whether an empty one is left over to abandon.

**A fold is not a divide.** Squashing changes together needs nothing but these commands. To move only
part into another existing change, use the `jj-move-diff` skill.
