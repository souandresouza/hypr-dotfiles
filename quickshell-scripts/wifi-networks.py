#!/usr/bin/env python3
import json
import subprocess

def split_escaped(line):
    parts, cur = [], []
    i = 0
    while i < len(line):
        c = line[i]
        if c == "\\" and i + 1 < len(line):
            cur.append(line[i + 1])
            i += 2
        elif c == ":":
            parts.append("".join(cur))
            cur = []
            i += 1
        else:
            cur.append(c)
            i += 1
    parts.append("".join(cur))
    return parts

def main():
    try:
        out = subprocess.run(
            ["nmcli", "-t", "-e", "yes", "-f", "SSID,SIGNAL,SECURITY", "dev", "wifi"],
            capture_output=True, text=True, timeout=5).stdout
    except (subprocess.SubprocessError, OSError):
        print("[]")
        return

    seen = {}
    for raw in out.splitlines():
        if not raw.strip():
            continue
        try:
            ssid, signal, security = split_escaped(raw)
        except ValueError:
            continue
        if not ssid:
            continue
        signal = int(signal or 0)
        if ssid not in seen or signal > seen[ssid][1]:
            seen[ssid] = (ssid, signal, security)

    result = [{
        "ssid": s,
        "signal": signal,
        "secured": sec not in ("", "(none)", "none", "NONE"),
    } for s, signal, sec in seen.values()]

    print(json.dumps(result))

if __name__ == "__main__":
    main()