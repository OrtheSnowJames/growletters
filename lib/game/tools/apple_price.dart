import 'dart:math';

int applePrice(double secondsPassed) {
  final price = (5 * pow(1 + secondsPassed / 50, 1.3)).floor();
  return max(1, price);

  /*
  Calculator equation:
  5 * (1 + x / 20)^1.3
  where x is the number of seconds passed.

  Approximate values:

  30s: 12
  60s: 23
  2 mins: 49
  5 mins: 120
  10 mins: 220
  20 mins: 540
  30 mins: 1100-1500 (depending on rounding)

  strong early spike so the player feels the inflation quickly
  growth slows later so long sessions don't become impossible
  2 min is the first major pressure point
  */
}
