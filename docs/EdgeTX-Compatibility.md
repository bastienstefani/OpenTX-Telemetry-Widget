# Developer Notes - EDGETX Compatibility

## Introduction

This guide describes now to modify the inav Lua Telemetry widget such that it works correctly in both EdgeTX and OpenTX.

EdgeTX is a touch-screen enabled fork of OpenTX. As part of the touch-screen enhancement, EdgeTX has expanded the way that some of the colour LCD APIs function. These changes are described in the [excellent EdgeTX API documenation](https://luadoc.edgetx.org/part_ii_-_opentx_lua_api_programming_guide/drawing-flags-and-colors).

## Summary of changes of the inav Lua widget

In order to keep the inav Lua widget compatible with both EdgeTX and OpenTX, the following are required for code that may run on colour screens.

* Do not modify the indexed colours as these are shared by the system theme and other widgets.
* Use the new `data.RBG()` function to convert RGB colour definitions to a Lua `COLOR`.
  - Do not call `lcd.RBG()` directly as it may return `nil` under some circumstances on OpenTX.
  - Do not use pre-computed integer values for colours; these will not work on EdgeTX.
* Do not set colours and display flags directly _on colour devices_. Use the new `data.set_flags()` function as this will work correctly on both EdgeTX and OpenTX. It will also work on older monochrome displays, but is unnecesasry in code that will not be executed on a colour device (e.g. `src/SCRIPTS/TELEMETRY/iNav/radar.lua`); note that `src/SCRIPTS/TELEMETRY/iNav/menu.lua` requires some care, it is runs on both colour and monochrome devices.

## Hints and tips

* The project should only contain a single instance of `CUSTOM_COLOR`; this is embedded in `src/SCRIPTS/TELEMETRY/iNav/func_h.lua` and is only used on OpenTX.
* The project uses its own colour map. It should not contain any other instances of `_COLOR` symbols.
* The user preference text colour is cached in `data.TextColor`, the user preference warning colour (which the widget modifies) is cached in `data.WarningColor`.

## Examples

```
local mycol = data.RGB(0, 121, 180)
local myflags = data.set_flags(MIDSIZE + RIGHT, mycol)
text(x, y, "A Message", myflags)
text(x1, y2, "More Text", myflags)
text(x2, y2, "Something else", data.set_flags(0, data.TextColor))
-- note we can't use myflags again (at least OpenTX) without resetting the value
line(x2, y2, x3, y3, SOLID, data.set_flags(0, LIGHTGREY))
```

## EdgeTX 2.11 and later (EdgeTX 3.x): Lua 5.3

EdgeTX 2.11 moved from Lua 5.2 to Lua 5.3 and EdgeTX 3.x builds on the same interpreter. The firmware is compiled with `LUA_32BITS` (32-bit integers and 32-bit floats), `LUA_COMPAT_5_2` (so `bit32` and `math.atan2` are still available) and `LUA_FLOORN2I=1`. OpenTX 2.3 still runs Lua 5.2. The widget must keep working on both, which means:

* **Pre-compiled files are not portable.** A `.luac` produced for Lua 5.2 fails on Lua 5.3 with `version mismatch in precompiled chunk` and vice versa. `make dist` therefore builds two pre-compiled packages, `LuaTelemetry_vX.Y.zip` (Lua 5.2, from `3rdparty/lua-5.2.4`) and `LuaTelemetry_vX.Y_edgetx.zip` (Lua 5.3, from `3rdparty/lua-5.3.6`), plus the plain source package. The bundled Lua 5.3.6 is built with the same options as the firmware and writes the same bytecode header as EdgeTX (a 4-byte `size_t` field, see `3rdparty/lua-5.3.6/README`), so the host-built files load directly on the radio.
* **Integers and floats are distinct types.** `tostring(1.0)` is `"1.0"` on Lua 5.3 (it was `"1"` on 5.2), so a float that reaches `lcd.drawText()` or string concatenation shows a trailing `.0`. Keep values that are conceptually integers as integers: use `math.floor()` (which returns an integer on 5.3) before displaying or concatenating, and avoid `x * 0.1 * 10` style arithmetic on integer settings. Configuration values in `config[n].v` are integers unless the option is a decimal one (`d = true`); `menu.lua`, `load.lua` and `save.lua` are written to preserve that.
* **Float to integer conversion floors.** Because of `LUA_FLOORN2I`, a float passed where the API expects an integer (`lcd.drawText` coordinates, `lcd.drawTimer`, `%d` in `string.format`) is floored instead of raising an error, and so is a float used as a table key or compared with `==` against an integer (`1.3 == 1` is true on the radio). Do not rely on float equality with integer constants.
* **Precision is 32-bit.** Floats only carry about 7 significant digits, which is enough for the telemetry shown here (GPS coordinates lose roughly the last decimal of the `%.6f` display).
* **`Bitmap` became `bitmap`.** EdgeTX 2.11 renamed the bitmap library to `bitmap` and only kept `Bitmap` as a temporary alias; `func_h.lua` resolves `bitmap or Bitmap` so both firmwares work.
* **Sources are compiled on the radio.** When only `.lua` files are installed, EdgeTX compiles them and writes the `.luac` next to them on first use. Code that checks whether an optional module exists must therefore look for both extensions (see `lang.lua`).

### Testing without a radio

The bundled interpreters can run the scripts on a PC with a small set of mocked EdgeTX functions. Build them with `make lua luac lua53 luac53`; `3rdparty/lua-5.3.6/src/lua` behaves like the EdgeTX 2.11+ interpreter (32-bit numbers, flooring conversions) and `3rdparty/lua-5.2.4/src/lua` like OpenTX (note that this OpenTX fork renumbers the Lua type tags, so its `type()` returns shifted names on the host; only its `luac` output matters).
