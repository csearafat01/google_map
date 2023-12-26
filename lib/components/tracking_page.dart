import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:g_map/components/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationTrackingPage extends StatefulWidget {
  const LocationTrackingPage({Key? key}) : super(key: key);

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation =
  LatLng(23.727373593008156, 90.39662492224777);

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then((location) {
      currentLocation = location;
    });

    GoogleMapController googleMapController = await _controller.future;

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;
      googleMapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(newLoc.latitude!, newLoc.longitude!),
              zoom: 13.5)));
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    getPolyPoints();
  }

  Future<void> getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    if (currentLocation != null) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        google_api_key,
        PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        setState(() {});
      }
    }
  }

  Set<Polyline> createPolylines() {
    Set<Polyline> polylines = {};
    if (currentLocation != null) {
      polylines.add(Polyline(
        polylineId: const PolylineId("poly-line-1"),
        color: Colors.blueAccent,
        width: 4,
        visible: true,
        patterns: const [
          // PatternItem.gap(10),
          // PatternItem.dash(10),
          // PatternItem.dot,
        ],
        points: [
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          sourceLocation,
        ],
      ));
    }
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Real-Time Location Tracker",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(currentLocation?.latitude ?? 0, currentLocation?.longitude ?? 0),
          zoom: 9.5,
        ),
        polylines: createPolylines(),
        markers: {
          Marker(
            markerId: const MarkerId("currentLocation"),
            position: LatLng(currentLocation?.latitude ?? 0, currentLocation?.longitude ?? 0),
            infoWindow: InfoWindow(
              title: "My Current Location",
              snippet:
              '${currentLocation?.latitude} , ${currentLocation?.longitude}',
            ),
          ),
          const Marker(
            markerId: MarkerId("destination"),
            position: sourceLocation,
          ),
        },
        onMapCreated: (mapController) {
          _controller.complete((mapController));
        },
      ),
    );
  }
}
