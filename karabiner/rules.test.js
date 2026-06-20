// Tests for rules.js. Run: `node karabiner/rules.test.js` or `make karabiner-test`.
//
// rules.js is an IIFE returning the rule object, so eval() yields it directly.
// We then walk `manipulators` in source order to mimic Karabiner's first-match
// semantics for a small set of synthetic events.

"use strict";

const fs = require("fs");
const path = require("path");

const rule = eval(fs.readFileSync(path.join(__dirname, "rules.js"), "utf8"));

let fails = 0;
function assert(cond, msg) {
  if (cond) return;
  console.error("FAIL: " + msg);
  fails++;
}

// ---------- structural ----------

assert(rule && typeof rule === "object", "rule is object");
assert(typeof rule.description === "string", "description present");
assert(Array.isArray(rule.manipulators) && rule.manipulators.length > 0, "manipulators non-empty");

const seen = new Set();
for (let i = 0; i < rule.manipulators.length; i++) {
  const m = rule.manipulators[i];
  assert(m.type === "basic", `[${i}] type=basic`);
  assert(m.from && typeof m.from.key_code === "string", `[${i}] from.key_code is string`);
  const to = m.to || m.to_after_key_up;
  assert(Array.isArray(to) && to.length > 0, `[${i}] has to/to_after_key_up`);
  for (const entry of to || []) {
    assert(entry.key_code || entry.shell_command || entry.set_variable,
           `[${i}] to entry has an action`);
    assert(!entry.modifiers || Array.isArray(entry.modifiers),
           `[${i}] to.modifiers is an array`);
  }

  // Detect exact-duplicate rules (same device-scope + variable + from-key +
  // mandatory mods). Two such rules would shadow each other.
  const key = JSON.stringify([m.conditions || [], m.from]);
  assert(!seen.has(key), `[${i}] duplicate rule signature: ${key}`);
  seen.add(key);
}

// ---------- matcher ----------

// Map a single device_identifiers entry to the synthetic device names used by
// the test cases ("builtin", "external", "tpkb2"). TrackPoint Keyboard II is
// vendor_id 6127 / product_id 24801.
function identifierMatches(id, device) {
  if (id.is_built_in_keyboard) return device === "builtin";
  if (id.vendor_id === 6127 && id.product_id === 24801) return device === "tpkb2";
  return false;
}

function deviceOK(conds, device) {
  for (const c of conds || []) {
    if (c.type === "device_if" && c.identifiers)
      return c.identifiers.some((id) => identifierMatches(id, device));
    if (c.type === "device_unless" && c.identifiers)
      return !c.identifiers.some((id) => identifierMatches(id, device));
  }
  return true;
}

function varsOK(conds, vars) {
  for (const c of conds || []) {
    if (c.type === "variable_if"     && (vars[c.name] || 0) !== c.value) return false;
    if (c.type === "variable_unless" && (vars[c.name] || 0) === c.value) return false;
  }
  return true;
}

function modsOK(eventMods, fromMods) {
  const mand = (fromMods && fromMods.mandatory) || [];
  const opt  = (fromMods && fromMods.optional)  || [];
  for (const m of mand) if (!eventMods.includes(m)) return false;
  if (opt.includes("any")) return true;
  for (const m of eventMods) {
    if (mand.includes(m)) continue;
    if (!opt.includes(m)) return false;
  }
  return true;
}

function findMatch(ev) {
  const mods = ev.modifiers || [];
  const vars = ev.variables || {};
  for (const m of rule.manipulators) {
    if (m.from.key_code !== ev.key_code) continue;
    if (!deviceOK(m.conditions, ev.device)) continue;
    if (!varsOK(m.conditions, vars)) continue;
    if (!modsOK(mods, m.from.modifiers)) continue;
    return m;
  }
  return null;
}

function expectKey(label, ev, expected) {
  const m = findMatch(ev);
  if (!m) { assert(false, `${label}: no rule matched`); return; }
  const t = (m.to || [])[0] || {};
  const wantMods = (expected.modifiers || []).slice().sort();
  const gotMods  = (t.modifiers       || []).slice().sort();
  assert(t.key_code === expected.key_code &&
         JSON.stringify(wantMods) === JSON.stringify(gotMods),
         `${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify({key_code: t.key_code, modifiers: t.modifiers})}`);
}

function keyCase(label, key_code, expected, opts = {}) {
  const ev = {
    device: opts.device || "builtin",
    key_code,
  };
  if (opts.shift) ev.modifiers = ["shift"];
  if (opts.henkan) ev.variables = { dudrack_henkan: 1 };
  return [label, ev, expected];
}

function expectKeyCases(section, cases) {
  for (const [label, ev, expected] of cases) {
    expectKey(`${section}: ${label}`, ev, expected);
  }
}

function expectNone(label, ev) {
  assert(findMatch(ev) === null, `${label}: expected no match`);
}

// ---------- external JIS remaps ----------

expectKeyCases("external JIS", [
  keyCase("shift+2 -> '\"'", "2", { key_code: "quote", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("shift+6 -> '&'", "6", { key_code: "7", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("shift+7 -> \"'\"", "7", { key_code: "quote" }, { device: "external", shift: true }),
  keyCase("shift+8 -> '('", "8", { key_code: "9", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("shift+9 -> ')'", "9", { key_code: "0", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("shift+hyphen -> '='", "hyphen", { key_code: "equal_sign" }, { device: "external", shift: true }),
  keyCase("equal_sign -> '^'", "equal_sign", { key_code: "6", modifiers: ["left_shift"] }, { device: "external" }),
  keyCase("shift+equal_sign -> '~'", "equal_sign", { key_code: "grave_accent_and_tilde", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("open_bracket -> '@'", "open_bracket", { key_code: "2", modifiers: ["left_shift"] }, { device: "external" }),
  keyCase("shift+open_bracket -> '`'", "open_bracket", { key_code: "grave_accent_and_tilde" }, { device: "external", shift: true }),
  keyCase("close_bracket -> '['", "close_bracket", { key_code: "open_bracket" }, { device: "external" }),
  keyCase("shift+close_bracket -> '{'", "close_bracket", { key_code: "open_bracket", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("non_us_pound -> ']'", "non_us_pound", { key_code: "close_bracket" }, { device: "external" }),
  keyCase("shift+non_us_pound -> '}'", "non_us_pound", { key_code: "close_bracket", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("backslash -> ']'", "backslash", { key_code: "close_bracket" }, { device: "external" }),
  keyCase("shift+backslash -> '}'", "backslash", { key_code: "close_bracket", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("shift+semicolon -> '+'", "semicolon", { key_code: "equal_sign", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("quote -> ':'", "quote", { key_code: "semicolon", modifiers: ["left_shift"] }, { device: "external" }),
  keyCase("shift+quote -> '*'", "quote", { key_code: "8", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("international1 -> '\\'", "international1", { key_code: "backslash" }, { device: "external" }),
  keyCase("shift+international1 -> '_'", "international1", { key_code: "hyphen", modifiers: ["left_shift"] }, { device: "external", shift: true }),
  keyCase("international3 -> '\\'", "international3", { key_code: "backslash" }, { device: "external" }),
  keyCase("shift+international3 -> '|'", "international3", { key_code: "backslash", modifiers: ["left_shift"] }, { device: "external", shift: true }),
]);

// ---------- external IME keys ----------

expectKeyCases("external IME", [
  keyCase("pc_nfer -> japanese_eisuu", "japanese_pc_nfer", { key_code: "japanese_eisuu" }, { device: "external" }),
  keyCase("pc_xfer -> japanese_kana", "japanese_pc_xfer", { key_code: "japanese_kana" }, { device: "external" }),
  keyCase("grave -> japanese_kana (driver fallback)", "grave_accent_and_tilde", { key_code: "japanese_kana" }, { device: "external" }),
]);

// ---------- built-in modifier remaps ----------

expectKey("builtin caps_lock -> left_control",
  { device: "builtin", key_code: "caps_lock" },
  { key_code: "left_control" });
expectKey("builtin tab -> left_command",
  { device: "builtin", key_code: "tab" },
  { key_code: "left_command" });
expectKey("builtin left_command -> left_option",
  { device: "builtin", key_code: "left_command" },
  { key_code: "left_option" });
expectKey("builtin left_option -> left_command",
  { device: "builtin", key_code: "left_option" },
  { key_code: "left_command" });
expectKey("builtin fn -> left_command",
  { device: "builtin", key_code: "fn" },
  { key_code: "left_command" });

// SandS: spacebar -> lazy left_shift (hold), to_if_alone spacebar (tap).
const spaceMatch = findMatch({ device: "builtin", key_code: "spacebar" });
assert(spaceMatch && spaceMatch.to && spaceMatch.to[0].key_code === "left_shift" &&
       spaceMatch.to[0].lazy === true,
       "builtin spacebar -> lazy left_shift on hold");
assert(spaceMatch && Array.isArray(spaceMatch.to_if_alone) &&
       spaceMatch.to_if_alone[0].key_code === "spacebar",
       "builtin spacebar -> spacebar on tap (to_if_alone)");
const spaceExtMatch = findMatch({ device: "external", key_code: "spacebar" });
assert(spaceExtMatch === null, "external spacebar untouched");

// ---------- Dudrack neutral (built-in, no henkan) ----------

expectKeyCases("builtin neutral", [
  keyCase("q -> ':'", "q", { key_code: "semicolon", modifiers: ["left_shift"] }),
  keyCase("shift+q -> '*'", "q", { key_code: "8", modifiers: ["left_shift"] }, { shift: true }),
  keyCase("w -> comma", "w", { key_code: "comma" }),
  keyCase("e -> period", "e", { key_code: "period" }),
  keyCase("r -> p", "r", { key_code: "p" }),
  keyCase("t -> y", "t", { key_code: "y" }),
  keyCase("y -> f", "y", { key_code: "f" }),
  keyCase("u -> g", "u", { key_code: "g" }),
  keyCase("i -> c", "i", { key_code: "c" }),
  keyCase("o -> r", "o", { key_code: "r" }),
  keyCase("p -> l", "p", { key_code: "l" }),
  keyCase("open_bracket -> slash", "open_bracket", { key_code: "slash" }),
  keyCase("a -> a", "a", { key_code: "a" }),
  keyCase("s -> o", "s", { key_code: "o" }),
  keyCase("d -> e", "d", { key_code: "e" }),
  keyCase("f -> u", "f", { key_code: "u" }),
  keyCase("g -> i", "g", { key_code: "i" }),
  keyCase("h -> d", "h", { key_code: "d" }),
  keyCase("j -> h", "j", { key_code: "h" }),
  keyCase("k -> t", "k", { key_code: "t" }),
  keyCase("l -> n", "l", { key_code: "n" }),
  keyCase("semicolon -> s", "semicolon", { key_code: "s" }),
  keyCase("quote -> hyphen", "quote", { key_code: "hyphen" }),
  keyCase("shift+quote -> '='", "quote", { key_code: "equal_sign" }, { shift: true }),
  keyCase("z -> semicolon", "z", { key_code: "semicolon" }),
  keyCase("shift+z -> '+'", "z", { key_code: "equal_sign", modifiers: ["left_shift"] }, { shift: true }),
  keyCase("x -> q", "x", { key_code: "q" }),
  keyCase("c -> j", "c", { key_code: "j" }),
  keyCase("v -> k", "v", { key_code: "k" }),
  keyCase("b -> x", "b", { key_code: "x" }),
  keyCase("n -> b", "n", { key_code: "b" }),
  keyCase("m -> m", "m", { key_code: "m" }),
  keyCase("comma -> w", "comma", { key_code: "w" }),
  keyCase("period -> v", "period", { key_code: "v" }),
  keyCase("slash -> z", "slash", { key_code: "z" }),
]);

// ---------- Dudrack henkan (built-in, dudrack_henkan=1) ----------

expectKeyCases("builtin henkan", [
  keyCase("q -> 1", "q", { key_code: "1" }, { henkan: true }),
  keyCase("w -> 2", "w", { key_code: "2" }, { henkan: true }),
  keyCase("shift+w -> '\"'", "w", { key_code: "quote", modifiers: ["left_shift"] }, { henkan: true, shift: true }),
  keyCase("e -> 3", "e", { key_code: "3" }, { henkan: true }),
  keyCase("r -> 4", "r", { key_code: "4" }, { henkan: true }),
  keyCase("t -> 5", "t", { key_code: "5" }, { henkan: true }),
  keyCase("y -> 6", "y", { key_code: "6" }, { henkan: true }),
  keyCase("shift+y -> '&'", "y", { key_code: "7", modifiers: ["left_shift"] }, { henkan: true, shift: true }),
  keyCase("u -> 7", "u", { key_code: "7" }, { henkan: true }),
  keyCase("shift+u -> \"'\"", "u", { key_code: "quote" }, { henkan: true, shift: true }),
  keyCase("i -> 8", "i", { key_code: "8" }, { henkan: true }),
  keyCase("shift+i -> '('", "i", { key_code: "9", modifiers: ["left_shift"] }, { henkan: true, shift: true }),
  keyCase("o -> 9", "o", { key_code: "9" }, { henkan: true }),
  keyCase("shift+o -> ')'", "o", { key_code: "0", modifiers: ["left_shift"] }, { henkan: true, shift: true }),
  keyCase("p -> 0", "p", { key_code: "0" }, { henkan: true }),
  keyCase("shift+p -> 0", "p", { key_code: "0" }, { henkan: true, shift: true }),
  keyCase("a -> tab", "a", { key_code: "tab" }, { henkan: true }),
  keyCase("s -> escape", "s", { key_code: "escape" }, { henkan: true }),
  keyCase("d -> return", "d", { key_code: "return_or_enter" }, { henkan: true }),
  keyCase("f -> delete_or_backspace", "f", { key_code: "delete_or_backspace" }, { henkan: true }),
  keyCase("g -> delete_forward", "g", { key_code: "delete_forward" }, { henkan: true }),
  keyCase("h -> '@'", "h", { key_code: "2", modifiers: ["left_shift"] }, { henkan: true }),
  keyCase("shift+h -> '`'", "h", { key_code: "grave_accent_and_tilde" }, { henkan: true, shift: true }),
  keyCase("j -> '\\'", "j", { key_code: "backslash" }, { henkan: true }),
  keyCase("shift+j -> '_'", "j", { key_code: "hyphen", modifiers: ["left_shift"] }, { henkan: true, shift: true }),
  keyCase("k -> '['", "k", { key_code: "open_bracket" }, { henkan: true }),
  keyCase("l -> ']'", "l", { key_code: "close_bracket" }, { henkan: true }),
  keyCase("semicolon -> '\\'", "semicolon", { key_code: "backslash" }, { henkan: true }),
  keyCase("shift+semicolon -> '|'", "semicolon", { key_code: "backslash", modifiers: ["left_shift"] }, { henkan: true, shift: true }),
  keyCase("z -> left_arrow", "z", { key_code: "left_arrow" }, { henkan: true }),
  keyCase("x -> down_arrow", "x", { key_code: "down_arrow" }, { henkan: true }),
  keyCase("c -> up_arrow", "c", { key_code: "up_arrow" }, { henkan: true }),
  keyCase("v -> right_arrow", "v", { key_code: "right_arrow" }, { henkan: true }),
  keyCase("b -> x", "b", { key_code: "x" }, { henkan: true }),
  keyCase("n -> japanese_kana", "n", { key_code: "japanese_kana" }, { henkan: true }),
  keyCase("m -> japanese_eisuu", "m", { key_code: "japanese_eisuu" }, { henkan: true }),
  keyCase("comma -> cmd+left", "comma", { key_code: "left_arrow", modifiers: ["left_command"] }, { henkan: true }),
  keyCase("period -> cmd+right", "period", { key_code: "right_arrow", modifiers: ["left_command"] }, { henkan: true }),
  keyCase("slash -> '^'", "slash", { key_code: "6", modifiers: ["left_shift"] }, { henkan: true }),
  keyCase("shift+slash -> '~'", "slash", { key_code: "grave_accent_and_tilde", modifiers: ["left_shift"] }, { henkan: true, shift: true }),
]);

// ---------- TrackPoint Keyboard II: Dudrack neutral + henkan ----------

// Rides the same Dudrack layers as the built-in, selected via vendor/product.
expectKeyCases("tpkb2 neutral", [
  keyCase("q -> ':'", "q", { key_code: "semicolon", modifiers: ["left_shift"] }, { device: "tpkb2" }),
  keyCase("shift+q -> '*'", "q", { key_code: "8", modifiers: ["left_shift"] }, { device: "tpkb2", shift: true }),
  keyCase("w -> comma", "w", { key_code: "comma" }, { device: "tpkb2" }),
  keyCase("j -> h", "j", { key_code: "h" }, { device: "tpkb2" }),
  keyCase("k -> t", "k", { key_code: "t" }, { device: "tpkb2" }),
  // quote goes through Dudrack (-> hyphen), NOT the raw-JIS remap (-> ':').
  keyCase("quote -> hyphen (not raw JIS)", "quote", { key_code: "hyphen" }, { device: "tpkb2" }),
]);

expectKeyCases("tpkb2 henkan", [
  keyCase("q -> 1", "q", { key_code: "1" }, { device: "tpkb2", henkan: true }),
  keyCase("h -> '@'", "h", { key_code: "2", modifiers: ["left_shift"] }, { device: "tpkb2", henkan: true }),
  keyCase("k -> '['", "k", { key_code: "open_bracket" }, { device: "tpkb2", henkan: true }),
]);

// ---------- TrackPoint Keyboard II: JIS modifier keys ----------

expectKey("tpkb2 caps_lock -> left_control",
  { device: "tpkb2", key_code: "caps_lock" },
  { key_code: "left_control" });
expectKey("tpkb2 tab -> left_command",
  { device: "tpkb2", key_code: "tab" },
  { key_code: "left_command" });
expectKey("tpkb2 muhenkan (無変換) -> left_shift",
  { device: "tpkb2", key_code: "japanese_pc_nfer" },
  { key_code: "left_shift" });
expectKey("tpkb2 katakana/hiragana (カタカナひらがな) -> left_command",
  { device: "tpkb2", key_code: "japanese_pc_katakana" },
  { key_code: "left_command" });
expectKey("tpkb2 right_option (右Alt) disabled",
  { device: "tpkb2", key_code: "right_option" },
  { key_code: "vk_none" });

// 変換 (henkan) key holds the Henkan layer via the shared dudrack_henkan var.
const tpkbHenkan = findMatch({ device: "tpkb2", key_code: "japanese_pc_xfer" });
assert(tpkbHenkan && tpkbHenkan.to[0].set_variable &&
       tpkbHenkan.to[0].set_variable.name === "dudrack_henkan" &&
       tpkbHenkan.to[0].set_variable.value === 1,
       "tpkb2 henkan key sets dudrack_henkan=1");
assert(Array.isArray(tpkbHenkan.to_after_key_up) &&
       tpkbHenkan.to_after_key_up[0].set_variable.value === 0,
       "tpkb2 henkan key clears dudrack_henkan on release");

// The other external keyboard still gets the raw-JIS IME remap on 変換.
expectKey("external pc_xfer -> japanese_kana (unaffected by tpkb2)",
  { device: "external", key_code: "japanese_pc_xfer" },
  { key_code: "japanese_kana" });

// ---------- TrackPoint Keyboard II: option falls through to the layout ----------
//
// option+<key> hits the Neutral/Henkan rule for that physical key, and Karabiner
// forwards the option modifier at runtime. The harness models only the literal
// layout output, so option is not shown in the expected results below.

// physical 'j' under Dudrack -> Neutral 'h' (runtime: option+h = focus left).
expectKey("tpkb2 option+j -> Neutral 'h'",
  { device: "tpkb2", key_code: "j", modifiers: ["option"] },
  { key_code: "h" });
// physical 'q' + henkan -> Henkan '1' (runtime: option+1 = focus l2).
expectKey("tpkb2 option+q under henkan -> Henkan '1'",
  { device: "tpkb2", key_code: "q", modifiers: ["option"], variables: { dudrack_henkan: 1 } },
  { key_code: "1" });
// physical 'x' hits the Neutral 'q' rule.
expectKey("tpkb2 option+x -> Neutral 'q'",
  { device: "tpkb2", key_code: "x", modifiers: ["option"] },
  { key_code: "q" });
// Henkan still wins over Neutral for the same physical key: 'c' is Neutral 'j'
// but Henkan 'up_arrow'.
expectKey("tpkb2 option+c without henkan -> Neutral 'j'",
  { device: "tpkb2", key_code: "c", modifiers: ["option"] },
  { key_code: "j" });
const cHenkan = findMatch({
  device: "tpkb2", key_code: "c",
  modifiers: ["option", "shift"], variables: { dudrack_henkan: 1 },
});
assert(cHenkan && cHenkan.to[0].key_code === "up_arrow",
       "tpkb2 option+shift+c under henkan -> Henkan up_arrow");
// Built-in behaves identically (the layers live in the shared DUDRACK scope).
const cHenkanBuiltin = findMatch({
  device: "builtin", key_code: "c",
  modifiers: ["option"], variables: { dudrack_henkan: 1 },
});
assert(cHenkanBuiltin && cHenkanBuiltin.to[0].key_code === "up_arrow",
       "builtin option+c under henkan -> Henkan up_arrow");

// ---------- disable Cmd+H (both keyboards) ----------

// Dudrack: physical 'j' yields 'h', so cmd+j is swallowed -- but only outside
// Henkan, where 'j' is '\' and must pass through.
const cmdJBuiltin = findMatch({ device: "builtin", key_code: "j", modifiers: ["command"] });
assert(cmdJBuiltin && cmdJBuiltin.to[0].key_code === "vk_none",
       "builtin cmd+j (post-conversion cmd+h) is swallowed");
const cmdJTpkb = findMatch({ device: "tpkb2", key_code: "j", modifiers: ["command"] });
assert(cmdJTpkb && cmdJTpkb.to[0].key_code === "vk_none",
       "tpkb2 cmd+j (post-conversion cmd+h) is swallowed");
const cmdJHenkan = findMatch({
  device: "builtin", key_code: "j",
  modifiers: ["command"], variables: { dudrack_henkan: 1 },
});
assert(cmdJHenkan && cmdJHenkan.to[0].key_code === "backslash",
       "builtin cmd+j under Henkan stays '\\' (not swallowed)");
// Cmd+Opt+H (Hide Others) is swallowed too (option is optional in the rule).
const cmdOptJBuiltin = findMatch({ device: "builtin", key_code: "j", modifiers: ["command", "option"] });
assert(cmdOptJBuiltin && cmdOptJBuiltin.to[0].key_code === "vk_none",
       "builtin cmd+option+j (Hide Others) is swallowed");
// External raw-JIS: 'h' is physical 'h'.
const cmdHExternal = findMatch({ device: "external", key_code: "h", modifiers: ["command"] });
assert(cmdHExternal && cmdHExternal.to[0].key_code === "vk_none",
       "external cmd+h is swallowed");
const cmdOptHExternal = findMatch({ device: "external", key_code: "h", modifiers: ["command", "option"] });
assert(cmdOptHExternal && cmdOptHExternal.to[0].key_code === "vk_none",
       "external cmd+option+h (Hide Others) is swallowed");
// option+j (no command) is unaffected by the cmd+h guard: it hits Neutral 'h'.
expectKey("builtin option+j -> Neutral 'h' (not the cmd+h guard)",
  { device: "builtin", key_code: "j", modifiers: ["option"] },
  { key_code: "h" });

// Built-in: both command keys held while reaching for '@' would surface as
// option+shift+2 (left_command -> option plus the Henkan '@' = shift+2), which
// collides with the external handler's "send window to workspace" chord. Option-contaminated
// physical 'h' under Henkan is swallowed so the misfire is a no-op.
const optHHenkan = findMatch({
  device: "builtin", key_code: "h",
  modifiers: ["option"], variables: { dudrack_henkan: 1 },
});
assert(optHHenkan && optHHenkan.to[0].key_code === "vk_none",
       "builtin option+h under Henkan is swallowed (no stray workspace move)");
const optShiftHHenkan = findMatch({
  device: "builtin", key_code: "h",
  modifiers: ["option", "shift"], variables: { dudrack_henkan: 1 },
});
assert(optShiftHHenkan && optShiftHHenkan.to[0].key_code === "vk_none",
       "builtin option+shift+h under Henkan is swallowed");
// '@' via Right Command + 'h' alone (no option contamination) still types.
expectKey("builtin h under Henkan (no option) still -> '@'",
  { device: "builtin", key_code: "h", variables: { dudrack_henkan: 1 } },
  { key_code: "2", modifiers: ["left_shift"] });
// Outside Henkan, option+h is unaffected (falls through to the Neutral layer).
expectKey("builtin option+h outside Henkan still -> 'd' (Neutral)",
  { device: "builtin", key_code: "h", modifiers: ["option"] },
  { key_code: "d" });

// ---------- home/end -> cmd+left/right (both devices) ----------

expectKey("builtin home -> cmd+left",
  { device: "builtin", key_code: "home" },
  { key_code: "left_arrow", modifiers: ["left_command"] });
expectKey("builtin end -> cmd+right",
  { device: "builtin", key_code: "end" },
  { key_code: "right_arrow", modifiers: ["left_command"] });
expectKey("external home -> cmd+left",
  { device: "external", key_code: "home" },
  { key_code: "left_arrow", modifiers: ["left_command"] });
expectKey("external end -> cmd+right",
  { device: "external", key_code: "end" },
  { key_code: "right_arrow", modifiers: ["left_command"] });
expectKey("shift+home -> shift+cmd+left (passthrough)",
  { device: "external", key_code: "home", modifiers: ["shift"] },
  { key_code: "left_arrow", modifiers: ["left_command"] });

// ---------- option passthrough to the layout ----------
// option+<key> hits the layout rule for that physical key; Karabiner forwards
// the option modifier at runtime. The harness shows only the literal layout
// output (option not shown). A window manager binds option+<layout output>.

// built-in physical 'j' -> Neutral 'h' (runtime option+h = focus left).
expectKey("builtin option+j -> Neutral 'h'",
  { device: "builtin", key_code: "j", modifiers: ["option"] },
  { key_code: "h" });

// external 'h' has no remap, so option+h passes straight through to macOS
// (runtime option+h = focus left); Karabiner adds no rule.
expectNone("external option+h passes through (no rule)",
  { device: "external", key_code: "h", modifiers: ["option"] });

// colon: built-in physical 'q' -> Neutral ':' (= shift+semicolon); runtime
// option+shift+semicolon = "focus l1".
expectKey("builtin option+q without henkan -> Neutral ':' (shift+semicolon)",
  { device: "builtin", key_code: "q", modifiers: ["option"] },
  { key_code: "semicolon", modifiers: ["left_shift"] });

// colon under henkan: physical 'q' -> Henkan '1'; runtime option+1 = "focus l2".
expectKey("builtin option+q under henkan -> Henkan '1'",
  { device: "builtin", key_code: "q", modifiers: ["option"], variables: { dudrack_henkan: 1 } },
  { key_code: "1" });

// colon on external: physical 'quote' -> JIS ':' (= shift+semicolon); runtime
// option+shift+semicolon = "focus l1". The JIS remap applies under option.
expectKey("external option+quote -> JIS ':' (shift+semicolon)",
  { device: "external", key_code: "quote", modifiers: ["option"] },
  { key_code: "semicolon", modifiers: ["left_shift"] });

// colon move on external: physical shift+'quote' -> JIS '*' (= shift+8); runtime
// option+shift+8 = "move-to l1" (the asymmetric focus/move pair for the colon key).
expectKey("external option+shift+quote -> JIS '*' (shift+8)",
  { device: "external", key_code: "quote", modifiers: ["option", "shift"] },
  { key_code: "8", modifiers: ["left_shift"] });

// toggle-float: physical 'd' + shift under henkan -> Henkan 'return_or_enter';
// runtime option+shift+return. The layout emits the key_code `return_or_enter`
// (the literal "return" is not a key_code macOS turns into the Return keycode).
expectKey("builtin option+shift+d under henkan -> Henkan 'return_or_enter'",
  { device: "builtin", key_code: "d", modifiers: ["option", "shift"], variables: { dudrack_henkan: 1 } },
  { key_code: "return_or_enter" });

// ---------- unbound option+key passes through ----------

// external 'x' has no remap, so option+x reaches macOS untouched (Karabiner adds
// no rule; its option-layer dead-key is handled at the input-source / .keylayout
// level).
expectNone("external option+x passes through (no rule)",
  { device: "external", key_code: "x", modifiers: ["option"] });

// built-in option+x hits the Neutral 'q' rule (runtime option+q).
expectKey("builtin option+x -> Neutral 'q'",
  { device: "builtin", key_code: "x", modifiers: ["option"] },
  { key_code: "q" });

// ---------- built-in keys not handled (pass-through) ----------

expectNone("builtin backslash untouched (no rule)",
  { device: "builtin", key_code: "backslash" });

// ---------- right-command sets dudrack_henkan variable ----------

const rcmd = findMatch({ device: "builtin", key_code: "right_command" });
assert(rcmd && rcmd.to[0].set_variable &&
       rcmd.to[0].set_variable.name === "dudrack_henkan" &&
       rcmd.to[0].set_variable.value === 1,
       "builtin right_command sets dudrack_henkan=1");
assert(Array.isArray(rcmd.to_after_key_up) &&
       rcmd.to_after_key_up[0].set_variable.value === 0,
       "builtin right_command clears dudrack_henkan on release");

// ----------

if (fails > 0) {
  console.error(`\n${fails} failure(s)`);
  process.exit(1);
}
console.log(`OK (${rule.manipulators.length} manipulators)`);
