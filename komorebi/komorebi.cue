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
	device_ids:         ["IOCFFFF-5&2686ec95&0&UID4352", "PHL095C-5&39ed454c&0&UID4354"]
	workspaces: [for i in list.Range(0, 8, 1) {"c\(i)"}]
}, {
	// left
	unmigrated_devices: ["GSM7799"]
	device_ids:         ["GSM779A-5&2686ec95&0&UID4353", "SDC4178-4&32ada849&0&UID8388688"]
	workspaces: [for i in list.Range(0, 3, 1) {"l\(i)"}]
}, {
	// right
	unmigrated_devices: []
	device_ids:         ["AUS272A-5&2686ec95&0&UID4355"]
	workspaces: [for i in list.Range(0, 6, 1) {"r\(i)"}]
}]

_allDeviceIds: list.FlattenN([for lm in _logicalMonitors {lm.device_ids}], 1)

_trayApps: ["Carla.exe", "qjackctl.exe", "jackd.exe", "iTunes.exe", "DeepL.exe", "OktaVerify.exe"]
_floatApps: ["ShellExperienceHost.exe", "DeepL.exe", "OktaVerify.exe", "steam.exe", "th15.exe", "th07.exe"]
_manageApps: ["claude.exe"]

_borderColor: {r: 232, g: 145, b: 45}

_barIndices: [0, 1, 2]

komorebi: {
	display_index_preferences: {for i, d in _allDeviceIds {"\(i)": d}}

	monitors: list.FlattenN([
		for lm in _logicalMonitors {[
			for _ in lm.device_ids {
				workspaces: [for ws in lm.workspaces {name: ws, layout: "BSP"}]
			},
		]},
	], 1)

	bar_configurations: [
		for i in _barIndices {"$Env:USERPROFILE\\.config\\komorebi\\komorebi.bar.\(i).json"},
	]

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

_barBase: {
	"$schema":   "https://raw.githubusercontent.com/LGUG2Z/komorebi/v0.1.39/schema.bar.json"
	font_family: "Moralerspace Krypton HWNF"
	theme: {
		palette: "Base16"
		name:    "Ashes"
		accent:  "Base0D"
	}
	left_widgets: [{
		Komorebi: {
			workspaces: {
				enable:                false
				hide_empty_workspaces: false
			}
			layout: {
				enable: true
			}
			focused_window: {
				enable:    false
				show_icon: true
			}
		}
	}]
	right_widgets: [{
		Update: {enable: true}
	}, {
		Media: {enable: true}
	}, {
		Storage: {enable: true}
	}, {
		Memory: {enable: true}
	}, {
		Network: {
			enable:              true
			show_activity:       true
			show_total_activity: true
		}
	}, {
		Date: {
			enable: true
			format: Custom: "%Y-%m-%d（%a）"
		}
	}, {
		Time: {
			enable: true
			format: "TwentyFourHour"
		}
	}, {
		Battery: {enable: true}
	}]
}

bars: [for i in _barIndices {
	_barBase & {monitor: i}
}]
