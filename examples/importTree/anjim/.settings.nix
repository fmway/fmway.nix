{ matchers, ... }:
{
  alias = [
  {
    match = matchers.prefix "makan";
    alias = k: v: {
      kontol = v;
    };
  }
  ];
}
