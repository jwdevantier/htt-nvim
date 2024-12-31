local rules = require("rules")
local c = require("//stx.htt")

render(c.Main, "lua/htt/init.lua", { rules = rules })
