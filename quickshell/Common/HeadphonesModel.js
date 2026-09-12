// Pure helpers for the Headphones widget: device ranking, battery formatting,
// brand detection from SDP UUIDs, mode management.
// Adapted from github.com/ncr/omarchy-headphones (MIT).

var LEVEL_GLYPHS = [
  "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}",
  "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"
]

var CHARGING_GLYPHS = [
  "\u{f089c}", "\u{f0086}", "\u{f0087}", "\u{f0088}", "\u{f089d}",
  "\u{f0089}", "\u{f089e}", "\u{f008a}", "\u{f008b}", "\u{f0085}"
]

var HEADPHONES_GLYPH = "\u{f02cb}"
var UNKNOWN_GLYPH = "\u{f0091}"

function str(value) {
  return String(value === undefined || value === null ? "" : value)
}

function asBool(value, fallback) {
  if (value === undefined || value === null || value === "") return fallback
  if (typeof value === "boolean") return value
  if (typeof value === "number") return value !== 0
  var text = str(value).trim().toLowerCase()
  if (text === "false" || text === "0" || text === "no" || text === "off") return false
  if (text === "true" || text === "1" || text === "yes" || text === "on") return true
  return fallback
}

function asInt(value, fallback) {
  if (value === undefined || value === null) return fallback
  if (typeof value === "number") return isFinite(value) ? Math.round(value) : fallback
  var text = str(value).trim()
  if (text === "") return fallback
  var number = Number(text)
  return isFinite(number) ? Math.round(number) : fallback
}

function plainText(value) {
  return str(value).replace(/</g, "\u2039").replace(/>/g, "\u203a")
}

function deviceLabel(device) {
  if (!device) return ""
  var name = plainText(device.name).trim()
  if (name) return name
  var reported = plainText(device.deviceName).trim()
  if (reported) return reported
  return str(device.address)
}

function isAudioDevice(device) {
  if (!device) return false
  if (str(device.icon).toLowerCase().indexOf("audio") !== -1) return true
  var name = deviceLabel(device).toLowerCase()
  return name.indexOf("buds") !== -1
    || name.indexOf("headphone") !== -1
    || name.indexOf("headset") !== -1
    || name.indexOf("airpod") !== -1
}

function matchesFilter(device, filter) {
  var needle = str(filter).trim().toLowerCase()
  if (!needle) return isAudioDevice(device)
  var haystack = (deviceLabel(device) + " " + str(device.address)).toLowerCase()
  return haystack.indexOf(needle) !== -1
}

function score(device, preferAddress) {
  var points = 0
  if (device.connected) points += 16
  if (device.batteryAvailable) points += 4
  if (isAudioDevice(device)) points += 2
  if (preferAddress && str(device.address).toUpperCase() === str(preferAddress).toUpperCase())
    points += 1
  return points
}

function rankDevices(devices, filter, preferAddress) {
  var list = devices || []
  var rows = []
  for (var i = 0; i < list.length; i++) {
    var device = list[i]
    if (!device) continue
    if (!device.paired && !device.connected) continue
    if (!matchesFilter(device, filter)) continue
    rows.push({
      device: device,
      points: score(device, preferAddress),
      label: deviceLabel(device).toLowerCase(),
      index: i
    })
  }
  rows.sort(function (a, b) {
    if (a.points !== b.points) return b.points - a.points
    if (a.label !== b.label) return a.label < b.label ? -1 : 1
    return a.index - b.index
  })
  var out = []
  for (var j = 0; j < rows.length; j++) out.push(rows[j].device)
  return out
}

function pickDevice(devices, filter, preferAddress) {
  var ranked = rankDevices(devices, filter, preferAddress)
  return ranked.length > 0 ? ranked[0] : null
}

function followedAddresses(devices, filter, preferAddress) {
  var ranked = rankDevices(devices, filter, preferAddress)
  var out = []
  for (var i = 0; i < ranked.length; i++)
    if (ranked[i].connected) out.push(str(ranked[i].address))
  if (out.length === 0 && ranked.length > 0) out.push(str(ranked[0].address))
  return out
}

function deviceByAddress(devices, address) {
  var wanted = str(address).trim().toUpperCase()
  if (wanted === "") return null
  var list = devices || []
  for (var i = 0; i < list.length; i++)
    if (list[i] && str(list[i].address).toUpperCase() === wanted) return list[i]
  return null
}

function sortFollowers(followers, preferAddress) {
  var list = followers || []
  var wanted = str(preferAddress).toUpperCase()
  var rows = []
  for (var i = 0; i < list.length; i++) {
    var follower = list[i]
    if (!follower) continue
    var points = 0
    if (follower.connected) points += 16
    if (wanted && str(follower.address).toUpperCase() === wanted) points += 1
    rows.push({
      follower: follower,
      points: points,
      label: str(follower.name).toLowerCase(),
      index: i
    })
  }
  rows.sort(function (a, b) {
    if (a.points !== b.points) return b.points - a.points
    if (a.label !== b.label) return a.label < b.label ? -1 : 1
    return a.index - b.index
  })
  var out = []
  for (var j = 0; j < rows.length; j++) out.push(rows[j].follower)
  return out
}

function findByWhich(followers, which) {
  var list = followers || []
  var needle = str(which).trim().toLowerCase()
  if (needle === "") return list.length > 0 ? 0 : -1
  for (var i = 0; i < list.length; i++) {
    var follower = list[i]
    if (!follower) continue
    var haystack = (str(follower.name) + " " + str(follower.address) + " " + str(follower.controlBackend)).toLowerCase()
    if (haystack.indexOf(needle) !== -1) return i
  }
  return -1
}

function batteryLevel(device) {
  if (!device || !device.connected || !device.batteryAvailable) return -1
  var level = Math.round(Number(device.battery) * 100)
  if (!isFinite(level)) return -1
  return Math.max(0, Math.min(100, level))
}

function levelGlyph(level, charging) {
  if (typeof level !== "number" || !isFinite(level) || level < 0) return ""
  var index = Math.max(0, Math.min(9, Math.floor(level / 10)))
  return charging ? CHARGING_GLYPHS[index] : LEVEL_GLYPHS[index]
}

function clamp(value, low, high) {
  var number = Math.round(Number(value))
  if (!isFinite(number)) return low
  return Math.max(low, Math.min(high, number))
}

function lowestBud(left, right) {
  if (left >= 0 && right >= 0) return Math.min(left, right)
  if (left >= 0) return left
  if (right >= 0) return right
  return -1
}

function barText(level, showPercentage) {
  if (level < 0 || !showPercentage) return HEADPHONES_GLYPH
  return HEADPHONES_GLYPH + " " + level + "%"
}

function percentLabel(level) {
  return level < 0 ? "\u2014" : level + "%"
}

function statusLine(state) {
  if (!state.hasDevice) return "no headphones paired"
  if (!state.connected) return "not connected"
  var known = singleLevel(state) >= 0 || state.left >= 0 || state.right >= 0 || state.level >= 0
  if (!known) return "connected \u00b7 battery not reported"
  return state.charging ? "connected \u00b7 charging" : "connected"
}

function tooltip(state) {
  if (!state.hasDevice) return "No headphones paired"
  if (!state.connected) return state.name + " \u00b7 not connected"
  if (singleLevel(state) >= 0) return state.name + " \u00b7 " + singleLevel(state) + "%"
  var parts = []
  if (state.left >= 0) parts.push("L " + state.left + "%")
  if (state.right >= 0) parts.push("R " + state.right + "%")
  if (state.caseLevel >= 0) parts.push("case " + state.caseLevel + "%")
  if (state.left < 0 && state.right < 0 && state.level >= 0)
    parts.unshift(state.level + "%")
  if (parts.length > 0) return state.name + " \u00b7 " + parts.join(" \u00b7 ")
  if (state.level >= 0) return state.name + " \u00b7 " + state.level + "%"
  return state.name + " \u00b7 battery unknown"
}

function lowBatteryBody(state) {
  if (singleLevel(state) >= 0) return singleLevel(state) + "% left"
  var parts = []
  if (state.left >= 0) parts.push("L " + state.left + "%")
  if (state.right >= 0) parts.push("R " + state.right + "%")
  if (parts.length > 0) return parts.join(" \u00b7 ") + " left"
  if (state.level >= 0) return state.level + "% left"
  return "battery low"
}

function shortError(text, fallback) {
  var lines = str(text).split("\n")
  for (var i = lines.length - 1; i >= 0; i--) {
    var line = lines[i].replace(/^\s+|\s+$/g, "")
    if (line === "") continue
    line = plainText(line)
    return line.length > 160 ? line.substring(0, 157) + "\u2026" : line
  }
  return fallback
}

function mergeReaderLine(previous, raw) {
  var next = {}
  for (var key in previous) next[key] = previous[key]
  var parsed = null
  try {
    parsed = JSON.parse(String(raw || "").trim() || "{}")
  } catch (e) {
    return next
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return next
  for (var incoming in parsed) next[incoming] = parsed[incoming]
  return next
}

function readerLineAddress(raw) {
  var parsed = null
  try {
    parsed = JSON.parse(String(raw || "").trim() || "{}")
  } catch (e) {
    return ""
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return ""
  if (typeof parsed.address !== "string") return ""
  return parsed.address.trim().toUpperCase()
}

function readerAddresses(followers) {
  var list = followers || []
  var out = []
  for (var i = 0; i < list.length; i++) {
    var follower = list[i]
    if (!follower || !follower.connected) continue
    var address = str(follower.address).trim().toUpperCase()
    if (address !== "" && out.indexOf(address) === -1) out.push(address)
  }
  return out
}

function parseSupport(raw) {
  try {
    var parsed = JSON.parse(String(raw || "").trim() || "{}")
    return (parsed && typeof parsed === "object" && !Array.isArray(parsed)) ? parsed : {}
  } catch (e) {
    return {}
  }
}

function supportVerdict(support, modelId) {
  if (!modelId) return -1
  var entry = support ? support[modelId] : undefined
  if (!entry || typeof entry !== "object") return -1
  if (entry.supported === true) return 1
  if (entry.supported === false) return 0
  return -1
}

function readerLevel(state, key) {
  var value = state ? state[key] : undefined
  return typeof value === "number" && value >= 0 ? value : -1
}

// ---- Brand detection from SDP UUIDs ----

var SONY_MDR_V2_UUID = "956c7b26-d49a-4ba8-b03f-b17d393cb6e2"
var SONY_MDR_V1_UUID = "96cc203e-5068-46ad-b32d-e316f5e069ba"
var SAMSUNG_SPP_UUID = "2e73a4ad-332d-41fc-90e2-16bef06523f2"
var NOTHING_NT_LINK_UUID = "aeac4a03-dff5-498f-843a-34487cf133eb"
var CSR_GAIA_UUID = "00001100-d102-11e1-9b23-00025b00a5a5"
var SOUNDCORE_UUID_PREFIX = "0cf12d31-fac3-4553-bd80-d6832e7"
var OPPO_HEYMELODY_UUID = "0000079a-d102-11e1-9b23-00025b00a5a5"

function uuidsFromBluetoothctl(text) {
  var out = []
  var lines = str(text).split("\n")
  for (var i = 0; i < lines.length; i++) {
    var found = lines[i].match(/UUID:.*\(([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})\)/)
    if (found) out.push(found[1].toLowerCase())
  }
  return out
}

var BACKENDS = [
  { name: "sony", bridge: "sony-bridge",
    uuids: [SONY_MDR_V2_UUID, SONY_MDR_V1_UUID],
    args: ["address", "uuid", "name"],
    ambient: { min: 0, max: 20, voice: "Focus on voice" } },
  { name: "samsung", bridge: "samsung-bridge",
    uuids: [SAMSUNG_SPP_UUID], args: ["address"] },
  { name: "nothing", bridge: "nothing-bridge",
    uuids: [NOTHING_NT_LINK_UUID], args: ["address", "name"] },
  { name: "xiaomi", bridge: "xiaomi-bridge",
    uuids: [CSR_GAIA_UUID], args: ["address"] },
  { name: "soundcore", bridge: "soundcore-bridge",
    uuidPrefix: SOUNDCORE_UUID_PREFIX, args: ["address"],
    ambient: { min: 1, max: 5, voice: "Wind noise reduction" } },
  { name: "oppo", bridge: "oppo-bridge",
    uuids: [OPPO_HEYMELODY_UUID], args: ["address"] },
  { name: "jbl", bridge: "jbl-bridge",
    ble: true, args: ["bleAddress", "modelId"] }
]

var AMBIENT_DEFAULT = { min: 0, max: 20, voice: "Focus on voice" }

function backendRow(name) {
  for (var i = 0; i < BACKENDS.length; i++)
    if (BACKENDS[i].name === str(name)) return BACKENDS[i]
  return null
}

function rowClaims(row, id) {
  if (row.uuids && row.uuids.indexOf(id) !== -1) return true
  return !!row.uuidPrefix && id.indexOf(row.uuidPrefix) === 0
}

function controlBackend(uuids, bleAddress) {
  var list = uuids || []
  var ids = []
  for (var i = 0; i < list.length; i++) ids.push(str(list[i]).trim().toLowerCase())
  for (var r = 0; r < BACKENDS.length; r++) {
    var row = BACKENDS[r]
    if (row.ble) {
      if (str(bleAddress).trim() !== "") return row.name
      continue
    }
    for (var j = 0; j < ids.length; j++)
      if (rowClaims(row, ids[j])) return row.name
  }
  return ""
}

var CLASSIC_BACKENDS = []
for (var backendIndex = 0; backendIndex < BACKENDS.length; backendIndex++)
  if (!BACKENDS[backendIndex].ble) CLASSIC_BACKENDS.push(BACKENDS[backendIndex].name)

function isClassicBackend(backend) {
  return CLASSIC_BACKENDS.indexOf(str(backend)) !== -1
}

function bridgeFor(backend) {
  var row = backendRow(backend)
  return row ? row.bridge : ""
}

function bridgeArgs(backend, values) {
  var row = backendRow(backend)
  if (!row) return []
  var known = values || {}
  var out = []
  for (var i = 0; i < row.args.length; i++) out.push(str(known[row.args[i]]))
  return out
}

function ambientRange(backend) {
  var row = backendRow(backend)
  return row && row.ambient ? row.ambient : AMBIENT_DEFAULT
}

function sonyUuidFor(uuids) {
  var list = uuids || []
  var v1 = ""
  for (var i = 0; i < list.length; i++) {
    var id = str(list[i]).trim().toLowerCase()
    if (id === SONY_MDR_V2_UUID) return SONY_MDR_V2_UUID
    if (id === SONY_MDR_V1_UUID) v1 = SONY_MDR_V1_UUID
  }
  return v1
}

var MODE_ORDER = ["off", "anc", "ambient", "talkthru"]

function modesAvailable(state) {
  var list = state ? state.available : undefined
  if (!list || !Array.isArray(list)) return MODE_ORDER.slice()
  var out = []
  for (var i = 0; i < MODE_ORDER.length; i++)
    if (list.indexOf(MODE_ORDER[i]) !== -1) out.push(MODE_ORDER[i])
  return out
}

var ANC_LEVEL_ORDER = ["low", "mid", "high", "adaptive"]

function ancLevelsAvailable(state) {
  var list = state ? state.ancLevels : undefined
  if (!list || !Array.isArray(list)) return []
  var out = []
  for (var i = 0; i < ANC_LEVEL_ORDER.length; i++)
    if (list.indexOf(ANC_LEVEL_ORDER[i]) !== -1) out.push(ANC_LEVEL_ORDER[i])
  return out
}

function ancLevel(state) {
  var value = str(state ? state.ancLevel : "")
  return ANC_LEVEL_ORDER.indexOf(value) !== -1 ? value : ""
}

function bridgeLevel(state, key) {
  var battery = state ? state.battery : undefined
  if (!battery || typeof battery !== "object" || Array.isArray(battery)) return -1
  var value = battery[key]
  if (typeof value !== "number" || !isFinite(value)) return -1
  if (value < 0 || value > 100) return -1
  return Math.round(value)
}

function bridgeCharging(state, key) {
  var battery = state ? state.battery : undefined
  if (!battery || typeof battery !== "object") return false
  var list = battery.charging
  return Array.isArray(list) && list.indexOf(key) !== -1
}

function bridgeCaseStale(state) {
  var battery = state ? state.battery : undefined
  return !!battery && typeof battery === "object" && battery.caseStale === true
}

function singleLevelFromState(state) {
  if (!state || state.single !== true) return -1
  var value = state.singleLevel
  return typeof value === "number" && value >= 0 ? value : -1
}
