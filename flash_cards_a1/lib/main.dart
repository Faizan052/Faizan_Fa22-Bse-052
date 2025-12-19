import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  home: HomeScreen(),
));

class Flashcard {
  final String question;
  final String answer;

  const Flashcard({required this.question, required this.answer});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> decks = [
    {
      'deckName': 'General Knowledge',
      'flashcards': [
        Flashcard(question: "What is the capital of France?", answer: "Paris"),
        Flashcard(question: "What is 2 + 2?", answer: "4"),
        Flashcard(question: "What is the largest planet?", answer: "Jupiter"),
        Flashcard(question: "Who wrote 'Romeo and Juliet'?", answer: "Shakespeare"),
      ],
    },
    {
      'deckName': 'Science',
      'flashcards': [
        Flashcard(question: "What is the chemical symbol for water?", answer: "H2O"),
        Flashcard(question: "What is the speed of light?", answer: "299,792 km/s"),
      ],
    },
  ];

  void _addNewDeck(String deckName, List<Flashcard> flashcards) {
    setState(() {
      decks.add({
        'deckName': deckName,
        'flashcards': flashcards,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Decks', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...decks.map((deck) => _buildDeckTile(context, deck['deckName'], Icons.folder, deck['flashcards'])).toList(),
            ListTile(
              title: const Text('Add New Deck', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
              leading: const Icon(Icons.add, color: Colors.white),
              tileColor: Colors.deepPurple.withOpacity(0.7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateDeckScreen(),
                  ),
                );
                if (result != null) {
                  _addNewDeck(result['deckName'], result['flashcards']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckTile(BuildContext context, String deckName, IconData icon, List<Flashcard> flashcards) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(deckName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        leading: Icon(icon, color: Colors.deepPurple),
        tileColor: Colors.white.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlashcardScreen(
                deckName: deckName,
                flashcards: flashcards,
              ),
            ),
          );
        },
      ),
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  final String deckName;
  final List<Flashcard> flashcards;

  const FlashcardScreen({Key? key, required this.deckName, required this.flashcards}) : super(key: key);

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  int score = 0;
  bool showAnswer = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _updateScore(bool isCorrect) {
    setState(() {
      if (isCorrect) score++;
      if (currentIndex < widget.flashcards.length - 1) {
        currentIndex++;
        showAnswer = false;
        _controller.reset();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('End of Deck', style: TextStyle(fontFamily: 'Poppins')),
            content: Text('Your final score is $score/${widget.flashcards.length}',
                style: const TextStyle(fontFamily: 'Poppins')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK', style: TextStyle(fontFamily: 'Poppins')),
              ),
            ],
          ),
        );
      }
    });
  }

  void _flipCard() {
    if (_controller.isAnimating) return;
    if (showAnswer) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => showAnswer = !showAnswer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final isFront = _animation.value < 0.5;
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_animation.value * 3.14159),
                        alignment: Alignment.center,
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            width: 300,
                            height: 200,
                            padding: const EdgeInsets.all(16),
                            child: isFront
                                ? _buildText(widget.flashcards[currentIndex].question)
                                : Transform(
                              transform: Matrix4.identity()..rotateY(3.14159),
                              alignment: Alignment.center,
                              child: _buildText(widget.flashcards[currentIndex].answer),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _updateScore(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Correct', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () => _updateScore(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Incorrect', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Score: $score/${widget.flashcards.length}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Container(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: text.length > 50 ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({Key? key}) : super(key: key);

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deckNameController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final List<Flashcard> newFlashcards = [];

  void _addFlashcard() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        newFlashcards.add(
          Flashcard(
            question: _questionController.text,
            answer: _answerController.text,
          ),
        );
        _questionController.clear();
        _answerController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Deck', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade300, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _deckNameController,
                  decoration: InputDecoration(
                    labelText: 'Deck Name',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a deck name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    labelText: 'Question',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Answer',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an answer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addFlashcard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Add Flashcard', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: newFlashcards.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(newFlashcards[index].question, style: const TextStyle(fontFamily: 'Poppins')),
                          subtitle: Text(newFlashcards[index].answer, style: const TextStyle(fontFamily: 'Poppins')),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_deckNameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a deck name')),
                      );
                      return;
                    }
                    if (newFlashcards.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please add at least one flashcard')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'deckName': _deckNameController.text,
                      'flashcards': newFlashcards,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Deck', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}