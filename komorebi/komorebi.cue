package komorebi

import "list"

#ExeRule: {
	kind:              "Exe"
	id:                string
	matching_strategy: "Equals"
}

_logicalMonitors: [{
	// center
	devices:    ["IOCFFFF", "GSM76F6", "DEL4187", "PHL095C", "DEL42A1", "DEL437D", "DELA0F4", "MRG4100"]
	device_ids: ["IOCFFFF-5&2686ec95&0&UID4352"]
	workspaces: [for i in list.Range(0, 8, 1) {"c\(i)"}]
}, {
	// left
	devices:    ["GSM779A", "GSM7799", "SDC4178"]
	device_ids: ["GSM779A-5&2686ec95&0&UID4353"]
	workspaces: [for i in list.Range(0, 3, 1) {"l\(i)"}]
}, {
	// right
	devices:    ["AUS272A"]
	device_ids: ["AUS272A-5&2686ec95&0&UID4355"]
	workspaces: [for i in list.Range(0, 6, 1) {"r\(i)"}]
}]

_allDeviceIds: list.FlattenN([for lm in _logicalMonitors {lm.device_ids}], 1)

display_index_preferences: {for i, d in _allDeviceIds {"\(i)": d}}

monitors: list.FlattenN([
	for lm in _logicalMonitors {[
		for _ in lm.device_ids {
			workspaces: [for ws in lm.workspaces {name: ws, layout: "BSP"}]
		},
	]},
], 1)

app_specific_configuration_path: "$Env:USERPROFILE\\.cache\\komorebi\\applications.yaml"
resize_delta:                      50
window_container_behaviour:        "Create"
cross_monitor_move_behaviour:      "Insert"
unmanaged_window_operation_behaviour: "Op"
focus_follows_mouse:               "Windows"
mouse_follows_focus:               true

border_width: 20
border:       true
_borderColor: {r: 232, g: 145, b: 45}
border_colours: {
	single:  _borderColor
	stack:   _borderColor
	monocle: _borderColor
}

default_workspace_padding:  10
default_container_padding:  10
alt_focus_hack:             false
window_hiding_behaviour:    "Cloak"

_trayApps: ["Carla.exe", "qjackctl.exe", "jackd.exe", "iTunes.exe", "DeepL.exe", "OktaVerify.exe", "VBAudioMatrix_x64.exe", "Wispr Flow.exe", "Wispr Flow Helper.exe"]
tray_and_multi_window_applications: [for app in _trayApps {#ExeRule & {id: app}}]

_floatApps: ["ShellExperienceHost.exe", "DeepL.exe", "OktaVerify.exe", "steam.exe", "th15.exe", "th07.exe", "Wispr Flow.exe", "Wispr Flow Helper.exe"]
float_rules: [for app in _floatApps {#ExeRule & {id: app}}]

_manageApps: ["VBAudioMatrix_x64.exe"]
manage_rules: [for app in _manageApps {#ExeRule & {id: app}}]
