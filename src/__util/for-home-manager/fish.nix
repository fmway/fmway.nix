{ lib, ... }: let
  inherit (builtins)
    match
    attrNames
    head
    isString
    isAttrs
    length
    tail
    filter
    concatStringsSep
    elemAt
  ;
  inherit (lib)
    splitString
  ;
  
  re = {
    str = ctx: ctx;
    arr = ctx: splitString " " ctx;
    bool = ctx: if ctx == "true" then
      true
    else if ctx == "false" then
      false
    else throw "Expected boolean, but you type ${ctx}";
  };
  opt = with re; {
    argumentNames = arr;
    description = str;
    inheritVariable = str;
    noScopeShadowing = bool; 
    onEvent = str;
    onJobExit = str;
    onProcessExit = str;
    onSignal = str;
    onVariable = str; 
    wraps = str;
  };
  parseOpt = name: value: let
    optNames = attrNames opt;
    filteredOpt = filter (x: x == name) optNames;
  in
  if isNull filteredOpt || length filteredOpt < 1 then
    {}
  else let
    name = head filteredOpt;
  in  {
    "${name}" = opt.${name} value;
  };
in rec {
  # parse functions in fish home-manager
  parseFish = var: let
    fish = if isString var then
      { body = var; }
    else if isAttrs var && var ? body then
      var
    else throw "required argument body";
    inherit (fish) body;
    toArray = splitString "\n" body;
    matched = match "^# @(.*)" (head toArray); # check if first line have comment # @balabla.....
  in if isNull matched then fish
  else let
    matchedd = match "^([^ ]+) ((.+)([^ ]))([ ]*)$" (head matched);
    name = head matchedd;
    value = elemAt matchedd 1;
    result = parseOpt name value;
  in parseFish (fish // result // { body = concatStringsSep "\n" (tail toArray); });
}
