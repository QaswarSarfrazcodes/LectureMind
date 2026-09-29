import 'package:flutter_test/flutter_test.dart';
import 'package:lecturemind/core/services/lecture_chunk_service.dart';
import 'package:lecturemind/shared_models/language.dart';
import 'package:lecturemind/shared_models/lecture.dart';
import 'package:lecturemind/shared_models/notes.dart';

void main() {
  group('LectureChunkService & RAG Grounding Engine', () {
    const chunkService = LectureChunkService();

    final testLecture = Lecture(
      id: 'lec-os-101',
      title: 'Operating Systems: Process Scheduling Algorithms',
      transcript: '''
Welcome to this lecture on Operating Systems. Today we will explore Process Scheduling and Context Switching.
In computer science, process scheduling is the activity of the process manager that handles the removal of the running process from the CPU and the selection of another process on the basis of a particular strategy.
Process scheduling is an essential part of a Multiprogramming operating systems. Such operating systems allow more than one process to be loaded into the executable memory at a time and the loaded process shares the CPU using time multiplexing.

Now let us examine the First-Come, First-Served scheduling algorithm, commonly abbreviated as FCFS.
FCFS is the simplest scheduling algorithm. In FCFS, the process that requests the CPU first is allocated the CPU first.
The implementation of the FCFS policy is easily managed with a FIFO queue.
However, FCFS often suffers from the Convoy Effect, where small processes wait for one big CPU-bound process to finish.

Next, we look at Shortest Job First or SJF. SJF schedules the process with the shortest burst time first.
It is optimal in terms of minimizing average waiting time, but suffers from starvation for long jobs.
Finally, Round Robin (RR) scheduling introduces a time quantum, making it ideal for interactive time-sharing systems.
''',
      summary: 'Comprehensive analysis of FCFS, SJF, and Round Robin process scheduling algorithms.',
      createdAt: DateTime.now(),
      language: Language.english,
      audioDurationSeconds: 600,
      sections: const [
        NoteSection(
          title: 'Introduction to Process Scheduling',
          body: 'Foundational concepts of CPU scheduling and multiprogramming.',
        ),
        NoteSection(
          title: 'FCFS and the Convoy Effect',
          body: 'First-Come First-Served FIFO queue mechanics and convoy bottlenecks.',
        ),
        NoteSection(
          title: 'SJF and Round Robin Algorithms',
          body: 'Shortest Job First optimality and Round Robin time quantum analysis.',
        ),
      ],
    );

    test('chunkLecture divides transcript into bounded chunks with metadata and timestamps', () {
      final chunks = chunkService.chunkLecture(testLecture);

      expect(chunks.isNotEmpty, isTrue);
      expect(chunks.first.lectureId, equals('lec-os-101'));
      expect(chunks.first.estimatedTimestamp, isNotEmpty);
      expect(chunks.first.sectionTitle, isNotEmpty);
    });

    test('retrieveRelevantChunks prioritizes exact query terms and section titles', () {
      final chunks = chunkService.retrieveRelevantChunks(
        testLecture,
        'Convoy Effect in FCFS',
        topK: 2,
      );

      expect(chunks.isNotEmpty, isTrue);
      final topChunk = chunks.first;
      expect(topChunk.text.toLowerCase(), contains('convoy effect'));
    });

    test('buildRAGContext constructs citation-annotated context block', () {
      final ragContext = chunkService.buildRAGContext(
        testLecture,
        'What is Round Robin time quantum?',
        topK: 2,
      );

      expect(ragContext, contains('LECTURE METADATA:'));
      expect(ragContext, contains('Operating Systems: Process Scheduling Algorithms'));
      expect(ragContext, contains('RETRIEVED GROUNDED LECTURE EXCERPTS'));
      expect(ragContext, contains('Excerpt'));
    });
  });
}
