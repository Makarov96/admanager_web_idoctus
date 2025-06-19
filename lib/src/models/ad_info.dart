import 'package:flutter/material.dart';

class AdInfo {
  final Size size;
  final bool isEmpty;
  final String? creativeId;
  final String? advertiserId;
  final String? lineItemId;

  AdInfo({
    required this.size,
    required this.isEmpty,
    this.creativeId,
    this.advertiserId,
    this.lineItemId,
  });
}
