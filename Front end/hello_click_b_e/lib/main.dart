import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:html' as html; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: MyButton(),
        ),
      ),
    );
  }
}

class MyButton extends StatefulWidget {
  @override
  _MyButtonState createState() {
    return _MyButtonState();
  }
}

class _MyButtonState extends State<MyButton> {
  String buttonText = "Click Me";

  @override
  void initState() {
    super.initState();
    setButtonText();
  }

  void setButtonText() {
    String lang = ui.PlatformDispatcher.instance.locale?.languageCode ?? "en";

    setState(() {
      if (lang.startsWith("ar")) {
        buttonText = "اضغط هنا";
      } else if (lang.startsWith("fr")) {
        buttonText = "Cliquez-moi";
      } else {
        buttonText = "Click Me";
      }
    });
  }

  void fetchMessage() async {
    try {
      
      Uri url = Uri.parse("http://localhost:5000/api/HelloClickMe");

      var response = await http.get(url, headers: {
        "Accept-Language": ui.PlatformDispatcher.instance.locale?.languageCode ?? "en"
      });

      if (response.statusCode == 200) {
       
        html.window.alert(response.body);
      } else {
        html.window.alert("Error: ${response.statusCode}");
      }
    } catch (e) {
      html.window.alert("Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: fetchMessage,
      child: Text(buttonText),
    );
  }
}
