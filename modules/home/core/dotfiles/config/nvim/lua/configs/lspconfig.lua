-- 1. Obtenemos las utilidades de NvChad (esto sigue siendo útil para mantener la UI)
local nvlsp = require "nvchad.configs.lspconfig"
local capabilities = nvlsp.capabilities
local on_attach = nvlsp.on_attach

-- 2. Servidores con configuración estándar
local servers = { "html", "cssls", "jsonls", "bashls", "pylsp", "texlab", "clangd", "rust_analyzer" }

for _, lsp in ipairs(servers) do
  vim.api.nvim_create_autocmd("FileType", {
    pattern = lsp,
    callback = function(args)
      vim.lsp.start({
        name = lsp,
        cmd = { lsp },
        capabilities = capabilities,
        on_attach = on_attach,
      })
    end,
  })
end

--- 3. Configuración específica para nixd
local hostname = vim.fn.system("hostname"):gsub("%s+", "")
local username = vim.fn.expand("$USER")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "nix",
  callback = function()
    vim.lsp.start({
      name = "nixd",
      cmd = { "nixd" },
      settings = {
        nixd = {
          nixpkgs = { expr = "import <nixpkgs> { }" },
          formatting = { command = { "nixfmt" } },
          options = {
            nixos = {
              expr = '(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations."' .. hostname .. '".options',
            },
            home_manager = {
              expr = '(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations."' .. hostname .. '".config.home-manager.users."' .. username .. '"',
            },
          },
        },
      },
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end,
})
