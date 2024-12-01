{ matchers, ... }: with matchers;
[
{
  match = prefix "lambe";
  alias = value: {
    inherit value;
  };
}
]
