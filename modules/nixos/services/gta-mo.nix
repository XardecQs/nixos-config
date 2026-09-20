{ lib, config, ... }:
let
  user = config.modulos.nixos.core.users.primaryUser;
  gtaMo = config.home-manager.users.${user}.modulos.home.apps.gta-mo;
in
{
  config = lib.mkIf (gtaMo.enable && gtaMo.persistencia) {
    modulos.persistencia.usuarios.${user} = {
      directories = [ ".local/share/gta-mo" ".local/share/umu" ];
      files = [ ".config/gta-mo/config.user.toml" ];
    };
  };
}
