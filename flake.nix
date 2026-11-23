{
  description = "Home Manager configuration of rafa";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvfetcher = {
      url = "github:berberman/nvfetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, nvfetcher, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations."rafa" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [ ./home.nix ];

        extraSpecialArgs = { inherit system; };
      };

      # Sandboxed Open Terminal: `home-manager switch --flake github:KUKARAF/home-manager#user`
      homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./terminal.nix ];
        extraSpecialArgs = { inherit system; };
      };

      apps.${system}.update = {
        type = "app";
        program = "${nvfetcher.packages.${system}.default}/bin/nvfetcher";
      };
    };
}
