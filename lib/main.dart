import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'components/pages/live.page.dart';
import 'components/pages/rooms.page.dart';
import 'components/pages/wrong.page.dart';
import 'model/store/LiveStore.dart';
import 'model/store/RoomsStore.dart';
import 'model/vo/RoomVO.dart';
import 'routes.dart';

const ROOM_ID = 'CXUQqhArYmjjyQwE8jsh';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(MultiProvider(
    providers: [
      Provider<RoomsStore>(create: (ctx) => RoomsStore() ),
      Provider<LiveStore>(create: (ctx) => LiveStore() ),
    ],
    child: FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) { return Text('Error Connection Firebase'); }
        if (snapshot.connectionState == ConnectionState.done) {
          return VideoLiveApp();
        }
        return Prepare();
      },
    )
  ));
}

class Prepare extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(width: 100, height: 100,
          child: CircularProgressIndicator()
      ),
    );
  }
}

class VideoLiveApp extends StatelessWidget {
  final style = TextStyle(color: Colors.black, fontSize: 24.0);

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomsStore>(builder: (ct, roomsStore, _) {
      return MaterialApp(
          title: 'VideoLive',
          onGenerateRoute: (RouteSettings settings) {
            print("> Main -> onGenerateRoute: ${settings.name}");
            Widget page;
            switch (settings.name) {
              case Routes.LIVE_PAGE:
                page = LivePage(settings.arguments as RoomVO);
                break;
              default:
                page = WrongPage();
            }
            return MaterialPageRoute(builder: (context) => page);
          },
          /* SELECT ROOM */
          home: RoomsPage()
        /* START STREAM */
     // home: LivePage(null)
        /* JOIN STREAM (ID must be real) */
//      home: LivePage(new RoomVO(ROOM_ID, 'ID'))
      );
    });
  }
}