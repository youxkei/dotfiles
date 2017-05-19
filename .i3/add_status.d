import std.algorithm : map, each, startsWith;
import std.stdio : File, stdin, stdout;
import std.json : JSONValue, parseJSON, toJSON;
import std.range : enumerate;
import std.format : format;
import std.math : round;

void main()
{
    foreach (i, line; stdin.byLine.enumerate())
    {
        if (i == 0 || i == 1)
        {
            stdout.writeln(line);
            stdout.flush();
        }
        else if (i == 2)
        {
            stdout.writeln(line.parseJSON().addStatuses());
            stdout.flush();
        }
        else
        {
            stdout.writeln(",", line[1..$].parseJSON().addStatuses());
            stdout.flush();
        }
    }
}

struct CpuTimes
{
    int used, iowait, total;
}

CpuTimes readCpuTimesFromProcStat()
{
    int user, nice, system, idle, iowait, irq, softirq, steal;
    File("/proc/stat").readf!"cpu  %d %d %d %d %d %d %d %d"(user, nice, system, idle, iowait, irq, softirq, steal);

    int used = user + nice + system + irq + softirq + steal;
    int total = used + idle + iowait;

    return CpuTimes(used, iowait, total);
}

static CpuTimes previousCpuTimes;
static this()
{
    previousCpuTimes = readCpuTimesFromProcStat();
}

JSONValue addStatuses(JSONValue json)
{
    CpuTimes cpuTimes = readCpuTimesFromProcStat();
    string cpuUsage = format!"CPU: %02d%%"(cast(int)round(100.0 * (0.0 + cpuTimes.used   - previousCpuTimes.used) / (cpuTimes.total - previousCpuTimes.total)));
    string iowait   = format!"iowait: %02d%%"(cast(int)round(100.0 * (0.0 + cpuTimes.iowait - previousCpuTimes.iowait) / (cpuTimes.total - previousCpuTimes.total)));
    previousCpuTimes = cpuTimes;

    return JSONValue([
        JSONValue([
            "name": "cpu_usage",
            "markup": "none",
            "full_text": cpuUsage,
        ]),
        JSONValue([
            "name": "iowait",
            "markup": "none",
            "full_text": iowait,
        ])
    ] ~ json.array());
}
