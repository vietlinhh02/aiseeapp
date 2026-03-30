import 'package:flutter/material.dart';

import 'aisee_performance_debug.dart';

/// Lớp phủ góc trên (không chặn chạm) khi `AISEE_DEBUG` bật.
class AiseeDebugHud extends StatelessWidget {
  const AiseeDebugHud({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AiseePerformanceDebug.instance.hudReport,
      builder: (BuildContext context, String text, Widget? child) {
        return IgnorePointer(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: MediaQuery.paddingOf(context).top + 6,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xD9000000),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF5D5D5D)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.35,
                      color: Color(0xFFB8E986),
                    ),
                    child: Text(text),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
