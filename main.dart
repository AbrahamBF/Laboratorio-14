import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'team.dart';
import 'DatabaseHelper.dart';

void main() {
  // Inicializa sqflite para soporte de escritorio
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equipo de Futbol',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TeamList(),
    );
  }
}

class TeamList extends StatefulWidget {
  @override
  _TeamListState createState() => _TeamListState();
}

class _TeamListState extends State<TeamList> {
  List<Team> teams = [];

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final dbHelper = DatabaseHelper();
    final loadedTeams = await dbHelper.getTeams();
    setState(() {
      teams = loadedTeams;
    });
  }

  Future<void> _showTeamDialog({Team? team}) async {
    final newTeam = await showDialog<Team>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(team != null ? 'Editar equipo' : 'Agregar equipo'),
          content: TeamForm(team: team),
        );
      },
    );

    if (newTeam != null) {
      setState(() {
        if (team != null) {
          // Actualizar equipo existente
          final index = teams.indexWhere((t) => t.id == team.id);
          if (index != -1) {
            teams[index] = newTeam;
            DatabaseHelper().updateTeam(newTeam);
          }
        } else {
          // Agregar nuevo equipo
          teams.add(newTeam);
          DatabaseHelper().insertTeam(newTeam);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liga 1'),
      ),
      body: ListView.builder(
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];
          return ListTile(
            leading: Icon(Icons.sports_soccer),
            title: Text(
              team.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyText2,
                children: [
                  TextSpan(
                    text: 'Año de Fundación: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '${team.foundingYear}\n'),
                  TextSpan(
                    text: 'Última Fecha de Campeonato: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '${team.lastChampDate.toLocal().toIso8601String().split('T').first}'),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showTeamDialog(team: team),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await DatabaseHelper().deleteTeam(team.id);
                    setState(() {
                      teams.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeamDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class TeamForm extends StatefulWidget {
  final Team? team;

  TeamForm({this.team});

  @override
  _TeamFormState createState() => _TeamFormState();
}

class _TeamFormState extends State<TeamForm> {
  final _formKey = GlobalKey<FormState>();
  late int _id;
  late String _name;
  late int _foundingYear;
  late DateTime _lastChampDate;
  TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.team != null) {
      _id = widget.team!.id;
      _name = widget.team!.name;
      _foundingYear = widget.team!.foundingYear;
      _lastChampDate = widget.team!.lastChampDate;
      _dateController.text = _lastChampDate.toLocal().toIso8601String().split('T').first;
    } else {
      _id = 0;
      _name = '';
      _foundingYear = DateTime.now().year;
      _lastChampDate = DateTime.now();
      _dateController.text = _lastChampDate.toLocal().toIso8601String().split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'ID'),
              keyboardType: TextInputType.number,
              initialValue: widget.team != null ? _id.toString() : '',
              onSaved: (value) {
                _id = int.parse(value!);
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Nombre'),
              initialValue: _name,
              onSaved: (value) {
                _name = value!;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Año de fundación'),
              keyboardType: TextInputType.number,
              initialValue: _foundingYear.toString(),
              onSaved: (value) {
                _foundingYear = int.parse(value!);
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Fecha del último campeonato'),
              controller: _dateController,
              readOnly: true,
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _lastChampDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != _lastChampDate) {
                  setState(() {
                    _lastChampDate = picked;
                    _dateController.text = _lastChampDate.toLocal().toIso8601String().split('T').first;
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final newTeam = Team(
                    id: _id,
                    name: _name,
                    foundingYear: _foundingYear,
                    lastChampDate: _lastChampDate,
                  );
                  Navigator.pop(context, newTeam);
                }
              },
              child: Text('Grabar'),
            ),
          ],
        ),
      ),
    );
  }
}
