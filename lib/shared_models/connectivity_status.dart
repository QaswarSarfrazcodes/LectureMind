/// Online-only app: every AssemblyAI/Groq action checks this first and
/// disables itself when offline — never queues (see `architecture.md` §6).
enum ConnectivityStatus { online, offline }
