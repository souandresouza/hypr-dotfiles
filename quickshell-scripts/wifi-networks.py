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


def run_nmcli(args):
    try:
        return subprocess.run(
            ["nmcli"] + args, capture_output=True, text=True, timeout=5).stdout
    except (subprocess.SubprocessError, OSError):
        return ""


def get_saved_ssids():
    out = run_nmcli(["-t", "-e", "yes", "-f", "NAME,TYPE", "con", "show"])
    ssids = []
    for raw in out.splitlines():
        if not raw.strip():
            continue
        try:
            name, ctype = split_escaped(raw)
        except ValueError:
            continue
        if ctype != "802-11-wireless":
            continue
        ssid = run_nmcli(["-g", "802-11-wireless.ssid", "con", "show", name]).strip()
        if ssid and ssid not in ssids:
            ssids.append(ssid)
    return ssids


def main():
    scan = {}
    out = run_nmcli(["-t", "-e", "yes", "-f", "SSID,SIGNAL,SECURITY", "dev", "wifi"])
    for raw in out.splitlines():
        if not raw.strip():
            continue
        try:
            ssid, signal, security = split_escaped(raw)
        except ValueError:
            continue
        if ssid and (ssid not in scan or int(signal or 0) > scan[ssid][0]):
            scan[ssid] = (int(signal or 0), security)

    saved = get_saved_ssids()
    if not saved:
        print("[]")
        return

    result = []
    for ssid in saved:
        signal, security = scan.get(ssid, (0, ""))
        result.append({
            "ssid": ssid,
            "signal": signal,
            "secured": security not in ("", "(none)", "none", "NONE"),
        })

    result.sort(key=lambda r: (-r["signal"], r["ssid"].lower()))
    print(json.dumps(result))


if __name__ == "__main__":
    main()