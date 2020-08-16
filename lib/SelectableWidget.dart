import 'package:flutter/material.dart';

class SelectableWidget extends StatefulWidget {
  final SelectableWidgetViewModel viewModel;

  SelectableWidget(this.viewModel);

  @override
  State<StatefulWidget> createState() {
    return SelectableWidgetState();
  }
}

class SelectableWidgetState extends State<SelectableWidget> {
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
          widget.viewModel.isSelected = !widget.viewModel.isSelected;
          widget.viewModel.onSelected(widget.viewModel.isSelected
              ? widget.viewModel.title
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

class SelectableWidgetViewModel {
  bool isSelected;
  String title;
  TextStyle style;
  OnSelected onSelected;

  SelectableWidgetViewModel(this.title, {this.isSelected = false, this.style, this.onSelected});
}