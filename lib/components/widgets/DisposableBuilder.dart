import 'package:flutter/material.dart';

typedef Disposer = void Function();

class DisposableBuilder extends StatefulWidget {
  const DisposableBuilder({
    Key key,
    @required this.builder,
    @required this.dispose,
    @required this.init,
  }) : assert(builder != null),
        super(key: key);

  final StatefulWidgetBuilder builder;
  final Disposer dispose;
  final Function init;

  @override
  _DisposableBuilderState createState() => _DisposableBuilderState();
}

class _DisposableBuilderState extends State<DisposableBuilder> {
  @override
  void initState() {
    super.initState();
    widget.init();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
  @override
  void dispose() {
    super.dispose();
    widget.dispose();
  }
}