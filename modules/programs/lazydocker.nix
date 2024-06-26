{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.lazydocker;

  yamlFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in {
  meta.maintainers = [ hm.maintainers.hausken ];

  options.programs.lazydocker = {
    enable = mkEnableOption "lazydocker, a simple terminal UI for git commands";

    package = mkPackageOption pkgs "lazydocker" { };

    containerEnginePackage = mkPackageOption pkgs "docker" { };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      defaultText = literalExpression ''
      {
        commandTemplates.dockerCompose = cfg.containerEnginePackage + "/bin/docker compose";
      }
      '';
      example = literalExpression ''
        {
          gui.theme.activeBorderColor = ["red" "bold"];
          commandTemplates.dockerCompose = cfg.containerEnginePackage + "/bin/docker compose -f docker-compose.yml";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/lazydocker/config.yml`
        on Linux or on Darwin if [](#opt-xdg.enable) is set, otherwise
        {file}`~/Library/Application Support/jesseduffield/lazydocker/config.yml`.
        See
        <https://github.com/jesseduffield/lazydocker/blob/master/docs/Config.md>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."Library/Application Support/jesseduffield/lazydocker/config.yml" =
      mkIf (cfg.settings != { } && (isDarwin && !config.xdg.enable)) {
        source = yamlFormat.generate "lazydocker-config" (lib.attrsets.recursiveUpdate {commandTemplates.dockerCompose = cfg.containerEnginePackage + "/bin/docker compose";} cfg.settings);
      };

    xdg.configFile."lazydocker/config.yml" =
      mkIf (cfg.settings != { } && !(isDarwin && !config.xdg.enable)) {
        source = yamlFormat.generate "lazydocker-config" (lib.attrsets.recursiveUpdate {commandTemplates.dockerCompose = cfg.containerEnginePackage + "/bin/docker compose";} cfg.settings);
      };
  };
}
