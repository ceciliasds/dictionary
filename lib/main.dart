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

  Future<void> _fetchDefinition(String word) async {
    final response = await http
        .get(Uri.parse("https://api.dictionaryapi.dev/api/v2/entries/en/$word"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _word = word;
        _searchedWord = word;
        _definitions = data;
      });
    } else {
      setState(() {
        _word = word;
        _searchedWord = word;
        _definitions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DICTIONARY',
          textAlign: TextAlign.center,
          style:
          TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Centered and bold quote
              Center(
                child: Text(
                  'Expand your vocabulary, broaden your mind.',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _controller,
                onChanged: (value) {
                  setState(() {
                    _word = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Search Dictionary',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _word = "";
                              _showWordOfTheDayButton = true;
                            });
                          },
                          icon: Icon(Icons.close),
                        ),
                      SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: () {
                          _searched = true;
                          _showWordOfTheDayButton = false; // Hide the Word of the Day button
                          _fetchDefinition(_controller.text);
                        },
                        child: Icon(
                          Icons.search,
                          size: 30,
                          color: Colors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          backgroundColor: Colors.blueGrey[900],
                          padding: EdgeInsets.all(15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (_showWordOfTheDayButton)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showWordOfTheDayButton = false;
                      _fetchWordOfTheDay();
                    });
                  },
                  child: Text(
                    'Word of the Day',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blueGrey[900],
                  ),
                ),
              if (_searched && (_definitions == null || _definitions!.isEmpty))
                _buildNotFoundMessage(_searchedWord),
              if (_definitions != null && _definitions!.isNotEmpty)
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _definitions!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final definition = entry.value;
                        final partOfSpeech =
                        definition['meanings'][0]['partOfSpeech'];
                        final occurrences = _definitions!.where((def) =>
                        def['meanings'][0]['partOfSpeech'] ==
                            partOfSpeech).toList();
                        final count = occurrences.length;
                        final currentIndex =
                            occurrences.indexOf(definition) + 1;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        '${definition['word']}',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        '$partOfSpeech${count > 1 ? ' ($currentIndex)' : ''}',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isBookmarked = !_isBookmarked;
                                      _starColor = _isBookmarked
                                          ? Colors.yellow
                                          : Colors.grey;
                                    });
                                  },
                                  child: Icon(Icons.star,
                                      color: _isBookmarked
                                          ? Colors.yellow
                                          : Colors.grey),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  '${definition['phonetics'][0]['text']}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(width: 5),
                                if (definition['phonetics'][0]['audio'] !=
                                    null)
                                  IconButton(
                                    onPressed: () {
                                      _speak(definition['word']);
                                    },
                                    icon: Icon(Icons.volume_up),
                                  ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${definition['meanings'][0]['definitions'][0]['definition']}',
                              style: TextStyle(fontSize: 16),
                            ),
                            if (definition['meanings'][0]['definitions'][0]
                            ['synonyms'] !=
                                null &&
                                (definition['meanings'][0]['definitions'][0]
                                ['synonyms'] as List)
                                    .isNotEmpty) ...[
                              SizedBox(height: 5),
                              Text(
                                'Synonyms: ${definition['meanings'][0]['definitions'][0]['synonyms'].join(", ")}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                            if (definition['meanings'][0]['definitions'][0]
                            ['example'] !=
                                null) ...[
                              SizedBox(height: 5),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (definition['meanings'][0]['definitions']
                                  [0]['example'] is List)
                                    ...List.generate(
                                      (definition['meanings'][0]['definitions']
                                      [0]['example']
                                      as List)
                                          .length,
                                          (exampleIndex) {
                                        final exampleSentences =
                                        (definition['meanings'][0]
                                        ['definitions'][0]
                                        ['example'][exampleIndex]
                                        as String)
                                            .split('. ');
                                        return Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            for (var i = 0;
                                            i < exampleSentences.length;
                                            i++)
                                              Text(
                                                '${i == 0 ? 'Example ${exampleIndex + 1}' : ''}${i == 0 ? ':' : ''} ${exampleSentences[i]}',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  if (definition['meanings'][0]['definitions']
                                  [0]['example'] is String)
                                    Text(
                                      'Example: ${definition['meanings'][0]['definitions'][0]['example']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                ],
                              ),
                            ],
                            SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundMessage(String searchedWord) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Material(
        elevation: 4,
        shadowColor: Colors.red,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                ' "$searchedWord" is not in our Dictionary. Try another word. ',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searched = false;
                  });
                  _controller.clear(); // Clear the search bar
                },
                child: Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }
}

void main() {
  runApp(MaterialApp(
    home: DictionaryScreen(),
    theme: ThemeData(
      primaryColor: Colors.blueGrey[900],
    ),
    debugShowCheckedModeBanner: false,
  ));
}
