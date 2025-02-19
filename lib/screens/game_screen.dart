import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordblock/audio/audio_service.dart';
import 'package:wordblock/components/game_button.dart';
import 'package:wordblock/components/wordblock_card.dart';
import 'package:wordblock/l10n/gen_l10n/app_localizations.dart';
import 'package:wordblock/models/game_mode.dart';
import 'package:wordblock/models/game_settings.dart';
import 'package:wordblock/screens/victory_screen.dart';
import 'package:wordblock/services/wordblock_service.dart';
import 'package:wordblock/themes/theme.dart';

class WordBlockGameScreen extends StatefulWidget {
  final GameSettings settings;
  
  const WordBlockGameScreen({
    super.key,
    required this.settings,
  });

  @override
  State<WordBlockGameScreen> createState() => _WordBlockGameScreenState();
}

class _WordBlockGameScreenState extends State<WordBlockGameScreen> {
  final WordblockService _wordblockService = WordblockService();
  List<WordBlockCard> cards = [];
  int currentCardIndex = 0;
  late List<int> teamScores;
  int currentTeamIndex = 0;
  int _turnsPlayed = 0;

  Timer? _timer;
  late int _secondsLeft;
  late int _skipsLeft;
  bool _isPlaying = false;
  int _roundScore = 0;

  @override
  void initState() {
    super.initState();
    AudioService.instance.stopSoundtrack();
    _secondsLeft = widget.settings.timeLimit;
    _skipsLeft = widget.settings.skipsAllowed;
    teamScores = List.filled(widget.settings.teamNames.length, 0);
  }

  // Need this to load cards
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _loadCards();
  }

  Future<void> _loadCards() async {    
    final loadedCards = await _wordblockService.loadCards(context);
    setState(() {
      cards = loadedCards;
      cards.shuffle();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    setState(() {
      _isPlaying = true;
      _secondsLeft = widget.settings.timeLimit;
      _skipsLeft = widget.settings.skipsAllowed;
      _roundScore = 0;
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          setState(() {
            if (_secondsLeft > 0) {
              _secondsLeft--;
              if (_secondsLeft == 10) {
                AudioService.instance.play('low_on_time.mp3');  
              }

              if (_secondsLeft < 10) {
                HapticFeedback.heavyImpact();
              }
            } else {
              _endRound();
            }
          });
        },
      );
    });
  }

  void _endRound() {
    _timer?.cancel();
    _nextCard();
    setState(() {
      _isPlaying = false;
      teamScores[currentTeamIndex] += _roundScore;
      _turnsPlayed++;

      if (widget.settings.mode == GameMode.quick && _turnsPlayed >= widget.settings.numberOfTurns) {
        _showVictoryScreen();
      } else if (widget.settings.mode == GameMode.targeted && 
          teamScores[currentTeamIndex] >= widget.settings.maxPoints) {
        _showVictoryScreen();
      } else {
        currentTeamIndex = (currentTeamIndex + 1) % widget.settings.teamNames.length;
      }
    });
  }

  void _showVictoryScreen() {
    final winningTeamIndex = teamScores.indexOf(teamScores.reduce((a, b) => a > b ? a : b));
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VictoryScreen(
          winningTeam: widget.settings.teamNames[winningTeamIndex],
          winningScore: teamScores[winningTeamIndex],
          teamNames: widget.settings.teamNames,
          teamScores: teamScores,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return !_isPlaying ? _buildStartScreen() : _buildGameScreen();
  }

  Widget _buildGameScreen() {
    final currentCard = cards[currentCardIndex];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.backgroundGradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildScoreBoard(),
              const SizedBox(height: 16),
              _buildGameInfo(),
              const SizedBox(height: 24),
              Expanded(
                child: _buildCard(currentCard),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildTeamScore(
              widget.settings.teamNames[currentTeamIndex],
              teamScores[currentTeamIndex],
              true,
            ),
          ),
          const SizedBox(width: 10),
          _buildTimer(),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTeamScore(
              widget.settings.teamNames[(currentTeamIndex + 1) % widget.settings.teamNames.length],
              teamScores[(currentTeamIndex + 1) % widget.settings.teamNames.length],
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoCard(AppLocalizations.of(context).label_round_score,  _roundScore.toString()),
        _buildInfoCard(AppLocalizations.of(context).label_skips_left, _skipsLeft.toString()),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(WordBlockCard card) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 250,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).highlightColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadius * 2),
              ),
            ),
            child: Text(
              card.mainWord.toUpperCase(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 25,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: card.forbiddenWords.map((word) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    word.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).highlightColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GameButton(
            icon: Icons.skip_next,
            label: 'Skip',
            color: _skipsLeft > 0 ? Colors.orange : Colors.grey,
            onPressed: _skipsLeft > 0 ? () async {
              await AudioService.instance.play('skip_answer.mp3');
              setState(() {
                _skipsLeft--;
                _nextCard();
              });
            } : null,
          ),
          GameButton(
            icon: Icons.check_circle,
            label: 'Guessed',
            color: Colors.green,
            defaultSize: 72,
            onPressed: () async {
              await AudioService.instance.play('correct_answer.mp3');

              setState(() {
                _roundScore++;
                _nextCard();
              });
            },
          ),
          GameButton(
            icon: Icons.dangerous,
            color: Colors.red,
            label: 'Ta-boo',
            onPressed: () async {
              await AudioService.instance.play('blocked_answer.mp3');

              setState(() {
                _roundScore--;
                _nextCard();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final isLowTime = _secondsLeft <= 10;
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: isLowTime ? Colors.red : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Text(
        _secondsLeft.toString(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: 36,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.backgroundGradientColors,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).label_turn_of(widget.settings.teamNames[currentTeamIndex]),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 24),
              if (widget.settings.mode == GameMode.quick)
                Text(
                  AppLocalizations.of(context).label_turn_number(_turnsPlayed + 1, widget.settings.numberOfTurns),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                )
              else if (widget.settings.mode == GameMode.targeted)
                Text(
                  AppLocalizations.of(context).label_helper_targeted_mode(widget.settings.maxPoints),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context).label_current_scores,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        for (int i = 0; i < widget.settings.teamNames.length; i++) ...[
                          _buildTeamScoreCompact(
                            widget.settings.teamNames[i],
                            teamScores[i],
                          ),
                          if (i < widget.settings.teamNames.length - 1)
                            const Text(
                              'vs',
                              style: TextStyle(color: Colors.white, fontSize: 24),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _startRound,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: Text(
                  AppLocalizations.of(context).label_start_round,
                  style: Theme.of(context).textTheme.titleMedium
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamScore(String team, int score, bool isActive) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.25;

    return Container(
      width: containerWidth,
      constraints: const BoxConstraints(
        maxWidth: 120,
        minWidth: 80,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: isActive ? Border.all(color: Colors.white.withOpacity(0.2)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            team,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            score.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreCompact(String team, int score) {
    return Column(
      children: [
        Text(
          team,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
          ),
        ),
        Text(
          score.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 25,
          ),
        ),
      ],
    );
  }
  
  void _nextCard() {
    setState(() {
      currentCardIndex = (currentCardIndex + 1) % cards.length;
    });
  }
}