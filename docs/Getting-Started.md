### Installation

!!! tip
    To upgrade from a previous version, see the (_**much**_ shorter) [upgrade instructions](../Upgrade)

Don't be too concerned about the length of these instructions. The first two sections are about setting up telemetry in INAV and your transmitter, which for most is already completed.  Also, the instructions are for multiple transmitters, telemetry protocols and I've tried to be very descriptive so even a novice could follow along. Therefore, it's a bit verbose but proceeds quickly, I promise.

#### INAV Configurator Telemetry Setup

1. Setup SmartPort(S.Port), F.Port, D-series, or Crossfire telemetry to send to your transmitter: [INAV telemetry docs](https://github.com/iNavFlight/inav/master/docs/Telemetry.md)
1. FrSky receivers (skip for TBS Crossfire):
    1. If you have an current sensor and want to show fuel percent remaining:
        * `set smartport_fuel_unit = PERCENT`
        * Set `battery_capacity` to the mAh you want to draw from your battery
    1. If instead you want to show the current sensor's mAh:
        * `set smartport_fuel_unit = MAH`
    1. With INAV v2.0.0+, `set frsky_pitch_roll = ON` in CLI settings for accurate attitude display and pitch angle

#### Add Telemetry Sensors to Transmitter

1. With battery connected and **after GPS fix** [discover telemetry sensors](https://www.youtube.com/watch?v=n09q26Gh858) so all telemetry sensors are discovered
1. FrSky receivers (skip for TBS Crossfire):
    1. Telemetry distance sensor name `0420` (or `0007` with D-series receivers) should be changed to `Dist` and set to the desired unit: `m` or `ft`
    1. The sensors `Dist`, `Alt`, `GAlt` and `Gspd` can be changed to the desired unit: `m` or `ft` / `kmh` or `mph`
    1. If you `set frsky_pitch_roll = ON` on INAV v2.0.0+ (which I suggest) you can optionally change the following for clarification:
        * Telemetry sensor `0430` (or `0008` with D-series receivers) can be changed to `Ptch`
        * Telemetry sensor `0440` (or `0020` with D-series receivers) can be changed to `Roll`
    1. Prior to INAV 8, **don't** change `Tmp1` or `Tmp2` from Celsius to Fahrenheit! They're not temps (used for flight modes and GNSS info)
	1. For INAV 8 and later, the default is to use sensor IDs `0470` and `0480` for flight mode and GNSS data respectively. For convenience, the names `Mode` (for `0470`) and `GNSS` (for `0480`) can be set in the transmitter.
    1. If you don't have a current sensor, you can optionally delete or rename the `Fuel` sensor so it doesn't show in Lua Telemetry

#### Install/Setup Lua Telemetry on Transmitter

1. Download the package matching your firmware from the [latest release](https://github.com/iNavFlight/OpenTX-Telemetry-Widget/releases/latest) (Note: **NOT** the GitHub "Source code" archives), see [Download Options](#download-options):
    * `LuaTelemetry_vX.Y_edgetx.zip` for EdgeTX 2.11 and later (including EdgeTX 3.x)
    * `LuaTelemetry_vX.Y.zip` for OpenTX 2.3 and EdgeTX up to 2.10
1. Copy the contents of the ZIP file (`SCRIPTS` and `WIDGETS` folders) to the transmitter's SD card's root
    * Taranis:
        1. In model setup, page to `DISPLAY`
        1. Set desired screen to `Script`
        1. Select `iNav`
    * Horus/Jumper T16 (EdgeTX before v2.11):
        1. Long-press `TELE` to access the user interface/views layout
        1. Select the desired view (or create a new one)
        1. Make `Layout` full screen, turn off `Top bar` and `Sliders+Trims`
        1. Select `Setup widgets`
        1. Press `Enter` till a menu appears and select `Select widget`
        1. Scroll to the `iNav` widget and press `Enter`
        1. Optionally (while still selecting the `iNAV` script), long-press `Enter`, select `Widget settings` where you can set your theme's `Text` color and `Warning` color
    * RadioMaster TX16S and other color touchscreen radios (EdgeTX v2.11, v2.12 and v3.x):
        1. Long-press `TELE` to access the user interface/views layout
        1. Select the desired view (or create a new one)
        1. Choose the `App Mode` layout (not `Full screen`) — this allows the widget to receive key and touch events and automatically hides the top bar and sliders/trims
        1. Long-press `Enter` (jog wheel) — it may take more than one long-press for the widget selection menu to appear
        1. Select `Select widget`, scroll to `iNav` and press `Enter`
        1. Optionally, long-press `Enter`, select `Widget settings` to set your theme's `Text` color and `Warning` color
        1. Press `RTN` to exit setup
        1. After a reboot, you may need to long-press the jog wheel or long-touch the screen to re-enter app mode (events are not passed to the widget until app mode is active)
    * Nirvana NV14:
        1. Press the Widgets icon
        1. Select the desired view
        1. Change the layout to full screen
        1. Uncheck all boxes
        1. Select `Setup widgets`, tap the screen and select `iNAV`
        1. Optionally, you can enable `Restore` (to restore your theme's colors) and set your theme's `Text` color and `Warning` color
1. Press `EXIT` or `RTN` several times to exit (back icon on Nirvana)

### Download Options
When [downloading INAV Lua Telemetry](https://github.com/iNavFlight/OpenTX-Telemetry-Widget/releases/latest), pick the package that matches your radio firmware. The scripts are the same in every package, only the pre-compiled form differs:

* **LuaTelemetry_vX.Y_edgetx.zip** - pre-compiled for **EdgeTX 2.11 and later** (EdgeTX 2.11, 2.12 and 3.x run Lua 5.3). Includes all views, sound files and languages
* **LuaTelemetry_vX.Y.zip** - pre-compiled for **OpenTX 2.3** and **EdgeTX up to 2.10** (Lua 5.2). Includes all views, sound files and languages
* **LuaTelemetry_vX.Y_lua.zip** - plain Lua sources, works on any supported firmware. The radio compiles the scripts itself the first time the widget runs, which takes a few seconds and needs more free memory than the pre-compiled packages, so prefer one of the packages above on radios with little memory
* **Source code** (zip / tar.gz) - GitHub source archives for this release - *not for transmitter install*

!!! warning
    Pre-compiled scripts are tied to the Lua version of the firmware. Installing the OpenTX / EdgeTX 2.10 package on EdgeTX 2.11 or later fails with a `version mismatch in precompiled chunk` error (or a blank screen) because those firmwares moved from Lua 5.2 to Lua 5.3. Delete the old `SCRIPTS/TELEMETRY/iNav` and `WIDGETS/iNav` folders from the SD card before installing the EdgeTX package.


#### Running Lua Telemetry

* Taranis:
    1. From the main screen on your transmitter, long-press `Page` (down d-pad on X-Lite)
    1. If Lua Telemetry isn't on your first page, short-press `Page` to the Lua Telemetry screen
* Horus/Jumper T16/Nirvava NV14:
    1. From the main screen on your transmitter, press `PgUp/Dn` (swipe left on Nirvana) to the Lua Telemetry view
* [Screen Description](../Screen-Description)
* [Configuration Settings](../Configuration-Settings)
* [Tips & Common Problems](../Tips-&-Common-Problems)
