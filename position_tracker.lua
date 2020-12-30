local JSON = require("JSON")

local x, y, z, o

local instance = {}

function instance.override(new_x, new_y, new_z, new_o)
	x = new_x
	y = new_y
	z = new_z
	o = new_o
	instance.update_remote()
end

function instance.turnLeft()
	o = o - 1
	if o < 0 then o = o + 4 end
	instance.update_remote()
	return turtle.turnLeft()
end

function instance.turnRight()
	o = o + 1
	if o > 3 then o = o - 4 end
	instance.update_remote()
	return turtle.turnRight()
end

function instance.orientation_to_offset(_o)
	local offset_x, offset_z
	if _o == 0 then
		offset_x = 0
		offset_z = -1
	elseif o == 1 then
		offset_x = 1
		offset_z = 0
	elseif o == 2 then
		offset_x = 0
		offset_z = 1
	elseif o == 3 then
		offset_x = -1
		offset_z = 0
	end
	return offset_x, offset_z
end

function instance.forward()
	local success = turtle.forward()
	if success then
		local offset_x, offset_z = instance.orientation_to_offset(o)
		x, z = x + offset_x, z + offset_z
		instance.update_remote()
	end
	return success
end

function instance.back()
	local success = turtle.back()
	if success then
		local offset_x, offset_z = instance.orientation_to_offset(o)
		x, z = x + -offset_x, z + -offset_z
		instance.update_remote()
	end
	return success
end

function instance.up()
	local success = turtle.up()
	if success then
		y = y + 1
		instance.update_remote()
	end
	return success
end

function instance.down()
	local success = turtle.down()
	if success then
		y = y - 1
		instance.update_remote()
	end
	return success
end

function instance.get()
	return x,y,z,o
end

function instance.register_websocket(ws)
	instance.ws = ws
end

function instance.update_remote()
	if instance.ws then
		local info = {
			request_id = -2,
			response = {
				x = x,
				y = y,
				z = z,
				o = o
			}
		}
		instance.ws.send(JSON:encode(info))
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
		instance.ws.send(json_response)
	end
end

return instance