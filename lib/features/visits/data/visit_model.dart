import 'package:isar/isar.dart';

part 'visit_model.g.dart';

@collection
class Visit {
  Id id = Isar.autoIncrement;

  @Index()
  late int patientId;

  DateTime timestamp = DateTime.now();

  String? audioPath;

  String? transcript;

  String? aiAnalysis; // JSON string

  String? chwNotes;

  @Index()
  DateTime createdAt = DateTime.now();

  @Index()
  DateTime updatedAt = DateTime.now();
}
