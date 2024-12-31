local M = {}

local val_or_default = function(prop, default)
	if prop ~= nil then
		return prop
	else
		return default
	end
end

local function xtype(o)
	local to = type(o)
	if to ~= "table" then
		return to
	else
		return o._xtype or to
	end
end

Group = {}
Group.__index = Group


setmetatable(Group, {
	__call = function(cls, name, pattern, opts)
		local opts_ = opts or {}
		local inst = setmetatable({
			name = name,
			pattern = pattern,
			capture = val_or_default(opts_.capture, true),
			required = val_or_default(opts_.require, true),
			contains = val_or_default(opts_.contains, {}),
			keepend = val_or_default(opts_.keepend, false),
			_xtype = "group"
		}, cls)
		return inst
	end
})

function Group:clone()
	return Group(self.name, self.pattern, self)
end

-- Create the Match metatable
Match = {}
Match.__index = Match

-- Constructor using call metamethod
setmetatable(Match, {
	__call = function(cls, name, ...)
		-- TODO: need a unique counter and to store a value inside this class
		--       need all generated type names to use it to ensure no clashes
		--       even when the overall rule actully does clash (and intentionally so)
		local instance = setmetatable({}, cls)
		local elems = {}
		instance.name = name
		instance.elems = elems
		instance._xtype = "rule"
		local rule_prefix = name .. "Start"
		for ndx, val in ipairs({ ... }) do
			if type(val) == "string" then
				local grp_name = string.format("%s_e%d", name, ndx)
				table.insert(elems, Group(grp_name, val, {
					capture = false
				}))
			elseif xtype(val) == "group" then
				-- We MUST generate unique names because each sub-rule has a unique
				-- nextgroup instruction
				-- TODO: generate clusters for all the similarly named sub-rules..?
				local new_val = val:clone()
				if val.name == '' then
					new_val.name = name -- TODO: enforce one only
					-- TODO: better idea, write a registry, error if clashes are discovered
				elseif val.name == nil then
					new_val.name = string.format("%s_e%d", name, ndx)
				else
					new_val.name = string.format("%s%s", name, val.name)
				end
				table.insert(elems, new_val)
			else
				error(string.format("require rule elements to be strings or Group's, got:\n%s", htt.str.stringify(val, "  ")))
			end
		end

		if #instance.elems < 1 then
			error("a rule MUST have one or more groups")
		end
		-- ... handle other arguments ...
		return instance
	end
})

function Match:full_match()
	local match = ""
	for _, elem in ipairs(self.elems) do
		local res = string.gsub(string.gsub(elem.pattern, [[\zs]], ""), [[\ze]], "")
		match = match .. res
	end
	return match
end

function Match:full_match_name()
	return string.format("%sStart", self.name)
end

table.insert(M, Match('httLuaLine',
	Group('CtlOpen', [=[^\s*\zs[%]]=]),
	[[\s*]],
	Group('', '.*$', {
		contains = { "@Lua", "luaCondElseif" },
		keepend = true
	})
))

table.insert(M, Match('httLuaLineEnd',
	Group('CtlOpen', [=[^\s*\zs[%]]=]),
	[[\s*]],
	Group('', [=[<end>\s*$]=])
))

table.insert(M, Match('httLuaLineElse',
	Group('CtlOpen', [=[^\s*\zs[%]]=]),
	[[\s*]],
	Group('', [=[<else>\s*$]=])
))

table.insert(M, Match("httDirective",
	Group('CtlOpen', [=[^\s*\zs[%]]=]),
	[[\s*]],
	Group('Kw', [=[[@]\w+]=]),
	[[\s*]],
	Group('Arg', [=[(\w+)?\ze\s*$]=])
))

return M
