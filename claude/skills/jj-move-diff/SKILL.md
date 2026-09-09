---
name: jj-move-diff
description: Moving selected hunks or lines from one existing jj change into another by having Claude edit both changes directly — recording a rollback operation, reading the source's parent/source/destination content, removing only the selected change from the source, applying its meaning to the destination, resolving rebases, restoring the original working-copy change, and verifying ownership. Use when work landed in the wrong change or when asked to move, transfer, transplant, or redistribute part of a diff between changes without an interactive diff editor.
---

# Moving diff between jj changes

**Claude moves partial diff by editing both changes directly. Do not open a diff editor.** The unit can
be a hunk, one or more lines, or part of a line because Claude uses the normal Read and Edit/Write
tools rather than `jj squash -i`.

This skill assumes the repository-wide rules in the `jj` skill. In particular, use no git command,
and do not move bookmarks or push while tidying changes.

## Record the exact starting point

Before changing history, snapshot the working copy and record both the change to return to and the
operation that restores the whole procedure:

```sh
jj st
jj log -r @ --no-graph -T 'change_id ++ "\n"'
jj op log -n 1 --no-graph -T 'id ++ "\n"'
```

Call those values `<original-working-copy>` and `<baseline-operation>`. Do not rely on one `jj undo`:
`jj edit`, snapshots, and descendant rebases can create several operations. To cancel the whole move,
use `jj op restore <baseline-operation>`.

## Establish the change being moved

Identify both endpoints and inspect their current diffs:

```sh
jj log
jj diff -r <source> --git
jj diff -r <destination> --git
```

`<source>` owns the change now. `<destination>` is the existing change that should own it. Ask where
either endpoint or the exact lines are unclear; do not infer ownership from paths alone.

This procedure is for a source with exactly one parent. Check before reading its baseline:

```sh
jj log -r '<source>-' --no-graph -T 'change_id ++ "\n"'
```

If that prints more than one change, the source is a merge. Stop and ask how its merge diff should be
attributed rather than choosing one parent or editing it with this procedure.

For every affected path in a single-parent source, read three versions before editing:

```sh
jj file show -r '<source>-' <path>   # before the source introduced its diff
jj file show -r <source> <path>      # with all of the source's diff
jj file show -r <destination> <path> # destination's own context
```

From these versions, state the selected transformation: what text the source added, removed, or
changed, and what source-owned edits must stay. The destination may have different surrounding text,
so move the transformation's meaning; do not blindly copy a complete source file or source hunk.

## Remove it from the source first

Make the source the working-copy change:

```sh
jj edit <source>
```

Read the live affected files, then use Edit or Write to reverse **only** the selected transformation.
Use the source-parent version as evidence for the text being restored, while retaining every
source-owned edit that is not moving.

Snapshot and inspect before touching the destination:

```sh
jj st
jj diff -r <source> --git
jj log -r 'descendants(<source>) & conflicts()'
```

The selected change must be absent from this diff and the changes staying in the source must still be
present. The last command must return no revisions. `jj st` reports the working copy, not necessarily
every conflicted descendant, so do not use it alone to judge the rebase.

## Apply it to the destination

Make the destination the working-copy change:

```sh
jj edit <destination>
```

Read the live affected files. They may differ from the destination version inspected earlier because
editing the source can rebase a related destination. Use Edit or Write to apply the selected
transformation in this current context. Preserve all destination-owned edits.

Then snapshot and inspect:

```sh
jj st
jj diff -r <destination> --git
jj log -r 'descendants(<destination>) & conflicts()'
```

The destination diff must now contain the moved change in its own context, and the last command must
return no revisions. Direct editing preserves
both changes' descriptions. An emptied source also remains as an empty change with its description;
do not abandon it unless the user separately asks to remove that change.

## Resolve rebase conflicts as ordinary file edits

When destination is an ancestor of source, rewriting destination rebases source again. Nearby edits
can conflict even when the lines are logically independent. This is not a reason to use a diff
editor.

```sh
jj st
jj edit <conflicted-change>
```

Read each conflicted file and use Edit or Write to produce the intended combined content:

- the moved transformation as owned by destination;
- every unrelated transformation still owned by source or another descendant;
- no conflict markers.

Run `jj st` and `jj diff -r <conflicted-change> --git` after resolution. Then rerun the relevant
`jj log -r 'descendants(<rewritten-change>) & conflicts()'`; treat every revision it lists the same
way, but stop and ask if the intended combined content is ambiguous.

## Return to the original working-copy change

After both changes and all rebased descendants are clean:

```sh
jj edit <original-working-copy>
```

Change IDs survive rewrites, so this returns to the original work even though its commit ID may have
changed. If source or destination was originally `@`, this naturally returns there.

## Verify ownership and final content

```sh
jj diff -r <source> --git
jj diff -r <destination> --git
jj log
jj st
```

Verify the ownership properties in every topology:

1. source no longer contains the selected transformation;
2. source still contains every transformation meant to remain there;
3. destination contains the selected transformation exactly once.

If source and destination are on one ancestor/descendant line, also inspect the line's final
descendant content and confirm it contains both the moved work and the work left in source. If they
are parallel, inspect each change's tree independently; inspect combined content only where a merge
descendant actually exists.

Do not call the move complete merely because there are no conflict markers. Diff ownership and the
resulting trees are separate checks.

## Roll back the whole procedure

If the direction, selection, or conflict resolution was wrong, restore the recorded operation:

```sh
jj op restore <baseline-operation>
```

Then run `jj st` and `jj log` to confirm the original working-copy change and history are back. A
single `jj undo` only reverses the latest operation and can leave a multi-step move half-applied.

## Commands that do not replace this procedure

- `jj squash -i --from <source> --into <destination>` requires an interactive diff editor, which
  Claude does not delegate to the user for this task.
- `jj squash --from <source> --into <destination> <fileset>` is suitable only when the complete diff
  of each named path moves; a fileset cannot select lines inside a path.
- `jj split` creates another change instead of moving work into an existing one.
- `jj absorb` chooses one or more ancestor destinations from line history rather than applying a
  selected transformation to the named destination.
- `jj restore` restores content but does not remove ownership from the source.
- A temporary carrier change followed by non-interactive `jj squash` is not a substitute: its patch
  is based on the source-side context and can pull unrelated context or conflicts into an ancestor
  destination.
