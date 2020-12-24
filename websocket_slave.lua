local JSON = require("JSON")

local ws, err = http.websocket("ws://25.67.108.123")
if not ws then
	print(err)
	return
end

local stop = false
while not stop do
	local json_content = ws.receive()
	local content = JSON:decode(json_content)

	if content.request_type == "eval" then
		local as_function = loadstring(content.to_eval)
		local error_message;
		local error = false;
		local returns = {xpcall(as_function, function(x) error = true error_message = x.."\n"..debug.traceback() end)}
		local response = {
			request_id = content.request_id,
			response = {
				error = error,
				error_message = error_message,
				returns = returns
			}
		}
		ws.send(JSON:encode(response))
	elseif content.request_type == "authentication" then
		ws.send(JSON:encode({request_id = content.request_id, response = {}}))
	elseif content.request_type == "graceful close" then
		stop = true
	end
end
