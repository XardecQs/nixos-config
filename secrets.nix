let
  neoReaper = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNEM9GAos27geNbizU0PoUWNoInV1TfdLAKUzLaoOIt agenix";
in
{
  "secrets/root-password.age".publicKeys = [ neoReaper ];
  "secrets/primaryUser-password.age".publicKeys = [ neoReaper ];
}
