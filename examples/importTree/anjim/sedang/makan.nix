{ superConfig, settings, ... }:
{
  result = true;
  inherit (superConfig.superConfig.superConfig) ngocok;
  inherit settings;
}
