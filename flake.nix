{
  description = "Configuración NixOS modular multi-host/multi-usuario";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    preservation.url = "github:nix-community/preservation";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    font-collection = {
      # local: repo pesado (~500 MB), GitHub es muy lento para reconstruir.
      # En una máquina sin este repo local, usar --override-input (ver `rebuild`).
      url = "git+file:///home/xardec/Proyectos/GitHub/font-collection";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    iconos = {
      url = "github:XardecQs/iconos";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    elyprismlauncher = {
      url = "github:ElyPrismLauncher/ElyPrismLauncher";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    gta-mo = {
      # local: proyecto en desarrollo; se testean commits locales sin push.
      # En una máquina sin este repo local, usar --override-input (ver `rebuild`).
      url = "git+file:///home/xardec/Proyectos/GTA-Mod-Organizer";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs =
    {
      nixpkgs-stable,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      vars = import ./vars.nix;

      helpers = import ./lib { inherit (nixpkgs-stable) lib; };

      unstableOverlay = system: _final: _prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      # Configuración de home-manager común a todo usuario.
      mkUser = user: {
        imports = [ ./users/${user} ];
        home.stateVersion = vars.stateVersion;
      };

      mkHost =
        {
          hostname,
          system ? vars.system,
          users ? [ vars.defaultUser ],
        }:
        let
          pkgs = nixpkgs-stable.legacyPackages.${system};
          host = import ./hosts/${hostname}/settings.nix { inherit pkgs; };
          userList = host.users or users;

          # Allowlist del home definida por el usuario del enforcement
          # (users/<usuario>/home-allowlist.nix). El host solo la activa.
          cfgUser = nixpkgs-stable.lib.attrByPath [ "modulos" "nixos" "homeEstado" "user" ] null host;
          allowPath = if cfgUser == null then null else ./users/${cfgUser}/home-allowlist.nix;
          homeAllow =
            if allowPath != null && builtins.pathExists allowPath then (import allowPath).allow or { } else { };
        in
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              helpers
              vars
              host
              ;
          };

          modules = [
            ./hosts/${hostname}
            inputs.font-collection.nixosModules.default
            inputs.iconos.nixosModules.default
            inputs.preservation.nixosModules.default
            inputs.agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.default
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [ (unstableOverlay system) ];
              modulos.nixos.homeEstado.allow = homeAllow;
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit
                    inputs
                    helpers
                    vars
                    host
                    ;
                };
                sharedModules = [
                  ./modules/home
                  inputs.nix-flatpak.homeManagerModules.nix-flatpak
                ];
                users = nixpkgs-stable.lib.listToAttrs (
                  map (u: {
                    name = u;
                    value = nixpkgs-stable.lib.mkMerge [
                      (mkUser u)
                      ((host.homeOverrides or { }).${u} or { })
                    ];
                  }) userList
                );
              };
            }
          ];
        };

    in
    {
      formatter.x86_64-linux = nixpkgs-stable.legacyPackages.x86_64-linux.nixfmt;

      nixosConfigurations = {
        NeoReaper = mkHost { hostname = "NeoReaper"; };
      };
    };
}
