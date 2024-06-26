import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:travelguide/translator2.dart';

class Translator extends StatefulWidget {
  const Translator({super.key});

  @override
  State<Translator> createState() => _TranslatorState();
}

class _TranslatorState extends State<Translator> {
  final TextEditingController _outputController = TextEditingController();

  Timer? _debounce;
  bool _isLoading =
      false; // Flag to control the visibility of loading animation

  //List<List<dynamic>> _dataCSV = [];

  var arabicProverb = "";
  var phoneticTranscription = "";
  var englishTranslation = "";

  bool isCardVisible = true;

  @override
  void initState() {
    super.initState();
    //_loadProverbsCSV();
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel the debounce timer to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 241, 241, 241),
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 160.0, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input Text
              Padding(
                padding: const EdgeInsets.only(right: 200.0),
                child: Text("Enter your text",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 23,
                            color: Color.fromARGB(255, 0, 0, 0)))),
              ),
              const SizedBox(height: 8.0),
              Material(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                elevation: 4.0,
                child: TextField(
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            width: 1, color: Color.fromRGBO(49, 0, 172, 1)),
                        borderRadius: BorderRadius.circular(20.0)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            width: 0.5,
                            color: Color.fromARGB(255, 255, 255, 255)),
                        borderRadius: BorderRadius.circular(20.0)),
                    filled: true,
                    fillColor: Color.fromARGB(255, 255, 255, 255),
                    contentPadding: EdgeInsets.all(55),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                  ),
                  maxLines: null,
                  onChanged: (text) {
                    debugPrint('changed text $text');
                    _translateText(text);
                  },
                ),
              ),

              const SizedBox(height: 60.0),

              // Translated Text
              Padding(
                padding: const EdgeInsets.only(right: 240),
                child: Text("Translated",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 23,
                            color: Color.fromARGB(255, 0, 0, 0)))),
              ),
              const SizedBox(height: 8.0),
              Material(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                elevation: 4.0,
                child: InputDecorator(
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 1, color: Color.fromRGBO(49, 0, 172, 1)),
                          borderRadius: BorderRadius.circular(50.0)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 0.5,
                              color: Color.fromARGB(255, 255, 255, 255)),
                          borderRadius: BorderRadius.circular(50.0)),
                      filled: true,
                      fillColor: Color.fromARGB(255, 255, 255, 255),
                      contentPadding: EdgeInsets.all(55),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                    ),
                    child: _isLoading
                        ? Text(
                            '${_outputController.text}...',
                            style: const TextStyle(
                              fontSize: 16.0,
                            ),
                            maxLines: null,
                            textDirection: TextDirection.rtl,
                          )
                        : TextField(
                            controller: _outputController,
                            maxLines: null,
                            readOnly: true,

                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration.collapsed(
                                hintText: "",
                                hintStyle: TextStyle(color: Colors.grey),
                                fillColor: Colors.grey),
                            //   // maybe onTap copies the text
                            //   // maybe leave it to the user to focus it to copy it or smthn
                            //   // canRequestFocus: false,
                            // ),
                          )),
              ),

              const SizedBox(height: 20),
              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Translator2()),
                    );
                  },
                  child: Text(
                    "Or Try Recording",
                    style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                            fontWeight: FontWeight.w400,
                            fontSize: 18,
                            color: Colors.blue)),
                  ),
                ),
              ),
              SizedBox(
                height: 50,
              ),
              // Material(
              //   borderRadius: const BorderRadius.all(Radius.circular(20)),
              //   child: TextButton(
              //     onPressed: () => _showRandomProverbDialog(),
              //     child: Text(
              //         style: GoogleFonts.poppins(
              //             textStyle: TextStyle(
              //                 fontWeight: FontWeight.normal,
              //                 fontSize: 18,
              //                 color: Color.fromARGB(255, 47, 0, 255))),
              //         "Show a random Egyptian proverb"),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // I think it implacitly takes the 2d list by reference so memory good
  // List<dynamic> chooseRandomProverb(List<List<dynamic>> proverbsCSV) {
  //   var randomValue = Random().nextInt(proverbsCSV.length - 1) + 1;
  //   return proverbsCSV[randomValue];
  // }

  // void _showRandomProverbDialog() {
  //   showDialog<String>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       // Choose a random proverb
  //       var proverb = chooseRandomProverb(_dataCSV);
  //       var arabic = proverb[0];
  //       var transpilation = proverb[1];
  //       var english = proverb[2];

  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: const Text('Random Egyptian Proverb'),
  //             content: Column(
  //               crossAxisAlignment: CrossAxisAlignment.center,
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(
  //                   arabic,
  //                   style: const TextStyle(fontSize: 18),
  //                   textDirection: TextDirection.rtl,
  //                 ),
  //                 Padding(
  //                   padding: const EdgeInsets.all(8.0),
  //                   child: Text(
  //                     transpilation,
  //                     style: const TextStyle(fontSize: 18),
  //                   ),
  //                 ),
  //                 Text(
  //                   english,
  //                   style: const TextStyle(fontSize: 18),
  //                 ),
  //                 TextButton(
  //                   onPressed: () {
  //                     setState(() {
  //                       // Choose a new random proverb
  //                       var newProverb = chooseRandomProverb(_dataCSV);
  //                       arabic = newProverb[0];
  //                       transpilation = newProverb[1];
  //                       english = newProverb[2];
  //                     });
  //                   },
  //                   child: const Text("Next"),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Future<void> _translateText(String inputText) async {
    _debounce?.cancel();
    setState(() {
      _isLoading = true;
    });

    // time for better feel, like google translate
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        String translatedText = await translate(inputText);
        setState(() {
          _outputController.text = translatedText;
        });
      } catch (e) {
        // Handle translation errors
        debugPrint(e.toString());
      } finally {
        setState(() {
          _isLoading = false; // Hide loading animation
        });
      }
    });
  }

  // void _loadProverbsCSV() async {
  //   try {
  //     // read from csv
  //     final String csvContent =
  //         await rootBundle.loadString("assets/proverbs.csv");
  //     List<List<dynamic>> rowsAsListOfValues =
  //         // custom eol instead of I think \r\n
  //         const CsvToListConverter(eol: "\n").convert(csvContent);
  //     setState(() {
  //       _dataCSV = rowsAsListOfValues;
  //     });
  //   } catch (e) {
  //     debugPrint("Error reading CSV file: $e");
  //   }
  // }

  Future<String> translate(String text) async {
    var translationRequest = TranslationRequest("auto", "ar", text);
    var encoded = jsonEncode(translationRequest.toJson());

    final response = await http.post(
      Uri.parse("https://deep-translator-api.azurewebsites.net/google/"),
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: encoded,
    );

    String utf8String = json.decode(response.body)['translation'];
    String parsed = utf8.decode(utf8String.codeUnits);

    if (response.statusCode == 200) {
      return parsed;
    } else {
      debugPrint('Failed with status: ${response.statusCode}');
      throw Exception('Failed to translate text');
      // Never
    }
  }
}

class TranslationRequest {
  final String source;
  final String target;
  final String text;
  final List proxies;

  TranslationRequest(this.source, this.target, this.text,
      {this.proxies = const []});

  Map<String, dynamic> toJson() => {
        'source': source,
        'target': target,
        'text': text,
        'proxies': proxies,
      };
}
