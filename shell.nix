{ pkgs ? import <nixpkgs> { } }:

let
  # =============================================================================
  # Configuration - modify these to enable/disable features
  # =============================================================================
  enabled = [ bash ];

  createNvimLua = true;

  extraPackages = [ ];

  extraNvimConfig = ''
  '';
  # =============================================================================

  lib = pkgs.lib;

  # ==== LANGUAGES ====
  bash = {
    packages = [
      pkgs.lefthook
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.markdownlint-cli
      pkgs.commitlint
      pkgs.cocogitto
      pkgs.nodePackages.cspell
      pkgs.nodePackages.bash-language-server
      pkgs.codespell
      pkgs.python313Packages.pycobertura
      pkgs.bats
      pkgs.bat
      pkgs.shellcheck
      pkgs.markdownlint-cli
      pkgs.git-chglog
      pkgs.jq
      pkgs.jqp
      pkgs.xmlstarlet
    ];
    linters = ''
      sh = { "shellcheck", "cspell", "codespell" },
      bash = { "shellcheck", "cspell", "codespell" },
    '';
    formatters = ''
      sh = { "shfmt" },
      bash = { "shfmt" },
      xml = { "xmlstarlet" },
    '';
    lsp = ''
      local servers = {
        lemminx = {
        settings = {
          xml={
            catalogs={vim.uv.cwd() .. "/specs/catalog.xml"},
            validation = {noNetwork=true},
            },
            },
        },
        bashls = {},
      }
    '';
    formatterSetup = "";
    hook = "";
  };
  # ==== END LANGUAGES ====

  packages = lib.flatten (map (x: x.packages) enabled) ++ extraPackages;
  linters = lib.concatStrings (map (x: x.linters) enabled);
  formatters = lib.concatStrings (map (x: x.formatters) enabled);
  formatterSetups = lib.concatStrings (map (x: x.formatterSetup) enabled);
  lspConfigs = lib.concatStrings (map (x: x.lsp) enabled);
  setupHook = lib.concatStrings (map (x: x.hook) enabled);

  nvimConfig = ''
    vim.o.exrc = false

    ${lspConfigs}
    for server, config in pairs(servers) do
      config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
      vim.lsp.config(server, config)
      vim.lsp.enable(server)
    end
    local lint = require("lint")
    lint.linters_by_ft = {
    ${linters}}
    ${formatterSetups}
    require("conform").formatters_by_ft = {
    ${formatters}}
    ${extraNvimConfig}
  '';

  nvimHook = lib.optionalString createNvimLua ''
    hash="${builtins.hashString "sha256" nvimConfig}"
    if [ ! -f .nvim.lua ] || ! grep -q "$hash" .nvim.lua; then
      cat > .nvim.lua << 'NVIM_EOF'
    -- hash: ${builtins.hashString "sha256" nvimConfig}
    ${nvimConfig}
    NVIM_EOF
      echo "Created .nvim.lua"
    fi
  '';

  syncHook = ''
    if command -v project_shell &> /dev/null; then
      project_shell --sync
    fi
    show_env
  '';
in
pkgs.mkShell {
  inherit packages;
  shellHook = syncHook + setupHook + nvimHook;
}
