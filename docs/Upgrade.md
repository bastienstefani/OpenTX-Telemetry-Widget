# Upgrade INAV Telemetry
## Already have Lua Telemetry installed
If you're already running Lua Telemetry, you can quickly upgrade to the latest release version by following these simple steps:

1. Download the package for your firmware from the [latest release](https://github.com/iNavFlight/OpenTX-Telemetry-Widget/releases/latest) (Note: **NOT** the GitHub "Source code" archives):
    * `LuaTelemetry_vX.Y_edgetx.zip` for EdgeTX 2.11 and later (including EdgeTX 3.x)
    * `LuaTelemetry_vX.Y.zip` for OpenTX 2.3 and EdgeTX up to 2.10
1. If you are upgrading the radio firmware from EdgeTX 2.10 (or OpenTX) to EdgeTX 2.11 or later at the same time, delete the old `SCRIPTS/TELEMETRY/iNav` and `WIDGETS/iNav` folders first: the old pre-compiled `.luac` files cannot be loaded by the new Lua 5.3 interpreter
1. Copy the contents of the ZIP file (`SCRIPTS` and `WIDGETS` folders) to the transmitter's SD card's root

![](http://www.leethost.com/link_pics/master.png)

And you're ready to go!
