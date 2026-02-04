class CreatorHomeModel {
  final int rank;
  final int totalDiamond;
  final int targetDiamond;
  final String totalHour;

  CreatorHomeModel({
    required this.rank,
    required this.totalDiamond,
    required this.targetDiamond,
    required this.totalHour,
  });

  /// Factory constructor to parse from JSON
  factory CreatorHomeModel.fromJson(Map<String, dynamic> json) {
    return CreatorHomeModel(
      rank: int.tryParse((json['rank'] ?? 0).toString()) ?? 0,
      totalDiamond: int.tryParse((json['total_diamond'] ?? 0).toString()) ?? 0,
      targetDiamond: int.tryParse((json['target_diamond'] ?? json['target_diamonds'] ?? 10000).toString()) ?? 10000,
      totalHour: (json['total_hour'] ?? '0').toString(),
    );
  }

  /// Convert object back to JSON
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'total_diamond': totalDiamond,
      'target_diamond': targetDiamond,
      'total_hour': totalHour,
    };
  }
}
