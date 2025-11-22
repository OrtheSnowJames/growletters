import 'dart:math';

int applePrice(double secondsPassed) {
  final price = (4 * pow(1.02, secondsPassed)).floor();
  return max(1, price);
  /*

  0 seconds: 4

  30 seconds: ~7

  60 seconds: ~13

  2 minutes: ~24

  5 minutes: ~54

  10 minutes: ~220 

  */
}
