position = require("position_tracker")

position.override(0,0,0,3)
function a()
local fn = loadstring("return position.get()")
print(xpcall(fn, function(error) print(error) end))
end

a()
