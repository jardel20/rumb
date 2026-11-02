# Módulo NixOS: programs.rumb.enable = true;
{ rumbPackages }:
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.rumb;
in
{
  options.programs.rumb = {
    enable = lib.mkEnableOption "rumb, a terminal dashboard for NixOS system health";
    terminal = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "kitty --title rumb -e";
      description = ''
        Command that opens a terminal and runs what follows it, for the launcher
        entry. With null the entry uses Terminal=true and leaves the choice to the launcher.
      '';
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = rumbPackages.${pkgs.stdenv.hostPlatform.system}.rumb.override { inherit (cfg) terminal; };
      defaultText = lib.literalExpression "inputs.rumb.packages.\${pkgs.stdenv.hostPlatform.system}.rumb";
      description = "The rumb package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
