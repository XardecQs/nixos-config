{
  description = "Configuración NixOS modular para NeoReaper";

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
      #url = "github:XardecQs/samt-nix";
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
      system = "x86_64-linux";

      helpers = import ./lib { inherit (nixpkgs-stable) lib; };

      unstableOverlay = _final: _prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      mkHost =
        hostname: extraModules:
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs helpers; };

          modules = [
            ./hosts/${hostname}/configuration.nix
            inputs.font-collection.nixosModules.default
            inputs.iconos.nixosModules.default
            inputs.preservation.nixosModules.default
            inputs.agenix.nixosModules.default
            home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.default
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [ unstableOverlay ];
            }
          ]
          ++ extraModules;
        };

    in
    {
      formatter.x86_64-linux = nixpkgs-stable.legacyPackages.x86_64-linux.nixfmt;

      nixosConfigurations = {
        NeoReaper = mkHost "NeoReaper" [ ];
      };
    };
}
