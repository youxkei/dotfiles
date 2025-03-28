package googlehome

import "list"

let config = {
    target: "ceiling_light - youxkei"

    time: {
        lightOffStart: #Time & {h: 17}
        lightOffEnd:   #Time & {h: 23}
    }

    temperature: {
        min: 2700
        max: 6500
    }

    delayBetweenActions: "5sec"
}

let stepSeconds = div(((#ToSeconds & {time: config.time.lightOffEnd}).out - (#ToSeconds & {time: config.time.lightOffStart}).out), 100)

metadata: {
    name: "照明オフ"
    description: "時刻に応じて照明を徐々にオフにする"
}

automations: [
    for i, _ in list.Repeat([_], 99) {
        starters: {
            type: "time.schedule"
            at: (#FormatTime & {time: (#AddSeconds & {time: config.time.lightOffStart, seconds: stepSeconds * i}).out}).out
        }

        actions: [
            {
                type: "device.command.BrightnessAbsolute"
                devices: config.target
                brightness: 99 - i
            },
            {
                type: "time.delay"
                for: config.delayBetweenActions
            },
            {
                type: "device.command.ColorAbsolute"
                devices: config.target
                color: temperature: "\(config.temperature.min)K"
            },
        ]
    },

    {
        starters: {
            type: "time.schedule"
            at: (#FormatTime & {time: config.time.lightOffEnd}).out
        }

        actions: [
            {
                type: "device.command.OnOff"
                devices: config.target
                on: false
            },
        ]
    }
]
