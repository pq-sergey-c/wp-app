import 'package:flutter/cupertino.dart';

enum FontVariationWeight {
  w100(100),
  w200(200),
  w300(300),
  w400(400),
  w500(500),
  w600(600),
  w700(700),
  w800(800),
  w900(900);

  final double weight;
  const FontVariationWeight(this.weight);

  FontVariation call() => FontVariation('wght', weight);
}
