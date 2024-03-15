import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  TextEditingController _controller = TextEditingController();
  String _word = "";
  String _searchedWord = "";
  List<dynamic>? _definitions;
  bool _searched = false;
  bool _isBookmarked = false;
  Color _starColor = Colors.white;
  FlutterTts flutterTts = FlutterTts();
  bool _showWordOfTheDayButton = true;

  @override
  void initState() {
    super.initState();
    _fetchWordOfTheDay();
  }
