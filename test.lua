require("textutils")

local ws,err = http.websocket("ws://25.67.108.123")
if ws then
	local auth_message = ws.receive()
	print(auth_message)
	local auth_json, err = unserializeJSON(auth_message)
	print(err)
	local back = {
		["request-id"] = auth_json["request-id"],
		response = {}
	}
	local back_message = serializeJSON(back)
	print(back_message)
	ws.send(back_message)
else
	print(err)
end
