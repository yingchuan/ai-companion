-- Luacheck configuration for ai-companion.nvim

-- Standard Neovim globals
std = "luajit"

-- Neovim-specific globals
globals = {
  "vim",
  "bit",
  "jit",
}

-- Read-only globals (don't warn about not setting them)
read_globals = {
  -- Lua
  "table",
  "string",
  "math",
  "os",
  "io",
  "debug",
  "coroutine",
  "package",

  -- Neovim API
  "vim.api",
  "vim.fn",
  "vim.cmd",
  "vim.keymap",
  "vim.notify",
  "vim.log",
  "vim.schedule",
  "vim.defer_fn",
  "vim.loop",
  "vim.uv",
  "vim.tbl_deep_extend",
  "vim.tbl_map",
  "vim.split",
  "vim.inspect",
  "vim.deepcopy",

  -- Neovim buffer/window options
  "vim.bo",
  "vim.wo",
  "vim.go",
  "vim.o",
  "vim.g",
  "vim.b",
  "vim.w",
  "vim.t",
  "vim.v",
  "vim.env",
}

-- Ignore warnings
ignore = {
  "212/self",  -- Unused argument self
  "631",       -- Line too long
  "612",       -- Line contains only whitespace
  "611",       -- Line contains trailing whitespace
  "614",       -- Trailing whitespace in a string
  "113",       -- Setting non-standard global variable
  "122",       -- Setting read-only field
}

-- File-specific configurations
files = {
  ["init.lua"] = {
    globals = {"require"}
  },
  ["**/*test*.lua"] = {
    globals = {"describe", "it", "before_each", "after_each"}
  }
}

-- Exclude patterns
exclude_files = {
  ".git/",
  "node_modules/",
  ".luarocks/",
  "*.min.lua"
}
