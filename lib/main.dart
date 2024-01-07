import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CalculatorApp(),
    );
  }
}

class CalculatorApp extends StatefulWidget {
  @override
  _CalculatorAppState createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  String _output = '0';
  String _realTimeOutput = '';
  late Parser parser;
  late ContextModel contextModel;
  List<String> history = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    parser = Parser();
    contextModel = ContextModel();
    _loadHistory();
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      history = prefs.getStringList('history') ?? [];
    });
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('history', history);
  }

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _output = '0';
        _realTimeOutput = '';
      } else if (buttonText == 'D') {
        if (_output.length > 1) {
          _output = _output.substring(0, _output.length - 1);
        } else {
          _output = '0';
        }
      } else if (buttonText == '=') {
        if (_output.endsWith('+') || _output.endsWith('-') || _output.endsWith('x') || _output.endsWith('/')) {
          _output = _output.substring(0, _output.length - 1);
        }
        try {
          String expressionString = _output.replaceAll('x', '*');
          Expression expression = parser.parse(expressionString);
          double result = expression.evaluate(EvaluationType.REAL, contextModel);
          _output = '$result';
          _realTimeOutput = '';
          history.add('$_output = $expressionString');
          _saveHistory();
        } catch (e) {
          _output = 'Error';
          _realTimeOutput = '';
        }
      } else if (buttonText == '+' || buttonText == '-' || buttonText == '/' || buttonText == 'x') {
        if (_output.isNotEmpty &&
            (_output.endsWith('+') || _output.endsWith('-') || _output.endsWith('x') || _output.endsWith('/'))) {
          _output = _output.substring(0, _output.length - 1);
        } else {
          _output += buttonText;
        }
      } else {
        if (_output == '0') {
          _output = buttonText;
        } else {
          _output += buttonText;
        }
        try {
          String expressionString = _output.replaceAll('x', '*');
          Expression expression = parser.parse(expressionString);
          double realTimeResult = expression.evaluate(EvaluationType.REAL, contextModel);
          _realTimeOutput = '$realTimeResult';
        } catch (e) {
          _realTimeOutput = 'Error';
        }
      }
    });
  }

  Widget _buildButton(String buttonText, {Color? textColor, Color? bgColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(7.0),
        child: ElevatedButton(
          onPressed: () => _buttonPressed(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor ?? Theme.of(context).primaryColor,
            foregroundColor: textColor ?? Colors.white,
            shape: CircleBorder(),
            minimumSize: Size(70, 70),
          ),
          child: Text(
            buttonText,
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: ElevatedButton(
        onPressed: () {
          _scaffoldKey.currentState!.openDrawer();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
          minimumSize: Size(70, 70),
        ),
        child: Text(
          'H',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Flutter Calculator'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _output,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _realTimeOutput,
                    style: TextStyle(fontSize: 24),
                  ),
                  Divider(
                    height: 5,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _buildButton('C', bgColor: Colors.red),
              _buildButton('%', textColor: Colors.white),
              _buildButton('D', bgColor: Colors.grey),
              _buildHistoryButton(),
            ],
          ),
          Row(
            children: [
              _buildButton('7'),
              _buildButton('8'),
              _buildButton('9'),
              _buildButton('/', bgColor: Colors.orange),
            ],
          ),
          Row(
            children: [
              _buildButton('4'),
              _buildButton('5'),
              _buildButton('6'),
              _buildButton('x', bgColor: Colors.orange),
            ],
          ),
          Row(
            children: [
              _buildButton('1'),
              _buildButton('2'),
              _buildButton('3'),
              _buildButton('-', bgColor: Colors.orange),
            ],
          ),
          Row(
            children: [
              _buildButton('0'),
              _buildButton('.', textColor: Colors.white),
              _buildButton('=', bgColor: Colors.green),
              _buildButton('+', bgColor: Colors.orange),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text(
                'Calculation History',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            for (String entry in history)
              ListTile(
                title: Text(entry),
              ),
          ],
        ),
      ),
    );
  }
}
