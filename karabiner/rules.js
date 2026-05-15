// Source for the sole `eval_js` complex_modifications rule in karabiner.json.
// Karabiner-Elements evaluates this with Duktape (ES5) and uses the returned
// object as a single complex_modifications rule.
//
// Run `make karabiner` after editing to re-embed this file into karabiner.json.
//
// Sections (manipulator order matters -- first match wins within the rule):
//   1. Komorebi shortcuts (option + key, both keyboards).
//   2. Built-in keyboard modifier remaps (Caps/Tab/L Cmd/R Cmd).
//   3. Dudrack Henkan layer (built-in, while Right Command is held).
//   4. Dudrack Neutral Dvorak layer (built-in, always).
//   5. External keyboard remaps (PC-JIS IME keys and JIS label behavior).
//   6. External: swallow unbound alt+key to block macOS option dead-keys.

(function () {
  var KOMOREBIC = "/opt/homebrew/bin/komorebic";

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

  var BUILTIN  = { type: "device_if",     identifiers: [{ is_built_in_keyboard: true }] };
  var EXTERNAL = { type: "device_unless", identifiers: [{ is_built_in_keyboard: true }] };
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
    if (spec.shift)  toMods.push("left_shift");
    if (spec.option) toMods.push("left_option");
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
  // 1. Komorebi shortcuts
  // ============================================================
  //
  // Bindings mirror whkd/whkdrc on Windows. The whkdrc key refers to the
  // **Dvorak letter** the user types (e.g. `alt + h` = the key that produces
  // 'h' in Dvorak). On built-in keyboards Dudrack remaps physical keys to
  // Dvorak output, so this inverts that map to bind option+<physical key>.
  // On external keyboards Dudrack is not active, so the whkdrc letter is used
  // directly as the karabiner key_code.

  // whkdrc is written for a JIS keyboard, so its VK_OEM_* codes resolve to
  // JIS positions (e.g. VK_OEM_1 is the `:` key, not `;`). Keys in the
  // bindings array below are named after the JIS character at that position
  // (`colon`, `comma`, `period`), and the maps point them at the physical
  // key on each Mac keyboard:
  //   built-in (Dudrack): the physical key that *outputs* the JIS character
  //                       per dudrack.map.
  //   external (raw JIS): the actual Karabiner key_code of that key.
  var dudrackInverse = {
    h: "j", j: "c", k: "v", l: "p",
    a: "a", colon: "q", o: "s", e: "d",
    comma: "w", period: "e",
    t: "k", n: "l", u: "f", i: "g", p: "r", y: "t",
    s: "semicolon", m: "m", r: "o", w: "comma", v: "period", b: "n",
    "1": "1", "2": "2", "3": "3", "4": "4", "5": "5",
    "return": "return_or_enter"
  };

  var externalKey = {
    h: "h", j: "j", k: "k", l: "l",
    a: "a", colon: "quote", o: "o", e: "e",
    comma: "comma", period: "period",
    t: "t", n: "n", u: "u", i: "i", p: "p", y: "y",
    s: "s", m: "m", r: "r", w: "w", v: "v", b: "b",
    "1": "1", "2": "2", "3": "3", "4": "4", "5": "5",
    "return": "return_or_enter"
  };

  // Built-in keyboard: physical key that produces a given whkdrc key while
  // the Henkan layer is active (Right Command held). The Henkan layer remaps
  // q/w/e/r/t -> 1/2/3/4/5 and d -> return, so alt+q with Right Command held
  // should fire the alt+1 binding (focus l2), not the alt+colon binding
  // (focus l1). Karabiner does not re-process its own output through other
  // manipulators, so we need an explicit rule on the *physical* source key.
  var henkanInverse = {
    "1": "q",
    "2": "w",
    "3": "e",
    "4": "r",
    "5": "t",
    "return": "d"
  };

  var komorebiBindings = [
    { key: "h", shift: false, command: "focus left" },
    { key: "j", shift: false, command: "focus down" },
    { key: "k", shift: false, command: "focus up" },
    { key: "l", shift: false, command: "focus right" },

    { key: "h", shift: true, command: "move left" },
    { key: "j", shift: true, command: "move down" },
    { key: "k", shift: true, command: "move up" },
    { key: "l", shift: true, command: "move right" },

    { key: "a",     shift: false, command: "focus-named-workspace l0" },
    { key: "colon", shift: false, command: "focus-named-workspace l1" },
    { key: "1",     shift: false, command: "focus-named-workspace l2" },

    { key: "o",      shift: false, command: "focus-named-workspace c0" },
    { key: "e",      shift: false, command: "focus-named-workspace c1" },
    { key: "comma",  shift: false, command: "focus-named-workspace c2" },
    { key: "period", shift: false, command: "focus-named-workspace c3" },
    { key: "2",      shift: false, command: "focus-named-workspace c4" },
    { key: "3",      shift: false, command: "focus-named-workspace c5" },
    { key: "t",      shift: false, command: "focus-named-workspace c6" },
    { key: "n",      shift: false, command: "focus-named-workspace c7" },

    { key: "u", shift: false, command: "focus-named-workspace r0" },
    { key: "i", shift: false, command: "focus-named-workspace r1" },
    { key: "p", shift: false, command: "focus-named-workspace r2" },
    { key: "y", shift: false, command: "focus-named-workspace r3" },
    { key: "4", shift: false, command: "focus-named-workspace r4" },
    { key: "5", shift: false, command: "focus-named-workspace r5" },

    { key: "a",     shift: true, command: "send-to-named-workspace l0" },
    { key: "colon", shift: true, command: "send-to-named-workspace l1" },
    { key: "1",     shift: true, command: "send-to-named-workspace l2" },

    { key: "o",      shift: true, command: "send-to-named-workspace c0" },
    { key: "e",      shift: true, command: "send-to-named-workspace c1" },
    { key: "comma",  shift: true, command: "send-to-named-workspace c2" },
    { key: "period", shift: true, command: "send-to-named-workspace c3" },
    { key: "2",      shift: true, command: "send-to-named-workspace c4" },
    { key: "3",      shift: true, command: "send-to-named-workspace c5" },
    { key: "t",      shift: true, command: "send-to-named-workspace c6" },
    { key: "n",      shift: true, command: "send-to-named-workspace c7" },

    { key: "u", shift: true, command: "send-to-named-workspace r0" },
    { key: "i", shift: true, command: "send-to-named-workspace r1" },
    { key: "p", shift: true, command: "send-to-named-workspace r2" },
    { key: "y", shift: true, command: "send-to-named-workspace r3" },
    { key: "4", shift: true, command: "send-to-named-workspace r4" },
    { key: "5", shift: true, command: "send-to-named-workspace r5" },

    { key: "s", shift: false, command: "toggle-pause" },
    { key: "m", shift: false, command: "manage" },
    { key: "r", shift: false, command: "retile" },
    { key: "w", shift: false, command: "change-layout rows" },
    { key: "v", shift: false, command: "change-layout columns" },
    { key: "b", shift: false, command: "change-layout bsp" },

    { key: "return", shift: true, command: "toggle-float" },
    { key: "r",      shift: true, command: "reload-configuration" }
  ];

  function komorebiManip(keyCode, withShift, device, command) {
    var mods = ["option"];
    if (withShift) mods.push("shift");
    return {
      type: "basic",
      conditions: [device],
      from: { key_code: keyCode, modifiers: { mandatory: mods, optional: ["caps_lock"] } },
      to: [{ shell_command: KOMOREBIC + " " + command }]
    };
  }

  function komorebiHenkanManip(physicalKey, withShift, command) {
    var mods = ["option"];
    if (withShift) mods.push("shift");
    return {
      type: "basic",
      conditions: [
        { type: "variable_if", name: "dudrack_henkan", value: 1 },
        BUILTIN
      ],
      from: { key_code: physicalKey, modifiers: { mandatory: mods, optional: ["caps_lock"] } },
      to: [{ shell_command: KOMOREBIC + " " + command }]
    };
  }

  // Henkan-aware built-in rules first: they carry `variable_if dudrack_henkan
  // == 1`, so the regular rules below (no variable condition) only fire when
  // Henkan is not active.
  for (var ihk = 0; ihk < komorebiBindings.length; ihk++) {
    var hBinding = komorebiBindings[ihk];
    var hKey = hBinding.key;
    if (!henkanInverse[hKey]) continue;
    manipulators.push(komorebiHenkanManip(
      henkanInverse[hKey],
      hBinding.shift,
      hBinding.command
    ));
  }

  for (var ib = 0; ib < komorebiBindings.length; ib++) {
    var binding = komorebiBindings[ib];
    var whkdKey = binding.key;
    var withShift = binding.shift;
    var command = binding.command;
    requireMapKey(dudrackInverse, "dudrackInverse", whkdKey);
    requireMapKey(externalKey, "externalKey", whkdKey);
    manipulators.push(komorebiManip(dudrackInverse[whkdKey], withShift, BUILTIN, command));
    manipulators.push(komorebiManip(externalKey[whkdKey], withShift, EXTERNAL, command));
  }

  // ============================================================
  // 2. Built-in keyboard modifier remaps
  // ============================================================

  function builtinRemap(fromKey, toKey) {
    return {
      type: "basic",
      conditions: [BUILTIN],
      from: { key_code: fromKey, modifiers: ANY_MODS },
      to: [{ key_code: toKey }]
    };
  }

  manipulators.push(builtinRemap("caps_lock",    "left_control"));
  manipulators.push(builtinRemap("tab",          "left_command"));
  manipulators.push(builtinRemap("left_command", "left_shift"));

  // Right Command activates the Henkan layer while held.
  manipulators.push({
    type: "basic",
    conditions: [BUILTIN],
    from: { key_code: "right_command", modifiers: ANY_MODS },
    to: [{ set_variable: { name: "dudrack_henkan", value: 1 } }],
    to_after_key_up: [{ set_variable: { name: "dudrack_henkan", value: 0 } }]
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
    { from: "comma",     shift: false, to: keyStroke("home") },
    { from: "period",    shift: false, to: keyStroke("end") },
    { from: "slash",     shift: true,  to: charKey("~") },
    { from: "slash",     shift: false, to: charKey("^") }
  ];

  var henkanConds = [{ type: "variable_if", name: "dudrack_henkan", value: 1 }, BUILTIN];
  var HENKAN_SHIFT_OPTIONAL_MODS = ["caps_lock", "command", "control", "option"];
  for (var ih = 0; ih < HENKAN.length; ih++) {
    manipulators.push(layerManip(henkanConds, HENKAN[ih], HENKAN_SHIFT_OPTIONAL_MODS));
  }

  // ============================================================
  // 4. Dudrack Neutral Dvorak layer
  // ============================================================
  //
  // Neutral rules come after Henkan rules so Right Command can override the
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
    manipulators.push(layerManip([BUILTIN], NEUTRAL[iN], NEUTRAL_SHIFT_OPTIONAL_MODS));
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
  // overlap. `option` is also excluded from optional so that alt+key still
  // hits the section 6 ALT_SUPPRESS rules.
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
      ? { mandatory: ["shift"], optional: ["caps_lock", "control", "command"] }
      : { optional: ["caps_lock", "control", "command"] };
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
  // 6. External keyboard: suppress unbound alt+key combinations
  // ============================================================
  //
  // macOS's option layer (e.g. "U.S." input source) inserts dead-key
  // characters like `æ` for alt+symbol. The user treats alt strictly as a
  // komorebi modifier on the external keyboard, so swallow alt+letter,
  // alt+number, or alt+JIS-symbol that no earlier manipulator consumed.
  // Komorebi rules above run first; this catch-all fires only when nothing
  // bound matched.

  var ALT_SUPPRESS_KEYS = [
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "quote", "open_bracket", "close_bracket", "non_us_pound",
    "international3", "international1", "equal_sign", "hyphen",
    "slash", "backslash", "semicolon", "comma", "period"
  ];

  for (var ia = 0; ia < ALT_SUPPRESS_KEYS.length; ia++) {
    manipulators.push({
      type: "basic",
      conditions: [EXTERNAL],
      from: {
        key_code: ALT_SUPPRESS_KEYS[ia],
        modifiers: { mandatory: ["option"], optional: ["shift", "caps_lock"] }
      },
      to: [{ key_code: "vk_none" }]
    });
  }

  return {
    description: "Custom rules: Dudrack + Komorebi + external JIS",
    manipulators: manipulators
  };
})();
