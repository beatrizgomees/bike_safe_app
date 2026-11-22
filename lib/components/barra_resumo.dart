import 'package:bikesafe_app/components/numero.dart';
import 'package:bikesafe_app/models/resumo.dart';
import 'package:flutter/widgets.dart';

class BarraResumo extends StatelessWidget {
  const BarraResumo(this.r);
  final Resumo r;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Wrap(
          spacing: 28,
          runSpacing: 6,
          children: [
            Numero('${r.acidentesBike}', 'acidentes com bike'),
            Numero('${r.geocodificados}', 'localizados no mapa'),
            Numero('${r.emCiclovia}', 'em ciclovia'),
            Numero('${r.comEstacaoNoRaio}', 'perto de estação'),
          ],
        ),
      );
}