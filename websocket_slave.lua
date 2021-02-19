local JSON = require("JSON")
position = require("position_tracker")

local arg = {...}
do
	local x, y, z, o, dim, server = tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4]), arg[5], arg[6]
	if x and y and z and o and dim and server then
		position.override(x, y, z, o, dim, server)
	else
		print("please provide numbers for location and orientation\n and provide names for the current dimension and server")
		return
	end
end

local null = {}

function auth(auth_string)
	position.update_remote()
	return {} -- this does nothing so far
end

function eval(to_eval)
	local eval_function = loadstring(to_eval)
	setfenv(eval_function, getfenv())
	local error = false
	local error_message
	local returns = {xpcall(eval_function, function(x) error = true error_message = x.."\n"..debug.traceback() end)}
	return {
		error = error,
		error_message = error_message,
		returns = returns
	}
end

function buffer(buffer)
	local command_results = {}
	for k,command in ipairs(buffer.commands) do
		local result, should_stop = execute_command(command)
		command_results[k] = result
		if should_stop then
			return command_results, should_stop
		end
	end
	return command_results, false
end

function inspect(direction)
	local current_position = {position.get()}
	local offset_x, offset_y, offset_z = 0,0,0
	local block, found_block
	if direction == "forward" then
		found_block, block = turtle.inspect()
		offset_x, offset_z = position.orientation_to_offset(current_position[4])
	elseif direction == "up" then
		found_block, block = turtle.inspectUp()
		offset_y = 1
	elseif direction == "down" then
		found_block, block = turtle.inspectDown()
		offset_y = -1
	end

	return {
		found_block = found_block,
		block = block,
		position = {current_position[1] + offset_x, current_position[2] + offset_y, current_position[3] + offset_z},
		dimension = current_position[5],
		server = current_position[6]
	}
end

function move(direction)
	local success
	if direction == "forward" then
		success = position.forward()
	elseif direction == "up" then
		success = position.up()
	elseif direction == "down" then
		success = position.down()
	elseif direction == "back" then
		success = position.back()
	else
		success = "unknown direction: "..type(direction).."("..tostring(direction)..")"
	end

	return {
		success = success
	}
end

function rotate(direction)
	if direction == "left" then
		position.turnLeft()
	elseif direction == "right" then
		position.turnRight()
	end

	return {}
end

function inventory(detailed)
	local inventory = {}
	for x=1,16 do
		inventory[x] = turtle.getItemDetail(x, detailed)
		if inventory[x] == nil then
			inventory[x] = null
		end
	end
	return inventory
end

function inventory_slot(slot, detailed)
	return turtle.getItemDetail(slot, detailed)
end

function inventory_move(from, to, amount)
	turtle.select(from)
	return {turtle.transferTo(to, amount)}
end

function make_direction_function(functions)
	return function(direction, ...)
		local success, error_message
		if functions[direction] then
			success, error_message = functions[direction](...)
		else
			return {error = true, error_message = "unkown direction"}
		end
		return {error = not success, error_message = error_message}
	end
end

drop_item_base = make_direction_function({forward = turtle.drop, up = turtle.dropUp, down = turtle.dropDown})

function drop_item(slot, direction, amount)
	turtle.select(slot)
	return drop_item_base(direction, amount)
end

pickup_item = make_direction_function{forward = turtle.suck, up = turtle.suckUp, down = turtle.suckDown}
destroy_block = make_direction_function{forward = turtle.dig, up = turtle.digUp, down = turtle.digDown}
place_block_base = make_direction_function{forward = turtle.place, up = turtle.placeUp, down = turtle.placeDown}

function place_block(slot, direction)
	turtle.select(slot)
	return place_block_base(direction)
end

function execute_command(command)
	if command.request_type == "authentication" then
		return auth(command.token)
	elseif command.request_type == "eval" then
		return eval(command.to_eval)
	elseif command.request_type == "close" then
		return nil, true
	elseif command.request_type == "command buffer" then
		return buffer(command)
	elseif command.request_type == "inspect" then
		return inspect(command.direction)
	elseif command.request_type == "move" then
		return move(command.direction)
	elseif command.request_type == "rotate" then
		return rotate(command.direction)
	elseif command.request_type == "inventory" then
		return inventory(command.detailed)
	elseif command.request_type == "inventory_slot" then
		return inventory_slot(command.slot, command.detailed)
	elseif command.request_type == "inventory_move" then
		return inventory_move(command.from, command.to, command.amount)
	elseif command.request_type == "drop_item" then
		return drop_item(command.slot, command.direction, command.amount)
	elseif command.request_type == "pickup_item" then
		return pickup_item(command.direction)
	elseif command.request_type == "break_block" then
		return destroy_block(command.direction)
	elseif command.request_type == "place_block" then
		return place_block(command.slot, command.direction)
	else
		return {error = true, error_message = "Unknown command: "..command.request_type}
	end
end

local requests = {}

local ws
local reconnect = false

function listen()
	print("listen started")
	while true do
		if ws == nil then
			os.sleep(0)
		else
			os.sleep(0)
			if ws and ws ~= true then
			print("waiting for message")
			pcall(ws.send, JSON:encode{special=1})
			local success, request = pcall(ws.receive)
				if success then
					if request ~= nil and request ~= "wake_up" then
						print("recieved message")
						table.insert(requests, request)
					end
				else
					reconnect = true
				end
			end
		end
	end
end

function handle()
while true do
	repeat
		os.sleep(10)
		print("attempt")
		ws = http.websocket("ws://25.67.108.123")
	until ws
	position.register_websocket(ws)

	os.sleep(0)

	while not reconnect do
		local json_request = requests[1]
		if json_request ~= nil then
			print("new request")
			table.remove(requests, 1)
			local request = JSON:decode(json_request)

			local result, should_reconnect = execute_command(request)
			if result then
				local response = {
					request_id = request.request_id,
					response = result
				}
				local json_response = JSON:encode(response, nil, {null=null})
				pcall(ws.send, json_response)
			end
			reconnect = should_reconnect
		else
			os.sleep(0)
		end
	end
	pcall(ws.close)
	ws = nil
	position.register_websocket(ws)
	reconnect = false
end
end

parallel.waitForAny(listen, handle)
