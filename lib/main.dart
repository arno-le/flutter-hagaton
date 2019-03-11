import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'LineSelectionScreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Nyssedemo',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
        ),
        home: BusMap());
  }
}

class BusMap extends StatefulWidget {
  @override
  State<BusMap> createState() => BusMapState();
}

class BusMapState extends State<BusMap> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _tampereLoc = CameraPosition(
    target: LatLng(61.497468, 23.763669),
    zoom: 12,
  );

  Duration _updateInterval = new Duration(seconds: 2);
  Timer _updateTimer;
  final apiUrl = 'https://nyssetutka.fi/api/blob';
  GoogleMapController _mapController;
  Map<MarkerId, Marker> busMarkers = <MarkerId, Marker>{};
  Map<String, bool> lines = <String, bool>{};
  String iconPath = "/assets/bus.png";

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _tampereLoc,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          _mapController = controller;
          _updateTimer = this._initializeData();
        },
        markers: Set<Marker>.of(busMarkers.values),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _navigateAndDisplaySelection(context);
          },
          label: Text('Linjat'),
          icon: Icon(Icons.directions_bus)),
    );
  }

  _navigateAndDisplaySelection(BuildContext context) async {
    // Navigator.push returns a Future that will complete after we call
    // Navigator.pop on the Selection Screen!
    // This could have e.g a return value
    final result = await Navigator.push(
      context,
      // We'll create the SelectionScreen in the next step!
      MaterialPageRoute(
          builder: (context) => LineSelectionScreen(
                lines: lines,
                saveState: _setLineVisibility,
              )),
    );

  }

  void _setLineVisibility(String key, bool value) {
    debugPrint('Setting line $key visible ');
    setState(() {
      lines[key] = value;
    });
  }

  Timer _initializeData() {
    return new Timer(_updateInterval, this.loadData);
  }

  Future loadData() async {
    Map headers = <String, String>{
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    final response = await http.get(this.apiUrl, headers: headers);
    // sends the request
    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON
      Map<String, dynamic> body = jsonDecode(response.body);
      // Handle data
      body['lines'].forEach((key, item) {
        final markerId = new MarkerId(key);
        // Move or add marker
        if (busMarkers.containsKey(markerId)) {
          _changePosition(markerId, item);
        } else {
          debugPrint('Creating new marker');
          // Hide the marker
          lines[item['lineRef']] = false;
          // Push to array containing lines
          final Marker marker = Marker(
            visible: lines[item['lineRef']],
            icon: BitmapDescriptor.fromAsset(iconPath),
            flat: true,
            markerId: markerId,
            position: LatLng(
              item['lat'],
              item['lon'],
            ),
            infoWindow:
                InfoWindow(title: item['lineRef'], snippet: item['dest']),
            onTap: () {
              // _onMarkerTapped(markerId);
            },
          );
          setState(() {
            busMarkers[markerId] = marker;
          });
        }
      });
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load data');
    }
    // Reboot timer
    this._updateTimer = Timer(_updateInterval, this.loadData);
  }

  void _changePosition(MarkerId markerId, var busLine) {
    final Marker marker = busMarkers[markerId];
    setState(() {
      busMarkers[markerId] = marker.copyWith(
        visibleParam: lines[busLine['lineRef']],
        positionParam: LatLng(busLine['lat'], busLine['lon']),
      );
    });
  }

  void _remove(MarkerId markerId) {
    setState(() {
      if (busMarkers.containsKey(markerId)) {
        debugPrint('Removing marker');
        busMarkers.remove(markerId);
      }
    });
  }
}
