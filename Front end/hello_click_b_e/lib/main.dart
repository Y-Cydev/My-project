import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Messages'),
        ),
        body: MessagesPage(),
      ),
    );
  }
}

class Message {
  final int id;
  final String content;
  final String language;

  Message({required this.id, required this.content, required this.language});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      content: json['content'] ?? '',
      language: json['language'] ?? '',
    );
  }
}

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final String baseUrl = 'http://localhost:5000/api/HelloClickMe';

  String _mode = 'idle';
  String _boxTitle = 'New Instruction';
  List<Message> _messages = [];

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _newContentController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    _newContentController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  void _resetBox() {
    _contentController.clear();
    _newContentController.clear();
    _languageController.clear();
  }

  void _onNew() {
    setState(() {
      _mode = 'new';
      _boxTitle = 'New Instruction';
      _resetBox();
    });
  }

  void _onUpgrade() {
    setState(() {
      _mode = 'upgrade';
      _boxTitle = 'Upgrade Instruction';
      _resetBox();
    });
  }

  void _onDelete() {
    setState(() {
      _mode = 'delete';
      _boxTitle = 'Delete Instruction';
      _resetBox();
    });
  }

  Future<void> _onShowAll() async {
    try {
      var url = Uri.parse('$baseUrl/all');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _messages = data.map((e) => Message.fromJson(e)).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _onRandom() async {
    try {
      var url = Uri.parse('$baseUrl/random');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['id'] != null) {
          setState(() {
            _messages = [Message.fromJson(data)];
          });
        } else {
          _showSnackBar(data['content'] ?? 'No messages');
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _onApply() async {
    try {
      http.Response response;
      switch (_mode) {
        case 'new':
          response = await http.post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'content': _contentController.text,
              'language': _languageController.text,
            }),
          );
          break;
        case 'upgrade':
          response = await http.put(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'originalContent': _contentController.text,
              'newContent': _newContentController.text,
              'language': _languageController.text,
            }),
          );
          break;
        case 'delete':
          var url = Uri.parse(
              '$baseUrl?content=${Uri.encodeComponent(_contentController.text)}&language=${Uri.encodeComponent(_languageController.text)}');
          response = await http.delete(url);
          break;
        default:
          return;
      }

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        _showSnackBar(data['message'] ?? 'Success');
        _resetBox();
        setState(() {
          _mode = 'idle';
        });
      } else {
        _showSnackBar('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton(onPressed: _onNew, child: Text('New')),
              SizedBox(width: 8),
              ElevatedButton(onPressed: _onUpgrade, child: Text('Upgrade')),
              SizedBox(width: 8),
              ElevatedButton(onPressed: _onDelete, child: Text('Delete')),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton(onPressed: _onShowAll, child: Text('Show ALL')),
                          SizedBox(width: 8),
                          ElevatedButton(onPressed: _onRandom, child: Text('Random')),
                        ],
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 10,
                                  columns: [DataColumn(label: Text('Content'))],
                                  rows: _messages
                                      .map((m) => DataRow(cells: [
                                            DataCell(Text(m.content)),
                                          ]))
                                      .toList(),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 10,
                                  columns: [DataColumn(label: Text('Language'))],
                                  rows: _messages
                                      .map((m) => DataRow(cells: [
                                            DataCell(Text(m.language)),
                                          ]))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _boxTitle,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: _contentController,
                            decoration: InputDecoration(
                              labelText: _mode == 'upgrade'
                                  ? 'Original Content'
                                  : 'Content',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_mode == 'upgrade') ...[
                            SizedBox(height: 8),
                            TextField(
                              controller: _newContentController,
                              decoration: InputDecoration(
                                labelText: 'New Content',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          SizedBox(height: 8),
                          TextField(
                            controller: _languageController,
                            decoration: InputDecoration(
                              labelText: 'Language',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _mode != 'idle' ? _onApply : null,
                              child: Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}