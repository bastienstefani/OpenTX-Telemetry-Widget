-- Headless smoke test for INAV Lua Telemetry.
-- Usage: lua tests/smoke.lua <scenario> <srcroot> <sandbox>   (or: make test)
-- Mocks the OpenTX/EdgeTX Lua API well enough to load and run the script.

local scenario, SRC, SANDBOX = arg[1], arg[2], arg[3]
local scen = ({
	x9d_otx    = { w = 212, h = 64,  radio = "x9d+",       os = nil,      major = 2, minor = 3, bitmap = "Bitmap" },
	qx7_etx    = { w = 128, h = 64,  radio = "x7",         os = "EdgeTX", major = 3, minor = 0, bitmap = "bitmap" },
	horus_otx  = { w = 480, h = 272, radio = "x10",        os = nil,      major = 2, minor = 3, bitmap = "Bitmap" },
	tx16s_etx2 = { w = 480, h = 272, radio = "tx16s",      os = "EdgeTX", major = 2, minor = 11, bitmap = "both" },
	tx16s_etx3 = { w = 480, h = 272, radio = "tx16s",      os = "EdgeTX", major = 3, minor = 0, bitmap = "bitmap", crsf = true },
	mk3_etx3   = { w = 800, h = 480, radio = "tx16s",      os = "EdgeTX", major = 3, minor = 0, bitmap = "bitmap", touch = true },
	tx15_etx3  = { w = 480, h = 320, radio = "tx15",       os = "EdgeTX", major = 3, minor = 0, bitmap = "bitmap" },
	nv14_etx3  = { w = 320, h = 480, radio = "nv14",       os = "EdgeTX", major = 3, minor = 0, bitmap = "bitmap" },
	qx7_crsf   = { w = 128, h = 64,  radio = "x7",         os = "EdgeTX", major = 3, minor = 0, bitmap = "bitmap", crsf = true },
})[scenario]
assert(scen, "unknown scenario " .. tostring(scenario))

-- The bundled OpenTX Lua 5.2.4 fork renumbers the type tags but not the type name table,
-- so its type() returns shifted names on the host. Remap by probing known values.
do
	local rawtype = type
	local names = { [rawtype(0)] = "number", [rawtype("")] = "string", [rawtype({})] = "table", [rawtype(print)] = "function",
		[rawtype(nil)] = "nil", [rawtype(true)] = "boolean", [rawtype(coroutine.create(function() end))] = "thread", [rawtype(io.stdout)] = "userdata" }
	type = function(v) return names[rawtype(v)] or rawtype(v) end
end
local isfloat = math.type and function(v) return math.type(v) == "float" end or function() return false end
local problems = {}
local function where()
	for lvl = 3, 12 do
		local info = debug.getinfo(lvl, "Sl")
		if not info then break end
		if info.short_src and info.short_src:find("SCRIPTS") then
			return " @" .. info.short_src:match("[^/]*$") .. ":" .. tostring(info.currentline)
		end
	end
	return ""
end
local function problem(fmt, ...)
	problems[#problems + 1] = string.format(fmt, ...) .. where()
end
local function num(v, what)
	if type(v) ~= "number" then problem("%s: expected number, got %s", what, type(v)) end
end

-- Screen / flag constants
LCD_W, LCD_H = scen.w, scen.h
local consts = { "SOLID", "DOTTED", "RIGHT", "LEFT", "CENTER", "SMLSIZE", "MIDSIZE", "DBLSIZE", "XXLSIZE", "INVERS", "BLINK",
	"FORCE", "ERASE", "GREY_DEFAULT", "SHADOWED", "VCENTER", "PREC1", "PREC2", "BOLD", "TIMEHOUR",
	"PLAY_NOW", "PLAY_BACKGROUND", "BOOL", "COLOR", "VALUE", "STRING", "SOURCE",
	"BLACK", "WHITE", "RED", "GREY", "LIGHTGREY", "DARKGREY", "YELLOW", "BLUE", "GREEN", "ORANGE", "LIGHTBLUE", "DARKRED", "DARKBLUE", "DARKGREEN",
	"CUSTOM_COLOR", "TEXT_COLOR", "WARNING_COLOR", "MENU_TITLE_COLOR", "TEXT_INVERTED_COLOR", "LINE_COLOR",
	"EVT_EXIT_BREAK", "EVT_MENU_BREAK", "EVT_PAGE_BREAK", "EVT_PAGE_LONG", "EVT_ENTER_BREAK", "EVT_ENTER_LONG",
	"EVT_PLUS_BREAK", "EVT_MINUS_BREAK", "EVT_PLUS_FIRST", "EVT_MINUS_FIRST", "EVT_PLUS_REPT", "EVT_MINUS_REPT",
	"EVT_ROT_BREAK", "EVT_ROT_LONG", "EVT_ROT_LEFT", "EVT_ROT_RIGHT", "EVT_VIRTUAL_NEXT_PAGE", "EVT_VIRTUAL_PREV_PAGE",
	"EVT_VIRTUAL_ENTER", "EVT_VIRTUAL_ENTER_LONG", "EVT_VIRTUAL_MENU", "EVT_VIRTUAL_MENU_LONG", "EVT_VIRTUAL_NEXT",
	"EVT_VIRTUAL_NEXT_REPT", "EVT_VIRTUAL_PREV", "EVT_VIRTUAL_PREV_REPT", "EVT_VIRTUAL_INC", "EVT_VIRTUAL_INC_REPT",
	"EVT_VIRTUAL_DEC", "EVT_VIRTUAL_DEC_REPT", "EVT_TOUCH_TAP", "EVT_TOUCH_SLIDE", "EVT_TOUCH_FIRST", "EVT_TOUCH_BREAK" }
for i, c in ipairs(consts) do _G[c] = 1000 + i * 7 end
SOLID, FORCE, ERASE, RIGHT, SMLSIZE, MIDSIZE, DBLSIZE, INVERS, BLINK = 0, 4, 8, 16, 32, 64, 128, 256, 512
if scen.w >= 480 or scen.h >= 480 then EVT_SYS_FIRST = 9001 end
if scen.os == nil then GREY_DEFAULT = 0x2000 end
if scen.radio == "nv14" then EVT_SYS_FIRST, EVT_ENTER_BREAK, EVT_EXIT_BREAK = nil, nil, nil end

-- Time
local ticks = 100
function getTime() return ticks end
function getDateTime() return { year = 2026, mon = 9, day = 14, hour = 12, min = 0, sec = 0 } end
function getUsage() return 10 end
function killEvents() end
function collectgarbage_orig() end

-- Version / settings
function getVersion()
	return string.format("%d.%d.0", scen.major, scen.minor), scen.radio .. "-simu", scen.major, scen.minor, 0, scen.os
end
function getGeneralSettings()
	return { battMin = 6.5, battMax = 8.4, language = "en", voice = "en", imperial = 0 }
end

-- Telemetry
local sensors = {}
local values = {}
local nextId = 1
local function addSensor(name, unit)
	sensors[name] = { id = nextId, name = name, unit = unit or 0 }
	nextId = nextId + 1
end
for _, n in ipairs({ "tx-voltage", "thr", "ail", "ele", "rud", "trim-t6" }) do addSensor(n, 0) end
if scen.crsf then
	for _, n in ipairs({ "FM", "RFMD", "1RSS", "2RSS", "RQly", "TPWR", "Sats", "Capa", "RxBt", "RxBt-", "Yaw", "Hdg", "Ptch", "Roll", "Curr", "Curr+", "GPS", "GAlt", "Alt", "Alt+", "GSpd", "GSpd+", "VSpd", "Fuel" }) do
		addSensor(n, (n == "Alt" or n == "GAlt" or n == "Alt+") and 9 or (n == "GSpd" or n == "GSpd+") and 7 or (n == "VSpd") and 5 or 0)
	end
else
	for _, n in ipairs({ "RxBt", "Mode", "GNSS", "GAlt", "GPS", "Hdg", "0450", "Alt", "Dist", "Curr", "Alt+", "Dist+", "Curr+", "VFAS", "VFAS-", "A4", "A4-", "Fuel", "VSpd", "GSpd", "GSpd+", "Ptch", "Roll", "AccX", "AccY", "AccZ" }) do
		addSensor(n, (n == "Alt" or n == "GAlt" or n == "Alt+" or n == "Dist" or n == "Dist+") and 9 or (n == "GSpd" or n == "GSpd+") and 7 or (n == "VSpd") and 5 or 0)
	end
end
local byId = {}
for n, s in pairs(sensors) do byId[s.id] = n end
function getFieldInfo(n) return sensors[n] end
function getValue(id)
	local name = byId[id]
	if name == nil then return 0 end
	local v = values[name]
	if v == nil then return 0 end
	return v
end
local rssi = 0
function getRSSI() return rssi, 45, 42 end
local audio = {}
function playFile(f) audio[#audio + 1] = f end
function playNumber(n, u) num(n, "playNumber"); audio[#audio + 1] = "num:" .. tostring(n) end
function playTone() end
function playHaptic() end
function crossfireTelemetryPush() return true end
function crossfireTelemetryPop() return nil end

-- Model
local timers = { [0] = { value = 0 }, [1] = { value = 0 }, [2] = { value = 0 } }
model = {
	getInfo = function() return { name = "Test Model" } end,
	getTimer = function(i) num(i, "getTimer index"); return timers[math.floor(i)] end,
	setTimer = function(i, t) num(i, "setTimer index"); timers[math.floor(i)] = t end,
}

-- Files
local real_io = { open = io.open, read = io.read, write = io.write, close = io.close, seek = io.seek }
local function resolve(path, mode)
	local sand = SANDBOX .. path
	if mode and mode:find("w") then
		return sand
	end
	local f = real_io.open(sand, "rb")
	if f then f:close(); return sand end
	return SRC .. path
end
function io.open(path, mode)
	local fh = real_io.open(resolve(path, mode), mode or "r")
	return fh
end
function io.read(fh, n) local s = fh:read(n); return s or "" end
function io.write(fh, s) fh:write(s) end
function io.close(fh) fh:close() end
function io.seek(fh, pos) fh:seek("set", pos) end

-- Script loading (maps .luac to .lua under the source tree)
function loadScript(path, mode)
	local p = path:gsub("%.luac$", ""):gsub("%.lua$", "")
	local chunk, err = loadfile(SRC .. p .. ".lua")
	if not chunk then error("loadScript(" .. path .. "): " .. tostring(err)) end
	return chunk
end

-- Strings produced by string.format("%.Nf") legitimately contain ".0"; remember them so the
-- float-display check below only flags values that were not explicitly formatted.
local legit = {}
local real_format = string.format
string.format = function(fmt, ...)
	local r = real_format(fmt, ...)
	if fmt:find("%%[%-%d%.]*f") then legit[r] = true end
	return r
end
local function explicitlyFormatted(s)
	for l in pairs(legit) do
		if s:find(l, 1, true) then return true end
	end
	return false
end

-- LCD
local drawn = {}
local function flags(f, what) if f ~= nil then num(f, what .. " flags") end end
lcd = {}
function lcd.clear(c) drawn = {} end
function lcd.RGB(r, g, b) return (r * 65536 + g * 256 + b) + 0x10000000 end
function lcd.setColor(i, c) end
function lcd.getColor(i) return 0 end
function lcd.sizeText(s, f) return #tostring(s) * 8, 16 end
function lcd.drawText(x, y, s, f)
	num(x, "drawText x"); num(y, "drawText y"); flags(f, "drawText")
	s = tostring(s)
	if (s:find("%d%.0%f[^%d]") or s:find("%d%.0$")) and not explicitlyFormatted(s) then
		problem("drawText: suspicious float text %q", s)
	end
	drawn[#drawn + 1] = s
end
function lcd.drawLine(x1, y1, x2, y2, p, f) num(x1, "line"); num(y1, "line"); num(x2, "line"); num(y2, "line") end
function lcd.drawRectangle(x, y, w, h, f) num(x, "rect"); num(y, "rect"); num(w, "rect"); num(h, "rect") end
function lcd.drawFilledRectangle(x, y, w, h, f) num(x, "fill"); num(y, "fill"); num(w, "fill"); num(h, "fill") end
function lcd.drawPoint(x, y) num(x, "point"); num(y, "point") end
function lcd.drawGauge(x, y, w, h, v, m, f) num(v, "gauge value"); num(m, "gauge max") end
function lcd.drawTimer(x, y, s, f) num(s, "timer seconds") end
function lcd.drawNumber(x, y, v, f) num(v, "drawNumber") end
function lcd.drawBitmap(b, x, y, s) assert(type(b) == "table" and b.__bitmap, "drawBitmap: not a bitmap") end
local bitmaplib = {
	open = function(name)
		local f = real_io.open(SRC .. name, "rb")
		if not f then problem("bitmap.open: missing %s", name) else f:close() end
		return { __bitmap = name }
	end,
	getSize = function() return 10, 10 end,
	resize = function(b) return b end,
}
if scen.bitmap == "Bitmap" or scen.bitmap == "both" then Bitmap = bitmaplib end
if scen.bitmap == "bitmap" or scen.bitmap == "both" then bitmap = bitmaplib end

-- Widget options as passed by the firmware
local zone = { x = 0, y = 0, w = LCD_W, h = LCD_H, xabs = 0, yabs = 0 }
local options = { Restore = 1, Text = WHITE, Warn = YELLOW, Warning = YELLOW }

-- Telemetry scenarios
local function setTelemetry(on, armed, fix, t)
	rssi = on and 80 or 0
	values["tx-voltage"] = 7.9
	values["thr"] = armed and 200 or -1000
	values["ail"], values["ele"], values["rud"] = 0, 0, 0
	values["trim-t6"] = 0
	if not on then return end
	if scen.crsf then
		values["1RSS"] = -60; values["2RSS"] = -70; values["RQly"] = 95; values["RFMD"] = 2; values["TPWR"] = t and 1000 or 250
		values["Sats"] = fix and 12 or 0; values["Capa"] = 300 + (t or 0); values["RxBt"] = 16.2; values["RxBt-"] = 15.9
		values["Yaw"] = 1.2; values["Hdg"] = 1.1; values["Ptch"] = 0.1; values["Roll"] = -0.05
		values["FM"] = armed and "ACRO" or "OK"
	else
		values["RxBt"] = 5.1
		values["Mode"] = armed and 5 or 1
		values["GNSS"] = fix and (12 + 800 + 3000) or 0
		values["Hdg"] = 123.4; values["0450"] = 1234
		values["Ptch"] = 12.5; values["Roll"] = -8.5
		values["Dist"] = 42; values["Dist+"] = 84
		values["VFAS"] = 16.1; values["VFAS-"] = 15.7; values["A4"] = 4.02; values["A4-"] = 3.93
	end
	values["GAlt"] = fix and 123.4 or 0
	values["GPS"] = fix and { lat = 48.858370 + (t or 0) * 0.0001, lon = 2.294481 } or { lat = 0, lon = 0 }
	values["Alt"] = 55.5 + (t or 0); values["Alt+"] = 120.5
	values["Curr"] = 12.3; values["Curr+"] = 30.1
	values["Fuel"] = 77
	values["VSpd"] = 1.5
	values["GSpd"] = 33.3; values["GSpd+"] = 61.2
end

local function step(inav, event, touch)
	ticks = ticks + 5
	local ok, err = pcall(inav.background)
	if not ok then problem("background(): %s", err) end
	ticks = ticks + 5
	local ok2, err2 = pcall(inav.run, event, touch)
	if not ok2 then problem("run(%s): %s", tostring(event), err2) end
end

local function newScript()
	local chunk = assert(loadfile(SRC .. "/SCRIPTS/TELEMETRY/iNav.lua"))
	return chunk(zone, options)
end

-- Scenario run ---------------------------------------------------------------
local HORUS = LCD_W >= 480 or LCD_H >= 480
setTelemetry(false)
local ok, inav = pcall(newScript)
if not ok then
	print("FAIL load: " .. tostring(inav))
	os.exit(1)
end

-- Frames without telemetry, then with telemetry, GPS fix, armed flight, disarm
for i = 1, 3 do step(inav, 0) end
setTelemetry(true, false, false)
for i = 1, 3 do step(inav, 0) end
setTelemetry(true, false, true)
for i = 1, 3 do step(inav, 0) end
setTelemetry(true, true, true)
for i = 1, 40 do
	setTelemetry(true, true, true, i)
	step(inav, 0)
end
-- Max/min toggle and views
step(inav, EVT_VIRTUAL_NEXT)
if not HORUS then
	for i = 1, 4 do step(inav, EVT_ENTER_BREAK); step(inav, 0) end
end
setTelemetry(true, false, true, 40)
for i = 1, 3 do step(inav, 0) end
step(inav, EVT_VIRTUAL_PREV)
step(inav, 0)

-- Config menu: open, walk all options, edit each one up and down, then exit (saves the file)
local MENU = HORUS and EVT_SYS_FIRST or EVT_VIRTUAL_MENU_LONG
step(inav, MENU)
for i = 1, 36 do
	step(inav, EVT_ENTER_BREAK)          -- select
	step(inav, EVT_VIRTUAL_INC)          -- +
	step(inav, EVT_VIRTUAL_INC)          -- +
	step(inav, EVT_VIRTUAL_DEC)          -- -
	step(inav, EVT_ENTER_BREAK)          -- deselect
	step(inav, EVT_VIRTUAL_NEXT)         -- next option
end
step(inav, EVT_EXIT_BREAK)
step(inav, 0)
local cfg = real_io.open(SANDBOX .. "/SCRIPTS/TELEMETRY/iNav/cfg/Test Model.dat", "rb")
if not cfg then
	problem("config file was not written")
else
	local content = cfg:read("*a"); cfg:close()
	if content:find("[^%d]") then problem("config file contains non-digit characters: %q", content) end
	print("config saved: " .. content)
end

-- Reload with saved config and a language override, run a few frames in each view
local lf = real_io.open(SANDBOX .. "/SCRIPTS/TELEMETRY/iNav/cfg/lang.dat", "wb"); lf:write("fr"); lf:close()
ok, inav = pcall(newScript)
if not ok then problem("reload: %s", tostring(inav)) else
	setTelemetry(true, true, true, 5)
	for i = 1, 5 do step(inav, 0) end
	step(inav, MENU)
	local french = false
	for i = 1, 40 do
		step(inav, EVT_VIRTUAL_NEXT)
		for _, d in ipairs(drawn) do if d:find("Batterie") or d:find("Alerte") then french = true end end
	end
	if not french then problem("French language file was not applied after cfg/lang.dat override") end
	step(inav, EVT_EXIT_BREAK)
	step(inav, 0)
	-- Touch screen interaction (EdgeTX App Mode on 800x480 radios)
	if scen.touch then
		step(inav, EVT_TOUCH_TAP, { x = 100, y = 100, tapCount = 1 })
		step(inav, EVT_TOUCH_TAP, { x = 100, y = 400, tapCount = 1 })   -- opens the config menu
		step(inav, EVT_TOUCH_SLIDE, { x = 100, y = 300, slideY = 35, startX = 100, startY = 265 })
		step(inav, EVT_TOUCH_SLIDE, { x = 100, y = 200, slideY = -35, startX = 100, startY = 235 })
		step(inav, EVT_TOUCH_TAP, { x = 100, y = 60, tapCount = 1 })    -- select a row
		step(inav, EVT_TOUCH_TAP, { x = 100, y = 60, tapCount = 1 })    -- toggle edit
		step(inav, EVT_EXIT_BREAK)
		step(inav, EVT_EXIT_BREAK)
		step(inav, 0)
	end
end

-- Report
local shown = {}
for _, s in ipairs(drawn) do shown[#shown + 1] = s end
print(string.format("%-11s frames ok, last frame drew %d strings, %d audio events", scenario, #drawn, #audio))
if #problems > 0 then
	local seen = {}
	for _, p in ipairs(problems) do
		if not seen[p] then seen[p] = true; print("  PROBLEM: " .. p) end
	end
	os.exit(1)
end
