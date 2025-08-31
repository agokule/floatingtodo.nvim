local M = {}

local win = nil

--- @class FloatingTodoOpts
--- @field target_file string The filename of the local todo list
--- @field global_file string The filename of the global todo list
--- @field autosave boolean Whether to save the file when leaving the todo list
--- @field height number
--- @field position "center" | "topleft" | "topright" | "bottomright" | "bottomleft"
--- @field width number
--- @field border 'none'|'single'|'double'|'rounded'|'solid'|'shadow'|string[]

--- @type FloatingTodoOpts
local default_opts = {
	target_file = "~/notes/todo.md",
	autosave = true,
	border = "single",
	width = 0.8,
	height = 0.8,
	position = "center",
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

local function open_floating_file(opts)
--- @param opts FloatingTodoOpts
	if win ~= nil and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
		return
	end

	local expanded_path

	if (file == "local") then
		expanded_path = vim.fn.expand(opts.target_file)
	else
		expanded_path = vim.fn.expand(opts.global_file)
	end

	if vim.fn.filereadable(expanded_path) == 0 then
		vim.notify("todo file does not exist at directory: " .. expanded_path, vim.log.levels.ERROR)
		return
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
end

--- @param opts FloatingTodoOpts
local function setup_user_commands(opts)
	opts = vim.tbl_deep_extend("force", default_opts, opts)

	vim.api.nvim_create_user_command("Td", function()
		open_floating_file(opts)
	end, {})
end

--- @param opts FloatingTodoOpts | any
M.setup = function(opts)
	setup_user_commands(opts)
end

return M
