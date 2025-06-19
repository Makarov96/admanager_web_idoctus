import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import "package:universal_html/html.dart";
import 'package:universal_html/js.dart' as js;
import 'package:visibility_detector/visibility_detector.dart';

import '../models/models.dart';
import 'adblock_size.dart';

/// Widget that displays an Ad from AdManager
class AdBlock extends StatefulWidget {
  final List<AdBlockSize> size;

  /// The ad unit code from AdManager Panel
  /// Example: /1234567/my-ad (where 1234567 is the network code and my-ad is the ad unit code)
  final String? adUnitId;

  /// Callback cuando el ad se carga y renderiza
  final void Function(AdInfo)? onAdLoaded;

  /// Callback cuando el ad es solicitado
  final void Function()? onAdRequested;

  const AdBlock({
    super.key,
    required this.size,
    required this.adUnitId,
    this.onAdLoaded,
    this.onAdRequested,
  });

  @override
  State<AdBlock> createState() => _AdBlockState();
}

class _AdBlockState extends State<AdBlock> {
  String blockId = "";
  double? width;
  double? height;
  bool isEmpty = false;
  bool hasLoaded = false;

  @override
  void initState() {
    super.initState();
    String counter = window.localStorage['GAM_counter'] ?? '0';
    window.localStorage['GAM_counter'] = (int.parse(counter) + 1).toString();
    blockId = "ad_$counter";

    window.addEventListener('gam_slot_render', _renderListener);

    _createView();

    _injectEnhancedEventListeners();
  }

  void _injectEnhancedEventListeners() {
    if (document.getElementById('admanager-enhanced-listeners') != null) {
      return;
    }

    const script = '''
      (function() {
        const originalDisplay = window.adManagerPluginDisplay;
        if (originalDisplay) {
          window.adManagerPluginDisplay = function(blockId, adUnitId, sizes) {
            originalDisplay.apply(this, arguments);
            window.googletag = window.googletag || {cmd: []};
            googletag.cmd.push(function() {
              googletag.pubads().getSlots().forEach(function(slot) {
                if (slot.getAdUnitPath() === adUnitId) {
                  googletag.pubads().addEventListener('slotRenderEnded', function(event) {
                    if (event.slot.getAdUnitPath() === adUnitId) {
                      window.dispatchEvent(new CustomEvent('gam_slot_render_extended', {
                        detail: {
                          blockId: blockId,
                          isEmpty: event.isEmpty,
                          size: event.size || [0, 0],
                          creativeId: event.creativeId,
                          advertiserId: event.advertiserId,
                          lineItemId: event.lineItemId
                        }
                      }));
                    }
                  });
                }
              });
            });
          };
        }
      })();
    ''';

    final scriptElement = ScriptElement()
      ..id = 'admanager-enhanced-listeners'
      ..text = script;
    document.head!.append(scriptElement);
  }

  void _createView() {
    ui_web.platformViewRegistry.registerViewFactory("gam_$blockId",
        (int viewId) {
      var div = DivElement()..id = blockId;

      div.style.width = "${widget.size[0].width}px";
      div.style.height = "${widget.size[0].height}px";

      return div;
    });
  }

  void _loadAd() {
    List<String> sizes =
        widget.size.map((e) => "${e.width}x${e.height}").toList();
    widget.onAdRequested?.call();

    js.context.callMethod('adManagerPluginDisplay', [
      blockId,
      widget.adUnitId,
      sizes.join("|"),
    ]);

    hasLoaded = true;
  }

  _renderListener(Event event) {
    if (event is CustomEvent) {
      var detail = event.detail as Map;

      if (detail['blockId'] == blockId) {
        setState(() {
          isEmpty = detail['isEmpty'];
          if (!isEmpty) {
            width = detail['size'][0];
            height = detail['size'][1];
          }
        });

        if (widget.onAdLoaded != null) {
          final adInfo = AdInfo(
            size: Size(
              width ?? widget.size[0].width.toDouble(),
              height ?? widget.size[0].height.toDouble(),
            ),
            isEmpty: isEmpty,
            creativeId: detail['creativeId']?.toString(),
            advertiserId: detail['advertiserId']?.toString(),
            lineItemId: detail['lineItemId']?.toString(),
          );
          widget.onAdLoaded!(adInfo);
        }
      }
    }
  }

  @override
  void dispose() {
    window.removeEventListener('gam_slot_render', _renderListener);
    window.removeEventListener('gam_slot_render_extended', _renderListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isEmpty && hasLoaded
        ? const SizedBox.shrink()
        : VisibilityDetector(
            key: Key(blockId),
            onVisibilityChanged: (visibilityInfo) {
              if (visibilityInfo.visibleFraction > 0 && !hasLoaded) {
                _loadAd();
              }
            },
            child: SizedBox(
              height: height ?? widget.size[0].height.toDouble(),
              width: width ?? widget.size[0].width.toDouble(),
              child: HtmlElementView(
                viewType: "gam_$blockId",
                onPlatformViewCreated: (id) {},
              ),
            ),
          );
  }
}
