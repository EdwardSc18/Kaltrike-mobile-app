import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/services/request_assistant.dart';
import 'package:kaltrike_driver_app/src/core/config/map_key.dart';
import 'package:kaltrike_driver_app/src/features/commuter/models/predicted_places.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/widgets/place_prediction_tile.dart';

class SearchPlacesScreen extends StatefulWidget {
  @override
  _SearchPlacesScreenState createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  List<PredictedPlaces> placesPredictedList = [];

  void findPlaceAutoCompleteSearch(String inputText) async {
    if (inputText.length > 1) {
      String urlAutoCompleteSearch =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=$inputText"
          "&key=$mapWebServiceKey"
          "&components=country:ph"
          "&sessiontoken=123456";

      var responseAutoCompleteSearch =
      await RequestAssistant.receiveRequest(urlAutoCompleteSearch);

      if (responseAutoCompleteSearch == "Error Occurred, Failed. No Response.") {
        print("Places API Error: No Response");
        return;
      }

      if (responseAutoCompleteSearch["status"] == "OK") {
        var placePredictions = responseAutoCompleteSearch["predictions"];
        var placePredictionsList = (placePredictions as List)
            .map((jsonData) => PredictedPlaces.fromJson(jsonData))
            .toList();

        setState(() {
          placesPredictedList = placePredictionsList;
        });
      } else {
        print("Places API Error: ${responseAutoCompleteSearch["status"]}");
        print("Error Message: ${responseAutoCompleteSearch["error_message"]}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Modern header section
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade300.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and title row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Destination Location",
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (valueTyped) {
                          findPlaceAutoCompleteSearch(valueTyped);
                        },
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          hintText: "Search for a destination...",
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Results section
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Results header
                  if (placesPredictedList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Search Results",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Results list
                  Expanded(
                    child: placesPredictedList.isNotEmpty
                        ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: placesPredictedList.length,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: PlacePredictionTileDesign(
                            predictedPlaces: placesPredictedList[index],
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 8);
                      },
                    )
                        : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF2563EB),
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Search for destinations",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter a location to find places",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}