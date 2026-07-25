import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const NoteDepenseApp());
}

class NoteDepenseApp extends StatelessWidget {
  const NoteDepenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Expense Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class NoteDepense {
  final String id;
  final String titre;
  final double montant;
  final String categorie;
  final DateTime date;

  NoteDepense({
    required this.id,
    required this.titre,
    required this.montant,
    required this.categorie,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'montant': montant,
      'categorie': categorie,
      'date': date.toIso8601String(),
    };
  }

  factory NoteDepense.fromMap(Map<String, dynamic> map) {
    return NoteDepense(
      id: map['id'],
      titre: map['titre'],
      montant: (map['montant'] as num).toDouble(),
      categorie: map['categorie'],
      date: DateTime.parse(map['date']),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<NoteDepense> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerNotes();
  }

  // Stockage local persistent
  Future<void> _chargerNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString('user_notes_depenses');
    if (notesJson != null) {
      final List<dynamic> decoded = jsonDecode(notesJson);
      setState(() {
        _notes = decoded.map((item) => NoteDepense.fromMap(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sauvegarderNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_notes.map((n) => n.toMap()).toList());
    await prefs.setString('user_notes_depenses', encoded);
  }

  void _ajouterNote(String titre, double montant, String categorie) {
    final nouvelleNote = NoteDepense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titre: titre,
      montant: montant,
      categorie: categorie,
      date: DateTime.now(),
    );

    setState(() {
      _notes.insert(0, nouvelleNote);
    });
    _sauvegarderNotes();
  }

  void _supprimerNote(String id) {
    setState(() {
      _notes.removeWhere((item) => item.id == id);
    });
    _sauvegarderNotes();
  }

  double get _totalDepenses => _notes.fold(0, (sum, item) => sum + item.montant);

  void _ouvrirFormulaire() {
    final titreController = TextEditingController();
    final montantController = TextEditingController();
    String categorieChoisie = 'Courses';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nouvelle Note / Dépense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: titreController,
              decoration: const InputDecoration(
                labelText: 'Titre ou description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: montantController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant (€)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: categorieChoisie,
              items: ['Courses', 'Loisirs', 'Abonnements', 'Transport', 'Autre']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => categorieChoisie = val!,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                final titre = titreController.text.trim();
                final montant = double.tryParse(montantController.text.replaceAll(',', '.')) ?? 0.0;
                if (titre.isNotEmpty && montant > 0) {
                  _ajouterNote(titre, montant, categorieChoisie);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Dépenses'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total accumulé',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_totalDepenses.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _notes.isEmpty
                      ? const Center(child: Text('Aucune note enregistrée'))
                      : ListView.builder(
                          itemCount: _notes.length,
                          itemBuilder: (ctx, index) {
                            final note = _notes[index];
                            return Dismissible(
                              key: Key(note.id),
                              background: Container(
                                color: Colors.red.shade900,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _supprimerNote(note.id),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(note.categorie[0]),
                                ),
                                title: Text(note.titre),
                                subtitle: Text(
                                  '${note.date.day}/${note.date.month} • ${note.categorie}',
                                ),
                                trailing: Text(
                                  '-${note.montant.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ouvrirFormulaire,
        child: const Icon(Icons.add),
      ),
    );
  }
}