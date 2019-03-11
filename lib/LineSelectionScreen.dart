import 'package:flutter/material.dart';

class LineSelectionScreen extends StatefulWidget {

  Map<String, bool> lines;
  Function saveState;
  LineSelectionScreen({Key key, @required this.lines, @required this.saveState}) : super(key: key);

  @override
  LineSelectionState createState() => new LineSelectionState(lines: this.lines, saveState: this.saveState);
}

class LineSelectionState extends State<LineSelectionScreen> {
  LineSelectionState({Key key, @required this.lines, @required this.saveState});
  Map<String, bool> lines;
  Function saveState;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Valitse linjat')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () { Navigator.pop(context); }

      ),
      body: new ListView(
        children: lines.keys.map((String key) {
          return new CheckboxListTile(
            title: Text(key),
            value: lines[key],
            onChanged: (bool value) {
              // Set UI state
              setState(() {
                lines[key] = value;
              });
              // Set parent ("global") state
              saveState(key, value);
            },
          );
        }).toList(),
      ),
    );
  }
}
