local JSON = require("JSON")

local verify_token = "yes, we are russian servers, we will not detonate the reactor"
local response_token = "i agree"

local modem = peripheral.wrap("left")
modem.open(6969)

local reactors = {peripheral.find("bigger-reactor")}
if reactors[1] == nil then
	reactors = {peripheral.find("BigReactors-Reactor")}
end
if reactors[1] == nil then
	error("unable to find reactor", 0)
end
local reactor = reactors[1]

while true do
	local _, _, _, from, json_mesg, _ = os.pullEvent("modem_message")
	print("recieved: "..json_mesg)
	print("from: "..tostring(from))
	if from == 42069 then
		local success, message = pcall(JSON.decode, JSON, json_mesg)
		print(success)
		if success then
			print(message.type, message.token, message.token == verify_token)
			if message.type == "handshake" and message.token == verify_token then
				modem.transmit(42069, 6969, JSON:encode{type = "handshake response", token = response_token})
			elseif message.type == "mbIsAvailable" then
				local success = pcall(reactor.mbIsAvailable)
				modem.transmit(42069, 6969, JSON:encode{type = "mbIsAvailable", yes=success})
			elseif message.type == "setActive" then
				reactor.setActive(message.value)
			elseif message.type == "mbIsConnected" then
				modem.transmit(42069, 6969, JSON:encode{mbIsConnected = reactor.mbIsConnected()})
			elseif message.type == "mbIsAssembled" then
				modem.transmit(42069, 6969, JSON:encode{mbIsAssembled = reactor.mbIsAssembled()})
			elseif message.type == "setControlRodsLevels" then
				reactor.setControlRodsLevels(message.levels)
			elseif message.type == "setAllControlRodLevels" then
				reactor.setAllControlRodLevels(message.levels)
			elseif message.type == "getEnergyStats" then
				modem.transmit(42069, 6969, JSON:encode{getEnergyStats = reactor.getEnergyStats()})
			elseif message.type == "getFuelStats" then
				modem.transmit(42069, 6969, JSON:encode{getFuelStats = reactor.getFuelStats()})
			elseif message.type == "getControlRodsLevels" then
				modem.transmit(42069, 6969, JSON:encode{getControlRodsLevels = reactor.getControlRodsLevels()})
			elseif message.type == "getEnergyStored" then
				modem.transmit(42069, 6969, JSON:encode{getEnergyStored = reactor.getEnergyStored()})
			elseif message.type == "getEnergyProducedLastTick" then
				modem.transmit(42069, 6969, JSON:encode{getEnergyProducedLastTick = reactor.getEnergyProducedLastTick()})
			elseif message.type == "getControlRodLevel" then
				modem.transmit(42069, 6969, JSON:encode{getControlRodLevel = reactor.getControlRodLevel()})
			elseif message.type == "getFuelConsumedLastTick" then
				modem.transmit(42069, 6969, JSON:encode{getFuelConsumedLastTick = reactor.getFuelConsumedLastTick()})
			end
		end
	end
end
