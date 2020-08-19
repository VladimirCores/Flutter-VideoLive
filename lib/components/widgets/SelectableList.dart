import 'package:flutter/material.dart';

class SelectableRoomWidget extends StatefulWidget {
  final SelectableRoomWidgetViewModel viewModel;

  SelectableRoomWidget(this.viewModel);

  @override
  State<StatefulWidget> createState() {
    return SelectableRoomWidgetState();
  }
}

class SelectableRoomWidgetState extends State<SelectableRoomWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Container container;

    if (widget.viewModel.isSelected) {
      container = new Container(
        alignment: Alignment.center,
        height: 100.0,
        color: Colors.green,
        child: new Text(
          widget.viewModel.title,
          textAlign: TextAlign.center,
          style: widget.viewModel.style,
        ),
      );
    } else {
      container = new Container(
        alignment: Alignment.center,
        height: 100.0,
        color: Colors.blue,
        child: new Text(
          widget.viewModel.title,
          textAlign: TextAlign.center,
          style: widget.viewModel.style,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.viewModel.onSelected(!widget.viewModel.isSelected
              ? widget.viewModel.id
              : null
          );
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: container,
      ),
    );
  }
}

typedef void OnSelected(String value);

class SelectableRoomWidgetViewModel {
  bool isSelected;
  String id;
  String title;
  TextStyle style;
  OnSelected onSelected;

  SelectableRoomWidgetViewModel(this.id, this.title, {this.isSelected = false, this.style, this.onSelected});
}