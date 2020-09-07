import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_videolive/components/widgets/SelectableList.dart';
import 'package:flutter_videolive/model/store/RoomsStore.dart';
import 'package:flutter_videolive/routes.dart';
import 'package:provider/provider.dart';

class RoomsPage extends StatelessWidget {

  static const _textStyle_Message = TextStyle(color: Colors.black, fontSize: 24.0);
  static const _textStyle_UnexpectedError = TextStyle(color: Colors.red, fontSize: 24.0);
  static const _textStyle_RoomSelected = TextStyle(color: Colors.black, fontSize: 24.0);
  
  @override
  Widget build(BuildContext context) {
    
    final navigateToLivePage = (room)  => Navigator.pushNamed(context, Routes.LIVE_PAGE, arguments: room);

    return Consumer<RoomsStore>(builder:
      (context, RoomsStore roomsStore, _) => Scaffold(
        backgroundColor: Colors.white10,
        floatingActionButton: Observer(builder: (_) {
          final hasSelectedRoom = roomsStore.hasSelectedRoom;
          print('< RoomsPage: floatingActionButton: hasSelectedRoom = $hasSelectedRoom');
          return FloatingActionButton.extended(
            label: Text(hasSelectedRoom ? 'Join' : 'Live'),
            onPressed: () => navigateToLivePage(roomsStore.selectedRoom)
              ..then((_) => roomsStore.clearSelected()),
            icon: Icon(hasSelectedRoom ? Icons.camera : Icons.camera_alt),
            backgroundColor: hasSelectedRoom ? Colors.green : Colors.lightBlue,
          );
        }),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          alignment: Alignment.topLeft,
          color: Colors.white,
          child: Observer(builder: (_) {
            switch(roomsStore.status) {
              case RoomsStatus.CONNECTING: return LinearProgressIndicator(); break;
              case RoomsStatus.ERROR:return _RoomsStatusMessage("Something went wrong", _textStyle_Message); break;
              case RoomsStatus.EMPTY:return _RoomsStatusMessage("No Rooms", _textStyle_Message); break;
              case RoomsStatus.READY:
                return ListView.builder(
                  itemCount: roomsStore.rooms.length,
                  itemBuilder: (context, index) {
                    return Observer(builder: (_) {
                      final room = roomsStore.rooms[index];
                      final isRoomSelected = roomsStore.isRoomSelected(room);
                      if (room.isCurrent) return Container();
                      return SelectableRoomWidget(
                        SelectableRoomWidgetViewModel(
                            room.id,
                            room.title,
                            onSelected: roomsStore.onRoomSelected,
                            isSelected: isRoomSelected,
                            style: _textStyle_RoomSelected
                        ));
                    });
                  },
                );
                break;
            }
            return _RoomsStatusMessage("Unexpected Error", _textStyle_UnexpectedError);
          }),
        )
      ),
    );
  }
}

class _RoomsStatusMessage extends StatelessWidget {
  final String message;
  final TextStyle textStyle;
  _RoomsStatusMessage(this.message, this.textStyle);
  @override
  Widget build(BuildContext context) {
    return Align(alignment: Alignment.center,
        child: Text(message, style: textStyle));
  }
}
