local M = {}
local fn = vim.fn
local api = vim.api
M.original_color = nil
M.original_opacity = nil
M.original_padding = nil

local get_kitty_background = function()
	if M.original_color == nil then
		fn.jobstart({ "kitty", "@", "get-colors" }, {
			on_stdout = function(_, d, _)
				for _, result in ipairs(d) do
					if string.match(result, "^background") then
						local color = vim.split(result, "%s+")[2]
						M.original_color = color
						break
					end
				end
			end,
			on_stderr = function(_, d, _)
				if #d > 1 then
					api.nvim_err_writeln(
						"Chameleon.nvim: Error getting background. Make sure kitty remote control is turned on."
					)
				end
			end,
		})
	end
end

local change_background = function(color, sync)
	local arg = 'background="' .. color .. '"'
	local command = "kitty @ set-colors " .. arg
	if not sync then
		fn.jobstart(command, {
			on_stderr = function(_, d, _)
				if #d > 1 then
					api.nvim_err_writeln(
						"Chameleon.nvim: Error changing background. Make sure kitty remote control is turned on."
					)
				end
			end,
		})
	else
		fn.system(command)
	end
end

local change_opacity = function(opacity, sync)
	local command = "kitty @ set-background-opacity " .. opacity
	if not sync then
		fn.jobstart(command, {
			on_stderr = function(_, d, _)
				if #d > 1 then
					api.nvim_err_writeln(
						"Chameleon.nvim: Error changing opacity. Make sure kitty remote control is turned on."
					)
				end
			end,
		})
	else
		fn.system(command)
	end
end

local change_padding = function(padding, sync)
	local command = "kitty @ set-spacing padding=" .. padding
	if not sync then
		fn.jobstart(command, {
			on_stderr = function(_, d, _)
				if #d > 1 then
					api.nvim_err_writeln(
						"Chameleon.nvim: Error changing padding. Make sure kitty remote control is turned on."
					)
				end
			end,
		})
	else
		fn.system(command)
	end
end

local apply = function()
	local color = string.format("#%06X", vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
	change_background(color)
	change_opacity("1")
	change_padding("0")
end

local restore = function()
	if M.original_color ~= nil then
		change_background(M.original_color, true)
		change_opacity(M.original_opacity)
		change_padding(M.original_padding)
		-- Looks like it was silently fixed in NVIM 0.10. At least, I can't reproduce it anymore,
		-- so for now disable it and see if anyone reports it again.
		-- https://github.com/neovim/neovim/issues/21856
		-- vim.cmd([[sleep 10m]])
	end
end

local setup_autocmds = function()
	local autocmd = api.nvim_create_autocmd
	local autogroup = api.nvim_create_augroup
	local bg_change = autogroup("BackgroundChange", { clear = true })

	autocmd({ "ColorScheme", "VimResume" }, {
		pattern = "*",
		callback = apply,
		group = bg_change,
	})

	autocmd("User", {
		pattern = "Huez",
		callback = apply,
		group = bg_change,
	})

	autocmd({ "VimLeavePre", "VimSuspend" }, {
		pattern = "*",
		callback = restore,
		group = autogroup("BackgroundRestore", { clear = true }),
	})
end

M.setup = function(original_opacity, original_padding)
	M.original_opacity = original_opacity
	M.original_padding = original_padding
	get_kitty_background()
	setup_autocmds()
end

M.change_background = change_background
M.change_opacity = change_opacity
M.change_padding = change_padding
M.restore = restore
M.apply = apply

return M
