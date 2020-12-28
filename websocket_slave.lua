local JSON = require("JSON")
position = require("position_tracker")

local arg = {...}
do
	local x, y, z, o = tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4])
	if x and y and z and o then
		position.override(x, y, z, o)
	else
		print("please provide numbers for location and orientation")
		return
	end
end

function auth(auth_string)
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
		position = {current_position[1] + offset_x, current_position[2] + offset_y, current_position[3] + offset_z}
	}
end

function execute_command(command)
	if command.request_type == "auth" then
		return auth(command.token)
	elseif command.request_type == "eval" then
		return eval(command.to_eval)
	elseif command.request_type == "close" then
		return nil, true
	elseif command.request_type == "command buffer" then
		return buffer(command)
	elseif command.request_type == "inspect" then
		return inspect(command.direction)
	else
		return {error = true, error_message = "Unknown command: "..command.request_type}
	end
end

local requests = {}

local ws

function listen()
	print("listen started")
	while true do
		if ws == nil then
			os.sleep(0)
		else
			print("waiting for message")
			local request = ws.receive()
			table.insert(requests, request)
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

	sleep(0)

	local reconnect = false
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
				local json_response = JSON:encode(response)
				ws.send(json_response)
			end
			reconnect = should_reconnect
			if not reconnect then
				local blocks = execute_command({
					request_type = "command buffer",
					commands = {
						{
							request_type = "inspect",
							direction = "forward"
						},
						{
							request_type = "inspect",
							direction = "up"
						},
						{
							request_type = "inspect",
							direction = "down"
						}
					}
				})
				local response = {
					request_id = -1,
					response = blocks
				}
				local json_response = JSON:encode(response)
				ws.send(json_response)
			end
		else
			print("sleeping")
			os.sleep(1)
		end
	end
	ws.close()
	ws = nil
end
end

parallel.waitForAll(listen, handle)
