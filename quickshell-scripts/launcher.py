#!/usr/bin/env python3
import configparser
import json
import os
import re

def wal_colors():
	result = {}
	try:
		with open(os.path.expanduser("~/.cache/wal/colors.css")) as f:
			css = f.read()
		for key in ["background", "foreground", "cursor"]:
			m = re.search(r"--%s:\s*(#[0-9a-fA-F]{6})" % key, css)
			if m:
				result[key] = m.group(1)
		for i in range(16):
			m = re.search(r"--color%d:\s*(#[0-9a-fA-F]{6})" % i, css)
			if m:
				result["color%d" % i] = m.group(1)
	except Exception:
		pass
	return result

dirs = [
	os.path.expanduser("~/.local/share/applications"),
	os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
	"/var/lib/flatpak/exports/share/applications",
	"/usr/share/applications",
]

out = []
seen = set()

for d in dirs:
	if not os.path.isdir(d):
		continue
	for fn in sorted(os.listdir(d)):
		if not fn.endswith(".desktop"):
			continue
		path = os.path.join(d, fn)
		try:
			cp = configparser.ConfigParser(interpolation=None)
			cp.read(path)
			if not cp.has_section("Desktop Entry"):
				continue
			s = cp["Desktop Entry"]
			if s.get("NoDisplay", "false").lower() == "true" or s.get("Hidden", "false").lower() == "true":
				continue
			if s.get("Type", "Application") != "Application":
				continue
			name = s.get("Name", "").strip()
			if not name or name in seen:
				continue
			seen.add(name)
			out.append({
				"name": name,
				"exec": s.get("Exec", "").strip(),
				"terminal": s.get("Terminal", "false").lower() == "true",
				"comment": s.get("Comment", "").strip(),
				"icon": s.get("Icon", "").strip(),
			})
		except Exception:
			continue

print(json.dumps({"entries": out, "wal": wal_colors()}))