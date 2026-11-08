-- Lists global writes (SETGLOBAL) in a Lua 5.1 chunk by reading its bytecode.
-- Must run on a real Lua 5.1 VM (string.dump format is version-specific).
-- Returns a list of { name = string, line = number }.
local function scan(src, chunkname)
	local fn, err = loadstring(src, chunkname)
	if not fn then
		return nil, err
	end
	local bc = string.dump(fn)
	local pos = 1
	local function byte()
		local b = bc:byte(pos)
		pos = pos + 1
		return b
	end
	-- header: ESC "Lua" version format endianness int size_t instruction number integral
	assert(bc:sub(1, 4) == "\27Lua" and bc:byte(5) == 0x51, "not Lua 5.1 bytecode")
	local little = bc:byte(7) == 1
	local sizeInt, sizeT, sizeInstr, sizeNum = bc:byte(8), bc:byte(9), bc:byte(10), bc:byte(11)
	pos = 13
	local function uint(n)
		local v = 0
		for i = 0, n - 1 do
			local b = bc:byte(pos + i)
			if little then
				v = v + b * 256 ^ i
			else
				v = v * 256 + b
			end
		end
		pos = pos + n
		return v
	end
	local function str()
		local n = uint(sizeT)
		if n == 0 then
			return nil
		end
		local s = bc:sub(pos, pos + n - 2)
		pos = pos + n
		return s
	end
	local found = {}
	local function func()
		str() -- source
		uint(sizeInt) -- linedefined
		uint(sizeInt) -- lastlinedefined
		pos = pos + 4 -- nups, numparams, is_vararg, maxstacksize
		local ncode = uint(sizeInt)
		local code = {}
		for i = 1, ncode do
			code[i] = uint(sizeInstr)
		end
		local nk = uint(sizeInt)
		local k = {}
		for i = 1, nk do
			local t = byte()
			if t == 0 then
				k[i] = nil
			elseif t == 1 then
				k[i] = byte() ~= 0
			elseif t == 3 then
				pos = pos + sizeNum
			elseif t == 4 then
				k[i] = str()
			end
		end
		local np = uint(sizeInt)
		for _ = 1, np do
			func()
		end
		local nline = uint(sizeInt)
		local lines = {}
		for i = 1, nline do
			lines[i] = uint(sizeInt)
		end
		local nloc = uint(sizeInt)
		for _ = 1, nloc do
			str()
			uint(sizeInt)
			uint(sizeInt)
		end
		local nup = uint(sizeInt)
		for _ = 1, nup do
			str()
		end
		for i, ins in ipairs(code) do
			local op = ins % 64
			if op == 7 then -- OP_SETGLOBAL
				local bx = math.floor(ins / 16384) -- A:8 at bits 6-13, Bx at bits 14-31
				found[#found + 1] = { name = k[bx + 1], line = lines[i] or 0 }
			end
		end
	end
	func()
	return found
end

return scan
