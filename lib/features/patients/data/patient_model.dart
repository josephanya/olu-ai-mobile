import 'package:isar/isar.dart';

part 'patient_model.g.dart';

@collection
class Patient {
  Id id = Isar.autoIncrement;

  late String firstName;
  late String lastName;

  DateTime? dateOfBirth;

  String? gender;

  String? phoneNumber;

  String? village;

  @Index()
  DateTime createdAt = DateTime.now();

  @Index()
  DateTime updatedAt = DateTime.now();
}
