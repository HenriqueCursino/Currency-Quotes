import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(CotacaoApp());
}

class CotacaoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cotação de Moedas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cotação de Moedas')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Ver Cotações Fixas'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CotacoesPage()),
                );
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Buscar Outra Moeda'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BuscaMoedaPage()),
                );
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Converter Moedas'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ConversorPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Tela de cotação fixa
class CotacoesPage extends StatefulWidget {
  @override
  _CotacoesPageState createState() => _CotacoesPageState();
}

class _CotacoesPageState extends State<CotacoesPage> {
  Map<String, dynamic>? cotacoes;
  bool carregando = false;
  String? erro;

  Future<void> buscarCotacoes() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final url = Uri.parse(
          'https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL');
      final resposta = await http.get(url);

      if (resposta.statusCode == 200) {
        final dados = json.decode(resposta.body);
        setState(() {
          cotacoes = dados;
          carregando = false;
        });
      } else {
        setState(() {
          erro = 'Erro ao buscar dados (código ${resposta.statusCode})';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        erro = 'Erro na conexão: $e';
        carregando = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    buscarCotacoes();
  }

  Widget _construirCotacao(String nome, String codigo) {
    if (cotacoes == null || !cotacoes!.containsKey(codigo)) {
      return Text('Sem dados para $nome');
    }

    final moeda = cotacoes![codigo];
    final preco = double.parse(moeda['bid']).toStringAsFixed(2);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: ListTile(
        leading: Icon(Icons.attach_money),
        title: Text('$nome'),
        subtitle: Text('R\$ $preco'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cotações Atuais')),
      body: carregando
          ? Center(child: CircularProgressIndicator())
          : erro != null
              ? Center(child: Text(erro!))
              : ListView(
                  children: [
                    _construirCotacao('Dólar Americano (USD)', 'USDBRL'),
                    _construirCotacao('Euro (EUR)', 'EURBRL'),
                    _construirCotacao('Bitcoin (BTC)', 'BTCBRL'),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.refresh),
                        label: Text('Atualizar'),
                        onPressed: buscarCotacoes,
                      ),
                    )
                  ],
                ),
    );
  }
}

// Tela de busca de uma moeda específica
class BuscaMoedaPage extends StatefulWidget {
  @override
  _BuscaMoedaPageState createState() => _BuscaMoedaPageState();
}

class _BuscaMoedaPageState extends State<BuscaMoedaPage> {
  final _controller = TextEditingController();
  String? resultado;
  String? erro;

  Future<void> buscarMoeda(String codigo) async {
    setState(() {
      resultado = null;
      erro = null;
    });

    try {
      final url =
          Uri.parse('https://economia.awesomeapi.com.br/json/last/$codigo-BRL');
      final resposta = await http.get(url);

      if (resposta.statusCode == 200) {
        final dados = json.decode(resposta.body);
        if (dados.isNotEmpty) {
          final moeda = dados.values.first;
          setState(() {
            resultado =
                "1 $codigo = R\$ ${double.parse(moeda['bid']).toStringAsFixed(2)}";
          });
        } else {
          setState(() => erro = 'Moeda não encontrada');
        }
      } else {
        setState(() => erro = 'Erro na requisição');
      }
    } catch (e) {
      setState(() => erro = 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar Moeda')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                  labelText: 'Digite o código da moeda (ex: USD)'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Buscar'),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  buscarMoeda(_controller.text.toUpperCase());
                }
              },
            ),
            SizedBox(height: 20),
            if (resultado != null)
              Text(resultado!, style: TextStyle(fontSize: 20)),
            if (erro != null) Text(erro!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

// Tela de conversão de moeda
class ConversorPage extends StatefulWidget {
  @override
  _ConversorPageState createState() => _ConversorPageState();
}

class _ConversorPageState extends State<ConversorPage> {
  final _valorController = TextEditingController();
  String moedaOrigem = 'USD';
  String moedaDestino = 'BRL';
  String? resultado;
  String? erro;

  Future<void> converterMoeda() async {
    final valorTexto = _valorController.text;

    if (valorTexto.isEmpty || double.tryParse(valorTexto) == null) {
      setState(() => erro = 'Digite um valor válido');
      return;
    }

    setState(() {
      resultado = null;
      erro = null;
    });

    try {
      final url = Uri.parse(
          'https://economia.awesomeapi.com.br/json/last/$moedaOrigem-$moedaDestino');
      final resposta = await http.get(url);

      if (resposta.statusCode == 200) {
        final dados = json.decode(resposta.body);
        final moeda = dados.values.first;
        final taxa = double.parse(moeda['bid']);
        final valor = double.parse(valorTexto);
        final convertido = valor * taxa;

        setState(() {
          resultado =
              '$valor $moedaOrigem = ${convertido.toStringAsFixed(2)} $moedaDestino';
        });
      } else {
        setState(() => erro = 'Erro ao buscar taxa de câmbio');
      }
    } catch (e) {
      setState(() => erro = 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conversor de Moedas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Valor a converter'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('De:', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: moedaOrigem,
                  onChanged: (String? nova) {
                    setState(() {
                      moedaOrigem = nova!;
                    });
                  },
                  items: ['USD', 'EUR', 'BTC', 'BRL']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Para:', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: moedaDestino,
                  onChanged: (String? nova) {
                    setState(() {
                      moedaDestino = nova!;
                    });
                  },
                  items: ['USD', 'EUR', 'BTC', 'BRL']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Converter'),
              onPressed: converterMoeda,
            ),
            SizedBox(height: 20),
            if (resultado != null)
              Text(resultado!, style: TextStyle(fontSize: 18)),
            if (erro != null) Text(erro!, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
