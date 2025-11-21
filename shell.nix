{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  shellHook = ''
  show_env
  '';
  packages = with pkgs; [
    lefthook
    bats
    shellcheck
    markdownlint-cli
    git-chglog
    commitlint
    cocogitto
  ];
}
