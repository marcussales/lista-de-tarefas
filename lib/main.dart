import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List toDoList = [];
  final _toDoController = TextEditingController();
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) =>
    {
      setState(() {
        toDoList = json.decode(data);
      })
    });
  }

  void addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = '';
      newToDo["ok"] = false;
      toDoList.add(newToDo);
      _saveFile();
    });
  }

  Future<File> getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveFile() async {
    String data = json.encode(toDoList);
    final file = await getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<Null> _refresh() async {
    setState(() {
      toDoList.sort((a, b) {
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
        _saveFile();
      });
    });
  }

  Widget buildItem(context, index) {
    return Dismissible(
        key: Key(DateTime
            .now()
            .millisecondsSinceEpoch
            .toString()),
        background: Container(
          color: Colors.red,
          child: Align(
              alignment: Alignment(-0.9, 0.0),
              child: Icon(Icons.delete, color: Colors.white)
          ),
        ),
        direction: DismissDirection.startToEnd,
        onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(toDoList[index]);
            _lastRemovedPos = index;
            toDoList.removeAt(index);
            _saveFile();
            final snack = SnackBar(
              content: Text("A tarefa ${_lastRemoved["title"]} foi removida"),
              action: SnackBarAction(
                label: "Desfazer",
                  onPressed: () {
                    setState(() {
                      toDoList.insert(_lastRemovedPos, _lastRemoved);
                      _saveFile();
                    });
                  }),
              duration: Duration(seconds: 2),
            );
            Scaffold.of(context).showSnackBar(snack);
          });
        },
        child: CheckboxListTile(
            title: Text(toDoList[index]["title"]),
            value: toDoList[index]["ok"],
            secondary: CircleAvatar(
                child: Icon(
                    toDoList[index]["ok"] ? Icons.check : Icons.error)),
            onChanged: (check) {
              setState(() {
                toDoList[index]["ok"] = check;
                _saveFile();
              });
            }
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: Text("Lista de tarefas"),
          centerTitle: true),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 5.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                          labelText: "Nome da tarefa",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                      controller: _toDoController,
                    )),
                RaisedButton(
                    color: Colors.blueAccent,
                    child: Text("Add"),
                    textColor: Colors.white,
                    onPressed: addToDo)
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
            onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: toDoList.length,
                  itemBuilder: buildItem)
            ),
          )
        ],
      ),
    );
  }
}
