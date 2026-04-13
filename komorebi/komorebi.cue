package komorebi

import "list"

#ExeRule: {
	kind:              "Exe"
	id:                string
	matching_strategy: "Equals"
}

_logicalMonitors: [{
	// center
	unmigrated_devices: ["GSM76F6", "DEL4187", "DEL42A1", "DEL437D", "DELA0F4", "MRG4100"]
	device_ids:         ["IOCFFFF-5&2686ec95&0&UID4352", "IOCFFFF-9&37b11675&0&UID262402", "PHL095C-5&39ed454c&0&UID4354"]
	workspaces: [for i in list.Range(0, 8, 1) {"c\(i)"}]
}, {
	// left
	unmigrated_devices: []
	device_ids:         ["SDC4178-4&32ada849&0&UID8388688", "207NTCZA4323"]
	workspaces: [for i in list.Range(0, 3, 1) {"l\(i)"}]
}, {
	// right
	unmigrated_devices: []
	device_ids:         ["LCLMQS088693 "]
	workspaces: [for i in list.Range(0, 6, 1) {"r\(i)"}]
}]

_allDeviceIds: list.FlattenN([for lm in _logicalMonitors {lm.device_ids}], 1)

_trayApps: ["Carla.exe", "qjackctl.exe", "jackd.exe", "iTunes.exe", "DeepL.exe", "OktaVerify.exe"]
_floatApps: ["ShellExperienceHost.exe", "DeepL.exe", "OktaVerify.exe", "steam.exe", "th15.exe", "th07.exe"]
_manageApps: ["claude.exe"]

_borderColor: {r: 232, g: 145, b: 45}

komorebi: {
	display_index_preferences: {for i, d in _allDeviceIds {"\(i)": d}}

	monitors: list.FlattenN([
		for lm in _logicalMonitors {[
			for _ in lm.device_ids {
				workspaces: [for ws in lm.workspaces {name: ws, layout: "BSP"}]
			},
		]},
	], 1)

	app_specific_configuration_path:      "$Env:USERPROFILE\\.cache\\komorebi\\applications.yaml"
	resize_delta:                         50
	window_container_behaviour:           "Create"
	cross_monitor_move_behaviour:         "Insert"
	unmanaged_window_operation_behaviour: "Op"
	focus_follows_mouse:                  "Windows"
	mouse_follows_focus:                  true

	border_width: 20
	border:       true
	border_colours: {
		single:  _borderColor
		stack:   _borderColor
		monocle: _borderColor
	}

	default_workspace_padding: 10
	default_container_padding: 10
	alt_focus_hack:            false
	window_hiding_behaviour:   "Cloak"

	tray_and_multi_window_applications: [for app in _trayApps {#ExeRule & {id: app}}]
	float_rules: [for app in _floatApps {#ExeRule & {id: app}}]
	manage_rules: [for app in _manageApps {#ExeRule & {id: app}}]
}
