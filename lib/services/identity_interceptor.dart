class IdentityInterceptor {
  static const List<_IdentityRule> _rules = [
    _IdentityRule(
      patterns: [
        'what are you',
        'who are you',
        'what model are you',
        'what is your name',
        'tell me about yourself',
        'introduce yourself',
      ],
      response: 'pocketIdentity',
    ),
    _IdentityRule(
      patterns: [
        'who made you',
        'who created you',
        'who built you',
        'who developed you',
        'your creator',
        'your developer',
      ],
      response: 'biuIdentity',
    ),
    _IdentityRule(
      patterns: [
        'are you chatgpt',
        'are you an ai',
        'are you a bot',
        'what kind of ai',
      ],
      response: 'notChatGPT',
    ),
  ];

  String? intercept(String input) {
    if (input.isEmpty) return null;

    final normalized = input.toLowerCase().trim();

    for (final rule in _rules) {
      for (final pattern in rule.patterns) {
        if (_fuzzyMatch(normalized, pattern)) {
          return rule.response;
        }
      }
    }

    return null;
  }

  bool _fuzzyMatch(String input, String pattern) {
    if (input.contains(pattern)) return true;

    final inputWords = input.split(RegExp(r'\s+'));
    final patternWords = pattern.split(RegExp(r'\s+'));

    final matchingWords = patternWords.where((pw) =>
      inputWords.any((iw) => _wordsSimilar(iw, pw))
    ).length;

    if (patternWords.length <= 2) {
      return matchingWords >= patternWords.length;
    }
    return matchingWords >= (patternWords.length - 1);
  }

  bool _wordsSimilar(String a, String b) {
    if (a == b) return true;

    if (a.length <= 3 && b.length <= 3) return false;

    final distance = _levenshteinDistance(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    return (maxLen - distance) / maxLen >= 0.6;
  }

  int _levenshteinDistance(String a, String b) {
    final aLen = a.length;
    final bLen = b.length;

    final dp = List.generate(aLen + 1, (_) => List.filled(bLen + 1, 0));

    for (int i = 0; i <= aLen; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= bLen; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= aLen; i++) {
      for (int j = 1; j <= bLen; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[aLen][bLen];
  }
}

class _IdentityRule {
  final List<String> patterns;
  final String response;

  const _IdentityRule({
    required this.patterns,
    required this.response,
  });
}
