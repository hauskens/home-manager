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

    containerEngine = mkOption {
      type = types.enum [ "docker" "podman" ];
      default = "docker";
      description = ''
        The container engine to use. If set to `podman`, Lazydocker will use
        Podman instead of Docker.
      '';
      };

    containerEnginePackage = mkPackageOption pkgs "docker" { };
    containerEngineSocket = mkOption {
      type = types.str;
      default = if cfg.containerEngine == "docker" then "/var/run/docker.sock" else "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
      example = "/var/run/docker.sock";
      description = ''
        Specifies the socket for the container engine, setting the DOCKER_HOST variable only for Lazydocker without affecting session or environment variables.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { commandTemplates.dockerCompose = if cfg.containerEngine == "docker" then cfg.containerEnginePackage + "/bin/docker compose" else "${pkgs.podman-compose}/bin/podman-compose"; };
      defaultText = literalExpression ''
      {
        commandTemplates.dockerCompose = "${if cfg.containerEngine == "docker" then cfg.containerEnginePackage + "/bin/docker compose" else "${pkgs.podman-compose}/bin/podman-compose"}"
      }
      '';
      example = literalExpression ''
        {
          gui.theme = {
            lightTheme = true;
            activeBorderColor = [ "blue" "bold" ];
            inactiveBorderColor = [ "black" ];
            selectedLineBgColor = [ "default" ];
          };
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

  config = let
  lazydockerWrapped = pkgs.writeShellScriptBin "lazydocker" ''
    DOCKER_HOST="${cfg.containerEngineSocket}" ${cfg.package}/bin/lazydocker "$@"
  '';
  in mkIf cfg.enable {
    home.packages = [ lazydockerWrapped ];

    home.file."Library/Application Support/jesseduffield/lazydocker/config.yml" =
      mkIf (cfg.settings != { } && (isDarwin && !config.xdg.enable)) {
        source = yamlFormat.generate "lazydocker-config" cfg.settings;
      };

    xdg.configFile."lazydocker/config.yml" =
      mkIf (cfg.settings != { } && !(isDarwin && !config.xdg.enable)) {
        source = yamlFormat.generate "lazydocker-config" cfg.settings;
      };
  };
}
