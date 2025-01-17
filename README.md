# N9

NixOS configurations of mine.

# .*

```nix
{ stdenv, gnumake, ... }:

stdenv.mkDerivation {
  # n-ix, yes, the n9 :O
  pname = "n";
  version = "ix";

  buildInputs = [ gnumake ];
  buildPhase = "make setup";
  installPhase = "make switch";
}
```

Break it!
