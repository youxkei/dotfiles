package googlehome

#Time: { h: uint, m: *0 | uint, s: *0 | uint }

// Zero-pad a 0-99 value to two digits so times read as HH:MM:SS.
#Pad2: {
    n: uint
    out: string
    if n < 10 { out: "0\(n)" }
    if n >= 10 { out: "\(n)" }
}

#FormatTime: {
    time: #Time

    out: "\((#Pad2 & {n: mod(time.h, 24)}).out):\((#Pad2 & {n: time.m}).out):\((#Pad2 & {n: time.s}).out)"
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
