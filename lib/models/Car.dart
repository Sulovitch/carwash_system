// models/car.dart
class Car {
  final int carId;
  final String? selectedMake;
  final String? selectedModel;
  final String? selectedYear;
  final List<String?> selectedArabicNumbers;
  final List<String?> selectedLatinNumbers;
  final List<String?> selectedArabicLetters;
  final List<String?> selectedLatinLetters;

  Car({
    required this.carId,
    this.selectedMake,
    this.selectedModel,
    this.selectedYear,
    required this.selectedArabicNumbers,
    required this.selectedLatinNumbers,
    required this.selectedArabicLetters,
    required this.selectedLatinLetters,
  });

  String get licensePlate {
    final arabicNumbers = selectedArabicNumbers.join('');
    final latinNumbers = selectedLatinNumbers.join('');
    final arabicLetters = selectedArabicLetters.join(' ');
    final latinLetters = selectedLatinLetters.join('');

    return "$arabicNumbers $latinNumbers | $arabicLetters $latinLetters";
  }
}
