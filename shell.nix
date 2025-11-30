{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  shellHook = ''
    show_env
  '';
  packages = with pkgs; [
    lefthook
    bats
    bat
    shellcheck
    markdownlint-cli
    git-chglog
    commitlint
    cocogitto
    jq
    jqp
    fzf
    entr
    runme
    openvscode-server
  ];
}
