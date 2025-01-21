{ nixpkgs, sops-nix, ... }:

# Making a Home Manager things.
# @input user|{user,group,uid,gid,home}: Information about the user.
# @input modules: Imports from.
# @input packages: Shortcut of home.packages, within the imports context.
#                  For this restriction, this should be array of strings.
# @output: AttrSet of ${user} = {group,uid,gid,config}
user:
{
  packages ? [ ],
  modules ? [ ],
}:

let
  userAttrs =
    if builtins.typeOf user == "string" then
      {
        inherit user;
        group = user;
        uid = 1000;
        gid = 1000;
        home = "/home/${user}";
      }
    else
      user;

  # https://www.reddit.com/r/NixOS/comments/1cnwfyi/comment/l3a38q5/
  attrByStrPath = set: strPath:
    nixpkgs.lib.attrsets.attrByPath
      (nixpkgs.lib.strings.splitString "." strPath)
      null set;
in
{
  ${userAttrs.user} = {
    inherit (userAttrs) group uid gid home;

    config = {
      imports = [
        sops-nix.homeManagerModules.sops
        ({ pkgs, ... }: {
          home.packages = map (attrByStrPath pkgs) packages;
        })
      ] ++ modules;

      home.username = userAttrs.user;
      home.homeDirectory = userAttrs.home;
      home.stateVersion = "25.05";
    };
  };
}
