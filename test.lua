local JSON = require("JSON")

local ws,err = http.websocket("ws://25.67.108.123")
if ws then
	local auth_message = ws.receive()
	print(auth_message)
	local auth_json = JSON:decode(auth_message)
	print(err)
	local back = {
		["request_id"] = auth_json["request_id"],
		response = {}
	}
	local back_message = JSON:encode(back)
	print(back_message)
	ws.send(back_message)
else
	print(err)
end
