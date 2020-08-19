import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_videolive/components/widgets/SelectableList.dart';
import 'package:flutter_videolive/model/store/RoomsStore.dart';
import 'package:provider/provider.dart';

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
