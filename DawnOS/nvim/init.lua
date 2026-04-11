vim.cmd("colorscheme matugen")
vim.api.nvim_create_autocmd("Signal", {
    pattern = "SIGUSR1",
    command = "colorscheme matugen",
})