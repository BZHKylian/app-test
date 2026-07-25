import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const BitLifeLiteApp());
}

class BitLifeLiteApp extends StatelessWidget {
  const BitLifeLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life Simulator Deluxe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LifeGameScreen(),
    );
  }
}

/* ========================================================================= */
/* MODÈLES DE DONNÉES (Métiers, Possessions, Événements)                      */
/* ========================================================================= */

class Metier {
  final String nom;
  final int salaire;
  final int reqIntelligence;
  final int reqAge;
  final String diplomeRequis;

  Metier({
    required this.nom,
    required this.salaire,
    required this.reqIntelligence,
    required this.reqAge,
    this.diplomeRequis = "Aucun",
  });
}

class Possession {
  final String id;
  final String nom;
  final int prix;
  final int entretienAnnuel;
  final int bonusBonheur;
  final String icone;

  Possession({
    required this.id,
    required this.nom,
    required this.prix,
    required this.entretienAnnuel,
    required this.bonusBonheur,
    required this.icone,
  });
}

class EvenementVie {
  final String texte;
  final int deltaSante;
  final int deltaBonheur;
  final int deltaIntel;
  final int deltaArgent;
  final int minAge;
  final int maxAge;

  EvenementVie({
    required this.texte,
    this.deltaSante = 0,
    this.deltaBonheur = 0,
    this.deltaIntel = 0,
    this.deltaArgent = 0,
    this.minAge = 0,
    this.maxAge = 120,
  });
}

/* ========================================================================= */
/* ÉCRAN PRINCIPAL DU JEU                                                    */
/* ========================================================================= */

class LifeGameScreen extends StatefulWidget {
  const LifeGameScreen({super.key});

  @override
  State<LifeGameScreen> createState() => _LifeGameScreenState();
}

class _LifeGameScreenState extends State<LifeGameScreen> {
  final Random _rand = Random();

  // Stats Personnage
  String _nom = "Kylian";
  int _age = 0;
  int _sante = 100;
  int _bonheur = 100;
  int _intelligence = 50;
  int _argent = 0;
  String _diplome = "Aucun";

  // Emploi actuel
  Metier? _jobActuel;

  // Inventaire de possessions
  final List<Possession> _mesPossessions = [];

  // État de vie
  bool _estVivant = true;

  // Journal d'événements
  final List<String> _journal = [];

  /* ----------------------------------------------------------------------- */
  /* BANQUE DE DONNÉES DU JEU (Facilement extensible)                        */
  /* ----------------------------------------------------------------------- */

  final List<Metier> _offresMetiers = [
    Metier(nom: "Livreur à vélo", salaire: 14000, reqIntelligence: 10, reqAge: 16),
    Metier(nom: "Caissier en supermarché", salaire: 19000, reqIntelligence: 20, reqAge: 18),
    Metier(nom: "Serveur en restaurant", salaire: 21000, reqIntelligence: 25, reqAge: 18),
    Metier(nom: "Technicien Informatique", salaire: 32000, reqIntelligence: 55, reqAge: 20, diplomeRequis: "Bac+2"),
    Metier(nom: "Développeur Fullstack", salaire: 45000, reqIntelligence: 70, reqAge: 21, diplomeRequis: "Bac+3"),
    Metier(nom: "Ingénieur en Cybersécurité", salaire: 62000, reqIntelligence: 85, reqAge: 23, diplomeRequis: "Master"),
    Metier(nom: "Médecin Généraliste", salaire: 85000, reqIntelligence: 90, reqAge: 26, diplomeRequis: "Doctorat"),
    Metier(nom: "Pilote de Chasse", salaire: 75000, reqIntelligence: 80, reqAge: 22, diplomeRequis: "Bac+5"),
  ];

  final List<Possession> _boutique = [
    Possession(id: "trottinette", nom: "Trottinette Électrique", prix: 400, entretienAnnuel: 30, bonusBonheur: 5, icone: "🛴"),
    Possession(id: "clio", nom: "Voiture d'occasion", prix: 3500, entretienAnnuel: 600, bonusBonheur: 15, icone: "🚗"),
    Possession(id: "sportscar", nom: "Voiture de Sport", prix: 65000, entretienAnnuel: 4000, bonusBonheur: 35, icone: "🏎️"),
    Possession(id: "studio", nom: "Studio en ville", prix: 110000, entretienAnnuel: 1200, bonusBonheur: 25, icone: "🏢"),
    Possession(id: "villa", nom: "Maison d'architecte", prix: 450000, entretienAnnuel: 5000, bonusBonheur: 50, icone: "🏡"),
  ];

  final List<EvenementVie> _evenementsAleatoires = [
    EvenementVie(texte: "Vous avez trouvé un billet de 50€ mouillé sur le trottoir !", deltaArgent: 50, deltaBonheur: 5),
    EvenementVie(texte: "Vous avez attrapé une grosse grippe hivernale.", deltaSante: -15, deltaBonheur: -10),
    EvenementVie(texte: "Vous avez regardé un documentaire passionnant sur la conquête spatiale.", deltaIntel: 5),
    EvenementVie(texte: "Vous vous êtes disputé avec un voisin à cause du bruit.", deltaBonheur: -10),
    EvenementVie(texte: "Un ami vous a invité à un concert mémorable !", deltaBonheur: 20, deltaArgent: -60),
    EvenementVie(texte: "Votre disque dur a lâché... vous avez perdu des projets persos.", deltaBonheur: -15),
    EvenementVie(texte: "Vous avez gagné un petit lot au tirage à gratter local !", deltaArgent: 250, deltaBonheur: 15),
    EvenementVie(texte: "Vous avez trébuché dans les escaliers... entorse à la cheville.", deltaSante: -10),
    EvenementVie(texte: "Vous avez lu un livre entier sur le développement personnel.", deltaIntel: 8, deltaBonheur: 5),
    EvenementVie(texte: "Une amende pour mauvais stationnement arrive par la poste.", deltaArgent: -35, deltaBonheur: -5),
    EvenementVie(texte: "Vous avez adopté un chaton errant !", deltaBonheur: 25, deltaArgent: -150),
    EvenementVie(texte: "Intoxication alimentaire après avoir mangé un kebab suspect.", deltaSante: -20, deltaBonheur: -10),
  ];

  /* ----------------------------------------------------------------------- */
  /* MOTEUR DU JEU                                                           */
  /* ----------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();
    _recommencerVie();
  }

  void _ajouterJournal(String msg) {
    setState(() {
      _journal.insert(0, "Âge $_age ans : $msg");
    });
  }

  void _vieillirUnAn() {
    if (!_estVivant) return;

    setState(() {
      _age++;

      // 1. Revenus & Entretien
      if (_jobActuel != null) {
        _argent += _jobActuel!.salaire;
      }

      int totalEntretien = 0;
      for (var p in _mesPossessions) {
        totalEntretien += p.entretienAnnuel;
      }
      _argent -= totalEntretien;

      // 2. Scolarité & Diplômes automatiques
      if (_age == 6) _ajouterJournal("🏫 Entrée à l'école primaire.");
      if (_age == 11) _ajouterJournal("🎒 Passage au collège.");
      if (_age == 15) _ajouterJournal("🏫 Entrée au lycée.");
      if (_age == 18) {
        _diplome = "Baccalauréat";
        _ajouterJournal("🎓 Vous obtenez votre Baccalauréat !");
      }

      // 3. Événement aléatoire de l'année
      _tirerEvenementAleatoire();

      // 4. Impact des possessions sur le bonheur
      for (var p in _mesPossessions) {
        _bonheur = (_bonheur + (p.bonusBonheur ~/ 5)).clamp(0, 100);
      }

      // 5. Test de santé & Vieillesse
      if (_sante <= 0) {
        _sante = 0;
        _estVivant = false;
        _ajouterJournal("💀 Vous êtes mort des suites de vos problèmes de santé.");
      } else if (_age >= 75) {
        int chanceMort = (_age - 70) * 4;
        if (_rand.nextInt(100) < chanceMort) {
          _estVivant = false;
          _ajouterJournal("🪦 Vous êtes décédé paisiblement de vieillesse.");
        }
      }
    });
  }

  void _tirerEvenementAleatoire() {
    final eligibles = _evenementsAleatoires.where((e) => _age >= e.minAge && _age <= e.maxAge).toList();
    if (eligibles.isEmpty) return;

    final ev = eligibles[_rand.nextInt(eligibles.length)];
    _sante = (_sante + ev.deltaSante).clamp(0, 100);
    _bonheur = (_bonheur + ev.deltaBonheur).clamp(0, 100);
    _intelligence = (_intelligence + ev.deltaIntel).clamp(0, 100);
    _argent += ev.deltaArgent;

    _ajouterJournal(ev.texte);
  }

  /* ----------------------------------------------------------------------- */
  /* ACTIONS DU JOUEUR                                                       */
  /* ----------------------------------------------------------------------- */

  void _faireSport() {
    if (!_estVivant) return;
    setState(() {
      _sante = (_sante + 8).clamp(0, 100);
      _bonheur = (_bonheur + 4).clamp(0, 100);
      _ajouterJournal("🏋️ Séance de sport intensive (+8 Santé, +4 Bonheur).");
    });
  }

  void _etudierPoursuite() {
    if (!_estVivant) return;
    setState(() {
      _intelligence = (_intelligence + 6).clamp(0, 100);
      _ajouterJournal("📖 Session d'étude approfondie à la bibliothèque (+6 Intel).");
    });
  }

  void _poursuivreEtudesSuperieures(String diplomeVise, int anneesReq) {
    if (_age < 18) return;
    if (_intelligence < 60) {
      _ajouterJournal("❌ Vos résultats sont trop faibles pour intégrer ce cursus.");
      return;
    }

    setState(() {
      _diplome = diplomeVise;
      _ajouterJournal("🎓 Diplôme obtenu : $diplomeVise !");
    });
  }

  void _postulerMetier(Metier job) {
    if (_age < job.reqAge) {
      _ajouterJournal("❌ Vous êtes trop jeune pour être ${job.nom}.");
      return;
    }
    if (_intelligence < job.reqIntelligence) {
      _ajouterJournal("❌ Vous avez échoué à l'entretien de ${job.nom} (Intelligence insuffisante).");
      return;
    }

    setState(() {
      _jobActuel = job;
      _ajouterJournal("🎉 Félicitations ! Vous êtes embauché comme ${job.nom} (${job.salaire}€/an).");
    });
  }

  void _acheterBien(Possession bien) {
    if (_argent < bien.prix) {
      _ajouterJournal("💸 Vous n'avez pas assez d'argent pour acheter : ${bien.nom}.");
      return;
    }

    setState(() {
      _argent -= bien.prix;
      _mesPossessions.add(bien);
      _bonheur = (_bonheur + bien.bonusBonheur).clamp(0, 100);
      _ajouterJournal("Achat effectué : ${bien.icone} ${bien.nom} !");
    });
  }

  void _recommencerVie() {
    setState(() {
      _age = 0;
      _sante = 100;
      _bonheur = 100;
      _intelligence = 40 + _rand.nextInt(30);
      _argent = 0;
      _diplome = "Aucun";
      _jobActuel = null;
      _mesPossessions.clear();
      _estVivant = true;
      _journal.clear();
      _journal.add("👶 Vous êtes né ! Une nouvelle histoire commence.");
    });
  }

  /* ----------------------------------------------------------------------- */
  /* DIALOGUES & INTERFACES SECONDAIRES                                      */
  /* ----------------------------------------------------------------------- */

  void _ouvrirMenuEmplois() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _offresMetiers.length,
        itemBuilder: (ctx, i) {
          final job = _offresMetiers[i];
          return ListTile(
            title: Text(job.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Salaire: ${job.salaire}€/an | Req: Intel ${job.reqIntelligence}% | Age ${job.reqAge}+"),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _postulerMetier(job);
              },
              child: const Text("Postuler"),
            ),
          );
        },
      ),
    );
  }

  void _ouvrirMenuBoutique() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _boutique.length,
        itemBuilder: (ctx, i) {
          final item = _boutique[i];
          return ListTile(
            leading: Text(item.icone, style: const TextStyle(fontSize: 28)),
            title: Text(item.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Prix: ${item.prix}€ | Entretien: ${item.entretienAnnuel}€/an"),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _acheterBien(item);
              },
              child: const Text("Acheter"),
            ),
          );
        },
      ),
    );
  }

  /* ----------------------------------------------------------------------- */
  /* RENDU VISUEL                                                            */
  /* ----------------------------------------------------------------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_nom ($_age ans)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _recommencerVie,
            tooltip: "Recommencer une vie",
          )
        ],
      ),
      body: Column(
        children: [
          // En-tête : Informations Financières et Professionnelles
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black38,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("💼 ${_jobActuel?.nom ?? 'Sans emploi'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text("💰 $_argent €", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("🎓 Diplôme : $_diplome", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ),
                const Divider(height: 20),
                _buildStatBar("❤️ Santé", _sante, Colors.redAccent),
                _buildStatBar("😊 Bonheur", _bonheur, Colors.amberAccent),
                _buildStatBar("🧠 Intelligence", _intelligence, Colors.lightBlueAccent),
              ],
            ),
          ),

          // Contenu Central : Journal de bord
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _journal.length,
              itemBuilder: (ctx, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      _journal[index],
                      style: TextStyle(
                        fontSize: 13,
                        color: index == 0 ? Colors.purpleAccent : Colors.white70,
                        fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Barre d'actions inférieure
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black54,
            child: _estVivant
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _faireSport,
                              icon: const Icon(Icons.fitness_center, size: 18),
                              label: const Text('Sport'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _etudierPoursuite,
                              icon: const Icon(Icons.school, size: 18),
                              label: const Text('Étudier'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _ouvrirMenuEmplois,
                              icon: const Icon(Icons.work, size: 18),
                              label: const Text('Emplois'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _ouvrirMenuBoutique,
                              icon: const Icon(Icons.shopping_cart, size: 18),
                              label: const Text('Achat'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _vieillirUnAn,
                          child: const Text(
                            '⏩ VIEILLIR (+1 AN)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Text(
                        "💀 VOUS ÊTES DÉCÉDÉ",
                        style: TextStyle(fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _recommencerVie,
                        child: const Text('Recommencer une nouvelle vie'),
                      )
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                color: color,
                backgroundColor: Colors.white12,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text("$value%", style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}