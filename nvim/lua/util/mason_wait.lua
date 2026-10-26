-- Для install.sh: в headless-режиме ставит все пакеты из ensure_installed и ждёт окончания.
-- Запуск: nvim --headless "+lua require('util.mason_wait').run()" +qa
local M = {}

function M.run(timeout_ms)
	local plugin = require("lazy.core.config").plugins["mason.nvim"]
	local opts = require("lazy.core.plugin").values(plugin, "opts", false)
	local registry = require("mason-registry")
	local pending = 0

	registry.refresh(function()
		for _, name in ipairs(opts.ensure_installed or {}) do
			local ok, pkg = pcall(registry.get_package, name)
			if ok and not pkg:is_installed() then
				pending = pending + 1
				pkg:once("closed", function()
					pending = pending - 1
				end)
				pkg:install()
			end
		end
	end)

	vim.wait(timeout_ms or 600000, function()
		return pending == 0 and not registry.refresh_in_progress
	end, 500)
end

return M
