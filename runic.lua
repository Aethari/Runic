-- Runic - A minimalist text editor written in pure Lua
-- See LICENSE.txt for license information
-- 2025 Aethari

-- This program's code is pretty shitty - there is a lot of old,
-- poorly written spaghetti code in here that needs cleaning.
-- Maybe I'll take care of it as the project progresses or maybe
-- not (I do plan on using this as a full time editor, so it
-- will probably need maintanenced at some point).

-- == Logging ==================================================
-- This logging mostly only exists for debugging - eventually I
-- will change it to create a log at a certain absolute path and
-- provide actual info
local file = io.open("log.txt", "w+")
file:close()

local log = {}
function log.write(msg)
	file = io.open("log.txt", "a")
	file:write(msg.."\n")
	file:close()
end

-- == ANSI character handling ==================================
local ansi = {}
function ansi.write(seq)
	-- 27 is the escape character
	io.write(string.char(27).."["..seq)
end

function ansi.parse()
	-- set terminal to raw mode - UNIX command
	os.execute("stty raw -echo")
	
	local out = {}
	local seq = ""

	io.read(1) -- skip ESC
	io.read(1) -- skip [

	repeat
		local char = io.read(1)
		if not char then break end
		seq = seq..char
	until char == "R"

	if seq:match("^%d+;%d+R") then
		out.type = "position"

		local colon_pos = seq:find(";")
		out.h = seq:match("%d+") - 1
		out.w = seq:match("%d+", colon_pos)	-1
	end

	-- set terminal back to normal - UNIX command
	os.execute("stty sane")

	return out
end

-- == Terminal helper ==========================================
local term = {}
function term.get_size()
	out = {w = 80, h = 24}

	-- move the cursor to the farthest bounds
	ansi.write("999;999H")

	-- get the cursor position
	ansi.write("6n")
	local pos = ansi.parse()

	if(pos.type == "position") then
		out.w = pos.w
		out.h = pos.h
	end

	-- move the cursor back to (0,0)
	ansi.write("H")
	
	return out
end

-- == File management ==========================================
local file = {}

function file.read(path)
	local out = {}
	local file = io.open(path, "r")

	if file then
		local i = 1
		for line in file:lines() do
			out[i] = line
			i = i + 1
		end

		return out
	else
		return {}
	end
end

-- == Buffer management ========================================
local buff = {}

-- cursor pos
buff.x = 1
buff.y = 1

-- offset (for scrolling)
buff.offset = 0

function buff.count_lines()
	return #buff.str + 1
end

function buff.draw()
	local size = term.get_size()

	if buff.offset <= 0 then buff.offset = 0 end

	-- -3 for margins
	for i = 1, size.h - 2 do
		local index = i + buff.offset
		local line = buff.str[index]

		if line then
			ansi.write(tostring(i+1)..";0H")
			io.write(string.format("%3d", index))
			io.write(" "..line.."\n")
		end
	end

	-- add values to offset the various lines used by the UI
	ansi.write(tostring(buff.y - buff.offset + 1)..";"..tostring(buff.x+4).."H")
end

-- == Drawing helper ===========================================
local draw = {}
function draw.hline(x, y, size)
	ansi.write(y..";"..x.."H")

	for i = x, size do
		io.write(" ")
	end
end

function draw.str(x, y, text)
	x = math.floor(x)
	y = math.floor(y)

	ansi.write(y..";"..x.."H")
	io.write(text)
end

function draw.ui()
	-- clear the screen
	ansi.write("2J")

	-- set cursor to (0,0)
	ansi.write("H")

	-- get the terminal size
	local size = term.get_size()

	-- top line
	draw.hline(0, 0, size.w)
	draw.str((size.w/2) - (#buff.filename/2), 1, buff.filename)

	local pos = "("..buff.x..":"..buff.y..")"
	draw.str(size.w - #pos - 1, 1, pos)

	-- bottom line
	draw.hline(0, size.h, size.w)
	draw.str(size.w - 47, size.h, "ctrl+r for command line | ctrl+o to open file")
end

-- == Input (no, really?!?) ====================================
local function input()
	os.execute("stty raw")

	local char = io.read(1)
	
	os.execute("stty sane")

	local char_code = string.byte(char)
	local is_ctrl = false
	local is_esc = false

	-- control characters
	if char_code >= 1 and char_code < 27 then
		-- convert to relevant character
		char = string.char(char_code + 64)
		is_ctrl = true
	elseif char_code == 27 then
		io.read(1)
		is_esc = true
	-- backspace
	elseif char_code == 8 or char_code == 127 then
		local line = buff.y
		if buff.x > 1 then
			buff.str[line] = buff.str[line]:sub(1, buff.x-2)..buff.str[line]:sub(buff.x)
			buff.x = buff.x - 1
		else
			buff.x = #buff.str[line-1] + 1
			buff.y = buff.y - 1

			buff.str[line-1] = buff.str[line-1]..buff.str[line]
			table.remove(buff.str, line)
		end
	-- insert characters
	else
		local line = buff.y
		buff.str[line] = buff.str[line]:sub(1, buff.x-1)..char..buff.str[line]:sub(buff.x)
		buff.x = buff.x + 1
	end

	if is_ctrl then
		char = char:lower()

		if char == "q" then
			return false
		-- enter
		elseif char == "m" then
			local line = buff.y

			local before = buff.str[line]:sub(1, buff.x-1)
			local new = buff.str[line]:sub(buff.x)

			buff.str[line] = before
			table.insert(buff.str, line+1, new)

			buff.y = buff.y + 1
			buff.x = 1
		end
	elseif is_esc then
		local code = io.read(1)

		-- up
		if code == "A" then
			if buff.y > 1 then
				buff.y = buff.y - 1

				if buff.x > #buff.str[buff.y] then
					buff.x = #buff.str[buff.y]
				end
				if buff.x < 1 then buff.x = 1 end

				local size = term.get_size()
				if buff.y < buff.offset + 4 then
					buff.offset = buff.offset - 1
				end
			end
		-- down
		elseif code == "B" then
			if buff.y < #buff.str then
				buff.y = buff.y + 1

				local size = term.get_size()
				if buff.y - buff.offset >= size.h - 4 then
					buff.offset = buff.offset + 1
				end

				if buff.x > #buff.str[buff.y] then
					buff.x = #buff.str[buff.y]
				end
				if buff.x < 1 then buff.x = 1 end
			end
		-- right
		elseif code == "C" then
			if buff.x < #buff.str[buff.y] then
				buff.x = buff.x + 1
			elseif buff.y < #buff.str then
				buff.y = buff.y + 1
				buff.x = 1
			end
		-- left
		elseif code == "D" then
			if buff.x > 1 then
				buff.x = buff.x - 1
			elseif buff.y > 1 then
				buff.y = buff.y - 1
				buff.x = #buff.str[buff.y]
			end
		-- home
		elseif code == "1" then
			buff.x = 1
		--end
		elseif code == "4" then
			buff.x = #buff.str[buff.y]

			-- if the line is empty, it set buff.x to 0, this fixes it
			if buff.x < 1 then buff.x = 1 end
		end
	end

	return true
end

-- == Entry point ==============================================
local function main()
	local running = true

	ansi.write("2 q")
	-- ansi.write("6 q")

	if arg[1] then
		buff.str = file.read(arg[1])
		buff.filename = arg[1]
	else
		buff.str = {""}
		buff.filename = "New file"
	end

	-- initial draw
	draw.ui()
	buff.draw()

	while running do
		running = input()
		draw.ui()
		buff.draw()
	end
end

main()

-- == Post app exit ============================================
-- reset the colors to black and white
ansi.write("0m")

-- reset the cursor to a solid block
ansi.write("2 q")

-- move to the last line of the terminal
local size = term.get_size()
ansi.write(tostring(size.h+1)..";0H")
