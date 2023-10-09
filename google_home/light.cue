package googlehome

import "list"

#config: {
    target: "ceiling_light - youxkei"

    time: {
        lightOn:       #Time & {h: 10}
        lightOffStart: #Time & {h: 17}
        lightOffEnd:   #Time & {h: 23}
    }

    temperature: {
        min: 2700
        max: 6500
    }
}

metadata: {
    name: "照明オンオフ"
    description: "時刻に応じて照明をオンにしたり徐々にオフにしたりする"
}

#stepSeconds: div(((#ToSeconds & {time: #config.time.lightOffEnd}).out - (#ToSeconds & {time: #config.time.lightOffStart}).out), 100)

automations: [
    for i, _ in list.Repeat([_], 100) {
        starters: {
            type: "time.schedule"
            at: (#FormatTime & {time: (#AddSeconds & {time: #config.time.lightOffStart, seconds: #stepSeconds * i}).out}).out
        }

        actions: [
            {
                type: "device.command.ColorAbsolute"
                devices: #config.target
                color: temperature: "\(#config.temperature.min)K"
            },
            {
                type: "device.command.BrightnessAbsolute"
                devices: #config.target
                brightness: 100 - i
            },
        ]
    }
] + [
    {
        starters: {
            type: "time.schedule"
            at: (#FormatTime & {time: #config.time.lightOffEnd}).out
        }

        actions: [
            {
                type: "device.command.OnOff"
                devices: #config.target
                on: false
            },
        ]
    },
    {
        starters: {
            type: "time.schedule"
            at: (#FormatTime & {time: #config.time.lightOn}).out
        }

        actions: [
            {
                type: "device.command.BrightnessAbsolute"
                devices: #config.target
                brightness: 100
            },
            {
                type: "device.command.ColorAbsolute"
                devices: #config.target
                color: temperature: "\(#config.temperature.max)K"
            },
        ]
    },
]
