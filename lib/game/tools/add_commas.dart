String addCommas(int number) {
  String numStr = number.toString();
  StringBuffer result = StringBuffer();

  int count = 0;
  for (int i = numStr.length - 1; i >= 0; i--) {
    result.write(numStr[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      result.write(',');
    }
  }

  return result.toString().split('').reversed.join('');
}
