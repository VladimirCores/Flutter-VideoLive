import 'package:flutter/material.dart';

class WrongPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white10,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        alignment: Alignment.topLeft,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            'You are on wrong page',
            style: TextStyle(
                fontSize: 44,
                color: Colors.black
            ),
          )
        )
      ),
    );
  }
}
