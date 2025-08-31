local M = {}

local win = nil

--- @class FloatingTodoOpts
--- The filename of the local todo list.
---
--- The function form takes in the file of the current buffer
--- and the current directory from vim.fn.getcwd()
---
--- This will be passed into vim.fn.expand()
--- @field target_file string|fun(file: string, dir: string):string
--- The filename of the global todo list
---
--- This will be passed into vim.fn.expand()
--- @field global_file string
--- @field autosave boolean Whether to save the file when leaving the todo list
--- @field height number
--- @field width number
--- @field position "center" | "topleft" | "topright" | "bottomright" | "bottomleft"
--- @field border 'none'|'single'|'double'|'rounded'|'solid'|'shadow'|string[]
--- Whether to automatically insert a markdown todo item when on a new line
--- @field mappings boolean

--- @type FloatingTodoOpts
local default_opts = {
	target_file = ".floatingtodo.md",
	global_file = vim.fn.stdpath('data') .. '/floatingtodo.md',
	autosave = true,
	border = "single",
	width = 0.8,
	height = 0.8,
	position = "center",
	mappings = true,
}

local function calculate_position(position)
	local posx, posy = 0.5, 0.5

	-- Custom position
	if type(position) == "table" then
		posx, posy = position[1], position[2]
	end

	-- Keyword position
	if position == "center" then
		posx, posy = 0.5, 0.5
	elseif position == "topleft" then
		posx, posy = 0, 0
	elseif position == "topright" then
		posx, posy = 1, 0
	elseif position == "bottomleft" then
		posx, posy = 0, 1
	elseif position == "bottomright" then
		posx, posy = 1, 1
	end
	return posx, posy
end

--- @param opts FloatingTodoOpts
--- @return vim.api.keyset.win_config # defining the window configuration.
local function win_config(opts)
	local width = math.min(math.floor(vim.o.columns * opts.width), 64)
	local height = math.floor(vim.o.lines * opts.height)

	local posx, posy = calculate_position(opts.position)

	local col = math.floor((vim.o.columns - width) * posx)
	local row = math.floor((vim.o.lines - height) * posy)

	return {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		border = opts.border,
	}
end

--- @param opts FloatingTodoOpts
--- @param file "global" | "local"
local function open_floating_file(opts, file)
	if win ~= nil and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
		return
	end

	local expanded_path

	if (file == "local") then
		if (type(opts.target_file) == 'function') then
			local current_file = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(0))
			local current_dir = vim.fn.getcwd()
			expanded_path = vim.fn.expand(opts.target_file(current_file, current_dir))
		else
			expanded_path = vim.fn.expand(opts.target_file --[[@as string]])
		end
	else
		expanded_path = vim.fn.expand(opts.global_file)
	end

	if vim.fn.filereadable(expanded_path) == 0 then
		vim.fn.writefile({}, expanded_path, 's')
	end

	local buf = vim.fn.bufnr(expanded_path, true)

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(buf, expanded_path)
	end

	vim.bo[buf].swapfile = false

	win = vim.api.nvim_open_win(buf, true, win_config(opts))

	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = buf }) then
				if opts.autosave then
					vim.api.nvim_buf_call(buf, function()
						vim.cmd("write")
					end)
					vim.api.nvim_win_close(0, true)
				else
					vim.notify("Save your changes before closing.", vim.log.levels.WARN)
				end
			else
				vim.api.nvim_win_close(0, true)
				win = nil
			end
		end,
	})

	if not opts.mappings then
		return
	end

	local newItem = '- [ ] '
	local keymap_opts = { nowait = true, silent = true, noremap = true }

	vim.api.nvim_buf_set_keymap(buf, 'n', '<a-o>', 'o', keymap_opts)
	vim.api.nvim_buf_set_keymap(buf, 'n', '<a-s-o>', 'O', keymap_opts)

	vim.api.nvim_buf_set_keymap(buf, 'n', 'o', 'o' .. newItem, keymap_opts)
	vim.api.nvim_buf_set_keymap(buf, 'n', 'O', 'O' .. newItem, keymap_opts)

	vim.api.nvim_buf_set_keymap(buf, 'i', '<enter>', '<enter>' .. newItem, keymap_opts)

	vim.api.nvim_buf_set_keymap(buf, 'n', '<a-enter>', '', {
		noremap = true,
		nowait = true,
		silent = true,
		callback = function ()
			local cursor = vim.fn.getcurpos()

			local lineNr = cursor[2]
			local line = vim.fn.getbufoneline(buf, lineNr)

			local filler_char
			if string.sub(line, 1, 6) == newItem then
				filler_char = 'x'
			elseif string.sub(line, 1, 3) == '- [' then
				filler_char = ' '
			else
				return
			end

			vim.cmd('norm 0f[ci[' .. filler_char)
			vim.fn.setpos('.', cursor)
			vim.cmd('norm j')
		end
	})
end

--- @param opts FloatingTodoOpts
local function setup_user_commands(opts)
	opts = vim.tbl_deep_extend("force", default_opts, opts)

	vim.api.nvim_create_user_command("TodoLocal", function()
		open_floating_file(opts, "local")
	end, {})
	vim.api.nvim_create_user_command("TodoGlobal", function()
		open_floating_file(opts, "global")
	end, {})
end

--- @param opts FloatingTodoOpts | any
M.setup = function(opts)
	setup_user_commands(opts)
end

return M
