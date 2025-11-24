import 'dart:math';

int applePrice(double secondsPassed) {
  final price = (4 * pow(1.01, secondsPassed/2)).floor();
  return max(1, price);
  /*

  0 seconds: 4

  30 seconds: ~6

  60 seconds: ~9

  2 minutes: ~14

  5 minutes: ~27

  10 minutes: ~95 

  */
}
