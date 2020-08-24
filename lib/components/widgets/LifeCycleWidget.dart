import 'package:flutter/material.dart';

typedef Disposer = void Function();

class LifeCycleWidget extends StatefulWidget {
  const LifeCycleWidget({
    Key key,
    @required this.builder,
    @required this.dispose,
    @required this.init,
    this.reassemble,
  }) : assert(builder != null),
        super(key: key);

  final StatefulWidgetBuilder builder;
  final Disposer dispose;
  final Function reassemble;
  final Function init;

  @override
  _LifeCycleWidgetState createState() => _LifeCycleWidgetState();
}

class _LifeCycleWidgetState extends State<LifeCycleWidget> {
  @override
  void initState() {
    super.initState();
    widget.init();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (widget.reassemble != null) {
      widget.reassemble();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
  @override
  void dispose() {
    super.dispose();
    widget.dispose();
  }
}