{ mkMerge, mkIf }:
p: yes: no:
mkMerge [
  (mkIf p yes)
  (mkIf (!p) no)
]
