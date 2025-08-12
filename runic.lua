-- Runic - A minimalist text editor written in pure Lua
-- See LICENSE.txt for license information
-- 2025 Aethari

-- This program's code is pretty shitty - there is a lot of old,
-- poorly written spaghetti code in here that needs cleaning.
-- Maybe I'll take care of it as the project progresses or maybe
-- not (I do plan on using this as a full time editor, so it
-- will probably need maintanenced at some point).

-- == Tables ===================================================
local log = {}
local ansi = {}
local term = {}
local file = {}
local buff = {}
local cmd = {}
local draw = {}
local core = {}

-- == Logging ==================================================
-- This logging mostly only exists for debugging - eventually I
-- will change it to create a log at a certain absolute path and
-- provide actual info
local f = io.open("log.txt", "w+")
f:close()

function log.write(msg)
	f = io.open("log.txt", "a")
	f:write(msg.."\n")
	f:close()
end

-- == ANSI character handling ==================================
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

	-- two match statements because i'm lazy
	-- for some reason, on some of the position calls that
	-- term.get_size sends, there is an extra brace ([) ahead
	-- of the returned value
	if seq:match("^%d+;%d+R") or seq:match("^%[%d+;%d+R") then
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

function term.reset()
	-- reset the cursor to a solid block
	ansi.write("2 q")

	-- move to the last line of the terminal
	local size = term.get_size()
	ansi.write(tostring(size.h+1)..";0H")
end

-- == File management ==========================================
function file.exists(path)
	local f = io.open(path, "r")

	if f ~= nil then
		f:close()
		return true
	else
		return false
	end
end

function file.read(path)
	local out = {}
	local f = io.open(path, "r")

	if f then
		local i = 1
		for line in f:lines() do
			out[i] = line
			i = i + 1
		end

		f:close()
		return out
	else
		return {}
	end
end

function file.write(path, str)
	local f = io.open(path, "w+")
	f:write(str)
	f:close()
end

-- == Mode management ==========================================
-- 1 = edit
-- 2 = nav
-- 3 = command line
-- 4 = file browser
local mode = 1

-- == Buffer management ========================================
-- cursor pos (in the file, not on screen)
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
			line = line:gsub("\t", "    ")
			ansi.write(tostring(i+1)..";0H")
			io.write(string.format("%3d", index))
			io.write(" "..line.."\n")
		end
	end

	-- add values to offset the various lines used by the UI
	ansi.write(tostring(buff.y - buff.offset + 1)..";"..tostring(buff.x+4).."H")
end

-- == Command buffer management ================================
cmd.history = {}
cmd.history_index = 0

cmd.x = 1

function cmd.draw()
	local size = term.get_size()

	ansi.write(tostring(size.h+1)..";0H")
	io.write(cmd.str)

	ansi.write(tostring(size.h+1)..";"..tostring(cmd.x).."H")
end

-- parses the command in cmd.str and runs it, if it is valid
function cmd.parse()
	table.insert(cmd.history, cmd.str)
	local first_word, second_word = string.match(cmd.str, "^(%w+) (.+)")

	if cmd.str == "quit" or cmd.str == "exit" or cmd.str == "q" then
		return false
	elseif first_word == "save" then
		if not second_word then
			core.save_file()
		else
			buff.filename = second_word
			core.save_file()
		end
	elseif first_word == "open" then
		if not second_word then
			log.write("open command recieved")
		else
			core.load_file(second_word)
		end
	elseif first_word == "mode" then
		if second_word == "edit" or second_word == "e" then
			mode = 1
			ansi.write("6 q")
		elseif second_word == "nav" or second_word == "n" then
			core.enter_nav()
		elseif second_word == "browser" or second_word == "b" then
			--mode = 4
		end
	elseif first_word == "line" then
		if second_word and tonumber(second_word) then
			local line = tonumber(second_word)

			if line ~= buff.y + buff.offset then
				buff.offset = line - 4
			end

			buff.y = line
		end
	end

	return true
end

-- == Drawing helper ===========================================
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
	if mode == 1 then
		draw.str(5, 0, "EDIT")
	elseif mode == 2 then
		draw.str(5, 0, "NAV")
	elseif mode == 3 then
		draw.str(5, 0, "CMD")
	elseif mode == 4 then
		draw.str(5, 0, "BROWSER")
	end

	draw.str((size.w/2) - (#buff.filename/2), 1, buff.filename)

	local pos = "("..buff.x..":"..buff.y..")"
	draw.str(size.w - #pos - 1, 1, pos)

	-- bottom line
	draw.str(size.w - 71, size.h, "ctrl+r for command line | ctrl+o to open file | ctrl+p for file browser")
end

-- == Core actions =============================================
function core.save_file()
	local out = ""
	for _, line in ipairs(buff.str) do
		out = out..line.."\n"
	end
	file.write(buff.filename, out)
end

function core.load_file(path)
	buff.filename = path

	if not file.exists(path) then
		buff.str = {}
		table.insert(buff.str, "")
	else
		buff.str = file.read(path)
	end
end

-- when calculating cursor position, gsub the tabs for spaces
function core.buff_cursor_up()
	if buff.y > 1 then
		buff.y = buff.y - 1

		local line = buff.str[buff.y]
		if line then line = line:gsub("\t", "    ") end

		if buff.x > #line then
			buff.x = #line + 1
		end
		if buff.x < 1 then buff.x = 1 end

		local size = term.get_size()
		if buff.y < buff.offset + 4 then
			buff.offset = buff.offset - 1
		end
	end
end

function core.buff_cursor_down()
	if buff.y < #buff.str then
		buff.y = buff.y + 1

		local size = term.get_size()
		if buff.y - buff.offset >= size.h - 4 then
			buff.offset = buff.offset + 1
		end

		local line = buff.str[buff.y]
		if line then line = line:gsub("\t", "    ") end

		if buff.x > #line then
			buff.x = #line + 1
		end
		if buff.x < 1 then buff.x = 1 end
	end
end

function core.buff_cursor_right()
	local line = buff.str[buff.y]
	if line then line = line:gsub("\t", "    ") end

	if buff.x < #line+1 then
		buff.x = buff.x + 1
	elseif buff.y < #buff.str then
		buff.y = buff.y + 1
		buff.x = 1
	end
end

function core.buff_cursor_left()
	local line = buff.str[buff.y]
	if line then line = line:gsub("\t", "    ") end

	if buff.x > 1 then
		buff.x = buff.x - 1
	elseif buff.y > 1 then
		buff.y = buff.y - 1
		buff.x = #buff.str[buff.y]:gsub("\t", "    ") + 1
	end
end

function core.enter_nav()
	mode = 2
	ansi.write("2 q")
end

function core.exit_nav()
	mode = 1
	ansi.write("6 q")
end

function core.open_cmd()
	cmd.str = ""
	cmd.x = 1
	cmd.history_index = #cmd.history + 1
	mode = 3
end

function core.close_cmd()
	mode = 1
	ansi.write("6 q")
end

function core.undo()
end

function core.redo()
end

-- == Input ====================================================
local function edit_input()
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
		elseif char == "s" then
			core.save_file()
		elseif char == "o" then
			core.open_cmd()
			cmd.str = "open "
			cmd.x = 6
		elseif char == "r" then
			core.open_cmd()
		elseif char == "l" then
			core.open_cmd()
			cmd.str = "line "
			cmd.x = 6
		elseif char == "j" then
			core.enter_nav()
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
			core.buff_cursor_up()
		-- down
		elseif code == "B" then
			core.buff_cursor_down()
		-- right
		elseif code == "C" then
			core.buff_cursor_right()
		-- left
		elseif code == "D" then
			core.buff_cursor_left()
		-- home
		elseif code == "1" then
			buff.x = 1
		-- end
		elseif code == "4" then
			buff.x = #buff.str[buff.y]:gsub("\t", "    ") + 1

			-- if the line is empty, it sets buff.x to 0, this fixes it
			if buff.x < 1 then buff.x = 1 end
		end
	end

	return true
end

local function nav_input()
	os.execute("stty raw")

	local char = io.read(1)
	
	os.execute("stty sane")

	local char_code = string.byte(char)
	local is_ctrl = false
	local is_esc = false

	if char_code >= 1 and char_code < 27 then
		-- convert to relevant character
		char = string.char(char_code + 64)
		is_ctrl = true
	elseif char_code == 27 then
		io.read(1)
		is_esc = true
	-- j
	elseif char_code == 106 then
		core.buff_cursor_down()
	-- k
	elseif char_code == 107 then
		core.buff_cursor_up()
	-- h
	elseif char_code == 104 then
		core.buff_cursor_left()
	-- l
	elseif char_code == 108 then
		core.buff_cursor_right()
	-- u
	elseif char_code == 117 then
		buff.x = 1
	-- i
	elseif char_code == 105 then
		buff.x = #buff.str[buff.y]:gsub("\t", "    ") + 1
	-- a
	elseif char_code == 97 then
		core.exit_nav()
	-- q
	elseif char_code == 113 then
		return false
	else
		char = string.char(char_code + 64)
		char = char:lower()

		if char == "j" then
			core.buff_cursor_down()
		end
	end

	if is_ctrl then
		char = char:lower()

		if char == "q" then
			return false
		elseif char == "s" then
			core.save_file()
		elseif char == "o" then
			core.open_cmd()
			cmd.str = "open "
			cmd.x = 6
		elseif char == "r" then
			core.open_cmd()
		elseif char == "l" then
			core.open_cmd()
			cmd.str = "line "
			cmd.x = 6
		elseif char == "j" then
			core.exit_nav()
		end
	elseif is_esc then
	end

	return true
end

local function cmd_input()
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
		if cmd.x > 1 then
			cmd.str = cmd.str:sub(1, cmd.x - 2)..cmd.str:sub(cmd.x)
			cmd.x = cmd.x - 1
		end
	-- insert characters
	else
		cmd.str = cmd.str:sub(1, cmd.x-1)..char..cmd.str:sub(cmd.x)
		cmd.x = cmd.x + 1
	end

	if is_ctrl then
		char = char:lower()

		if char == "q" then
			return false
		elseif char == "r" then
			core.close_cmd()
		-- enter
		elseif char == "m" then
			local res = cmd.parse()
			core.close_cmd()
			return res
		end
	elseif is_esc then
		local code = io.read(1)

		-- up
		if code == "A" then
			if cmd.history_index > 1 then
				cmd.history_index = cmd.history_index - 1
				local buff = cmd.history[cmd.history_index]
				if buff then
					cmd.str = buff
				else
					cmd.history_index = cmd.history_index + 1
					cmd.str = ""
				end
			end
		-- down
		elseif code == "B" then
			-- next cmd.history
			if cmd.history_index < #cmd.history+1 then
				cmd.history_index = cmd.history_index + 1
				local buff = cmd.history[cmd.history_index]
				if buff then
					cmd.str = buff
				else
					cmd.history_index = cmd.history_index - 1
					cmd.str = ""
				end
			end
		-- right
		elseif code == "C" then
			-- cursor right
			if cmd.x < #cmd.str+1 then
				cmd.x = cmd.x + 1
			end
		-- left
		elseif code == "D" then
			-- cursor left
			if cmd.x > 1 then
				cmd.x = cmd.x - 1
			end
		-- home
		elseif code == "1" then
			cmd.x = 1
		-- end
		elseif code == "4" then
			cmd.x = #cmd.str + 1

			-- if the line is empty, it sets cmd.x to 0, this fixes it
			if cmd.x < 1 then cmd.x = 1 end
		end
	end

	return true
end

-- == Entry point ==============================================
local function main()
	local running = true

	ansi.write("6 q")

	if arg[1] then
		if not file.exists(arg[1]) then
			buff.str = {}
			table.insert(buff.str, "")
			buff.filename = arg[1]
		else
			buff.str = file.read(arg[1])
			buff.filename = arg[1]
		end

	else
		buff.str = {""}
		buff.filename = "New file"
	end


	-- initial draw
	draw.ui()
	buff.draw()

	while running do
		if mode == 1 then
			draw.ui()
			buff.draw()

			running = edit_input()
		elseif mode == 2 then
			draw.ui()
			buff.draw()

			running = nav_input()
		elseif mode == 3 then
			draw.ui()
			buff.draw()
			cmd.draw()

			running = cmd_input()
		end
	end
end

main()

-- == Post app exit ============================================
term.reset()
