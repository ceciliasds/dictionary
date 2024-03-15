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

  Future<void> _fetchWordOfTheDay() async {
    final response =
    await http.get(Uri.parse("https://api.dictionaryapi.dev/api/v2/entries/en/random"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final wordOfTheDay = data[0]['word'];
      await _fetchDefinition(wordOfTheDay);
    } else {
      setState(() {
        _word = "";
        _searchedWord = "Failed to fetch the Word of the Day";
        _definitions = [];
      });
    }
  }

  Future<void> _fetchRandomWord() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime? lastFetchedDate =
    DateTime.tryParse(prefs.getString('lastFetchedDate') ?? '');

    if (lastFetchedDate == null ||
        !isSameDay(lastFetchedDate, DateTime.now())) {
      final response = await http
          .get(Uri.parse("https://random-word-api.herokuapp.com/word?number=1"));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final randomWord = data[0];
        await _fetchDefinition(randomWord);
        prefs.setString('lastFetchedDate', DateTime.now().toString());
      } else {
        setState(() {
          _word = "";
          _searchedWord = "Failed to fetch random word";
          _definitions = [];
        });
      }
    } else {
      setState(() {
        _word = "";
        _searchedWord = "Word of the Day already fetched today";
        _definitions = [];
      });
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
