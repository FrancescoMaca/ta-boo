import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get button_play => 'Play!';

  @override
  String get title_setup_game => 'Game Setup';

  @override
  String get title_teams => 'Teams';

  @override
  String get title_modes => 'Modes';

  @override
  String get title_settings => 'Settings';

  @override
  String get swipe => 'SWIPE';

  @override
  String get down => 'DOWN';

  @override
  String get to => 'TO';

  @override
  String get start => 'START';

  @override
  String get title_have_fun => 'Have fun';

  @override
  String get label_swipe_down => 'swipe down';

  @override
  String label_round_time(int time) {
    return 'Round Time: $time seconds';
  }

  @override
  String label_skips_allowed(int amount) {
    return 'Skips Allowed: $amount';
  }

  @override
  String label_points_needed(int points) {
    return 'Points needed: $points';
  }

  @override
  String label_number_of_turns(int turns) {
    return 'Number of turns: $turns';
  }

  @override
  String get label_add_team => 'Add Team';

  @override
  String get label_remove_team => 'Remove Team';

  @override
  String error_team_name(int teamNumber) {
    return 'Please enter team $teamNumber name';
  }

  @override
  String get mode_targeted => 'Targeted';

  @override
  String get mode_qne => 'Quick \'n Easy';

  @override
  String get mode_endless => 'Endless';
}
