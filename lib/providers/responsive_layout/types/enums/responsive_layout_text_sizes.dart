enum TextSizes {
  xs2('xs2'),
  xs('xs'),
  sm('sm'),
  normal('normal'),
  lg('lg'),
  xl('xl'),
  xl2('2xl'),
  xl3('3xl'),
  xl4('4xl'),
  xl5('5xl'),
  xl6('6xl'),
  xl7('7xl'),
  xl8('8xl'),
  xl9('9xl');

  final String textSizeString;

  const TextSizes(this.textSizeString);

  double fontSize(double baseSize) {
    return switch (this) {
      TextSizes.xs2 => baseSize * 0.625,
      TextSizes.xs => baseSize * 0.75,
      TextSizes.sm => baseSize * 0.875,
      TextSizes.normal => baseSize * 1.0,
      TextSizes.lg => baseSize * 1.125,
      TextSizes.xl => baseSize * 1.25,
      TextSizes.xl2 => baseSize * 1.5,
      TextSizes.xl3 => baseSize * 1.875,
      TextSizes.xl4 => baseSize * 2.25,
      TextSizes.xl5 => baseSize * 3.0,
      TextSizes.xl6 => baseSize * 3.75,
      TextSizes.xl7 => baseSize * 4.5,
      TextSizes.xl8 => baseSize * 6.0,
      TextSizes.xl9 => baseSize * 8.0,
    };
  }
}
