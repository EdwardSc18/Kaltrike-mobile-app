class PredictedPlaces {
  String? place_id;
  String? main_text;
  String? secondary_text;
  double? latitude;
  double? longitude;

  PredictedPlaces({
    this.place_id,
    this.main_text,
    this.secondary_text,
    this.latitude,
    this.longitude,
  });

  PredictedPlaces.fromJson(Map<String, dynamic> jsonData) {
    place_id = jsonData["place_id"];
    main_text = jsonData["structured_formatting"]["main_text"];
    secondary_text = jsonData["structured_formatting"]["secondary_text"];
  }
}
