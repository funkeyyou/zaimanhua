import 'package:flutter/material.dart';

class AuthorUnlock extends StatefulWidget {
  const AuthorUnlock({super.key, required this.onUnlock});
  final Future<void> Function() onUnlock;
  @override
  State<AuthorUnlock> createState() => _AuthorUnlockState();
}

class _AuthorUnlockState extends State<AuthorUnlock> {
  int taps = 0;
  DateTime? lastTap;
  bool busy = false;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () async {
          if (busy) return;
          final now = DateTime.now();
          if (lastTap == null || now.difference(lastTap!).inSeconds >= 3) {
            taps = 0;
          }
          lastTap = now;
          if (++taps != 10) return;
          taps = 0;
          busy = true;
          try {
            await widget.onUnlock();
          } finally {
            busy = false;
          }
        },
        child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('funkeyyou')),
      );
}
