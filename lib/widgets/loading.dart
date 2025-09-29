import 'package:flutter/material.dart';
import '../helpers/utils.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        Text('فضلاً انتظر ...',
            style: TextStyle(
              fontSize: 16,
              color: Utils.primary,
              fontWeight: FontWeight.w800,
              // fontFamily: 'Cairo'
            )),
      ],
    ));
  }
}
