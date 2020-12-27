local JSON = require("JSON")
local position = require("position_tracker")

local arg = {...}

function auth(auth_string)
	return {} -- this does nothing so far
end

function eval(to_eval)
	local eval_function = loadstring(to_eval)
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

function execute_command(command)
	if command.request_type == "auth" then
		return auth(command.token)
	elseif command.request_type == "eval" then
		return eval(command.to_eval)
	elseif command.request_type == "close" then
		return nil, true
	elseif command.request_type == "command buffer" then
		return buffer(command)
	else
		return {error = true, error_message = "Unknown command: "..command.request_type}
	end
end

if arg[1] and arg[2] and arg[3] and arg[4] then
	position.override(arg[1], arg[2], arg[3], arg[4])
end

while true do
	local ws
	repeat
		os.sleep(10)
		print("attempt")
		ws = http.websocket("ws://25.67.108.123")
	until ws

	local reconnect = false
	while not reconnect do
		local json_request = ws.receive()
		local request = JSON:decode(json_request)

		print(json_request)
		local result, should_reconnect = execute_command(request)
		print(result)
		if result then
			local response = {
				request_id = request.request_id,
				response = result
			}
			local json_response = JSON:encode(response)
			print("sending: ", json_response)
			ws.send(json_response)
		end
		reconnect = should_reconnect
	end
	ws.close()
	ws = nil
end
