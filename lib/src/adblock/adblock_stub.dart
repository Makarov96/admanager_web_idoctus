import 'package:admanager_web/admanager_web.dart' show AdBlockSize;
import 'package:flutter/widgets.dart'
    show BuildContext, SizedBox, StatelessWidget, Widget;

import '../models/models.dart';

class AdBlock extends StatelessWidget {
  const AdBlock({
    super.key,
    required this.size,
    required this.adUnitId,
    this.onAdLoaded,
    this.onAdRequested,
  });

  final List<AdBlockSize> size;
  final String? adUnitId;
  final void Function(AdInfo)? onAdLoaded;
  final void Function()? onAdRequested;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
