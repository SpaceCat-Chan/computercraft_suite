-- ****************************************************** --
-- ****************************************************** --
-- **             Reactor Madness Program              ** --
-- **                 for Big Reactor                  ** --
-- **                Written by krakaen                ** --
-- **                  Video Tutorial                  ** --
-- ** 	https://www.youtube.com/watch?v=SbbT7ncyS2M    ** --
-- ****************************************************** --
-- ****************************************************** --

-- ******** Version 0.1 Changelog (02/16/2016) ********
-- Changed currentRFTotal to 1 (makes power show at start)

-- ******** Version 0.2 Changelog (02/16/2016) ********
-- Added fuel usage (mb/t)
-- Added function round
-- Added function comma_value
-- Added function format_num

-- ******** Version 0.3 Changelog (02/17/2016) ********
-- Change Rod looking for 0 instead of 1

-- ******** Version 0.4 Changelog (10/18/2016) ********
-- Change rodLevel to do a Math.ceil instead of Math.floor

-- ******** Version 0.5 Changelog (03/01/2017) ********
-- Change drawBoxed and drawFilledBox for drawLines with for loop
-- to get compatibility with 1.60+

-- ******** Version 0.6 Changelog (03/22/2017) ********
-- Added Custom error handling
-- fixed typo in controlsSize for controlsSize

-- ******** Version 0.7 Changelog (05/15/2018) ********
-- Added new functions for Extreme reactor handling. Will work on both new and old versions

-- ******** Version 0.8 Changelog (31/10/2020) ********
-- Added new functions for Bigger reactor handling. Will work on both new, newer and old versions

-- you need to give the index to be able to use the program
-- ex : NameOfProgram Index   (reactor Krakaen) 

-- ******** Version 0.9 Changelog (2021-02-14) ********
-- made better date format
-- made connection to russian server instead of reactor


-- connect to remote server
local JSON = require("JSON")

print("trying to find remote reactor")

local verify_token = "yes, we are russian servers, we will not detonate the reactor"
local response_token = "i agree"

local modem = peripheral.wrap("left")
modem.open(42069)

local connection_success = false
function listen_for_handshake_response()
	repeat
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			print("recieved from 6969: "..json_mesg)
			local is_json, message = pcall(JSON.decode, JSON, json_mesg)
			if is_json and message.type == "handshake response" and message.token == response_token then
				connection_success = true
			end
		end
	until connection_success
end

function send_handshake()
	repeat
		modem.transmit(6969, 42069, JSON:encode{type = "handshake", token=verify_token})
		sleep(10)
	until connection_success
end

parallel.waitForAll(listen_for_handshake_response, send_handshake)

print("found remote reactor")
-- humor shit below here --


local args = { ... }

local button = {}
local filleds = {}
local boxes = {}
local lines = {}
local texts = {}

local refresh = true

local infosSize = {}
local controlsSize = {}
local numbersSize = {}
local currentRfTotal = 1
local currentRfTick = 1
local currentFuelConsumedLastTick = 0.00001


local rfPerTickMax = 1
local minPowerRod = 0
local maxPowerRod = 100
local currentRodLevel = 1

local index = "reactor_info"

local reactors = {}
local monitors = {}

function checkVersionTooOld()
	monitors = {peripheral.find("monitor")}
end


function checkMBFunctionAvailability()
	modem.transmit(6969, 42069, JSON:encode{type = "mbIsAvailable"})
	local got_answer = false
	while not got_answer do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			if message.type == "mbIsAvailable" then
				if message.yes then
					return
				else
					error("aa")
				end
			end
		end
	end
end

function checkErrors()
	checkVersionTooOld()

  	if monitors[1] == nil then
    	error("The Monitor is not being detected, make sure the connections(modem) are activated", 0)
  	end
end



checkErrors() -- Verify that everything is okay to start the program

local mon = monitors[1]

-- Use the black thingy sponge to clear the chalkboard

term.redirect(mon)
mon.clear()
mon.setTextColor(colors.white)
mon.setBackgroundColor(colors.black)

function clearTable()
	button = {}
end


-- All the things that make my buttons work

function setButton(name, title, func, xmin, ymin, xmax, ymax, elem, elem2, color)
	button[name] = {}
	button[name]["title"] = title
  	button[name]["func"] = func
   	button[name]["active"] = false
   	button[name]["xmin"] = xmin
   	button[name]["ymin"] = ymin
   	button[name]["xmax"] = xmax
   	button[name]["ymax"] = ymax
   	button[name]["color"] = color
   	button[name]["elem"] = elem
   	button[name]["elem2"] = elem2
end

-- stuff and things for buttons

function fill(text, color, bData)
   mon.setBackgroundColor(color)
   mon.setTextColor(colors.white)
   local yspot = math.floor((bData["ymin"] + bData["ymax"]) /2)
   local xspot = math.floor((bData["xmax"] - bData["xmin"] - string.len(bData["title"])) /2) +1
   for j = bData["ymin"], bData["ymax"] do
      mon.setCursorPos(bData["xmin"], j)
      if j == yspot then
         for k = 0, bData["xmax"] - bData["xmin"] - string.len(bData["title"]) +1 do
            if k == xspot then
               mon.write(bData["title"])
            else
               mon.write(" ")
            end
         end
      else
         for i = bData["xmin"], bData["xmax"] do
            mon.write(" ")
         end
      end
   end
   mon.setBackgroundColor(colors.black)
end

-- stuff and things for buttons

function screen()
   local currColor
   for name,data in pairs(button) do
      local on = data["active"]
      currColor = data["color"]
      fill(name, currColor, data)
   end
end

-- stuff and things for buttons

function flash(name)
	screen()
end

-- magical handler for clicky clicks

function checkxy(x, y)
   for name, data in pairs(button) do
      if y>=data["ymin"] and  y <= data["ymax"] then
         if x>=data["xmin"] and x<= data["xmax"] then
            data["func"](data["elem"], data["elem2"])
            flash(data['name'])
            return true
            --data["active"] = not data["active"]
            --print(name)
         end
      end
   end
   return false
end

-- Don't question my code, it works on my machine...

function label(w, h, text)
   mon.setCursorPos(w, h)
   mon.write(text)
end

-- Draw function : put's all the beautiful magic in the screen

function draw()
	for key,value in pairs(filleds) do
		local counter = 1
		for i=value[2],value[4],1 do
			paintutils.drawLine(value[1] , value[2]+counter, value[3], value[2]+counter, value[5])
			counter = counter + 1
		end
	end

	for key,value in pairs(boxes) do
		paintutils.drawLine(value[1] , value[2], value[1], value[4], value[5])
		paintutils.drawLine(value[1] , value[2], value[3], value[2], value[5])
		paintutils.drawLine(value[1] , value[4], value[3], value[4], value[5])
		paintutils.drawLine(value[3] , value[2], value[3], value[4], value[5])
	end

	for key,value in pairs(lines) do
		paintutils.drawLine(value[1] , value[2], value[3], value[4], value[5])
	end

	for key,value in pairs(texts) do
		mon.setCursorPos(value[1], value[2])
		mon.setTextColor(value[4])
		mon.setBackgroundColor(value[5])
		mon.write(value[3])
	end
	screen()
	resetDraw()
end

-- Resets the elements to draw to only draw the neccessity

function resetDraw()
	filleds = {}
	boxes = {}
	lines = {}
	texts = {}
end

-- Handles all the clicks for the buttons

function clickEvent()
	local myEvent={os.pullEvent("monitor_touch")}
	checkxy(myEvent[3], myEvent[4])
end

-- Power up the reactor (M&N are a good source of food right?)

function powerUp(m,n)
	modem.transmit(6969, 42069, JSON:encode{type = "setActive", value = true})
end

-- Power down the reactor (M&N are a good source of food right?)

function powerDown(m,n)
	modem.transmit(6969, 42069, JSON:encode{type = "setActive", value = false})
end

-- Handles and calculate the Min and Max of the power limitation

function modifyRods(limit, number)
	local tempLevel = 0

	if limit == "min" then
		tempLevel = minPowerRod + number
		if tempLevel <= 0 then
			minPowerRod = 0
		end

		if tempLevel >= maxPowerRod then
			minPowerRod = maxPowerRod -10
		end

		if tempLevel < maxPowerRod and tempLevel > 0 then
			minPowerRod = tempLevel
		end
	else
		tempLevel = maxPowerRod + number
		if tempLevel <= minPowerRod then
			maxPowerRod = minPowerRod +10
		end

		if tempLevel >= 100 then
			maxPowerRod = 100
		end

		if tempLevel > minPowerRod and tempLevel < 100 then
			maxPowerRod = tempLevel
		end
	end

	table.insert(lines, {controlsSize['inX'], controlsSize['inY'] +(controlsSize['sectionHeight']*1)+4, controlsSize['inX'] + controlsSize['width'], controlsSize['inY']+(controlsSize['sectionHeight']*1)+4, colors.black})

	table.insert(texts, {controlsSize['inX']+5, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+4, minPowerRod .. '%', colors.lightBlue, colors.black})
	table.insert(texts, {controlsSize['inX']+13, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+4, '--', colors.white, colors.black})
	table.insert(texts, {controlsSize['inX']+20, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+4, maxPowerRod .. '%', colors.purple, colors.black})

	setInfoToFile()
	adjustRodsLevel()
end

-- Calculate and adjusts the level of the rods

function mbIsConnected()
	modem.transmit(6969, 42069, JSON:encode{type = "mbIsConnected"})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.mbIsConnected
		end
	end
end
function mbIsAssembled()
	modem.transmit(6969, 42069, JSON:encode{type = "mbIsAssembled"})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.mbIsAssembled
		end
	end
end

function setControlRodsLevels(levels)
	modem.transmit(6969, 42069, JSON:encode{type = "setControlRodsLevels", levels = levels})
end

function setAllControlRodLevels(levels)
	modem.transmit(6969, 42069, JSON:encode{type = "setAllControlRodLevels", levels = levels})
end

function adjustRodsLevel()
	local rfTotalMax = 10000000

	local allStats = getAllStats()
	local currentRfTotal = allStats["rfTotal"]
	local reactorRodsLevel = allStats["reactorRodsLevel"]

	differenceMinMax = maxPowerRod - minPowerRod

	maxPower = (rfTotalMax/100) * maxPowerRod
	minPower = (rfTotalMax/100) * minPowerRod

	if currentRfTotal >= maxPower then
		currentRfTotal = maxPower
	end

	if currentRfTotal <= minPower then
		currentRfTotal = minPower
	end

	currentRfTotal = currentRfTotal - (rfTotalMax/100) * minPowerRod

	local rfInBetween = (rfTotalMax/100) * differenceMinMax
	local rodLevel = math.ceil((currentRfTotal/rfInBetween)*100)
	if pcall(checkMBFunctionAvailability) then
		if mbIsConnected() == true and mbIsAssembled() == true then
			for key,value in pairs(reactorRodsLevel) do 
				reactorRodsLevel[key] = rodLevel
			end
			setControlRodsLevels(reactorRodsLevel)
		end
	else
		setAllControlRodLevels(rodLevel)
	end
end

-- Creates the frame and the basic of the visual
-- Also adds the variables informations for placement of stuff and things

function addDrawBoxesSingleReactor()
	local w, h = mon.getSize()
	local margin = math.floor((w/100)*2)

	infosSize['startX'] = margin + 1
	infosSize['startY'] =  margin + 1
	infosSize['endX'] = (((w-(margin*2))/3)*2)-margin
	infosSize['endY'] = h - margin
	infosSize['height'] = infosSize['endY']-infosSize['startY']-(margin*2)-2
	infosSize['width'] = infosSize['endX']-infosSize['startX']-(margin*2)-2
	infosSize['inX'] = infosSize['startX'] + margin +1
	infosSize['inY'] = infosSize['startY'] + margin +1
	infosSize['sectionHeight'] = math.floor(infosSize['height']/3)

	table.insert(boxes, {infosSize['startX'] , infosSize['startY'], infosSize['endX'], infosSize['endY'], colors.gray})
	local name = "INFOS"
	table.insert(lines, {infosSize['startX'] + margin , infosSize['startY'], infosSize['startX'] + (margin*2) + #name+1, infosSize['startY'], colors.black})
	table.insert(texts, {infosSize['startX'] + (margin*2), infosSize['startY'], name, colors.white, colors.black})

	local names = {}
	names[1] = 'ENERGY LAST TICK'
	names[2] = 'ENERGY STORED'
	names[3] = 'CONTROL ROD LEVEL'

	for i=0,2,1 do
		table.insert(texts, {infosSize['inX'] + margin, infosSize['inY'] + (infosSize['sectionHeight']*i) +i, names[i+1], colors.white, colors.black})
		table.insert(filleds, {infosSize['inX'] , infosSize['inY'] + 2 + (infosSize['sectionHeight']*i) +i, infosSize['inX'] + infosSize['width'], infosSize['inY'] + (infosSize['sectionHeight']*(i+1))-2 +i, colors.lightGray})
	end


	-- Controls

	controlsSize['startX'] = infosSize['endX'] + margin + 1
	controlsSize['startY'] =  margin + 1
	controlsSize['endX'] = w-margin
	controlsSize['endY'] = (((h - (margin*2))/3)*2) +1
	controlsSize['height'] = controlsSize['endY']-controlsSize['startY']-(margin)-1
	controlsSize['width'] = controlsSize['endX']-controlsSize['startX']-(margin*2)-2
	controlsSize['inX'] = controlsSize['startX'] + margin +1
	controlsSize['inY'] = controlsSize['startY'] + margin

	table.insert(boxes, {controlsSize['startX'] , controlsSize['startY'], controlsSize['endX'], controlsSize['endY'], colors.gray})
	name = "CONTROLS"
	table.insert(lines, {controlsSize['startX'] + margin , controlsSize['startY'], controlsSize['startX'] + (margin*2) + #name+1, controlsSize['startY'], colors.black})
	table.insert(texts, {controlsSize['startX'] + (margin*2), controlsSize['startY'], name, colors.white, colors.black})

	controlsSize['sectionHeight'] = math.floor(controlsSize['height']/4)


	mon.setTextColor(colors.white)
	setButton("ON","ON", powerUp, controlsSize['inX'], controlsSize['inY'], controlsSize['inX'] + math.floor(controlsSize['width']/2) -1, controlsSize['inY'] +2, 0, 0, colors.green)
	setButton("OFF","OFF", powerDown, controlsSize['inX'] + math.floor(controlsSize['width']/2) +2, controlsSize['inY'], controlsSize['inX'] + controlsSize['width'], controlsSize['inY'] +2,0, 0, colors.red)

	table.insert(texts, {controlsSize['inX']+8, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+1, 'AUTO-CONTROL', colors.white, colors.black})

	table.insert(texts, {controlsSize['inX']+5, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+3, 'MIN', colors.lightBlue, colors.black})
	table.insert(texts, {controlsSize['inX']+5, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+4, minPowerRod..'%', colors.lightBlue, colors.black})

	table.insert(texts, {controlsSize['inX']+13, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+4, '--', colors.white, colors.black})
	table.insert(texts, {controlsSize['inX']+20, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+3, 'MAX', colors.purple, colors.black})
	table.insert(texts, {controlsSize['inX']+20, controlsSize['inY'] +(controlsSize['sectionHeight']*1)+4, maxPowerRod..'%', colors.purple, colors.black})
	mon.setTextColor(colors.white)

	setButton("low-10","-10", modifyRods, controlsSize['inX'], controlsSize['inY'] +(controlsSize['sectionHeight']*2)+2, controlsSize['inX'] + math.floor(controlsSize['width']/2) -1, controlsSize['inY'] +(controlsSize['sectionHeight']*2)+4, "min", -10, colors.lightBlue)
	setButton("high-10","-10", modifyRods, controlsSize['inX'] + math.floor(controlsSize['width']/2) +2, controlsSize['inY'] +(controlsSize['sectionHeight']*2)+2, controlsSize['inX'] + controlsSize['width'], controlsSize['inY'] +(controlsSize['sectionHeight']*2)+4, "max", -10, colors.purple)

	setButton("low+10","+10", modifyRods, controlsSize['inX'], controlsSize['inY'] +(controlsSize['sectionHeight']*3)+2, controlsSize['inX'] + math.floor(controlsSize['width']/2) -1, controlsSize['inY'] +(controlsSize['sectionHeight']*3)+4, "min", 10, colors.lightBlue)
	setButton("high+10","+10", modifyRods, controlsSize['inX'] + math.floor(controlsSize['width']/2) +2, controlsSize['inY'] +(controlsSize['sectionHeight']*3)+2, controlsSize['inX'] + controlsSize['width'], controlsSize['inY'] +(controlsSize['sectionHeight']*3)+4, "max", 10, colors.purple)

	-- Numbers

	numbersSize['startX'] = infosSize['endX'] + margin + 1
	numbersSize['startY'] = controlsSize['endY'] + margin + 1
	numbersSize['endX'] = w-margin
	numbersSize['endY'] = h-margin
	numbersSize['height'] = numbersSize['endY']-numbersSize['startY']-(margin)-1
	numbersSize['width'] = numbersSize['endX']-numbersSize['startX']-(margin*2)-2
	numbersSize['inX'] = numbersSize['startX'] + margin +1
	numbersSize['inY'] = numbersSize['startY'] + margin

	table.insert(boxes, {numbersSize['startX'] , numbersSize['startY'], numbersSize['endX'], numbersSize['endY'], colors.gray})
	name = "NUMBERS"
	table.insert(lines, {numbersSize['startX'] + margin , numbersSize['startY'], numbersSize['startX'] + (margin*2) + #name+1, numbersSize['startY'], colors.black})
	table.insert(texts, {numbersSize['startX'] + (margin*2), numbersSize['startY'], name, colors.white, colors.black})

	refresh = true
	while refresh do
		parallel.waitForAny(refreshSingleReactor,clickEvent)
	end
end

-- Makes and Handles the draw function for less lag in the visual

function getEnergyStats()
	modem.transmit(6969, 42069, JSON:encode{type = "getEnergyStats"})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.getEnergyStats
		end
	end
end
function getFuelStats()
	modem.transmit(6969, 42069, JSON:encode{type = "getFuelStats"})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.getFuelStats
		end
	end
end
function getControlRodsLevels()
	modem.transmit(6969, 42069, JSON:encode{type = "getControlRodsLevels"})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.getControlRodsLevels
		end
	end
end
function getEnergyStored()
	modem.transmit(6969, 42069, JSON:encode{type = "getEnergyStored"})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.getEnergyStored
		end
	end
end
function getEnergyProducedLastTick()
	modem.transmit(6969, 42069, JSON:encode{type = "getEnergyProducedLastTick"})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.getEnergyProducedLastTick
		end
	end
end
function getControlRodLevel(rod)
	modem.transmit(6969, 42069, JSON:encode{type = "getControlRodLevel", rod=rod})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.getControlRodLevel
		end
	end
end
function getFuelConsumedLastTick()
	modem.transmit(6969, 42069, JSON:encode{type = "getFuelConsumedLastTick"})
	while true do
		local _, _, _, sender, json_mesg, _ = os.pullEvent("modem_message")
		if sender == 6969 then
			local message = JSON:decode(json_mesg)
			return message.getFuelConsumedLastTick
		end
	end
end
function getAllStats()
	local stats = {}

	if pcall(checkMBFunctionAvailability) then 
		if mbIsConnected() == true and mbIsAssembled() == true then
			local reactorEnergyStats = getEnergyStats()
			local reactorFuelStats = getFuelStats()
			stats["reactorRodsLevel"] = getControlRodsLevels()

			stats["rfTotal"] = reactorEnergyStats["energyStored"]
			stats["rfPerTick"] = math.ceil(reactorEnergyStats["energyProducedLastTick"])
			stats["rodLevel"] = stats["reactorRodsLevel"][0]
			stats["fuelPerTick"] = round(reactorFuelStats["fuelConsumedLastTick"], 2)
		end
	else 
		stats["rfTotal"] = getEnergyStored()
		stats["rfPerTick"] = math.floor(getEnergyProducedLastTick())
		stats["rodLevel"] = math.floor(getControlRodLevel(0))
		stats["fuelPerTick"] = getFuelConsumedLastTick()
	end
	
	return stats 
end

function refreshSingleReactor()
	local rfPerTick = 0
	local rfTotal = 0
	local rfTotalMax = 10000000

	local allStats = getAllStats()
	rfTotal = allStats["rfTotal"]
	rfPerTick = allStats["rfPerTick"]
	rodLevel = allStats["rodLevel"]
	fuelPerTick = allStats["fuelPerTick"]

	local i = 0
	local infotoAdd = 'RF PER TICK : '

	if currentRfTick ~= rfPerTick then
		currentRfTick = rfPerTick
		if rfPerTick > rfPerTickMax then
			rfPerTickMax = rfPerTick
		end

		table.insert(lines, {numbersSize['inX'] , numbersSize['inY'],numbersSize['inX'] + numbersSize['width'] , numbersSize['inY'], colors.black})
		table.insert(texts, {numbersSize['inX'], numbersSize['inY'], infotoAdd .. rfPerTick .. " RF", colors.white, colors.black})
		table.insert(filleds, {infosSize['inX'] , infosSize['inY'] + 1 + (infosSize['sectionHeight']*i) +i, infosSize['inX'] + infosSize['width'], infosSize['inY'] + (infosSize['sectionHeight']*(i+1))-2 +i, colors.lightGray})

		width = math.floor((infosSize['width'] / rfPerTickMax)*rfPerTick)
		table.insert(filleds, {infosSize['inX'] , infosSize['inY'] + 1 + (infosSize['sectionHeight']*i) +i, infosSize['inX'] + width, infosSize['inY'] + (infosSize['sectionHeight']*(i+1))-2 +i, colors.green})

	end

	i = 1
	infotoAdd = 'ENERGY STORED : '
	if currentRfTotal ~= rfTotal then
		currentRfTotal = rfTotal

		table.insert(filleds, {infosSize['inX'] , infosSize['inY'] + 1 + (infosSize['sectionHeight']*i) +i, infosSize['inX'] + infosSize['width'], infosSize['inY'] + (infosSize['sectionHeight']*(i+1))-2 +i, colors.lightGray})

		width = math.floor((infosSize['width'] / rfTotalMax)*rfTotal)
		table.insert(filleds, {infosSize['inX'] , infosSize['inY'] + 1 + (infosSize['sectionHeight']*i) +i, infosSize['inX'] + width, infosSize['inY'] + (infosSize['sectionHeight']*(i+1))-2 +i, colors.green})
		table.insert(lines, {numbersSize['inX'] , numbersSize['inY'] +2 ,numbersSize['inX'] + numbersSize['width'] , numbersSize['inY'] +2, colors.black})
		table.insert(texts, {numbersSize['inX'], numbersSize['inY']+ 2 , infotoAdd .. rfTotal .. " RF", colors.white, colors.black})
	end

	i = 2
	infotoAdd = 'CONTROL ROD LEVEL : '
	if currentRodLevel ~= rodLevel then
		currentRodLevel = rodLevel

		table.insert(filleds, {infosSize['inX'] , infosSize['inY'] + 1 + (infosSize['sectionHeight']*i) +i, infosSize['inX'] + infosSize['width'], infosSize['inY'] + (infosSize['sectionHeight']*(i+1))-2 +i, colors.lightGray})

		width = math.floor((infosSize['width'] / 100)*rodLevel)
		table.insert(filleds, {infosSize['inX'] , infosSize['inY'] + 1 + (infosSize['sectionHeight']*i) +i, infosSize['inX'] + width, infosSize['inY'] + (infosSize['sectionHeight']*(i+1))-2 +i, colors.green})
		table.insert(lines, {numbersSize['inX'] , numbersSize['inY']+4 ,numbersSize['inX'] + numbersSize['width'] , numbersSize['inY'] +4, colors.black})
		table.insert(texts, {numbersSize['inX'], numbersSize['inY']+ 4 , infotoAdd .. rodLevel .. "%", colors.white, colors.black})
	end

	i = 3
	infotoAdd = 'FUEL USAGE : '
	if currentFuelConsumedLastTick ~= fuelPerTick then
		currentFuelConsumedLastTick = fuelPerTick

		table.insert(lines, {numbersSize['inX'] , numbersSize['inY']+6 ,numbersSize['inX'] + numbersSize['width'] , numbersSize['inY'] +6, colors.black})
		table.insert(texts, {numbersSize['inX'], numbersSize['inY']+ 6 , infotoAdd .. format_num(tonumber(fuelPerTick),3) .. "mb/t", colors.white, colors.black})
	end

	mon.setTextColor(colors.white)
	adjustRodsLevel()

	draw()

	sleep(2)
end

--
-- ** Get the informations from the index file
-- line 1 = min ROD
-- line 2 = max ROD
--

function getInfoFromFile()

	 if (fs.exists(index..".txt") == false) then
	 	file = io.open(index..".txt","w")
	    file:write("0")
	    file:write("\n")
	    file:write("100")
	    file:close()
	else
		file = fs.open(index..".txt","r")
		minPowerRod = tonumber(file.readLine())
		maxPowerRod = tonumber(file.readLine())
	    file.close()
	end
end

-- Save informations to the index file

function setInfoToFile()
	file = io.open(index..".txt","w")
	file:write(minPowerRod .. "\n" .. maxPowerRod)
    file:flush()
    file:close()
end

---============================================================
-- add comma to separate thousands
-- From Lua-users.org/wiki/FormattingNumbers
--
--
function comma_value(amount)
  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

---============================================================
-- rounds a number to the nearest decimal places
-- From Lua-users.org/wiki/FormattingNumbers
--
--
function round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

--===================================================================
-- given a numeric value formats output with comma to separate thousands
-- and rounded to given decimal places
-- From Lua-users.org/wiki/FormattingNumbers
--
function format_num(amount, decimal, prefix, neg_prefix)
  local str_amount,  formatted, famount, remain

  decimal = decimal or 2  -- default 2 decimal places
  neg_prefix = neg_prefix or "-" -- default negative sign

  famount = math.abs(round(amount,decimal))
  famount = math.floor(famount)

  remain = round(math.abs(amount) - famount, decimal)

        -- comma to separate the thousands
  formatted = comma_value(famount)

        -- attach the decimal portion
  if (decimal > 0) then
    remain = string.sub(tostring(remain),3)
    formatted = formatted .. "." .. remain ..
                string.rep("0", decimal - string.len(remain))
  end

        -- attach prefix string e.g '$'
  formatted = (prefix or "") .. formatted

        -- if value is negative then format accordingly
  if (amount<0) then
    if (neg_prefix=="()") then
      formatted = "("..formatted ..")"
    else
      formatted = neg_prefix .. formatted
    end
  end

  return formatted
end

-- Clear and make the pixel smaller because we are not blind

mon.setBackgroundColor(colors.black)
mon.clear()
mon.setTextScale(0.5)

-- Get the information from the index file
getInfoFromFile()


-- Add's the visual and starts the Loop
addDrawBoxesSingleReactor()