---
name: jj-move-diff
description: Moving selected hunks or lines from one existing jj change into another — with jj operations first (the source's evolog snapshots and jj restore), and Claude's own Edit only for the parts no snapshot separates — recording a rollback operation, finding the snapshot to restore from, editing locally what remains, resolving rebases, restoring the original working-copy change, and verifying ownership. Use when work landed in the wrong change or when asked to move, transfer, transplant, or redistribute part of a diff between changes without an interactive diff editor.
---

# Moving diff between jj changes

**Move with jj operations, and edit by hand only where they cannot reach.** Every jj command
snapshots the working copy, so the source's evolog usually holds the exact content the source should
end with; `jj restore` from it does the bulk of the move. Edit/Write is for the parts no snapshot
separates, one hunk at a time — never a reversal of the whole selection retyped by hand. Do not open a
diff editor.

This skill assumes the repository-wide rules in the `jj` skill. In particular, use no git command,
and do not push while tidying changes.

## Record the exact starting point

```sh
jj st
jj log -r @ --no-graph -T 'change_id ++ "\n"'
jj log -r <source> --no-graph -T 'commit_id ++ "\n"'
jj op log -n 1 --no-graph -T 'id ++ "\n"'
```

Call those `<original-working-copy>`, `<source-commit>` and `<baseline-operation>`. To cancel the
whole move, `jj op restore <baseline-operation>`; one `jj undo` is not enough, the move being several
operations.

## Establish what moves

```sh
jj log
jj diff -r <source> --git
jj diff -r <destination> --git
```

`<source>` owns the work now and `<destination>` is the existing change that should own it. Ask where
either endpoint or the exact lines are unclear; do not infer ownership from paths alone. If
`jj log -r '<source>-'` prints more than one change, the source is a merge: stop and ask how its diff
should be attributed.

## Find the snapshots that separate it

```sh
jj evolog -r <source> --no-graph -T 'commit.commit_id().short(8) ++ " " ++ commit.description().first_line() ++ "\n"'
jj diff --from <snapshot> --to <next snapshot> --git
```

Read the diff between each pair of consecutive snapshots and mark each step as the moving work, the
staying work, or both. The **restore point** is the last snapshot before the first step that holds
moving work.

## Restore what the snapshots give

```sh
jj restore --from <restore point> --into <source> <paths>
```

The source now holds everything up to the restore point and nothing after it. Where the destination
is an empty change opened right after the source, it gets the rest back whole:

```sh
jj restore --from <source-commit> --into <destination> <paths>
```

## Edit locally what they do not

Use Edit on only these, reading the live file each time:

- **staying work done after the restore point**: re-apply it to the source, with the snapshot diff of
  its step as the text to apply;
- **a step holding both**: its staying hunks to the source, as above;
- **a destination that is not an empty change right after the source**: apply the moving hunks to it
  in its own context, from the snapshot diffs, preserving its own edits.

`jj edit <change>` to work in each, and after each change is edited:

```sh
jj st
jj diff -r <change> --git
jj log -r 'descendants(<change>) & conflicts()'
```

The last must return no revisions. Where one is conflicted, `jj edit` it and Edit each file to the
intended combined content — the moved work as the destination's, everything else as its owner's, no
markers — and ask where that content is ambiguous.

## Return and verify

```sh
jj edit <original-working-copy>
jj diff -r <source> --git
jj diff -r <destination> --git
jj diff --from <source-commit> --to <the line's final descendant>
```

1. the source no longer contains the moving work;
2. the source still contains everything meant to stay;
3. the destination contains the moving work exactly once;
4. where source and destination are on one line, the last diff is empty apart from what the
   destination already held — the move changed ownership and not content.

Both changes keep their descriptions; an emptied source stays as an empty change unless the user asks
for it to go.

## Commands that do not replace this procedure

- `jj squash -i` needs an interactive diff editor, which Claude does not delegate to the user.
- `jj squash --from <source> --into <destination> <fileset>` moves only whole paths.
- `jj split` creates another change instead of moving work into an existing one.
- `jj absorb` picks destinations from line history, not the named destination.
- A temporary carrier change followed by `jj squash` builds its patch on the source's context and
  can pull unrelated context or conflicts into an ancestor destination.
