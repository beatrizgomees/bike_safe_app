import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Numero extends StatelessWidget {
  const Numero(this.valor, this.rotulo);
  final String valor, rotulo;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valor, style: Theme.of(context).textTheme.titleLarge),
          Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}