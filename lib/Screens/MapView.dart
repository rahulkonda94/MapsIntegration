import 'dart:async';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as LocationManager;
import './PlaceDetailView.dart';

const kGoogleApiKey = "AIzaSyAYpKqHZyoF7AmBAVCTv4d11xxSDGfkkDU";
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class MapView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MapViewState();
  }
}

class MapViewState extends State<MapView> {
  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController mapController;
  List<PlacesSearchResult> places = [];
  bool isLoading = false;
  String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: homeScaffoldKey,
        appBar: AppBar(
          title: const Text("Location"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _handlePressButton();
              },
            ),
          ],
        ),
        body: Container(
          child: GoogleMap(
              onMapCreated: _onMapCreated,
              options: GoogleMapOptions(
                  myLocationEnabled: true,
                  cameraPosition:
                      const CameraPosition(target: LatLng(0.0, 0.0)))),
        ));
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    var currentLocation;
    final location = LocationManager.Location();
    currentLocation = await location.getLocation();
    mapController.addMarker(
      MarkerOptions(
        position: LatLng(double.parse(currentLocation['latitude']),
            double.parse(currentLocation['longitude'])),
        infoWindowText:
            InfoWindowText('location', currentLocation.value['my location']),
        icon: BitmapDescriptor.defaultMarker,
      ),
    );
    getNearbyPlaces(currentLocation);
  }

  Future<LatLng> getUserLocation() async {
    var currentLocation;
    final location = LocationManager.Location();
    try {
      currentLocation = await location.getLocation();
      final lat = currentLocation["latitude"];
      final lng = currentLocation["longitude"];
      final center = LatLng(lat, lng);
      return center;
    } on Exception {
      currentLocation = null;
      return null;
    }
  }

  void getNearbyPlaces(LatLng center) async {
    setState(() {
      this.isLoading = true;
      this.errorMessage = null;
    });

    final location = Location(center.latitude, center.longitude);
    final result = await _places.searchNearbyWithRadius(location, 2500);
    setState(() {
      this.isLoading = false;
      if (result.status == "OK") {
        this.places = result.results;
        result.results.forEach((f) {
          final markerOptions = MarkerOptions(
              position:
                  LatLng(f.geometry.location.lat, f.geometry.location.lng),
              infoWindowText: InfoWindowText("${f.name}", "${f.types?.first}"));
          mapController.addMarker(markerOptions);
        });
      } else {
        this.errorMessage = result.errorMessage;
      }
    });
  }

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }

  Future<void> _handlePressButton() async {
    try {
      final center = await getUserLocation();
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          strictbounds: center == null ? false : true,
          apiKey: kGoogleApiKey,
          onError: onError,
          mode: Mode.fullscreen,
          language: "en",
          location: center == null
              ? null
              : Location(center.latitude, center.longitude),
          radius: center == null ? null : 10000);

      showDetailPlace(p.placeId);
    } catch (e) {
      return;
    }
  }

  Future<Null> showDetailPlace(String placeId) async {
    if (placeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PlaceDetail(placeId)),
      );
    }
  }
}
