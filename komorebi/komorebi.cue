package komorebi

import "list"

#ExeRule: {
	kind:              "Exe"
	id:                string
	matching_strategy: "Equals"
}

// device_ids / device_ids_mac are append-only.
logicalMonitors: {
	center: {
		unmigrated_devices: ["GSM76F6", "DEL4187", "DEL42A1", "DELA0F4", "MRG4100"]
		device_ids:         ["IOCFFFF-5&2686ec95&0&UID4352", "IOCFFFF-9&37b11675&0&UID262402", "PHL095C-5&39ed454c&0&UID4354", "6KN5834", "41JP734", "JTHP734"]
		device_ids_mac: [
			"0",       // PHL 346B1C (CGDisplaySerialNumber returns 0)
			"BQRR834", // DELL P3223QE
			"CRRR834", // DELL P3223QE
		]
		workspaces: [for i in list.Range(0, 8, 1) {"c\(i)"}]
	}
	left: {
		unmigrated_devices: []
		device_ids:         ["SDC4178-4&32ada849&0&UID8388688", "207NTCZA4323"]
		device_ids_mac: ["4251086178"] // Built-in Retina Display
		workspaces: [for i in list.Range(0, 3, 1) {"l\(i)"}]
	}
	right: {
		unmigrated_devices: []
		device_ids:         ["LCLMQS088693 "]
		device_ids_mac: []
		workspaces: [for i in list.Range(0, 6, 1) {"r\(i)"}]
	}
}

// Reshape logicalMonitors so the mac device IDs sit under `device_ids`. Exported
// for bin/watch-komorebi to parse; also reused below to build komorebiMac.
logicalMonitorsMac: {
	for name, lm in logicalMonitors {
		"\(name)": {
			device_ids: lm.device_ids_mac
			workspaces: lm.workspaces
		}
	}
}

// Build komorebi's `monitors` array by replicating each logical monitor's
// workspaces for every device_id in `src`.
_monitors: {
	src: [string]: {device_ids: [...string], workspaces: [...string], ...}
	out: list.FlattenN([
		for lm in src {[
			for _ in lm.device_ids {
				workspaces: [for ws in lm.workspaces {name: ws, layout: "BSP"}]
			},
		]},
	], 1)
}

// Build display_index_preferences ({"0": id0, "1": id1, ...}) from `src`.
_displayIndexPreferences: {
	src: [string]: {device_ids: [...string], ...}
	out: {
		for i, d in list.FlattenN([for lm in src {lm.device_ids}], 1) {
			"\(i)": d
		}
	}
}

_trayApps: ["Carla.exe", "qjackctl.exe", "jackd.exe", "iTunes.exe", "DeepL.exe", "OktaVerify.exe"]
_floatApps: ["ShellExperienceHost.exe", "DeepL.exe", "OktaVerify.exe", "steam.exe", "th15.exe", "th07.exe"]
_manageApps: ["claude.exe"]

// macOS menu bar popups expose AX windows that komorebi otherwise tries to
// tile (Control Center: Wi-Fi/battery/sound/etc; Notification Center: clock
// widgets). komorebi reads the AX title, which is localized, so the Japanese
// system UI must be matched by its Japanese name.
_macIgnoreApps: ["コントロールセンター", "通知センター"]
_macFloatApps: ["Okta Verify"]

_borderColor: {r: 232, g: 145, b: 45}

// Settings whose name, type, and value are accepted by both Windows komorebi
// and komorebi-for-mac.
_shared: {
	resize_delta:                         50
	window_container_behaviour:           "Create"
	cross_monitor_move_behaviour:         "Insert"
	unmanaged_window_operation_behaviour: "Op"
	mouse_follows_focus:                  true

	border:       true
	border_width: 20
	border_colours: {
		single:  _borderColor
		stack:   _borderColor
		monocle: _borderColor
	}

	default_workspace_padding: 10
	default_container_padding: 10
}

komorebi: _shared & {
	display_index_preferences: (_displayIndexPreferences & {src: logicalMonitors}).out
	monitors:                  (_monitors & {src:                  logicalMonitors}).out

	app_specific_configuration_path: "$Env:USERPROFILE\\.cache\\komorebi\\applications.yaml"
	focus_follows_mouse:             "Windows"
	alt_focus_hack:                  false
	window_hiding_behaviour:         "Cloak"

	tray_and_multi_window_applications: [for app in _trayApps {#ExeRule & {id: app}}]
	float_rules: [for app in _floatApps {#ExeRule & {id: app}}]
	manage_rules: [for app in _manageApps {#ExeRule & {id: app}}]
}

komorebiMac: _shared & {
	display_index_preferences: (_displayIndexPreferences & {src: logicalMonitorsMac}).out
	monitors:                  (_monitors & {src:                  logicalMonitorsMac}).out

	manage_rules: []
	floating_applications: [for app in _macFloatApps {#ExeRule & {id: app}}]
	ignore_rules: [for app in _macIgnoreApps {#ExeRule & {id: app}}]

	// Chrome PWAs whose AX window exposes no title; komorebi refuses to manage
	// titleless windows unless their app name is listed here.
	titleless_applications: ["Rejysten"]
}
