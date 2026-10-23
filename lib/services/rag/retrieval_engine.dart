import 'dart:math';
import '../../models/rag_chunk_model.dart';
import 'document_indexer_service.dart';

/// Resultado de una consulta de recuperación de fragmentos.
class RetrievalResult {
  final bool hasSufficientEvidence;
  final List<DocumentChunk> chunks;
  final double topScore;
  final String normalizedQuery;

  const RetrievalResult({
    required this.hasSufficientEvidence,
    required this.chunks,
    required this.topScore,
    required this.normalizedQuery,
  });

  factory RetrievalResult.insufficient({required String normalizedQuery}) {
    return RetrievalResult(
      hasSufficientEvidence: false,
      chunks: const [],
      topScore: 0.0,
      normalizedQuery: normalizedQuery,
    );
  }
}

/// Motor de recuperación de información (RAG) basado en BM25 adaptado para
/// la recuperación precisa de documentos históricos en español.
class RetrievalEngine {
  static final RetrievalEngine _instance = RetrievalEngine._internal();
  factory RetrievalEngine() => _instance;
  RetrievalEngine._internal();

  final DocumentIndexerService _indexer = DocumentIndexerService();

  static const double _defaultMinScoreThreshold = 3.2;

  static const Set<String> _spanishStopwords = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
    'de', 'del', 'al', 'a', 'en', 'con', 'por', 'para',
    'sobre', 'entre', 'hacia', 'hasta', 'desde', 'sin', 'tras',
    'durante', 'contra', 'mediante', 'y', 'e', 'o', 'u', 'que',
    'se', 'su', 'sus', 'mi', 'mis', 'tu', 'tus', 'nuestro', 'nuestra',
    'es', 'son', 'fue', 'era', 'eran', 'fueron', 'ha', 'han', 'hay',
    'habia', 'habian', 'como', 'cual', 'cuales', 'quien', 'quienes',
    'donde', 'cuando', 'cuanto', 'cuanta', 'cuantos', 'cuantas',
    'este', 'esta', 'estos', 'estas', 'ese', 'esa', 'esos', 'esas',
    'aquel', 'aquella', 'aquellos', 'aquellas', 'lo', 'le', 'les',
    'me', 'te', 'nos', 'pero', 'mas', 'porque', 'si', 'no',
    'dime', 'cuentame', 'explicame', 'saber', 'acerca',
  };

  /// Normaliza una cadena de texto eliminando acentos, puntuación y caracteres especiales.
  static String normalize(String text) {
    var output = text.toLowerCase().trim();
    output = output
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
    output = output.replaceAll(RegExp(r'[^\w\s]'), ' ');
    return output.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Extrae tokens sustantivos descartando palabras vacías (stopwords).
  static List<String> tokenize(String text) {
    final clean = normalize(text);
    if (clean.isEmpty) return [];
    return clean
        .split(' ')
        .where((token) => token.length > 2 && !_spanishStopwords.contains(token))
        .toList();
  }

  /// Recupera los fragmentos más relevantes para la pregunta del estudiante.
  RetrievalResult retrieve(
    String query, {
    int topK = 4,
    double minThreshold = _defaultMinScoreThreshold,
  }) {
    final allChunks = _indexer.chunks;
    if (allChunks.isEmpty) {
      return RetrievalResult.insufficient(normalizedQuery: normalize(query));
    }

    final queryTokens = tokenize(query);
    final normalizedQuery = normalize(query);

    // Si la consulta no tiene palabras clave sustantivas
    if (queryTokens.isEmpty) {
      return RetrievalResult.insufficient(normalizedQuery: normalizedQuery);
    }

    // Precomputar longitudes y estadísticas
    final int totalDocuments = allChunks.length;
    double totalTokens = 0;
    final List<List<String>> tokenizedCorpus = [];
    final Map<String, int> docFrequency = {};

    for (final chunk in allChunks) {
      final tokens = tokenize(chunk.text);
      tokenizedCorpus.add(tokens);
      totalTokens += tokens.length;

      final uniqueTokens = tokens.toSet();
      for (final t in uniqueTokens) {
        docFrequency[t] = (docFrequency[t] ?? 0) + 1;
      }
    }

    final double avgDocLen = totalTokens / totalDocuments;
    const double k1 = 1.2;
    const double b = 0.75;

    // Identificar tokens desconocidos en el corpus
    final List<String> unknownTokens = [];
    final List<String> knownTokens = [];
    for (final token in queryTokens) {
      if ((docFrequency[token] ?? 0) == 0) {
        unknownTokens.add(token);
      } else {
        knownTokens.add(token);
      }
    }

    // Si la pregunta contiene conceptos temáticos desconocidos que representan
    // una parte sustancial de la duda (por ejemplo "Waterloo", "convolucional", "Einstein"),
    // los documentos internos no cubren el tema.
    if (unknownTokens.isNotEmpty) {
      final double unknownRatio = unknownTokens.length / queryTokens.length;
      if (unknownRatio >= 0.3 || (unknownTokens.isNotEmpty && queryTokens.length <= 3)) {
        return RetrievalResult.insufficient(normalizedQuery: normalizedQuery);
      }
    }

    // Términos hiper-genéricos que no deben sostener por sí solos una coincidencia
    const genericTerms = {'ano', 'anos', 'dia', 'dias', 'ocurrio', 'paso', 'momento', 'tiempo', 'hecho', 'historia'};

    final scoredChunks = <_ScoredChunk>[];

    for (int i = 0; i < totalDocuments; i++) {
      final chunk = allChunks[i];
      final docTokens = tokenizedCorpus[i];
      final docLen = docTokens.length;
      if (docLen == 0) continue;

      // Conteo de términos en el documento
      final Map<String, int> termCounts = {};
      for (final t in docTokens) {
        termCounts[t] = (termCounts[t] ?? 0) + 1;
      }

      double score = 0.0;
      int matchedTokensCount = 0;
      int nonGenericMatches = 0;

      for (final qToken in queryTokens) {
        final count = termCounts[qToken] ?? 0;
        if (count > 0) {
          matchedTokensCount++;
          if (!genericTerms.contains(qToken)) {
            nonGenericMatches++;
          }
          final df = docFrequency[qToken] ?? 1;
          // BM25 IDF
          final idf = log(1.0 + (totalDocuments - df + 0.5) / (df + 0.5));
          // BM25 TF component
          final tf = (count * (k1 + 1.0)) / (count + k1 * (1.0 - b + b * (docLen / avgDocLen)));
          score += max(0.0, idf * tf);
        }
      }

      // Requerir que al menos coincida un término específico no genérico
      if (score > 0 && nonGenericMatches > 0) {
        final double coverageRatio = matchedTokensCount / queryTokens.length;

        // Si la cobertura de términos es muy pobre (< 40%) en preguntas largas, descartar
        if (queryTokens.length >= 3 && coverageRatio < 0.4) {
          continue;
        }

        // Boost por coincidencia de frase exacta de 2 o más palabras
        final cleanChunkText = normalize(chunk.text);
        if (normalizedQuery.length >= 6 && cleanChunkText.contains(normalizedQuery)) {
          score += 4.5;
        }

        // Boost si coincide en el título de la sección
        final cleanSection = normalize(chunk.section);
        for (final qToken in queryTokens) {
          if (cleanSection.contains(qToken)) {
            score += 1.5;
          }
        }

        // Bonificación por cobertura alta de términos de la pregunta
        if (coverageRatio >= 0.70) {
          score += 2.5;
        }

        scoredChunks.add(_ScoredChunk(chunk: chunk, score: score, coverageRatio: coverageRatio));
      }
    }

    if (scoredChunks.isEmpty) {
      return RetrievalResult.insufficient(normalizedQuery: normalizedQuery);
    }

    scoredChunks.sort((a, b) => b.score.compareTo(a.score));

    final bestChunk = scoredChunks.first;

    // Control estricto de evidencia: score mínimo y ratio de cobertura
    if (bestChunk.score < minThreshold || bestChunk.coverageRatio < 0.35) {
      return RetrievalResult.insufficient(normalizedQuery: normalizedQuery);
    }

    final topResults = scoredChunks.take(topK).map((sc) => sc.chunk).toList();

    return RetrievalResult(
      hasSufficientEvidence: true,
      chunks: topResults,
      topScore: bestChunk.score,
      normalizedQuery: normalizedQuery,
    );
  }
}

class _ScoredChunk {
  final DocumentChunk chunk;
  final double score;
  final double coverageRatio;

  _ScoredChunk({
    required this.chunk,
    required this.score,
    required this.coverageRatio,
  });
}
