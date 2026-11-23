# Profile for the Open Terminal sandbox (osmosis/open-webui/terminal): a shell the model controls.
# Deliberately small: only common.nix. No personal tooling, cloud SDKs or stored credentials.
{ ... }:
{
  imports = [ ./common.nix ];

  home.username = "user";
  home.homeDirectory = "/home/user";

  # Manage ~/.bashrc so the HM session vars and PATH are sourced. Run the switch with
  # `-b bak` if a plain ~/.bashrc already exists on the volume.
  programs.bash.enable = true;
}
