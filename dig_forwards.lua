local arg = {...}

local max_move_amount = tonumber(arg[1] or 100)
local block_types = require(arg[2] or "default_miner_block_types")

if #block_types == 0 then
	print("MINER ERROR: missing block type")
	return
end


turtle.select(1)
turtle.refuel()
local max_move_amount = math.min(max_move_amount, math.floor((turtle.getFuelLevel() / 2) - 50))
if max_move_amount <= 10 then
	print("MINER ERROR: not enough fuel")
	return
end

function mine_surrounding_blocks()
	check_block_up()
	check_block_down()
	for i=1,4 do
		check_block_forward()
		turtle.turnLeft()
	end
end

function is_in_types(name)
	for _,type in pairs(block_types) do
		if name == type then
			return true
		end
	end
	return false
end

function check_block_forward()
	local success, block = turtle.inspect()
	if success and is_in_types(block.name) then
		turtle.dig()
		turtle.forward()
		mine_surrounding_blocks()
		turtle.back()
	end
end

function check_block_up()
	local success, block = turtle.inspectUp()
	if success and is_in_types(block.name) then
		turtle.digUp()
		turtle.up()
		mine_surrounding_blocks()
		turtle.down()
	end
end

function check_block_down()
	local success, block = turtle.inspectDown()
	if success and is_in_types(block.name) then
		turtle.digDown()
		turtle.down()
		mine_surrounding_blocks()
		turtle.up()
	end
end

function drop_unneeded_items()
	for x=1,16 do
		local item_data = turtle.getItemDetail(x)
		if item_data and not is_in_types(item_data.name) then
			turtle.select(x)
			turtle.drop()
		end
	end
end

local amount_moved_forward = 0

while amount_moved_forward < max_move_amount do
	mine_surrounding_blocks()
	turtle.dig()
	turtle.forward()

	if amount_moved_forward % 20 == 0 then
		drop_unneeded_items()
	end

	local fuel_amount = turtle.getFuelLevel()
	amount_moved_forward = amount_moved_forward + 1
	max_move_amount = math.min(max_move_amount, math.floor((fuel_amount+amount_moved_forward / 2) - 50))
end
drop_unneeded_items()
turtle.turnLeft()
turtle.turnLeft()
while amount_moved_forward > 0 do
	turtle.dig()
	turtle.forward()
	amount_moved_forward = amount_moved_forward - 1
end
