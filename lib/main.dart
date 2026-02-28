import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

// ═══════════════════════════════════════════════════════
//  FIX: Added async + WidgetsFlutterBinding.ensureInitialized()
//  so SharedPreferences is ready before the app starts.
// ═══════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MindTrackApp());
}

// ═══════════════════════════════════════════════════════
//  ROOT APP
// ═══════════════════════════════════════════════════════
class MindTrackApp extends StatelessWidget {
  const MindTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C63FF),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      ),
      home: const HomeScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  DAILY MOTIVATIONAL QUOTES
// ═══════════════════════════════════════════════════════
const List<String> kQuotes = [
  '"The secret of getting ahead is getting started." – Mark Twain',
  '"It always seems impossible until it\'s done." – Nelson Mandela',
  '"Don\'t watch the clock; do what it does. Keep going." – Sam Levenson',
  '"Success is the sum of small efforts repeated day in and day out." – R. Collier',
  '"Believe you can and you\'re halfway there." – Theodore Roosevelt',
  '"You don\'t have to be great to start, but you have to start to be great." – Zig Ziglar',
  '"The harder you work for something, the greater you\'ll feel when you achieve it."',
  '"Dream big. Start small. Act now."',
  '"Push yourself, because no one else is going to do it for you."',
  '"Great things never come from comfort zones."',
  '"Study hard, for the well is deep and our brains are shallow." – Richard Baxter',
  '"An investment in knowledge pays the best interest." – Benjamin Franklin',
  '"The beautiful thing about learning is nobody can take it away from you." – B.B. King',
  '"Education is the most powerful weapon you can use to change the world." – Nelson Mandela',
  '"Strive for progress, not perfection."',
  '"You are capable of more than you know." – E.O. Wilson',
  '"Focus on being productive instead of busy." – Tim Ferriss',
  '"Small daily improvements over time lead to stunning results."',
  '"Your future is created by what you do today, not tomorrow."',
  '"Work hard in silence, let success make the noise."',
];

String getTodayQuote() {
  final day = DateTime.now().day + DateTime.now().month;
  return kQuotes[day % kQuotes.length];
}

// ═══════════════════════════════════════════════════════
//  BADGE DEFINITIONS
// ═══════════════════════════════════════════════════════
class Badge {
  final String id;
  final String emoji;
  final String title;
  final String description;
  const Badge({required this.id, required this.emoji, required this.title, required this.description});
}

const List<Badge> kBadges = [
  Badge(id: 'first_entry',  emoji: '🌱', title: 'First Step',    description: 'Log your first entry'),
  Badge(id: 'three_days',   emoji: '🔥', title: 'On Fire',       description: 'Log 3 entries'),
  Badge(id: 'seven_days',   emoji: '⭐', title: 'Week Warrior',  description: 'Log 7 entries'),
  Badge(id: 'twenty_days',  emoji: '🏆', title: 'Champion',      description: 'Log 20 entries'),
  Badge(id: 'ten_hours',    emoji: '📚', title: 'Bookworm',      description: 'Study 10 total hours'),
  Badge(id: 'fifty_hours',  emoji: '🎓', title: 'Scholar',       description: 'Study 50 total hours'),
  Badge(id: 'happy_streak', emoji: '😊', title: 'Good Vibes',    description: 'Log Happy mood 5 times'),
  Badge(id: 'goal_crusher', emoji: '🎯', title: 'Goal Crusher',  description: 'Meet daily goal 3 times'),
  Badge(id: 'night_owl',    emoji: '🦉', title: 'Night Owl',     description: 'Log an entry after 9 PM'),
  Badge(id: 'early_bird',   emoji: '🌅', title: 'Early Bird',    description: 'Log an entry before 7 AM'),
];

Set<String> computeEarnedBadges(List<MoodEntry> entries, double goal) {
  final earned = <String>{};
  if (entries.isEmpty) return earned;
  final total = entries.length;
  final totalHours = entries.fold<double>(0, (s, e) => s + e.studyHours);
  final happyCount = entries.where((e) => e.mood == 'Happy').length;
  final Map<String, double> dayHours = {};
  for (final e in entries) {
    final key = '${e.date.year}-${e.date.month}-${e.date.day}';
    dayHours[key] = (dayHours[key] ?? 0) + e.studyHours;
  }
  final goalMetDays = dayHours.values.where((h) => h >= goal).length;
  if (total >= 1)        earned.add('first_entry');
  if (total >= 3)        earned.add('three_days');
  if (total >= 7)        earned.add('seven_days');
  if (total >= 20)       earned.add('twenty_days');
  if (totalHours >= 10)  earned.add('ten_hours');
  if (totalHours >= 50)  earned.add('fifty_hours');
  if (happyCount >= 5)   earned.add('happy_streak');
  if (goalMetDays >= 3)  earned.add('goal_crusher');
  if (entries.any((e) => e.date.hour >= 21)) earned.add('night_owl');
  if (entries.any((e) => e.date.hour < 7))   earned.add('early_bird');
  return earned;
}

// ═══════════════════════════════════════════════════════
//  DATA MODEL
// ═══════════════════════════════════════════════════════
class MoodEntry {
  final String id;
  final String mood;
  final double studyHours;
  final DateTime date;
  final String note;

  MoodEntry({required this.id, required this.mood, required this.studyHours, required this.date, this.note = ''});

  MoodEntry copyWith({String? mood, double? studyHours, String? note}) =>
      MoodEntry(id: id, mood: mood ?? this.mood, studyHours: studyHours ?? this.studyHours, date: date, note: note ?? this.note);

  Map<String, dynamic> toMap() => {'id': id, 'mood': mood, 'studyHours': studyHours, 'date': date.toIso8601String(), 'note': note};

  factory MoodEntry.fromMap(Map<String, dynamic> map) => MoodEntry(
        id: map['id'] ?? map['date'],
        mood: map['mood'],
        studyHours: (map['studyHours'] as num).toDouble(),
        date: DateTime.parse(map['date']),
        note: map['note'] ?? '',
      );
}

// ═══════════════════════════════════════════════════════
//  STORAGE HELPER
//  FIX: Replaced all getInstance() calls with a single
//  cached instance to avoid race conditions on some devices.
// ═══════════════════════════════════════════════════════
class StorageHelper {
  static const _entriesKey = 'mood_entries';
  static const _goalKey    = 'daily_goal';

  // Cache the prefs instance so every call reuses the same object
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<List<MoodEntry>> loadEntries() async {
    final prefs = await _instance;
    final raw   = prefs.getStringList(_entriesKey) ?? [];
    return raw
        .map((e) => MoodEntry.fromMap(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveEntry(MoodEntry entry) async {
    final prefs = await _instance;
    final raw   = prefs.getStringList(_entriesKey) ?? [];
    raw.add(jsonEncode(entry.toMap()));
    await prefs.setStringList(_entriesKey, raw);
  }

  static Future<void> updateEntry(MoodEntry updated) async {
    final prefs  = await _instance;
    final raw    = prefs.getStringList(_entriesKey) ?? [];
    final newRaw = raw.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] == updated.id ? jsonEncode(updated.toMap()) : e;
    }).toList();
    await prefs.setStringList(_entriesKey, newRaw);
  }

  static Future<void> deleteEntry(String id) async {
    final prefs = await _instance;
    final raw   = prefs.getStringList(_entriesKey) ?? [];
    raw.removeWhere((e) => (jsonDecode(e) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_entriesKey, raw);
  }

  static Future<void> saveGoal(double hours) async {
    final prefs = await _instance;
    await prefs.setDouble(_goalKey, hours);
  }

  static Future<double> loadGoal() async {
    final prefs = await _instance;
    return prefs.getDouble(_goalKey) ?? 6.0;
  }

  static Future<void> clearAll() async {
    final prefs = await _instance;
    await prefs.remove(_entriesKey);
    await prefs.remove(_goalKey);
    // Reset cache so next load is clean
    _prefs = null;
  }
}

// ═══════════════════════════════════════════════════════
//  SMART SUGGESTION
// ═══════════════════════════════════════════════════════
String getSuggestion(String mood, double hours, double goal) {
  final pct = goal > 0 ? hours / goal : 0;
  if (mood == 'Happy' && pct >= 1.0)            return '🔥 Goal crushed with great energy — you\'re unstoppable!';
  if (mood == 'Happy' && hours < 3)             return '😊 Great mood! Channel that positivity into a longer session.';
  if (mood == 'Neutral' && hours >= goal * 0.8) return '📚 Solid effort! Consistency beats perfection every time.';
  if (mood == 'Neutral' && hours < 4)           return '💡 Feeling meh? Try the Pomodoro technique to get started.';
  if (mood == 'Sad' && hours >= 4)              return '💪 Impressive dedication on a tough day. Remember to rest!';
  if (mood == 'Sad')                            return '🌱 It\'s okay to have off days. Be kind to yourself today.';
  return '✨ Keep going — every hour counts toward your goal!';
}

// ═══════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  String _selectedMood = 'Happy';
  final _hoursController = TextEditingController();
  final _noteController  = TextEditingController();
  final _goalController  = TextEditingController();
  List<MoodEntry> _entries = [];
  String? _suggestion;
  double _dailyGoal = 6.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final entries = await StorageHelper.loadEntries();
    final goal    = await StorageHelper.loadGoal();
    if (!mounted) return;
    setState(() {
      _entries   = entries;
      _dailyGoal = goal;
      _goalController.text = goal.toString();
    });
  }

  double get _todayHours {
    final t = DateTime.now();
    return _entries
        .where((e) => e.date.year == t.year && e.date.month == t.month && e.date.day == t.day)
        .fold(0.0, (s, e) => s + e.studyHours);
  }

  Future<void> _saveEntry() async {
    final hours = double.tryParse(_hoursController.text.trim());
    if (hours == null || hours < 0 || hours > 24) {
      _showSnack('Please enter valid study hours (0–24).');
      return;
    }
    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mood: _selectedMood,
      studyHours: hours,
      date: DateTime.now(),
      note: _noteController.text.trim(),
    );
    await StorageHelper.saveEntry(entry);
    await _loadData();
    final earned = computeEarnedBadges(_entries, _dailyGoal);
    final badge  = kBadges.where((b) => earned.contains(b.id)).lastOrNull;
    if (badge != null && mounted) _showBadgeToast(badge);
    if (!mounted) return;
    setState(() {
      _suggestion = getSuggestion(_selectedMood, hours, _dailyGoal);
      _hoursController.clear();
      _noteController.clear();
    });
  }

  Future<void> _saveGoal() async {
    final goal = double.tryParse(_goalController.text.trim());
    if (goal == null || goal <= 0 || goal > 24) {
      _showSnack('Please enter a valid goal (1–24 hours).');
      return;
    }
    await StorageHelper.saveGoal(goal);
    if (!mounted) return;
    setState(() => _dailyGoal = goal);
    _showSnack('✅ Daily goal updated to ${goal}h!');
  }

  void _showBadgeToast(Badge badge) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF6C63FF),
      duration: const Duration(seconds: 3),
      content: Row(children: [
        Text(badge.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Badge Unlocked!', style: TextStyle(color: Colors.white70, fontSize: 11)),
          Text(badge.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ]),
    ));
  }

  void _showEditDialog(MoodEntry entry) {
    String editMood       = entry.mood;
    final editHours       = TextEditingController(text: entry.studyHours.toString());
    final editNote        = TextEditingController(text: entry.note);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        title: const Text('Edit Entry'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mood', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: ['Happy', 'Neutral', 'Sad'].map((m) {
            const icons = {'Happy': '😊', 'Neutral': '😐', 'Sad': '😔'};
            final sel = editMood == m;
            return Expanded(child: GestureDetector(
              onTap: () => setS(() => editMood = m),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.grey.shade100,
                  border: Border.all(color: sel ? const Color(0xFF6C63FF) : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Text(icons[m]!, style: const TextStyle(fontSize: 22)),
                  Text(m, style: TextStyle(fontSize: 11, color: sel ? const Color(0xFF6C63FF) : Colors.grey)),
                ]),
              ),
            ));
          }).toList()),
          const SizedBox(height: 16),
          const Text('Study Hours', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: editHours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. 3.5', filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          const Text('Journal Note', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: editNote, maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any reflections...', filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
            onPressed: () async {
              final h = double.tryParse(editHours.text.trim());
              if (h == null || h < 0 || h > 24) { _showSnack('Invalid hours.'); return; }
              await StorageHelper.updateEntry(entry.copyWith(mood: editMood, studyHours: h, note: editNote.text.trim()));
              await _loadData();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      )),
    );
  }

  void _confirmDelete(MoodEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This entry will be permanently removed.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7B7B), foregroundColor: Colors.white),
            onPressed: () async {
              await StorageHelper.deleteEntry(entry.id);
              await _loadData();
              if (ctx.mounted) Navigator.pop(ctx);
              _showSnack('Entry deleted.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _hoursController.dispose();
    _noteController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Icon(Icons.psychology_alt, size: 28),
          SizedBox(width: 8),
          Text('MindTrack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all data',
            onPressed: () async {
              await StorageHelper.clearAll();
              await _loadData();
              if (!mounted) return;
              setState(() => _suggestion = null);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [_buildLogTab(), _buildAnalyticsTab(), _buildAchievementsTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() { _tabIndex = i; _suggestion = null; }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit_note),    label: 'Log Today'),
          NavigationDestination(icon: Icon(Icons.bar_chart),    label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Achievements'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB 1 — LOG TODAY
  // ═══════════════════════════════════════════════════
  Widget _buildLogTab() {
    final todayHours = _todayHours;
    final progress   = (_dailyGoal > 0 ? (todayHours / _dailyGoal).clamp(0.0, 1.0) : 0.0).toDouble();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _headerCard(),
        const SizedBox(height: 16),
        _quoteCard(),
        const SizedBox(height: 16),
        _goalProgressCard(todayHours, progress),
        const SizedBox(height: 24),
        _sectionLabel('How are you feeling today?'),
        const SizedBox(height: 12),
        _moodSelector(),
        const SizedBox(height: 24),
        _sectionLabel('Study hours today'),
        const SizedBox(height: 12),
        TextField(
          controller: _hoursController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'e.g. 3.5',
            prefixIcon: const Icon(Icons.timer_outlined),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Journal note (optional)'),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController, maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What did you study? Any reflections...',
            prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.notes_outlined)),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _saveEntry,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
        if (_suggestion != null) ...[const SizedBox(height: 20), _suggestionCard(_suggestion!)],
        if (_entries.isNotEmpty) ...[
          const SizedBox(height: 28),
          _sectionLabel('Recent Entries'),
          const SizedBox(height: 12),
          ..._entries.take(10).map(_entryTile),
        ],
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB 2 — ANALYTICS
  // ═══════════════════════════════════════════════════
  Widget _buildAnalyticsTab() {
    if (_entries.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No data yet — log your first entry!', style: TextStyle(color: Colors.grey, fontSize: 16)),
      ]));
    }
    final totalHours = _entries.fold<double>(0, (s, e) => s + e.studyHours);
    final happy      = _entries.where((e) => e.mood == 'Happy').length.toDouble();
    final neutral    = _entries.where((e) => e.mood == 'Neutral').length.toDouble();
    final sad        = _entries.where((e) => e.mood == 'Sad').length.toDouble();
    final avg        = totalHours / _entries.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _goalSettingsCard(),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _statCard('Total Hours', totalHours.toStringAsFixed(1), Icons.schedule,       color: const Color(0xFF6C63FF))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Avg / Day',   avg.toStringAsFixed(1),        Icons.trending_up,    color: const Color(0xFF43C59E))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Days Logged', '${_entries.length}',          Icons.calendar_today, color: const Color(0xFFFF7B7B))),
        ]),
        const SizedBox(height: 28),
        _sectionLabel('This Week — Study Hours'),
        const SizedBox(height: 16),
        _weeklyBarChart(),
        const SizedBox(height: 28),
        _sectionLabel('Mood Distribution'),
        const SizedBox(height: 16),
        _moodPieChart(happy, neutral, sad),
        const SizedBox(height: 12),
        _pieLegend(),
        const SizedBox(height: 28),
        _sectionLabel('Activity Calendar'),
        const SizedBox(height: 16),
        _calendarHeatmap(),
        const SizedBox(height: 28),
        _insightBanner(happy, neutral, sad, avg),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB 3 — ACHIEVEMENTS
  // ═══════════════════════════════════════════════════
  Widget _buildAchievementsTab() {
    final earned      = computeEarnedBadges(_entries, _dailyGoal);
    final earnedCount = earned.length;
    final totalCount  = kBadges.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            const Text('🏅', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Achievements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('$earnedCount / $totalCount badges unlocked', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${((earnedCount / totalCount) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? earnedCount / totalCount : 0,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
          children: kBadges.map((badge) {
            final isEarned = earned.contains(badge.id);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isEarned ? const Color(0xFF6C63FF).withOpacity(0.08) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isEarned ? const Color(0xFF6C63FF).withOpacity(0.4) : Colors.grey.shade200, width: isEarned ? 1.5 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(badge.emoji, style: TextStyle(fontSize: 28, color: isEarned ? null : const Color(0xFF000000).withOpacity(0.15))),
                const SizedBox(height: 6),
                Text(badge.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                    color: isEarned ? const Color(0xFF333355) : Colors.grey.shade400)),
                const SizedBox(height: 2),
                Text(badge.description, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: isEarned ? Colors.grey : Colors.grey.shade400)),
                if (isEarned) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Earned', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════
  //  UI WIDGETS
  // ═══════════════════════════════════════════════════

  Widget _headerCard() {
    final now    = DateTime.now();
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Text("How's your study day going?",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ]),
    );
  }

  Widget _quoteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB84D).withOpacity(0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Quote of the Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFCC8800))),
          const SizedBox(height: 4),
          Text(getTodayQuote(), style: const TextStyle(fontSize: 13, color: Color(0xFF555533), fontStyle: FontStyle.italic)),
        ])),
      ]),
    );
  }

  Widget _goalProgressCard(double todayHours, double progress) {
    final isGoalMet = progress >= 1.0;
    final color     = isGoalMet ? const Color(0xFF43C59E) : progress >= 0.6 ? const Color(0xFFFFB84D) : const Color(0xFF6C63FF);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(isGoalMet ? Icons.emoji_events : Icons.flag_outlined, color: color, size: 20),
            const SizedBox(width: 8),
            Text(isGoalMet ? 'Daily Goal Reached! 🎉' : 'Daily Study Goal',
                style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
          ]),
          Text('${todayHours.toStringAsFixed(1)} / ${_dailyGoal.toStringAsFixed(1)}h',
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color))),
        const SizedBox(height: 6),
        Text(isGoalMet ? 'Amazing work today!' : '${((1 - progress) * _dailyGoal).toStringAsFixed(1)}h more to reach your goal',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }

  Widget _goalSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.flag, color: Color(0xFF6C63FF), size: 20),
          SizedBox(width: 8),
          Text('Set Daily Study Goal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(
            controller: _goalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Hours (e.g. 6)', suffixText: 'hrs',
              filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
          )),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _saveGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            child: const Text('Save'),
          ),
        ]),
      ]),
    );
  }

  Widget _weeklyBarChart() {
    final today = DateTime.now();
    final Map<String, double> dayMap = {};
    for (var i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      dayMap['${d.year}-${d.month}-${d.day}'] = 0;
    }
    for (final e in _entries) {
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      if (dayMap.containsKey(key)) dayMap[key] = (dayMap[key] ?? 0) + e.studyHours;
    }
    const dayLabels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final bars      = dayMap.entries.toList();
    final maxVal    = bars.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: SizedBox(height: 180, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxVal + 2).clamp(4, 24).toDouble(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= 7) return const SizedBox();
                final d = today.subtract(Duration(days: 6 - idx));
                return Text(dayLabels[d.weekday - 1], style: const TextStyle(fontSize: 10, color: Colors.grey));
              })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: bars[i].value, width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            color: i == 6 ? const Color(0xFF6C63FF) : const Color(0xFF6C63FF).withOpacity(0.35)),
        ])),
      ))),
    );
  }

  Widget _calendarHeatmap() {
    final today = DateTime.now();
    final Map<String, double> dayHoursMap = {};
    for (final e in _entries) {
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      dayHoursMap[key] = (dayHoursMap[key] ?? 0) + e.studyHours;
    }
    final List<DateTime> days = List.generate(35, (i) => today.subtract(Duration(days: 34 - i)));
    const months  = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const dayAbbr = ['M','T','W','T','F','S','S'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SizedBox(width: 32),
          ...List.generate(7, (i) => Expanded(child: Center(child: Text(dayAbbr[i], style: const TextStyle(fontSize: 10, color: Colors.grey))))),
        ]),
        const SizedBox(height: 6),
        ...List.generate(5, (week) {
          final weekDays = days.sublist(week * 7, week * 7 + 7);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 32, child: Text(
                weekDays.any((d) => d.day == 1) ? months[weekDays.firstWhere((d) => d.day == 1).month] : '',
                style: const TextStyle(fontSize: 9, color: Colors.grey))),
              ...weekDays.map((d) {
                final key    = '${d.year}-${d.month}-${d.day}';
                final hours  = dayHoursMap[key] ?? 0;
                final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
                Color cellColor = hours == 0       ? Colors.grey.shade200
                    : hours < 2 ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : hours < 4 ? const Color(0xFF6C63FF).withOpacity(0.45)
                    : hours < 6 ? const Color(0xFF6C63FF).withOpacity(0.7)
                    : const Color(0xFF6C63FF);
                return Expanded(child: Tooltip(
                  message: '${d.day}/${d.month}: ${hours.toStringAsFixed(1)}h',
                  child: Container(
                    margin: const EdgeInsets.all(2), height: 26,
                    decoration: BoxDecoration(
                      color: cellColor, borderRadius: BorderRadius.circular(4),
                      border: isToday ? Border.all(color: const Color(0xFFFF7B7B), width: 2) : null),
                  ),
                ));
              }),
            ]),
          );
        }),
        const SizedBox(height: 8),
        Row(children: [
          const SizedBox(width: 32),
          const Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 4),
          ...[0.0, 0.2, 0.45, 0.7, 1.0].map((op) => Container(
            width: 14, height: 14, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: op == 0 ? Colors.grey.shade200 : const Color(0xFF6C63FF).withOpacity(op),
              borderRadius: BorderRadius.circular(3)))),
          const SizedBox(width: 4),
          const Text('More', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333355)));

  Widget _moodSelector() {
    const moods = [
      {'label': 'Happy',   'emoji': '😊', 'color': Color(0xFF43C59E)},
      {'label': 'Neutral', 'emoji': '😐', 'color': Color(0xFFFFB84D)},
      {'label': 'Sad',     'emoji': '😔', 'color': Color(0xFFFF7B7B)},
    ];
    return Row(children: moods.map((m) {
      final isSelected = _selectedMood == m['label'];
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _selectedMood = m['label'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? (m['color'] as Color).withOpacity(0.15) : Colors.white,
            border: Border.all(color: isSelected ? m['color'] as Color : Colors.grey.shade200, width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text(m['emoji'] as String, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(m['label'] as String, style: TextStyle(fontWeight: FontWeight.w600,
                color: isSelected ? m['color'] as Color : Colors.grey.shade600)),
          ]),
        ),
      ));
    }).toList());
  }

  Widget _suggestionCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEECFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.lightbulb_outline, color: Color(0xFF6C63FF)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF333355)))),
      ]),
    );
  }

  Widget _entryTile(MoodEntry e) {
    const moodIcons = {'Happy': '😊', 'Neutral': '😐', 'Sad': '😔'};
    return Card(
      margin: const EdgeInsets.only(bottom: 10), elevation: 0, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(moodIcons[e.mood] ?? '😐', style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.mood, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text('${e.date.day}/${e.date.month}/${e.date.year}  •  ${e.studyHours}h',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('${e.studyHours}h', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
              onPressed: () => _showEditDialog(e), constraints: const BoxConstraints(), padding: const EdgeInsets.all(4)),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF7B7B)),
              onPressed: () => _confirmDelete(e), constraints: const BoxConstraints(), padding: const EdgeInsets.all(4)),
        ]),
        if (e.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF4F6FB), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.notes, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(e.note, style: const TextStyle(fontSize: 12, color: Colors.grey))),
            ])),
        ],
      ])),
    );
  }

  Widget _statCard(String label, String value, IconData icon, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _moodPieChart(double happy, double neutral, double sad) {
    return SizedBox(height: 220, child: PieChart(PieChartData(
      sectionsSpace: 3, centerSpaceRadius: 50,
      sections: [
        if (happy > 0)   PieChartSectionData(value: happy,   color: const Color(0xFF43C59E), title: '${happy.toInt()}',   radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        if (neutral > 0) PieChartSectionData(value: neutral, color: const Color(0xFFFFB84D), title: '${neutral.toInt()}', radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        if (sad > 0)     PieChartSectionData(value: sad,     color: const Color(0xFFFF7B7B), title: '${sad.toInt()}',     radius: 60, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    )));
  }

  Widget _pieLegend() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _legendDot(const Color(0xFF43C59E), 'Happy'),
      const SizedBox(width: 16),
      _legendDot(const Color(0xFFFFB84D), 'Neutral'),
      const SizedBox(width: 16),
      _legendDot(const Color(0xFFFF7B7B), 'Sad'),
    ]);
  }

  Widget _legendDot(Color color, String label) => Row(children: [
    CircleAvatar(radius: 7, backgroundColor: color),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 13)),
  ]);

  Widget _insightBanner(double happy, double neutral, double sad, double avgHours) {
    String insight;
    if (happy > neutral && happy > sad) {
      insight = '🌟 You\'re mostly happy — great! High mood days correlate with better focus.';
    } else if (sad > happy) {
      insight = '💙 You\'ve had some tough days. Try lighter goals on low-mood days.';
    } else {
      insight = '⚖️ Your mood is fairly balanced. Keep tracking to spot patterns over time.';
    }
    if (avgHours >= _dailyGoal) insight += ' 🏆 You\'re consistently hitting your ${_dailyGoal}h goal!';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFEEECFF), borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.insights, color: Color(0xFF6C63FF)),
        const SizedBox(width: 10),
        Expanded(child: Text(insight, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }
}