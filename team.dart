class Team {
  int id;
  String name;
  int foundingYear;
  DateTime lastChampDate;

  Team({required this.id, required this.name, required this.foundingYear, required this.lastChampDate});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'foundingYear': foundingYear,
      'lastChampDate': lastChampDate.toIso8601String(),
    };
  }
}
