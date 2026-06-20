// Source for the sole `eval_js` complex_modifications rule in karabiner.json.
// Karabiner-Elements evaluates this with Duktape (ES5) and uses the returned
// object as a single complex_modifications rule.
//
// Run `make karabiner` after editing to re-embed this file into karabiner.json.
//
// Device scopes (see definitions below): BUILTIN, DUDRACK (built-in + the
// Lenovo TrackPoint Keyboard II), EXTERNAL (other external keyboards), and
// TPKB2_ONLY (the TrackPoint Keyboard II alone). The TrackPoint Keyboard II is
// a plain JIS QWERTY keyboard typed in Dudrack just like the built-in, so it
// rides the Dudrack Neutral/Henkan layers and is excluded from the raw-JIS
// external remaps.
//
// Sections (manipulator order matters -- first match wins within the rule):
//   1. Modifier remaps: Caps -> Control and Tab -> Command (Dudrack scope:
//      built-in + TrackPoint Keyboard II); built-in-only (L Cmd/L Opt/Fn/R Cmd/
//      Space SandS); and TrackPoint Keyboard II (変換 -> Henkan layer, 無変換 ->
//      Shift, カタカナひらがな -> Cmd, 右Alt disabled).
//   2. Disable Cmd+H / Cmd+Opt+H (Hide / Hide Others, both keyboards), caught
//      on the post-conversion 'h' key.
//   3. Dudrack Henkan layer (Dudrack scope, while the Henkan key is held).
//   4. Dudrack Neutral Dvorak layer (Dudrack scope, always).
//   5. External keyboard remaps (PC-JIS IME keys and JIS label behavior).
//   6. Home/End -> Cmd+Left/Right (both keyboards, macOS line-nav).
//
// Karabiner only reproduces the JIS-Dvorak layout; modifiers pass straight
// through, so `option+<phys key>` emits `option+<layout output>` (e.g. built-in
// physical 'j' -> option+h, physical 'q' -> option+shift+;). A window-manager
// hot key handler binds those chords directly. An unbound `option+<key>` reaches
// macOS untouched; its option-layer dead-keys are handled at the input-source /
// .keylayout level.

(function () {
  // Character -> ANSI keycode combination. Used by the Dudrack layers and the
  // external-JIS remap to emit specific characters.
  //
  // virtual_hid_keyboard.keyboard_type_v2 is set to "ansi" (not "jis") because
  // on JIS Karabiner aliases the US-ANSI `backslash` scancode (HID 0x31) to
  // the JIS `]` position, so emitting `backslash` produces `]` and ctrl+`\\`
  // is unreachable. With "ansi" + the macOS "ABC" input source, `backslash`
  // emits `\\` natively and ctrl+`\\` works. The trade-off is that the external
  // PC-JIS keyboard's keys no longer emit their JIS labels by default; that
  // is restored explicitly in the external-JIS remap section below.
  var CHAR_TO_KEYSTROKE = {
    "\"": { key_code: "quote",               shift: true },
    "'":  { key_code: "quote"                             },
    "&":  { key_code: "7",                   shift: true },
    "(":  { key_code: "9",                   shift: true },
    ")":  { key_code: "0",                   shift: true },
    "=":  { key_code: "equal_sign"                        },
    "~":  { key_code: "grave_accent_and_tilde", shift: true },
    "^":  { key_code: "6",                   shift: true },
    "`":  { key_code: "grave_accent_and_tilde"            },
    "@":  { key_code: "2",                   shift: true },
    "{":  { key_code: "open_bracket",        shift: true },
    "[":  { key_code: "open_bracket"                      },
    "}":  { key_code: "close_bracket",       shift: true },
    "]":  { key_code: "close_bracket"                     },
    "+":  { key_code: "equal_sign",          shift: true },
    "*":  { key_code: "8",                   shift: true },
    ":":  { key_code: "semicolon",           shift: true },
    "_":  { key_code: "hyphen",              shift: true },
    "\\": { key_code: "backslash"                         },
    "|":  { key_code: "backslash",           shift: true }
  };

  // Lenovo TrackPoint Keyboard II (Bluetooth). A plain JIS QWERTY keyboard the
  // user types in Dudrack, exactly like the built-in keyboard.
  var TPKB2 = { vendor_id: 6127, product_id: 24801 };

  var BUILTIN  = { type: "device_if",     identifiers: [{ is_built_in_keyboard: true }] };
  // Dudrack scope: built-in OR TrackPoint Keyboard II. `device_if` identifiers
  // are OR'd, so this matches either keyboard. Drives the Neutral/Henkan layers
  // (and therefore the Dudrack-side option chords, which fall out of those
  // layers via modifier passthrough).
  var DUDRACK  = { type: "device_if",     identifiers: [{ is_built_in_keyboard: true }, TPKB2] };
  // Raw-JIS external scope: every external keyboard EXCEPT the TrackPoint
  // Keyboard II. `device_unless` identifiers are NONE-of, so this excludes both
  // the built-in and the TrackPoint Keyboard II. Drives the PC-JIS label and
  // IME-key remaps.
  var EXTERNAL = { type: "device_unless", identifiers: [{ is_built_in_keyboard: true }, TPKB2] };
  // TrackPoint Keyboard II alone: used for its dedicated JIS modifier keys.
  var TPKB2_ONLY = { type: "device_if",   identifiers: [TPKB2] };
  var ANY_MODS = { optional: ["any"] };

  function keyStroke(name, shift) {
    var o = { key_code: name };
    if (shift) o.shift = true;
    return o;
  }

  function charKey(ch) {
    requireMapKey(CHAR_TO_KEYSTROKE, "CHAR_TO_KEYSTROKE", ch);
    return CHAR_TO_KEYSTROKE[ch];
  }

  function toKeyEntry(spec) {
    var toEntry = { key_code: spec.key_code };
    var toMods = [];
    if (spec.shift)   toMods.push("left_shift");
    if (spec.option)  toMods.push("left_option");
    if (spec.command) toMods.push("left_command");
    if (toMods.length) toEntry.modifiers = toMods;
    return toEntry;
  }

  function requireMapKey(map, mapName, key) {
    if (!Object.prototype.hasOwnProperty.call(map, key)) {
      throw new Error(mapName + " is missing key: " + key);
    }
  }

  var manipulators = [];

  // ============================================================
  // 1. Modifier remaps (built-in, then TrackPoint Keyboard II)
  // ============================================================

  function builtinRemap(fromKey, toKey) {
    return {
      type: "basic",
      conditions: [BUILTIN],
      from: { key_code: fromKey, modifiers: ANY_MODS },
      to: [{ key_code: toKey }]
    };
  }

  // Caps Lock -> Control and Tab -> Command on every Dudrack keyboard (built-in
  // + TrackPoint Keyboard II). The remaining swaps below are MacBook-physical-
  // specific and stay built-in only.
  manipulators.push({
    type: "basic",
    conditions: [DUDRACK],
    from: { key_code: "caps_lock", modifiers: ANY_MODS },
    to: [{ key_code: "left_control" }]
  });
  manipulators.push({
    type: "basic",
    conditions: [DUDRACK],
    from: { key_code: "tab", modifiers: ANY_MODS },
    to: [{ key_code: "left_command" }]
  });
  manipulators.push(builtinRemap("left_command", "left_option"));
  manipulators.push(builtinRemap("left_option",  "left_command"));
  manipulators.push(builtinRemap("fn",           "left_command"));

  // SandS (Space and Shift): hold space as shift, tap space outputs space.
  // Built-in only; the external PC-JIS keyboard keeps space as space.
  //
  // `lazy: true` on left_shift means the modifier is set internally but the
  // shift key event is not emitted to the OS until another non-modifier key
  // needs it, so tapping space alone fires `to_if_alone` without producing a
  // stray shift down/up.
  //
  // Rationale: the previous left_command -> left_shift remap left the user
  // unable to type ~ via left_cmd + right_cmd + slash on the built-in
  // keyboard because pressing both command keys triggers NKRO ghosting on
  // MacBook keyboards and the slash press is never reported by the hardware.
  manipulators.push({
    type: "basic",
    conditions: [BUILTIN],
    from: { key_code: "spacebar", modifiers: ANY_MODS },
    to: [{ key_code: "left_shift", lazy: true }],
    to_if_alone: [{ key_code: "spacebar" }]
  });

  // Right Command activates the Henkan layer while held.
  manipulators.push({
    type: "basic",
    conditions: [BUILTIN],
    from: { key_code: "right_command", modifiers: ANY_MODS },
    to: [{ set_variable: { name: "dudrack_henkan", value: 1 } }],
    to_after_key_up: [{ set_variable: { name: "dudrack_henkan", value: 0 } }]
  });

  // TrackPoint Keyboard II modifier keys. Caps Lock -> Control and Tab ->
  // Command are shared via the Dudrack scope above; the other built-in remaps
  // are MacBook-specific and excluded. This keyboard's JIS thumb keys carry the
  // rest:
  //   - 変換 (japanese_pc_xfer)   -> hold to activate the Henkan layer (the
  //     built-in uses Right Command; this keyboard has a real 変換 key).
  //   - 無変換 (japanese_pc_nfer) -> Shift.
  //   - カタカナひらがな (japanese_pc_katakana) -> Command.
  // And Right Option / 右Alt (right_option) is disabled (vk_none) to avoid
  // accidental presses.
  // The same dudrack_henkan variable is shared, so the Henkan layer (section 3)
  // fires for this keyboard too.
  manipulators.push({
    type: "basic",
    conditions: [TPKB2_ONLY],
    from: { key_code: "japanese_pc_xfer", modifiers: ANY_MODS },
    to: [{ set_variable: { name: "dudrack_henkan", value: 1 } }],
    to_after_key_up: [{ set_variable: { name: "dudrack_henkan", value: 0 } }]
  });
  manipulators.push({
    type: "basic",
    conditions: [TPKB2_ONLY],
    from: { key_code: "japanese_pc_nfer", modifiers: ANY_MODS },
    to: [{ key_code: "left_shift" }]
  });
  manipulators.push({
    type: "basic",
    conditions: [TPKB2_ONLY],
    from: { key_code: "japanese_pc_katakana", modifiers: ANY_MODS },
    to: [{ key_code: "left_command" }]
  });
  manipulators.push({
    type: "basic",
    conditions: [TPKB2_ONLY],
    from: { key_code: "right_option", modifiers: ANY_MODS },
    to: [{ key_code: "vk_none" }]
  });

  // ============================================================
  // 2. Disable Cmd+H / Cmd+Opt+H (Hide / Hide Others, both keyboards)
  // ============================================================
  //
  // Cmd+H (Hide) and Cmd+Opt+H (Hide Others) hide windows, which the user
  // triggers by accident. Karabiner does not re-process its own output, so this
  // catches the *physical* key that yields 'h' after layout conversion, while
  // command is held (option optional, covering Hide Others):
  //   - Dudrack scope (built-in + TrackPoint Keyboard II): physical 'j' -> 'h'
  //     in the Neutral layer. Guarded by `variable_unless dudrack_henkan` so it
  //     only fires outside Henkan, where 'j' is '\' (not 'h').
  //   - External raw-JIS: 'h' is physical 'h'.
  // `option` is in the optional list (not mandatory) so plain Cmd+H matches too,
  // while plain alt+key (no command) still falls through to the Neutral/Henkan
  // layers.
  // Must precede the Neutral layer (section 4) so it wins the physical-'j' match.

  manipulators.push({
    type: "basic",
    conditions: [{ type: "variable_unless", name: "dudrack_henkan", value: 1 }, DUDRACK],
    from: { key_code: "j", modifiers: { mandatory: ["command"], optional: ["caps_lock", "option"] } },
    to: [{ key_code: "vk_none" }]
  });
  manipulators.push({
    type: "basic",
    conditions: [EXTERNAL],
    from: { key_code: "h", modifiers: { mandatory: ["command"], optional: ["caps_lock", "option"] } },
    to: [{ key_code: "vk_none" }]
  });

  // Built-in keyboard: neutralize the misfire where both physical command keys
  // are held while reaching for '@'. left_command -> left_option leaks `option`,
  // and the Henkan layer turns physical 'h' into '@' (= shift+2), so the chord
  // surfaces as option+shift+2 -- which collides with the external handler's
  // "send window to a workspace" chord and flings the focused window off to
  // another workspace.
  // Swallow option-contaminated physical 'h' under Henkan so the stray chord is
  // a no-op; '@' typed via Right Command + 'h' alone (no option) is untouched.
  // Must precede the Henkan layer (section 3) so it wins the physical-'h' match.
  manipulators.push({
    type: "basic",
    conditions: [{ type: "variable_if", name: "dudrack_henkan", value: 1 }, BUILTIN],
    from: { key_code: "h", modifiers: { mandatory: ["option"], optional: ["caps_lock", "shift"] } },
    to: [{ key_code: "vk_none" }]
  });

  // ============================================================
  // 3. Dudrack Henkan layer
  // ============================================================
  //
  // Symbol outputs flow through CHAR_TO_KEYSTROKE so the ANSI virtual HID
  // emits the intended characters. Shifted variants must come before
  // unshifted because Karabiner picks the first matching manipulator and
  // unshifted uses `optional: any`.

  function layerManip(conditions, entry, shiftedOptionalMods) {
    var fromMods = entry.shift
      ? { mandatory: ["shift"], optional: shiftedOptionalMods }
      : ANY_MODS;
    return {
      type: "basic",
      conditions: conditions,
      from: { key_code: entry.from, modifiers: fromMods },
      to: [toKeyEntry(entry.to)]
    };
  }

  var HENKAN = [
    { from: "q",         shift: false, to: keyStroke("1") },
    { from: "w",         shift: true,  to: charKey("\"") },
    { from: "w",         shift: false, to: keyStroke("2") },
    { from: "e",         shift: false, to: keyStroke("3") },
    { from: "r",         shift: false, to: keyStroke("4") },
    { from: "t",         shift: false, to: keyStroke("5") },
    { from: "y",         shift: true,  to: charKey("&") },
    { from: "y",         shift: false, to: keyStroke("6") },
    { from: "u",         shift: true,  to: charKey("'") },
    { from: "u",         shift: false, to: keyStroke("7") },
    { from: "i",         shift: true,  to: charKey("(") },
    { from: "i",         shift: false, to: keyStroke("8") },
    { from: "o",         shift: true,  to: charKey(")") },
    { from: "o",         shift: false, to: keyStroke("9") },
    { from: "p",         shift: true,  to: keyStroke("0") },
    { from: "p",         shift: false, to: keyStroke("0") },
    { from: "a",         shift: false, to: keyStroke("tab") },
    { from: "s",         shift: false, to: keyStroke("escape") },
    { from: "d",         shift: false, to: keyStroke("return_or_enter") },
    { from: "f",         shift: false, to: keyStroke("delete_or_backspace") },
    { from: "g",         shift: false, to: keyStroke("delete_forward") },
    { from: "h",         shift: true,  to: charKey("`") },
    { from: "h",         shift: false, to: charKey("@") },
    { from: "j",         shift: true,  to: charKey("_") },
    { from: "j",         shift: false, to: charKey("\\") },
    { from: "k",         shift: false, to: charKey("[") },
    { from: "l",         shift: false, to: charKey("]") },
    { from: "semicolon", shift: true,  to: charKey("|") },
    { from: "semicolon", shift: false, to: charKey("\\") },
    { from: "z",         shift: false, to: keyStroke("left_arrow") },
    { from: "x",         shift: false, to: keyStroke("down_arrow") },
    { from: "c",         shift: false, to: keyStroke("up_arrow") },
    { from: "v",         shift: false, to: keyStroke("right_arrow") },
    { from: "b",         shift: false, to: keyStroke("x") },
    { from: "n",         shift: false, to: keyStroke("japanese_kana") },
    { from: "m",         shift: false, to: keyStroke("japanese_eisuu") },
    { from: "comma",     shift: false, to: { key_code: "left_arrow",  command: true } },
    { from: "period",    shift: false, to: { key_code: "right_arrow", command: true } },
    { from: "slash",     shift: true,  to: charKey("~") },
    { from: "slash",     shift: false, to: charKey("^") }
  ];

  var henkanConds = [{ type: "variable_if", name: "dudrack_henkan", value: 1 }, DUDRACK];
  var HENKAN_SHIFT_OPTIONAL_MODS = ["caps_lock", "command", "control", "option"];
  for (var ih = 0; ih < HENKAN.length; ih++) {
    manipulators.push(layerManip(henkanConds, HENKAN[ih], HENKAN_SHIFT_OPTIONAL_MODS));
  }

  // ============================================================
  // 4. Dudrack Neutral Dvorak layer
  // ============================================================
  //
  // Neutral rules come after Henkan rules so the Henkan key can override the
  // same physical keys while the Henkan variable is set.

  var NEUTRAL = [
    { from: "q",            shift: true,  to: charKey("*") },
    { from: "q",            shift: false, to: charKey(":") },
    { from: "w",            shift: false, to: keyStroke("comma") },
    { from: "e",            shift: false, to: keyStroke("period") },
    { from: "r",            shift: false, to: keyStroke("p") },
    { from: "t",            shift: false, to: keyStroke("y") },
    { from: "y",            shift: false, to: keyStroke("f") },
    { from: "u",            shift: false, to: keyStroke("g") },
    { from: "i",            shift: false, to: keyStroke("c") },
    { from: "o",            shift: false, to: keyStroke("r") },
    { from: "p",            shift: false, to: keyStroke("l") },
    { from: "open_bracket", shift: false, to: keyStroke("slash") },
    { from: "a",            shift: false, to: keyStroke("a") },
    { from: "s",            shift: false, to: keyStroke("o") },
    { from: "d",            shift: false, to: keyStroke("e") },
    { from: "f",            shift: false, to: keyStroke("u") },
    { from: "g",            shift: false, to: keyStroke("i") },
    { from: "h",            shift: false, to: keyStroke("d") },
    { from: "j",            shift: false, to: keyStroke("h") },
    { from: "k",            shift: false, to: keyStroke("t") },
    { from: "l",            shift: false, to: keyStroke("n") },
    { from: "semicolon",    shift: false, to: keyStroke("s") },
    { from: "quote",        shift: true,  to: charKey("=") },
    { from: "quote",        shift: false, to: keyStroke("hyphen") },
    { from: "z",            shift: true,  to: charKey("+") },
    { from: "z",            shift: false, to: keyStroke("semicolon") },
    { from: "x",            shift: false, to: keyStroke("q") },
    { from: "c",            shift: false, to: keyStroke("j") },
    { from: "v",            shift: false, to: keyStroke("k") },
    { from: "b",            shift: false, to: keyStroke("x") },
    { from: "n",            shift: false, to: keyStroke("b") },
    { from: "m",            shift: false, to: keyStroke("m") },
    { from: "comma",        shift: false, to: keyStroke("w") },
    { from: "period",       shift: false, to: keyStroke("v") },
    { from: "slash",        shift: false, to: keyStroke("z") }
  ];

  var NEUTRAL_SHIFT_OPTIONAL_MODS = ["any"];
  for (var iN = 0; iN < NEUTRAL.length; iN++) {
    manipulators.push(layerManip([DUDRACK], NEUTRAL[iN], NEUTRAL_SHIFT_OPTIONAL_MODS));
  }

  // ============================================================
  // 5. External keyboard remaps
  // ============================================================

  // PC-JIS IME keys -> Apple-JIS Eisuu/Kana. Some Windows JIS keyboards on
  // macOS deliver 変換 as grave_accent_and_tilde (HID 0x35) due to driver
  // mangling, so capture that too.
  var IME_KEYS = [
    ["japanese_pc_nfer",       "japanese_eisuu"],
    ["japanese_pc_xfer",       "japanese_kana"],
    ["grave_accent_and_tilde", "japanese_kana"]
  ];
  for (var im = 0; im < IME_KEYS.length; im++) {
    manipulators.push({
      type: "basic",
      conditions: [EXTERNAL],
      from: { key_code: IME_KEYS[im][0], modifiers: ANY_MODS },
      to: [{ key_code: IME_KEYS[im][1] }]
    });
  }

  // External PC-JIS keyboard: remap each key whose JIS label differs from the
  // ANSI label (or that has no ANSI counterpart) so the keyboard behaves per
  // its JIS labels. virtual_hid_keyboard is "ansi", so without these the JIS
  // keys would emit ANSI characters at the same scancode position.
  // Entry shape: { from, shift, to }.
  // Order within the table doesn't matter: shifted entries use mandatory
  // shift; unshifted entries' optional list excludes shift, so the two never
  // overlap. `option` is in the optional list, so the JIS remap also applies
  // under option (e.g. option+quote -> option+`:`), reproducing the layout
  // faithfully under any modifier.
  var JIS_EXTERNAL = [
    // Number row -- shifted symbols differ from ANSI.
    { from: "2",              shift: true,  to: charKey("\"") },
    { from: "6",              shift: true,  to: charKey("&") },
    { from: "7",              shift: true,  to: charKey("'") },
    { from: "8",              shift: true,  to: charKey("(") },
    { from: "9",              shift: true,  to: charKey(")") },
    // Hyphen / equal-sign area. JIS: -/= and ^/~.
    { from: "hyphen",         shift: true,  to: keyStroke("equal_sign") },
    { from: "equal_sign",     shift: true,  to: charKey("~") },
    { from: "equal_sign",     shift: false, to: charKey("^") },
    // Bracket area. JIS: @/`, [/{, ]/}.
    { from: "open_bracket",   shift: true,  to: charKey("`") },
    { from: "open_bracket",   shift: false, to: charKey("@") },
    { from: "close_bracket",  shift: true,  to: charKey("{") },
    { from: "close_bracket",  shift: false, to: charKey("[") },
    // JIS `]/}` is HID 0x32 (non_us_pound) on most keyboards, but some report
    // it as HID 0x31 (backslash). Cover both so either physical wiring works.
    { from: "non_us_pound",   shift: true,  to: charKey("}") },
    { from: "non_us_pound",   shift: false, to: charKey("]") },
    { from: "backslash",      shift: true,  to: charKey("}") },
    { from: "backslash",      shift: false, to: charKey("]") },
    // Semicolon / quote row. JIS: ;/+, :/*.
    { from: "semicolon",      shift: true,  to: charKey("+") },
    { from: "quote",          shift: true,  to: charKey("*") },
    { from: "quote",          shift: false, to: charKey(":") },
    // JIS-only keys absent from ANSI:
    //   - "_\\" (international1) -> \ / _ per JIS label
    //   - "￥|" (international3) -> ANSI backslash key behavior (\ / |)
    { from: "international1", shift: true,  to: charKey("_") },
    { from: "international1", shift: false, to: charKey("\\") },
    { from: "international3", shift: true,  to: charKey("|") },
    { from: "international3", shift: false, to: charKey("\\") }
  ];

  function jisExternalManip(entry) {
    var fromMods = entry.shift
      ? { mandatory: ["shift"], optional: ["caps_lock", "control", "command", "option"] }
      : { optional: ["caps_lock", "control", "command", "option"] };
    return {
      type: "basic",
      conditions: [EXTERNAL],
      from: { key_code: entry.from, modifiers: fromMods },
      to: [toKeyEntry(entry.to)]
    };
  }

  for (var ij = 0; ij < JIS_EXTERNAL.length; ij++) {
    manipulators.push(jisExternalManip(JIS_EXTERNAL[ij]));
  }

  // ============================================================
  // 6. Home/End -> Cmd+Left/Right (both keyboards)
  // ============================================================
  //
  // macOS uses Cmd+Left/Right for line navigation; the bare Home/End keys are
  // app-dependent (often "scroll to top/bottom" rather than "beginning/end of
  // line"). Remap them globally so they always mean line-nav, with extra
  // modifiers (e.g. shift for selection) passed through.

  manipulators.push({
    type: "basic",
    from: { key_code: "home", modifiers: ANY_MODS },
    to: [{ key_code: "left_arrow", modifiers: ["left_command"] }]
  });
  manipulators.push({
    type: "basic",
    from: { key_code: "end", modifiers: ANY_MODS },
    to: [{ key_code: "right_arrow", modifiers: ["left_command"] }]
  });

  return {
    description: "Custom rules: Dudrack JIS-Dvorak + external JIS",
    manipulators: manipulators
  };
})();
