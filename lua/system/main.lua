-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- this file is executed once on the engine lua startup

-- change default lookup path
package.path = "lua/system/?.lua;lua/?.lua;?.lua"

local STP = require "StackTracePlus"
debug.traceback = STP.stacktrace

-- only set ground model in engine mode
require("utils")
particles = require("particles")
require("groundmodel")
console   = require("console")
gamelogic = require("gamelogic")
scanvas   = require("scanvas")
simpleAI  = require("simpleAI")
json      = require("json")
wayPoints = require("wp")

enableWayPoints = 1
--scenario  = require("scenario")

local systemCanvas = nil

print("system reloaded")

--initCanvas()

--scenario.init()

-- set default gravity for anything: default is -9.81
-- Settings.gravity = 0

messageQueue = {}

function msg(txt, t)
	t = t or 5
	m = { txt = txt, t = t }
	table.insert(messageQueue, m)
end

raceTimer = 0
lastChk = -1

local aiMode = "off"

function graphicsStep(dt)
	--print("engine - graphicsStep " .. dt )
	--gamelogic.update(dt)
	
	--scanvas.update(dt)
	
	if aiMode ~= "off" then
		--print("aiupdate")
		simpleAI.update(aiMode)
	end
	raceTimer = raceTimer + dt
	
	if ( enableWayPoints ~= 0 ) then
		wayPoints.update(dt)
	end


	--msg("The quick brown fox jumps over the lazy dog.")
end


function onEnterCheckpoint(triggerID, triggerName, objPID, objID, objName)
	print(" object " .. tostring(objPID) .. " / " .. tostring(objName) .. " [" .. tostring(objID) .. "] just entered trigger " .. tostring(triggerName) .. " [" .. tostring(triggerID) .. "]")
	
	chkNum = tonumber(string.match(triggerName, "%d+"))
	
	if chkNum == 1 and lastChk == -1 then
		msg("Race started!")
		raceTimer = 0
		lastChk = chkNum
	elseif chkNum == 5 and lastChk == 4 then
		msg(string.format("Race finished in %0.3f s", raceTimer))
		lastChk = -1
	elseif chkNum == lastChk + 1 then
		msg("Passed checkpoint "..chkNum..", head to "..(chkNum+1))
		lastChk = chkNum
	end
	
		
	
	--[[ 
	--example: reset the vehicle
	local b = BeamEngine:getSlot(objPID)
	if b ~= nil then
		b:queueLuaCommand("obj:requestReset(RESET_PHYSICS)")
	end
	]]--
end

function onLeaveCheckpoint(triggerID, triggerName, objPID, objID, objName)
	print(" object " .. tostring(objPID) .. " / " .. tostring(objName) .. " [" .. tostring(objID) .. "] just left trigger " .. tostring(triggerName) .. " [" .. tostring(triggerID) .. "]")
end

function onTickCheckpoint(triggerID, triggerName, objPID, objID, objName)
	print(" object " .. tostring(objPID) .. " / " .. tostring(objName) .. " [" .. tostring(objID) .. "] just ticked in trigger " .. tostring(triggerName) .. " [" .. tostring(triggerID) .. "]")
end


function onGasStationTick(triggerID, triggerName, objPID, objID, objName)
	local b = BeamEngine:getSlot(objPID)
	if b ~= nil then
		-- TODO
		b:queueLuaCommand("drivetrain.refill()")
	end
end

function AIGUICallback(mode, str)
	if mode == "apply" then
		--print("luaChooserPartsCallback("..tostring(str)..")")
		local args = unserialize(str)
		--dump(args)
		if args.aimode then
			aiMode = args.aimode
			print("aiMode switched to "..aiMode)
			if aiMode == "off" then
				simpleAI.reset()
			end
		end
	end
end

function showAIGUI()
	local g = [[beamngguiconfig 1
callback system AIGUICallback
title system configuration
control
  type = chooser
  name = aimode
  description = AI Mode
  level = 1
  selection = ]] .. aiMode .. [[

  option = off Off
  option = player Chasing Player
  option = car0 Flee from player

]]	
	print(g)
	gameEngine:showGUI(g)
end