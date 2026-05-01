{
  description = "Configuración NixOS modular para NeoReaper y PC-Hogar";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    impermanence.url = "github:nix-community/impermanence";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    #affinity-nix.url = "github:mrshmllow/affinity-nix";
    elyprismlauncher = {
      url = "github:ElyPrismLauncher/ElyPrismLauncher";
    };
    lan-mouse = {
      url = "github:feschber/lan-mouse";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      mkHost =
        hostname: extraModules:
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };

          modules = [
            ./hosts/${hostname}/configuration.nix
            inputs.impermanence.nixosModules.impermanence
            home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.default
            {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [ unstableOverlay ];

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };

                users.xardec = {
                  imports = [
                    ./hosts/${hostname}/home.nix
                    inputs.spicetify-nix.homeManagerModules.default
                    inputs.nix-flatpak.homeManagerModules.nix-flatpak
                  ];
                };
              };
            }
          ]
          ++ extraModules;
        };

    in
    {
      nixosConfigurations = {
        NeoReaper = mkHost "NeoReaper" [ ];
        PC-Hogar = mkHost "PC-Hogar" [ ];
      };
    };
}
