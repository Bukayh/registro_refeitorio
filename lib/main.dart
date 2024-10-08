import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Refeição',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _matriculaController = TextEditingController();
  String? _parteDoDia;

  void _registrarEntrada() async {
    String matricula = _matriculaController.text;

    if (await DatabaseHelper().matriculaExists(matricula)) {
      String nome = await DatabaseHelper().getNome(matricula);
      String parteDoDia = _parteDoDia ?? "Indefinido";

      await DatabaseHelper().registerEntry(matricula, nome, parteDoDia);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Entrada registrada com sucesso!")),
      );
      setState(() { // Atualiza a tela
      _matriculaController.clear(); // Limpa a matrícula após registrar
    });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Senha não encontrada.")),
      );
    }
  }

  void _showConfigMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100.0, 100.0, 0.0, 0.0),
      items: [
        PopupMenuItem<String>(
          value: 'cadastrar',
          child: Text('Cadastrar Novo Colaborador'),
        ),
        PopupMenuItem<String>(
          value: 'baixar',
          child: Text('Baixar Registro'),
        ),
        PopupMenuItem<String>(
          value: 'mostrar',
          child: Text('Mostrar Cadastros'),
        ),
      ],
    ).then((value) {
      if (value == 'cadastrar') {
        _confirmarSenhaParaCadastro();
      } else if (value == 'baixar') {
        _selecionarDatas(context);
      } else if (value == 'mostrar') {
        _confirmarSenhaParaMostrarCadastros();
      }
    });
  }

  void _confirmarSenhaParaCadastro() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _senhaController = TextEditingController();

        return AlertDialog(
          title: Text("Confirmar Senha Admin"),
          content: TextField(
            controller: _senhaController,
            decoration: InputDecoration(labelText: "Senha Admin"),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_senhaController.text == "1523") {
                  Navigator.of(context).pop();
                  _cadastrarUsuario();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Senha incorreta.")),
                  );
                }
              },
              child: Text("Confirmar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  void _cadastrarUsuario() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _matriculaController = TextEditingController();
        final TextEditingController _nomeController = TextEditingController();

        return AlertDialog(
          title: Text("Cadastrar Usuário"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _matriculaController,
                decoration: InputDecoration(labelText: "Senha"),
              ),
              TextField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: "Nome Completo"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await DatabaseHelper().addUser(
                  _matriculaController.text,
                  _nomeController.text,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Usuário cadastrado com sucesso!")),
                );
              },
              child: Text("Cadastrar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            )
          ]
        );
      },
    );
  }

void _baixarRegistro(DateTime dataInicial, DateTime dataFinal) async {
  // Chama a função exportToCSV passando as datas selecionadas
  await DatabaseHelper().exportToCSV(dataInicial, dataFinal);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Registro baixado com sucesso!")),
  );
}

Future<void> _selecionarDatas(BuildContext context) async {
  DateTime? dataInicial = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
    helpText: 'Selecione a data inicial',
  );

  if (dataInicial != null) {
    DateTime? dataFinal = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: dataInicial,
      lastDate: DateTime.now(),
      helpText: 'Selecione a data final',
    );

    if (dataFinal != null) {
      _baixarRegistro(dataInicial, dataFinal);
    }
  }
}

  void _confirmarSenhaParaMostrarCadastros() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _senhaController = TextEditingController();

        return AlertDialog(
          title: Text("Confirmar Senha Admin"),
          content: TextField(
            controller: _senhaController,
            decoration: InputDecoration(labelText: "Senha Admin"),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_senhaController.text == "1523") {
                  Navigator.of(context).pop();
                  _mostrarCadastros();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Senha incorreta.")),
                  );
                }
              },
              child: Text("Confirmar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  void _mostrarCadastros() async {
    final usuarios = await DatabaseHelper().getAllUsers();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Usuários Cadastrados"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(usuarios[index]['nome']),
                  subtitle: Text(usuarios[index]['matricula']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _confirmarExclusao(usuarios[index]['matricula']);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  void _confirmarExclusao(String matricula) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar Exclusão"),
          content: Text("Você tem certeza que deseja excluir este usuário?"),
          actions: [
            TextButton(
              onPressed: () async {
                await DatabaseHelper().deleteUser(matricula);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Usuário excluído com sucesso!")),
                );
              },
              child: Text("Excluir"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    );
  }

  void _definirParteDoDia() {
    final agora = DateTime.now();
    final hora = agora.hour;

    if (hora >= 6 && hora < 10) {
      setState(() {
        _parteDoDia = 'Café da Manhã';
      });
    } else if (hora >= 10 && hora < 14) {
      setState(() {
        _parteDoDia = 'Almoço';
      });
    } else if (hora >= 18 && hora < 22) {
      setState(() {
        _parteDoDia = 'Janta';
      });
    } else {
      setState(() {
        _parteDoDia = 'Indefinido';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _definirParteDoDia();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Registro de Refeição"),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => _showConfigMenu(context),
        ),
      ],
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Digite sua Senha:"),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _matriculaController.text, // Exibe a matrícula digitada
                  style: TextStyle(fontSize: 24), // Tamanho do texto
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumericButton('1'),
                    _buildNumericButton('2'),
                    _buildNumericButton('3'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumericButton('4'),
                    _buildNumericButton('5'),
                    _buildNumericButton('6'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumericButton('7'),
                    _buildNumericButton('8'),
                    _buildNumericButton('9'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumericButton('0'),
                    _buildNumericButton('C'),
                    ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.all(15), // Aumenta o padding dentro do botão
                            minimumSize: Size(80, 80), // Define o tamanho mínimo dos botões
                          ),
                      onPressed: _registrarEntrada,
                      child: Icon(Icons.check,size:36), // Ícone de "Enter"
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildNumericButton(String value) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.all(15), // Aumenta o padding dentro do botão
      minimumSize: Size(80, 80), // Define o tamanho mínimo dos botões
    ),
    onPressed: () {
      setState(() { // Adicionando setState para atualizar a tela
        if (value == 'C' ) {
          _matriculaController.clear();
        } else {
          _matriculaController.text += value;
        }
      });
    },
    child: Text(
value,
      style: TextStyle(fontSize: 24),),
  );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = p.join(documentsDirectory.path, "registro_trabalho.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            matricula TEXT PRIMARY KEY,
            nome TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE registro (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            matricula TEXT,
            nome TEXT,
            parte_do_dia TEXT,
            data_hora TEXT,
            FOREIGN KEY (matricula) REFERENCES usuarios (matricula)
          )
        ''');
      },
    );
  }

  Future<void> addUser(String matricula, String nome) async {
    final db = await database;
    await db.insert('usuarios', {'matricula': matricula, 'nome': nome});
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('usuarios');
  }

  Future<void> deleteUser(String matricula) async {
    final db = await database;
    await db.delete('usuarios', where: 'matricula = ?', whereArgs: [matricula]);
  }

  Future<void> registerEntry(String matricula, String nome, String parteDoDia) async {
    final db = await database;
    String dataHora = DateFormat('yyyy-MM-dd – HH:mm:ss').format(DateTime.now());
    await db.insert('registro', {
      'matricula': matricula,
      'nome': nome,
      'parte_do_dia': parteDoDia,
      'data_hora': dataHora,
    });
  }

  Future<bool> matriculaExists(String matricula) async {
    final db = await database;
    final result = await db.query('usuarios', where: 'matricula = ?', whereArgs: [matricula]);
    return result.isNotEmpty;
  }

  Future<String> getNome(String matricula) async {
    final db = await database;
    final result = await db.query('usuarios', where: 'matricula = ?', whereArgs: [matricula]);
    return result.isNotEmpty ? result.first['nome'] as String : '';
  }

Future<void> exportToCSV(DateTime dataInicial, DateTime dataFinal) async {
  final db = await database;

  // Formata as datas para o formato aceito pelo banco de dados
  String dataInicialFormatada = dataInicial.toIso8601String();
  String dataFinalFormatada = dataFinal.toIso8601String();

  // Consulta os registros dentro do intervalo de datas
  final result = await db.query(
    'registro',
    where: 'data_hora BETWEEN ? AND ?',
    whereArgs: [dataInicialFormatada, dataFinalFormatada],
  );

  // Monta os dados CSV
  String csvData = 'Matrícula,Nome,Parte do Dia,Data Hora\n';
  for (var row in result) {
    csvData += '${row['matricula']},${row['nome']},${row['parte_do_dia']},${row['data_hora']}\n';
  }

  // Cria um arquivo temporário para o CSV
  final Directory tempDir = await getTemporaryDirectory();
  final File tempFile = File('${tempDir.path}/registros_filtrados.csv');

  // Escreve os dados no arquivo
  await tempFile.writeAsString(csvData);

  // Compartilha o arquivo
  await Share.shareXFiles([XFile(tempFile.path)], text: 'Registros exportados em CSV');
}

}
