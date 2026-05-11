import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/services/request_assistant.dart';
import 'package:kaltrike_driver_app/src/core/config/map_key.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/widgets/progress_dialog.dart';
import 'package:provider/provider.dart';
import 'package:kaltrike_driver_app/src/features/commuter/config/global.dart';
import 'package:kaltrike_driver_app/src/features/commuter/state/app_info.dart';
import 'package:kaltrike_driver_app/src/shared/models/directions.dart';
import 'package:kaltrike_driver_app/src/features/commuter/models/predicted_places.dart';

//getPlaceDirectionDetails
class PlacePredictionTileDesign extends StatefulWidget
{
  final PredictedPlaces? predictedPlaces;

  PlacePredictionTileDesign({this.predictedPlaces});

  @override
  State<PlacePredictionTileDesign> createState() => _PlacePredictionTileDesignState();
}

class _PlacePredictionTileDesignState extends State<PlacePredictionTileDesign> {
  getPlaceDirectionDetails(String? placeId, context) async {
    showDialog(
      context: context, builder: (BuildContext context)=> ProgressDialog(
      message: "Setting up Destination.",
    ),
    );
// get request and test to a clickable adress
    String placeDirectionDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapWebServiceKey";
    var responseApi = await RequestAssistant.receiveRequest(placeDirectionDetailsUrl);
    Navigator.pop(context);

    if (responseApi == "Error Occurred, Failed. No Response."){
      return;
    }
    if (responseApi["status"] == "OK"){
      Directions directions = Directions();
      directions.locationName = (responseApi["result"]["formatted_address"] ?? responseApi["result"]["name"] ?? "Selected destination").toString();
      directions.locationId = placeId;
      directions.locationLatitude = responseApi["result"]["geometry"]["location"]["lat"];
      directions.locationLongitude = responseApi["result"]["geometry"]["location"]["lng"];

      Provider.of<AppInfo>(context, listen: false).updateDropOffLocationAddress(directions);

      setState(() {
        userDropOffAddress = directions.locationName!;
      });

      Navigator.pop(context, "obtainedDropoff");
    }
  }

  @override
  Widget build(BuildContext context){
    return ElevatedButton(
      onPressed: (){
        getPlaceDirectionDetails(widget.predictedPlaces!.place_id, context);
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          )
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          children: [
            const Icon(
              Icons.add_location_alt_outlined,
              color: Color(0xFF42A5F5),
              size: 25,
            ),
            const SizedBox(width: 14.0,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18.0,),
                  Text(
                    widget.predictedPlaces!.main_text!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2.0,),
                  Text(
                    widget.predictedPlaces!.secondary_text!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8.0,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
