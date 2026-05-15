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

function deviceOK(conds, device) {
  for (const c of conds || []) {
    if (c.type === "device_if" && c.identifiers && c.identifiers[0].is_built_in_keyboard)
      return device === "builtin";
    if (c.type === "device_unless" && c.identifiers && c.identifiers[0].is_built_in_keyboard)
      return device === "external";
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

function expectShell(label, ev, substr) {
  const m = findMatch(ev);
  if (!m) { assert(false, `${label}: no rule matched`); return; }
  const cmd = (m.to && m.to[0] && m.to[0].shell_command) || "";
  assert(cmd.indexOf(substr) !== -1, `${label}: expected shell containing "${substr}", got "${cmd}"`);
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
expectKey("builtin left_command -> left_shift",
  { device: "builtin", key_code: "left_command" },
  { key_code: "left_shift" });

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
  keyCase("comma -> home", "comma", { key_code: "home" }, { henkan: true }),
  keyCase("period -> end", "period", { key_code: "end" }, { henkan: true }),
  keyCase("slash -> '^'", "slash", { key_code: "6", modifiers: ["left_shift"] }, { henkan: true }),
  keyCase("shift+slash -> '~'", "slash", { key_code: "grave_accent_and_tilde", modifiers: ["left_shift"] }, { henkan: true, shift: true }),
]);

// ---------- komorebi shell commands ----------

// dudrackInverse.h = "j": physical 'j' on built-in = whkd 'h' = "focus left".
expectShell("builtin alt+j -> komorebic focus left",
  { device: "builtin", key_code: "j", modifiers: ["option"] },
  "focus left");

// externalKey.h = "h": physical 'h' on external = "focus left".
expectShell("external alt+h -> komorebic focus left",
  { device: "external", key_code: "h", modifiers: ["option"] },
  "focus left");

// Henkan-aware komorebi: physical 'q' with option+henkan = whkd '1' = "focus-named-workspace l2".
expectShell("builtin alt+q under henkan -> focus-named-workspace l2",
  { device: "builtin", key_code: "q", modifiers: ["option"], variables: { dudrack_henkan: 1 } },
  "focus-named-workspace l2");

// Without henkan, same physical 'q' (whkd ':') = "focus-named-workspace l1".
expectShell("builtin alt+q without henkan -> focus-named-workspace l1",
  { device: "builtin", key_code: "q", modifiers: ["option"] },
  "focus-named-workspace l1");

// Shifted komorebi: alt+shift+h on external -> "move left".
expectShell("external alt+shift+h -> komorebic move left",
  { device: "external", key_code: "h", modifiers: ["option", "shift"] },
  "move left");

// ---------- alt suppress ----------

// 'x' has no whkd binding, so external alt+x should be swallowed.
const altX = findMatch({ device: "external", key_code: "x", modifiers: ["option"] });
assert(altX && altX.to && altX.to[0].key_code === "vk_none", "external alt+x -> vk_none");

// Built-in keyboards do not suppress (they have Dudrack output instead).
const altXBuiltin = findMatch({ device: "builtin", key_code: "x", modifiers: ["option"] });
assert(!altXBuiltin || altXBuiltin.to[0].key_code !== "vk_none",
       "builtin alt+x is not suppressed");

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
