--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Horus X10 and X12 radios
--
-- Copyright (C) 2018-2019. Alessandro Apostoli
-- https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--

---------------------
-- MAIN CONFIG
-- 480x272 LCD_W x LCD_H
---------------------

---------------------
-- VERSION
---------------------
-- load and compile of lua files
-- uncomment to force compile of all chunks, comment for release
--#define COMPILE
-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764

---------------------
-- FEATURE CONFIG
---------------------
-- enable splash screen for no telemetry data
--#define SPLASH
-- enable code to draw a compass rose vs a compass ribbon
--#define COMPASS_ROSE

---------------------
-- DEV FEATURE CONFIG
---------------------
-- enable memory debuging 
--#define MEMDEBUG
-- enable dev code
--#define DEV
-- uncomment haversine calculation routine
--#define HAVERSINE
-- enable telemetry logging to file (experimental)
--#define LOGTELEMETRY
-- use radio channels imputs to generate fake telemetry data
--#define TESTMODE
-- enable debug of generated hash or short hash string
--#define HASHDEBUG

---------------------
-- DEBUG REFRESH RATES
---------------------
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE

---------------------
-- SENSOR IDS
---------------------
















-- Throttle and RC use RPM sensor IDs

---------------------
-- BATTERY DEFAULTS
---------------------
---------------------------------
-- BACKLIGHT SUPPORT
-- GV is zero based, GV 8 = GV 9 in OpenTX
---------------------------------
---------------------------------
-- CONF REFRESH GV
---------------------------------

---------------------------------
-- ALARMS
---------------------------------
--[[
 ALARM_TYPE_MIN needs arming (min has to be reached first), value below level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_MAX no arming, value above level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_TIMER no arming, fired periodically, spoken time, reset on landing
 ALARM_TYPE_BATT needs arming (min has to be reached first), value below level for grace, no reset on landing
{ 
  1 = notified, 
  2 = alarm start, 
  3 = armed, 
  4 = type(0=min,1=max,2=timer,3=batt), 
  5 = grace duration
  6 = ready
  7 = last alarm
}  
--]]--
--
--

--

----------------------
-- COMMON LAYOUT
----------------------
-- enable vertical bars HUD drawing (same as taranis)
--#define HUD_ALGO1
-- enable optimized hor bars HUD drawing
--#define HUD_ALGO2
-- enable hor bars HUD drawing






--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------

--------------------------
-- UNIT OF MEASURE
--------------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
-- 

-----------------------
-- LIBRARY LOADING
-----------------------

----------------------
--- COLORS
----------------------

--#define COLOR_LABEL 0x7BCF
--#define COLOR_BG 0x0169
--#define COLOR_BARSEX 0x10A3


--#define COLOR_SENSORS 0x0169

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------


--------------------------
-- CLIPPING ALGO DEFINES
--------------------------








---------------------------------
-- LAYOUT
---------------------------------






-- x:300 y:135 inside HUD













local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)--,getMaxValue,getBitmap,drawBlinkBitmap,lcdBacklightOn)
  --lcd.setColor(CUSTOM_COLOR,lcd.RGB(0,33,56))
  --lcd.drawFilledRectangle(x + 3,21,93,203,CUSTOM_COLOR)  
  if conf.rangeFinderMax > 0 then
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.setColor(CUSTOM_COLOR,0x0000)     
    lcd.drawText(25, 21, "Range("..unitLabel..")", SMLSIZE+CUSTOM_COLOR)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.setColor(CUSTOM_COLOR,0xF800)       
      lcd.drawFilledRectangle(88-65, 33+4,65,21,CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,0xFFFF)     
    lcd.drawText(88, 33, string.format("%.1f",rng*0.01*unitScale), MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  else
    flags = BLINK
    -- always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = utils.getMaxValue(alt,12)
    end
    if status.showMinMaxValues == true then
      flags = 0
    end
    lcd.setColor(CUSTOM_COLOR,0x0000)     
    lcd.drawText(25, 21, "AltAsl("..unitLabel..")", SMLSIZE+CUSTOM_COLOR)
    local stralt = string.format("%d",alt*unitScale)
    lcd.setColor(CUSTOM_COLOR,0xFFFF)     
    lcd.drawText(88, 33, stralt, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  end
  -- LABELS
  lcd.setColor(CUSTOM_COLOR,0x0000)
  lcd.drawText(88, 102, "Dist("..unitLabel..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  --lcd.drawText(88, 138, "Dist("..unitLongLabel..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(88, 154, "WPN", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(165, 154, "WPD("..unitLabel..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- drawn on HUD bottom left
  lcd.drawText(88, 63, "ASpd("..conf.horSpeedLabel..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.drawText(315, 154, "Thr(%)", SMLSIZE+CUSTOM_COLOR+RIGHT)
  -- VALUES
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  -- home distance
  drawLib.drawHomeIcon(2, 102 + 18,utils)
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 0xce, 0)) --yellow
  local strdist = string.format("%d",dist*unitScale)
  lcd.setColor(CUSTOM_COLOR,0xFE60)   
  lcd.drawText(88, 113, strdist, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  -- total distance
  lcd.setColor(CUSTOM_COLOR,0xFFFF)
  lcd.drawText(88, 138, unitLongLabel, SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawNumber(69, 134, telemetry.totalDist*unitLongScale*100, 0+RIGHT+CUSTOM_COLOR+PREC2)
  -- wp number
  lcd.drawNumber(68, 164, telemetry.wpNumber,MIDSIZE+RIGHT+CUSTOM_COLOR)
  -- wp distance
  lcd.drawNumber(165, 164, telemetry.wpDistance * unitScale,MIDSIZE+RIGHT+CUSTOM_COLOR)
  -- airspeed
  lcd.drawNumber(88,74,telemetry.airspeed * conf.horSpeedMultiplier,MIDSIZE+RIGHT+PREC1+CUSTOM_COLOR)
  -- throttle %
  lcd.drawNumber(315,164,telemetry.throttle,MIDSIZE+RIGHT+CUSTOM_COLOR)
  -- LINES
  lcd.setColor(CUSTOM_COLOR,0xFFFF) --yellow
  -- wp bearing
  drawLib.drawRArrow(80,180,9,telemetry.wpBearing*45,CUSTOM_COLOR)
  --
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(3, 33+4,true,false,utils)
    drawLib.drawVArrow(3, 113+4 ,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
  -- RC CHANNELS
  --[[
  if conf.enableRCChannels == true then
    for i=1,#telemetry.rcchannels do
      setTelemetryValue(Thr_ID, Thr_SUBID, Thr_INSTANCE + i, telemetry.rcchannels[i], 13 , Thr_PRECISION , "RC"..i)
    end
  end
  --]]  
  -- VFR
  setTelemetryValue(0x0AF, 0, 0, telemetry.airspeed*0.1, 4 , 0 , "ASpd")
  setTelemetryValue(0x010F, 0, 1, telemetry.baroAlt*10, 9 , 1 , "BAlt")
  setTelemetryValue(0x050F, 0, 0, telemetry.throttle, 13 , 0 , "Thr")
  
  -- WP
  setTelemetryValue(0x050F, 0, 10, telemetry.wpNumber, 0 , 0 , "WPN")
  setTelemetryValue(0x082F, 0, 10, telemetry.wpDistance, 9 , 0 , "WPD")
  
  -- crosstrack error and wp bearing not exposed as OpenTX variables by default
  --[[
  setTelemetryValue(WPX_ID, WPX_SUBID, WPX_INSTANCE, telemetry.wpXTError, 9 , WPX_PRECISION , WPX_NAME)
  setTelemetryValue(WPB_ID, WPB_SUBID, WPB_INSTANCE, telemetry.wpBearing, 20 , WPB_PRECISION , WPB_NAME)
  --]]end

return {drawPane=drawPane,background=background}
