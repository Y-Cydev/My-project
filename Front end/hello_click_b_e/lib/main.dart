import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
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
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final String baseUrl = 'http://localhost:5000/api/HelloClickMe';
  final int pageSize = 10;

  List<Message> _messages = [];
  int _currentPage = 1;
  int _totalMessages = 0;
  String _searchQuery = '';
  Set<int> _selectedIds = {};
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageInputController = TextEditingController();
  Timer? _debounce;

  int get _totalPages => _totalMessages == 0 ? 1 : (_totalMessages / pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _pageInputController.text = _currentPage.toString();
    _loadMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageInputController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    _pageInputController.text = _currentPage.toString();
    try {
      var params = <String, String>{
        'page': _currentPage.toString(),
        'pageSize': pageSize.toString(),
      };
      if (_searchQuery.isNotEmpty) {
        params['search'] = _searchQuery;
      }
      var uri = Uri.parse('$baseUrl/all').replace(queryParameters: params);
      var response = await http.get(uri);
      if (response.statusCode == 200) {
        var body = json.decode(response.body);
        List<dynamic> data = body['data'];
        setState(() {
          _messages = data.map((e) => Message.fromJson(e)).toList();
          _totalMessages = body['total'];
          _selectedIds.clear();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Connection error: $e');
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value;
        _currentPage = 1;
      });
      _loadMessages();
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    setState(() => _currentPage = page);
    _loadMessages();
  }

  Future<void> _showAddDialog() async {
    final contentController = TextEditingController();
    final langController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: langController,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        var response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'content': contentController.text,
            'language': langController.text,
          }),
        );
        if (response.statusCode == 200) {
          _showSnackBar('Message created');
          _loadMessages();
        } else {
          _showSnackBar('Error: ${response.statusCode}');
        }
      } catch (e) {
        _showSnackBar('Failed: $e');
      }
    }
    contentController.dispose();
    langController.dispose();
  }

  Future<void> _showEditDialog() async {
    if (_selectedIds.length != 1) return;
    var msg = _messages.firstWhere((m) => m.id == _selectedIds.first);
    if (mounted) {
      _showEditDialogFor(msg);
    }
  }

  Future<void> _showEditDialogFor(Message msg) async {
    final contentController = TextEditingController(text: msg.content);
    final langController = TextEditingController(text: msg.language);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: langController,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        var response = await http.put(
          Uri.parse('$baseUrl/${msg.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'content': contentController.text,
            'language': langController.text,
          }),
        );
        if (response.statusCode == 200) {
          _showSnackBar('Message updated');
          _loadMessages();
        } else {
          _showSnackBar('Error: ${response.statusCode}');
        }
      } catch (e) {
        _showSnackBar('Failed: $e');
      }
    }
    contentController.dispose();
    langController.dispose();
  }

  Future<void> _onDelete() async {
    if (_selectedIds.isEmpty) return;
    try {
      http.Response response;
      if (_selectedIds.length == 1) {
        response = await http.delete(Uri.parse('$baseUrl/${_selectedIds.first}'));
      } else {
        response = await http.post(
          Uri.parse('$baseUrl/delete-batch'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(_selectedIds.toList()),
        );
      }
      if (response.statusCode == 200) {
        _showSnackBar('Deleted successfully');
        _loadMessages();
      } else {
        _showSnackBar('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Failed: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchAndPagination(),
        _buildButtonBar(),
        Expanded(child: _buildTable()),
        if (_totalPages > 1) _buildPaginationBar(),
        if (_totalPages <= 1) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Text(
            'Messages',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Icon(Icons.mail_outline, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildSearchAndPagination() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search for a message',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black38),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$_currentPage/$_totalPages',
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildAddButton(),
          if (_selectedIds.isNotEmpty) ...[
            const SizedBox(width: 8),
            if (_selectedIds.length == 1) ...[
              _buildEditButton(),
              const SizedBox(width: 8),
            ],
            _buildDeleteButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _showAddDialog,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 15, 4, 224),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton.icon(
      onPressed: _showEditDialog,
      icon: const Icon(Icons.edit, size: 18),
      label: const Text('Edit'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return ElevatedButton.icon(
      onPressed: _onDelete,
      icon: const Icon(Icons.delete, size: 18),
      label: const Text('Delete'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty ? 'No messages match your search' : 'No messages yet',
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isSelected = _selectedIds.contains(msg.id);
        return Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds.add(msg.id);
                    } else {
                      _selectedIds.remove(msg.id);
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIds.remove(msg.id);
                    } else {
                      _selectedIds.add(msg.id);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          msg.content,
                          style: const TextStyle(color: Colors.black, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        msg.language,
                        style: const TextStyle(color: Colors.black, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: _currentPage > 1 ? Colors.black54 : Colors.black12,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _pageInputController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              onSubmitted: (value) {
                var page = int.tryParse(value);
                if (page != null) {
                  _goToPage(page);
                } else {
                  _pageInputController.text = _currentPage.toString();
                }
              },
            ),
          ),
          Text(
            '/$_totalPages',
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            color: _currentPage < _totalPages ? Colors.black54 : Colors.black12,
          ),
        ],
      ),
    );
  }
}