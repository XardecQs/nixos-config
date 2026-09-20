{ helpers, ... }:
{
  imports = (helpers.importDir ./. ) ++ [ ./../compartidos ];
}
