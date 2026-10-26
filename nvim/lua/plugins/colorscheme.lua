return {
	-- Скачиваем тему tokyonight и включаем прозрачность
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true, -- Сохраняем прозрачный фон, как у вас было
			style = "night", -- Можно выбрать: storm, moon, night, day
		},
	},

	-- Устанавливаем её основной темой для LazyVim
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight",
		},
	},
}
