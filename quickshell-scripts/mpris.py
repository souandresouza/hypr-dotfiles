#!/usr/bin/env python3
import json
import sys
import dbus

ACTION = "--action"
bus = dbus.SessionBus()

def as_str(value):
	if isinstance(value, (list, tuple, dbus.Array)):
		return ", ".join(as_str(v) for v in value)
	return str(value)

def player_map(name):
	obj = bus.get_object(name, "/org/mpris/MediaPlayer2")
	props = dbus.Interface(obj, dbus.PROPERTIES_IFACE)
	try:
		status = props.Get("org.mpris.MediaPlayer2.Player", "PlaybackStatus")
		meta = props.Get("org.mpris.MediaPlayer2.Player", "Metadata")
		identity = props.Get("org.mpris.MediaPlayer2", "Identity")
		can_control = props.Get("org.mpris.MediaPlayer2.Player", "CanControl")
		can_play = props.Get("org.mpris.MediaPlayer2.Player", "CanPlay")
		can_pause = props.Get("org.mpris.MediaPlayer2.Player", "CanPause")
		can_prev = props.Get("org.mpris.MediaPlayer2.Player", "CanGoPrevious")
		can_next = props.Get("org.mpris.MediaPlayer2.Player", "CanGoNext")
		pos = props.Get("org.mpris.MediaPlayer2.Player", "Position")
		try:
			vol = float(props.Get("org.mpris.MediaPlayer2.Player", "Volume"))
		except (dbus.DBusException, TypeError):
			vol = -1.0
	except dbus.DBusException:
		return None
	return {
		"id": name,
		"identity": as_str(identity),
		"status": as_str(status),
		"title": as_str(meta.get("xesam:title", "")),
		"artist": as_str(meta.get("xesam:artist", "")),
		"album": as_str(meta.get("xesam:album", "")),
		"artUrl": as_str(meta.get("mpris:artUrl", "")),
		"canControl": bool(can_control),
		"canPlay": bool(can_play),
		"canPause": bool(can_pause),
		"canGoPrevious": bool(can_prev),
		"canGoNext": bool(can_next),
		"length": int(meta.get("mpris:length", 0)),
		"position": int(pos),
		"volume": vol,
	}

def list_players():
	out = []
	for name in sorted(bus.list_names()):
		if not name.startswith("org.mpris.MediaPlayer2."):
			continue
		m = player_map(name)
		if m:
			out.append(m)
	print(json.dumps(out))

def action(name, cmd):
	try:
		obj = bus.get_object(name, "/org/mpris/MediaPlayer2")
		player = dbus.Interface(obj, "org.mpris.MediaPlayer2.Player")
		app = dbus.Interface(obj, "org.mpris.MediaPlayer2")
		props = dbus.Interface(obj, dbus.PROPERTIES_IFACE)
		if cmd == "play-pause":
			player.PlayPause()
		elif cmd == "next":
			player.Next()
		elif cmd == "previous":
			player.Previous()
		elif cmd == "play":
			player.Play()
		elif cmd == "pause":
			player.Pause()
		elif cmd == "raise":
			app.Raise()
		elif cmd == "volume":
			value = max(0.0, min(1.0, float(args[i + 3])))
			props.Set("org.mpris.MediaPlayer2.Player", "Volume", dbus.Double(value))
		elif cmd == "status":
			s = props.Get("org.mpris.MediaPlayer2.Player", "PlaybackStatus")
			print(str(s))
	except dbus.DBusException:
		sys.exit(1)

if __name__ == "__main__":
	args = sys.argv[1:]
	if ACTION in args:
		i = args.index(ACTION)
		name = args[i + 1]
		cmd = args[i + 2]
		action(name, cmd)
	else:
		list_players()