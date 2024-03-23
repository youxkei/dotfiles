package googlehome

#Time: { h: uint, m: *0 | uint, s: *0 | uint }

#FormatTime: {
    time: #Time

    out: "\(mod(time.h, 24)):\(time.m):\(time.s)"
}

#ToSeconds: {
    time: #Time

    out: time.h * 3600 + time.m * 60 + time.s
}

#FromSeconds: {
    seconds: uint

    out: #Time & {
        h: div(seconds, 3600)
        m: div(mod(seconds, 3600), 60)
        s: mod(seconds, 60)
    }
}

#AddSeconds: {
    t = time: #Time
    s = seconds: int

    out: (#FromSeconds & {seconds: (#ToSeconds & {time: t}).out + s}).out
}
