enum AcademicDomain {
  computerScience(
    displayName: 'Computer Science & Software',
    code: 'CS',
  ),
  mathematics(
    displayName: 'Mathematics & Statistics',
    code: 'MATH',
  ),
  medicine(
    displayName: 'Medicine & Life Sciences',
    code: 'MED',
  ),
  physics(
    displayName: 'Physical Sciences & Engineering',
    code: 'PHYS',
  ),
  economics(
    displayName: 'Economics & Business',
    code: 'ECON',
  ),
  generalAcademic(
    displayName: 'General Academic Studies',
    code: 'GEN',
  );

  const AcademicDomain({
    required this.displayName,
    required this.code,
  });

  final String displayName;
  final String code;
}

class DomainClassificationResult {
  const DomainClassificationResult({
    required this.domain,
    required this.confidence,
    required this.detectedKeywords,
    required this.domainDirective,
  });

  final AcademicDomain domain;
  final double confidence;
  final List<String> detectedKeywords;
  final String domainDirective;
}

class SubjectClassifierService {
  const SubjectClassifierService();

  static const Map<AcademicDomain, List<String>> _domainKeywords = {
    AcademicDomain.computerScience: [
      'algorithm', 'code', 'software', 'programming', 'database', 'sql', 'api',
      'function', 'variable', 'object', 'class', 'inheritance', 'recursion',
      'array', 'list', 'tree', 'graph', 'hash', 'queue', 'stack', 'compiler',
      'runtime', 'thread', 'concurrency', 'deadlock', 'memory', 'pointer',
      'framework', 'flutter', 'dart', 'python', 'java', 'c++', 'javascript',
      'backend', 'frontend', 'cpu', 'cache', 'operating system', 'network',
      'tcp', 'ip', 'server', 'async', 'await', 'oop', 'rest api',
    ],
    AcademicDomain.mathematics: [
      'calculus', 'integral', 'derivative', 'matrix', 'matrices', 'linear algebra',
      'vector', 'probability', 'statistics', 'variance', 'polynomial', 'equation',
      'theorem', 'proof', 'differential', 'trigonometry', 'sine', 'cosine',
      'limit', 'continuous', 'discrete', 'logarithm', 'geometry', 'algebra',
      'eigenvalue', 'eigenvector', 'hypothesis', 'standard deviation',
    ],
    AcademicDomain.medicine: [
      'cell', 'dna', 'rna', 'protein', 'enzyme', 'gene', 'genetic', 'mitosis',
      'meiosis', 'pathology', 'anatomy', 'physiology', 'neuron', 'brain',
      'cardiovascular', 'heart', 'artery', 'blood', 'immune', 'antibody',
      'antigen', 'receptor', 'hemoglobin', 'disease', 'patient', 'clinical',
      'drug', 'pharmacology', 'bacteria', 'virus', 'atp', 'pcr', 'homeostasis',
      'hormone', 'metabolism', 'cellular',
    ],
    AcademicDomain.physics: [
      'velocity', 'acceleration', 'force', 'mass', 'gravity', 'momentum',
      'energy', 'kinetic', 'potential', 'quantum', 'thermodynamics', 'entropy',
      'optics', 'electromagnetic', 'voltage', 'current', 'resistance', 'circuit',
      'photon', 'wave', 'frequency', 'wavelength', 'friction', 'torque',
      'angular', 'newton', 'relativity', 'field', 'particle',
    ],
    AcademicDomain.economics: [
      'inflation', 'gdp', 'supply', 'demand', 'elasticity', 'macroeconomics',
      'microeconomics', 'fiscal', 'monetary', 'interest rate', 'market',
      'equilibrium', 'monopoly', 'revenue', 'profit', 'cost', 'investment',
      'capital', 'currency', 'trade', 'deficit', 'budget', 'gdp growth',
      'central bank', 'consumer',
    ],
  };

  DomainClassificationResult classify(String text) {
    final lower = text.toLowerCase();
    if (lower.trim().isEmpty) {
      return DomainClassificationResult(
        domain: AcademicDomain.generalAcademic,
        confidence: 1.0,
        detectedKeywords: const [],
        domainDirective: _getDirective(AcademicDomain.generalAcademic),
      );
    }

    final scores = <AcademicDomain, List<String>>{};
    for (final domain in _domainKeywords.keys) {
      final matches = <String>[];
      final keywords = _domainKeywords[domain]!;
      for (final kw in keywords) {
        final regex = RegExp('\\b${RegExp.escape(kw)}s?\\b', caseSensitive: false);
        if (regex.hasMatch(lower)) {
          matches.add(kw);
        }
      }
      scores[domain] = matches;
    }

    AcademicDomain bestDomain = AcademicDomain.generalAcademic;
    int maxHits = 0;
    List<String> bestKeywords = const [];

    for (final entry in scores.entries) {
      if (entry.value.length > maxHits) {
        maxHits = entry.value.length;
        bestDomain = entry.key;
        bestKeywords = entry.value;
      }
    }

    // Require at least 2 distinct domain keywords to commit to a specialized domain
    if (maxHits < 2) {
      bestDomain = AcademicDomain.generalAcademic;
      bestKeywords = const [];
    }

    final confidence = maxHits >= 6 ? 0.95 : (maxHits >= 2 ? 0.80 : 0.60);

    return DomainClassificationResult(
      domain: bestDomain,
      confidence: confidence,
      detectedKeywords: bestKeywords,
      domainDirective: _getDirective(bestDomain),
    );
  }

  String _getDirective(AcademicDomain domain) {
    switch (domain) {
      case AcademicDomain.computerScience:
        return 'ACADEMIC DOMAIN DIRECTIVE (Computer Science & Software):\n'
            '• Enclose code snippets, CLI commands, and function calls in syntax-highlighted markdown code blocks.\n'
            '• Clearly analyze time and space complexity using Big-O notation.\n'
            '• Highlight architecture patterns, error boundaries, memory safety, and thread concurrency implications.';

      case AcademicDomain.mathematics:
        return 'ACADEMIC DOMAIN DIRECTIVE (Mathematics & Statistics):\n'
            '• Render equations with clear math notation and formulas.\n'
            '• Present mathematical proofs and derivations step by step with explicit assumptions.\n'
            '• State boundary conditions, edge cases, and geometric or probabilistic intuitions.';

      case AcademicDomain.medicine:
        return 'ACADEMIC DOMAIN DIRECTIVE (Medicine & Life Sciences):\n'
            '• Preserve standard biochemical and anatomical terminology (e.g. DNA/RNA, ATP, PCR, Homeostasis).\n'
            '• Correlate physiological/cellular mechanisms with clinical outcomes and diagnostics.\n'
            '• Distinguish etiology, pathogenesis, and compensatory bodily responses.';

      case AcademicDomain.physics:
        return 'ACADEMIC DOMAIN DIRECTIVE (Physics & Physical Sciences):\n'
            '• Explicitly state governing physical laws, conservation principles, and SI units.\n'
            '• Break down vector quantities into components and specify reference coordinate frames.\n'
            '• Clarify idealizations vs. real-world dissipative mechanisms (friction, air drag, thermal loss).';

      case AcademicDomain.economics:
        return 'ACADEMIC DOMAIN DIRECTIVE (Economics & Business):\n'
            '• Frame concepts in terms of supply-demand dynamics, opportunity costs, and incentives.\n'
            '• Differentiate short-run vs. long-run macroeconomic and microeconomic equilibrium.\n'
            '• Explain fiscal vs. monetary policy levers with concrete quantitative intuition.';

      case AcademicDomain.generalAcademic:
        return 'ACADEMIC DOMAIN DIRECTIVE (General Academic):\n'
            '• Deliver structured, pedagogy-first explanations using the Feynman technique.\n'
            '• Clarify definitions first, followed by mechanism, concrete analogies, and Socratic reflection.';
    }
  }
}
