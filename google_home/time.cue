package googlehome

#Time: { h: uint, m: *0 | uint, s: *0 | uint }

#FormatTime: X = {
    time: #Time

    out: "\(mod(X.time.h, 24)):\(X.time.m):\(X.time.s)"
}

#ToSeconds: X = {
    time: #Time

    out: X.time.h * 3600 + X.time.m * 60 + X.time.s
}

#FromSeconds: X = {
    seconds: uint

    out: #Time & {
        h: div(X.seconds, 3600)
        m: div(mod(X.seconds, 3600), 60)
        s: mod(X.seconds, 60)
    }
}

#AddSeconds: X = {
    time: #Time
    seconds: int

    out: (#FromSeconds & {seconds: (#ToSeconds & {time: X.time}).out + X.seconds}).out
}
