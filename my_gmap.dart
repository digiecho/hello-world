// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'dart:math';

import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'index.dart'; // Imports other custom widgets

import 'package:test/components/enter_field/enter_field_widget.dart';
import 'package:test/components/select_staff/select_staff_widget.dart';

import 'index.dart'; // Imports other custom widgets

import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'index.dart'; // Imports other custom widgets
import 'package:flutter/services.dart';
import '../../auth/firebase_auth/auth_util.dart';
import 'package:test/flutter_flow/flutter_flow_icon_button.dart';

import 'index.dart'; // Imports other custom widgets
import 'package:test/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide LatLng;
import 'package:google_maps_flutter/google_maps_flutter.dart' as latlng;
//import 'package:google_maps_flutter_web/google_maps_flutter_web.dart'
//    hide GoogleMapController;
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as Math;
import 'index.dart' as custom_widgets;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//import 'package:maps_toolkit/maps_toolkit.dart' hide LatLng;
import 'package:maps_toolkit/maps_toolkit.dart' as mt;

class MyGMap extends StatefulWidget {
  const MyGMap({
    Key? key,
    this.width,
    this.height,
    this.initialCamaraPosition,
    this.zoom,
    this.tilt,
    this.geoFenceData,
    this.userId,
    this.toDoRef,
    required this.action,
  }) : super(key: key);

  final double? width;
  final double? height;
  final LatLng? initialCamaraPosition;
  final double? zoom;
  final double? tilt;
  final List<GeoFencesRecord>? geoFenceData;
  final DocumentReference? userId;
  final DocumentReference? toDoRef;
  final Future<dynamic> Function() action;

  @override
  _MyGMapState createState() => _MyGMapState();
}

class _MyGMapState extends State<MyGMap> {
  _MyGMapState();
  late GoogleMapController _googleMapController;
  GoogleMapController? controller;
  Completer<GoogleMapController> _controllerCompleter = Completer();
  String? _mapStyle;

  bool _mapStyleLoaded = true;
  late BitmapDescriptor _markerIcon;

  List<CircleMarker> circleUndoStack = [];
  Set<Marker> _markers = {};
  Set<Circle> _circles = HashSet<Circle>();
  Set<Polygon> _polygons = HashSet<Polygon>();
  List<PolygonMarker> _polygonMarkers = [];
  List<CircleMarker> _circleMarkers = [];
  List<MarkerMarker> _markerMarkers = [];
  bool dragging = false;
  PolygonMarker? _selectedPolygonMarker;
  MarkerMarker? _selectedMarker;
  CircleMarker? _selectedCircle;
  String geoFencetype = 'Polygon';
  Color? color;
  // Start at the first icon 'Polygon'.
  int currentIconIndex = 0;
  List<IconData> icons = [
    Icons.polyline_rounded,
    FontAwesomeIcons.circleDot,
    Icons.location_on
  ];
  Icon? circleandpolygonmarkerIcon = Icon(Icons.circle);

  Mode _currentMode = Mode.Adding; // Default to adding mode.

  TextEditingController? textController;
  bool undo = false;

  @override
  void initState() {
    textController = TextEditingController();
    rootBundle.loadString('assets/map_style2.txt').then((jsonStyle) {
      setState(() {
        _mapStyle = jsonStyle;
        _mapStyleLoaded = true;
      });
    });

    print('should have loaded');
    super.initState();
  }

  @override
  void dispose() {
    textController?.dispose();
    super.dispose();
  }

  // Start the map with setting
  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;

    setState(() {
      _controllerCompleter.complete(controller);
      controller.setMapStyle(_mapStyle);
    });
  }

  // This function is to change the marker icon
  Future<BitmapDescriptor> getMarkerIcon(
    IconData iconData,
    double size,
  ) async {
    Color color = FFAppState().selectedColor;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final ui.TextDirection? td = ui.TextDirection.ltr;
    final textPainter = TextPainter(textDirection: td);
    textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
            letterSpacing: 0.0,
            fontSize: size,
            fontFamily: iconData.fontFamily,
            color: color));
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Set<Circle> _getCircles() {
    Set<Circle> circles = {};

    for (CircleMarker cm in _circleMarkers) {
      circles.add(cm.circle);
    }

    return circles;
  }

  Set<Marker> _getMarkers() {
    Set<Marker> markers = {};

    for (CircleMarker cm in _circleMarkers) {
      markers.add(cm.centerMarker);
      markers.add(cm.edgeMarker);
    }

    for (PolygonMarker pm in _polygonMarkers) {
      markers.addAll(pm.markers);
      markers.addAll(pm.midMarkers!);
    }
    for (MarkerMarker mm in _markerMarkers) {
      markers.add(mm.marker);
    }

    return markers;
  }

  Set<Polygon> _getPolygons() {
    Set<Polygon> polygons = {};
    for (PolygonMarker pm in _polygonMarkers) {
      polygons.add(pm.polygon);
    }

    return polygons;
  }

//change the icon of the geofence type button
  void changeIcon() {
    setState(() {
      currentIconIndex = (currentIconIndex + 1) % icons.length;
      _selectedPolygonMarker = null;
      _selectedMarker = null;
      _selectedCircle = null;
      _currentMode = Mode.Adding;

      Random random = Random();
      Color tempcol = Color.fromRGBO(
        random.nextInt(255),
        random.nextInt(255),
        random.nextInt(255),
        1,
      );
      FFAppState().selectedColor = tempcol;

      if (currentIconIndex == 0) {
        geoFencetype = 'Polygon';

        if (_polygonMarkers.isNotEmpty) {
          _selectedPolygonMarker = _polygonMarkers.last;
        }
        configurePolygonMode();
      } else if (currentIconIndex == 1) {
        geoFencetype = 'Circle';
        circleUndoStack.clear();
        if (_circleMarkers.isNotEmpty) {
          _selectedCircle = _circleMarkers.last;
        }
        configureCircleMode();
      } else if (currentIconIndex == 2) {
        geoFencetype = 'Marker';
        if (_markerMarkers.isNotEmpty) {
          _selectedMarker = _markerMarkers.last;
        }
        configureMarkerMode();
      }
    });
  }

  void configurePolygonMode() {
    setAllMarkers(false, false);
    setAllCircleMarkers(false, false);
    setAllPolygonMarkers(false, false);
    setState(() {
      if (_selectedPolygonMarker != null) {
        PolygonMarker pm = _selectedPolygonMarker!;
        pm.polygon = pm.polygon.copyWith(
          consumeTapEventsParam: true,
          strokeWidthParam: 2,
          strokeColorParam: pm.polygon.strokeColor,
          fillColorParam: pm.polygon.fillColor.withOpacity(0.15),
          onTapParam: () {
            _onPolygonTapped(pm.polygonId);
          },
        );

        // Update markers
        List<Marker> updatedMarkers = [];
        for (var m in pm.markers) {
          updatedMarkers.add(
            m.copyWith(draggableParam: true, visibleParam: true),
          );
        }
        pm.markers = updatedMarkers;
        List<Marker> updatedMidMarkers = [];
        for (var mm in pm.midMarkers!) {
          updatedMidMarkers.add(
            mm.copyWith(draggableParam: true, visibleParam: true),
          );
        }
        pm.markers = updatedMarkers;
        pm.midMarkers = updatedMidMarkers;

        _polygonMarkers.removeWhere(
          (element) => element.polygonId == _selectedPolygonMarker!.polygonId,
        );

        _polygonMarkers.add(pm);
        _selectedPolygonMarker = pm;
        undo = false;
      }
    });
  }

  void configureCircleMode() {
    setAllMarkers(false, false);
    setAllPolygonMarkers(false, false);
    setAllCircleMarkers(false, false);

    if (_selectedCircle != null) {
      CircleMarker cm = _selectedCircle!;
      cm.circle = cm.circle.copyWith(
        consumeTapEventsParam: true,
        strokeWidthParam: 2,
        strokeColorParam: cm.circle.strokeColor,
        fillColorParam: cm.circle.fillColor.withOpacity(0.15),
        onTapParam: () {
          _onCircleTapped(cm.circle.circleId.value);
        },
      );

      cm.centerMarker = cm.centerMarker.copyWith(
        draggableParam: true,
        visibleParam: true,
      );

      cm.edgeMarker = cm.edgeMarker.copyWith(
        draggableParam: true,
        visibleParam: true,
      );

      _circleMarkers.removeWhere(
          (element) => element.circle.circleId == cm.circle.circleId);
      _circleMarkers.add(cm);
    }

    setState(() {});
  }

  void configureMarkerMode() {
    setAllMarkers(true, true);
    setAllPolygonMarkers(false, false);
    setAllCircleMarkers(false, false);
    // // Set all markers not related to circles or polygons to be visible
    // Set<Marker>? updatedMarkers = {};
    // for (var m in _markers) {
    //   m = m.copyWith(draggableParam: true, visibleParam: true);
    //   updatedMarkers.add(m);
    // }

    // _markers = updatedMarkers;
    setState(() {});
  }

  void setAllCircleMarkers(bool draggable, bool visible) {
    for (var cm in _circleMarkers) {
      cm.centerMarker = cm.centerMarker
          .copyWith(draggableParam: draggable, visibleParam: visible);
      cm.edgeMarker = cm.edgeMarker
          .copyWith(draggableParam: draggable, visibleParam: visible);
    }
  }

  void setAllMarkers(bool draggable, bool visible) async {
    List<MarkerMarker> markerMarkers = _markerMarkers;
    // Convert Set to List for indexing
    for (var markers in markerMarkers) {
      if (markers.marker.markerId.value ==
          _selectedMarker!.marker.markerId.value) {
        IconData newIcon = Icons.location_on_rounded;
        var icon = await getMarkerIcon(newIcon, 40);
        debugPrint('icon Big');
        markers.marker = markers.marker.copyWith(
            draggableParam: draggable, visibleParam: visible, iconParam: icon);
      } else {
        debugPrint('icon small');
        IconData newIcon = Icons.location_on_rounded;
        var icon = await getMarkerIcon(newIcon, 20);
        markers.marker = markers.marker.copyWith(
            draggableParam: draggable, visibleParam: visible, iconParam: icon);
      }
    }
    markerMarkers = markerMarkers; // Convert List back to Set
    setState(() {});
  }

  void setAllPolygonMarkers(bool draggable, bool visible) {
    List<PolygonMarker>? updatedPolygonMarkers = [];
    for (var polygonMarker in _polygonMarkers) {
      List<Marker>? mr = [];
      List<Marker>? mmr = [];
      if (polygonMarker.markers.isNotEmpty) {
        for (var m in polygonMarker.markers) {
          mr.add(m.copyWith(draggableParam: draggable, visibleParam: visible));
        }
      }
      if (polygonMarker.midMarkers!.isNotEmpty) {
        for (var m in polygonMarker.midMarkers!) {
          mmr.add(m.copyWith(draggableParam: draggable, visibleParam: visible));
        }
      }

      var npm = PolygonMarker(
          polygonId: polygonMarker.polygonId,
          polygon: polygonMarker.polygon,
          markers: mr);

      updatedPolygonMarkers.add(npm);
    }
    _polygonMarkers = updatedPolygonMarkers;
    setState(() {});
  }

//generqte ids for the polygons, circles, and markers
  String generateUniqueId() {
    var random = Math.Random();
    return '${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(10000)}';
  }

  void _addPointToPolygon(latlng.LatLng point) async {
    var icon = await getMarkerIcon(
        IconData(circleandpolygonmarkerIcon!.icon!.codePoint,
            fontFamily: circleandpolygonmarkerIcon!.icon!.fontFamily,
            fontPackage: circleandpolygonmarkerIcon!.icon!.fontPackage),
        20);
    setState(() {
      PolygonMarker pm;

      // Are we editing an existing polygon?
      if (_selectedPolygonMarker != null && _currentMode == Mode.Editing) {
        pm = _selectedPolygonMarker!;
      } else {
        // Create a new polygon.
        String polygonIdVal = generateUniqueId();

        pm = PolygonMarker(
          polygonId: polygonIdVal,
          polygon: Polygon(
            consumeTapEvents: true,
            polygonId: PolygonId(polygonIdVal),
            points: [],
            strokeWidth: 2,
            strokeColor: FFAppState().selectedColor,
            fillColor: FFAppState().selectedColor.withOpacity(0.15),
            onTap: () {
              _onPolygonTapped(polygonIdVal);
            },
          ),
          markers: [],
          midMarkers: [],
        );

        _polygonMarkers.add(pm);

        // Set the current mode to Editing and the currently selected polygon marker.
        _currentMode = Mode.Editing;
        _selectedPolygonMarker = pm;
      }

      // Get the index of the new point (it will be the last point after adding the new one).
      final int pointIndex = pm.polygon.points.length;

      // Generate a unique ID for the new marker.
      final String markerIdVal = '${pm.polygonId}_marker_$pointIndex';

      // Create the new marker.
      Marker marker = Marker(
        icon: icon,
        markerId: MarkerId(markerIdVal),
        position: point,
        draggable: true, // Enable marker dragging.
        onDrag: (newPosition) {
          _updatePolygonPoint(
            markerIdVal,
            LatLng(
              newPosition.latitude,
              newPosition.longitude,
            ),
          ); // Update the position of the marker
        },
        onDragEnd: (newPosition) {
          _updatePolygonPoint(
            markerIdVal,
            LatLng(
              newPosition.latitude,
              newPosition.longitude,
            ),
          ); // Update the position of the marker
        },
        // Configure other marker options here.
      );

      // Add the point to the polygon.
      pm.polygon = Polygon(
        consumeTapEvents: true,
        polygonId: PolygonId(pm.polygonId),
        points: List.from(pm.polygon.points)..add(point),
        strokeWidth: 2,
        strokeColor: FFAppState().selectedColor,
        fillColor: FFAppState().selectedColor.withOpacity(0.15),
        onTap: () {
          _onPolygonTapped(pm.polygonId);
        },
      );

      // Add the marker to the list.
      pm.markers.add(marker);

      // Update _selectedPolygonMarker to be the updated polygon marker.
      _polygonMarkers
          .removeWhere((element) => element.polygonId == pm.polygonId);
      _polygonMarkers.add(pm);
      _selectedPolygonMarker = pm;
    });
  }

  void _addCircleMarker(LatLng center) async {
    var icon = await getMarkerIcon(
        IconData(
          circleandpolygonmarkerIcon!.icon!.codePoint,
          fontFamily: circleandpolygonmarkerIcon!.icon!.fontFamily,
          fontPackage: circleandpolygonmarkerIcon!.icon!.fontPackage,
        ),
        20);

    CircleMarker? cm;

    if (_selectedCircle != null && _currentMode == Mode.Editing) {
      cm = _selectedCircle!;
    } else {
      final String circleIdVal = generateUniqueId();

      // The radius in meters.
      double radius = 100;

      Marker centerMarker = Marker(
        icon: icon,
        markerId: MarkerId('center_$circleIdVal'),
        position: latlng.LatLng(center.latitude, center.longitude),
        draggable: true,
        onDrag: (dragEndPosition) {
          dragging = true;
          _updateCircleCenter(
            circleIdVal,
            LatLng(dragEndPosition.latitude, dragEndPosition.longitude),
          );
        },
        onDragEnd: (dragEndPosition) {
          dragging = false;
          //   // Update the position of the edge marker based on the new center
          LatLng newEdgePosition = _calculateEdgePosition(
              dragEndPosition,
              _selectedCircle!.edgeMarker.position,
              _selectedCircle!.circle.radius);
          //add delay of 1 second

          CircleMarker cm = CircleMarker(
              circle: _selectedCircle!.circle.copyWith(
                centerParam: dragEndPosition,
              ),
              centerMarker: _selectedCircle!.centerMarker
                  .copyWith(positionParam: dragEndPosition),
              edgeMarker: _selectedCircle!.edgeMarker.copyWith(
                  positionParam: latlng.LatLng(
                      newEdgePosition.latitude, newEdgePosition.longitude)));

          circleUndoStack.add(cm);
          _updateCircleCenter(
            circleIdVal,
            LatLng(dragEndPosition.latitude, dragEndPosition.longitude),
          );
        },
      );

      LatLng cnt = _calculateEdgePosition(
          latlng.LatLng(center.latitude, center.longitude), null, radius);

      Marker edgeMarker = Marker(
        icon: icon,
        markerId: MarkerId('edge_$circleIdVal'),
        position: latlng.LatLng(cnt.latitude, cnt.longitude),
        draggable: true,
        onDrag: (dragEndPosition) {
          dragging = true;
          _updateCircleRadius(
            circleIdVal,
            LatLng(dragEndPosition.latitude, dragEndPosition.longitude),
          );
        },
        onDragEnd: (dragEndPosition) {
          dragging = false;
          CircleMarker cm = CircleMarker(
            circle: _selectedCircle!.circle,
            centerMarker: _selectedCircle!.centerMarker,
            edgeMarker: _selectedCircle!.edgeMarker.copyWith(
                positionParam: latlng.LatLng(
                    dragEndPosition.latitude, dragEndPosition.longitude)),
          );

          circleUndoStack.add(cm);
          _updateCircleRadius(
            circleIdVal,
            LatLng(dragEndPosition.latitude, dragEndPosition.longitude),
          );
          print('dragEndPosition $dragEndPosition');
          //   // Update the position of the edge marker based on the new center
          // LatLng newEdgePosition = _calculateEdgePosition(dragEndPosition, _selectedCircle!.circle.radius);

          // configureCircleMode();
        },
      );

      Circle circle = Circle(
        consumeTapEvents: true,
        circleId: CircleId(circleIdVal),
        center: latlng.LatLng(center.latitude, center.longitude),
        radius: radius, // default radius is 1km
        strokeWidth: 2,
        strokeColor: FFAppState().selectedColor,
        fillColor: FFAppState().selectedColor.withOpacity(0.15),
        onTap: () {
          _onCircleTapped(circleIdVal);
        },
      );

      cm = CircleMarker(
        circle: circle,
        centerMarker: centerMarker,
        edgeMarker: edgeMarker,
      );

      _circleMarkers.add(cm);
    }

    setState(() {
      _selectedCircle = cm;
      _currentMode = Mode.Editing;
    });
  }

  void _updateCircleCenter(String id, LatLng center) async {
    int circleIndex =
        _circleMarkers.indexWhere((cm) => cm.circle.circleId.value == id);
    if (circleIndex != -1) {
      if (mounted) {
        CircleMarker oldCM = _selectedCircle!;

        // Calculate the distance between the old center and edge marker
        double oldRadius = oldCM.circle.radius;
        if (!dragging) {
          print(
              'updating circle from center marker: oldEdgePosition ${oldCM.edgeMarker.position}');
        }
        // Calculate the new position for the edge marker based on the new center
        LatLng newEdgePosition = _calculateEdgePosition(
            latlng.LatLng(center.latitude, center.longitude),
            oldCM.edgeMarker.position,
            oldRadius);

        // Update the properties of the old CircleMarker
        oldCM.circle = oldCM.circle.copyWith(
            centerParam: latlng.LatLng(center.latitude, center.longitude));
        oldCM.centerMarker = oldCM.centerMarker.copyWith(
            positionParam: latlng.LatLng(center.latitude, center.longitude));
        oldCM.edgeMarker = oldCM.edgeMarker.copyWith(
            positionParam: latlng.LatLng(
                newEdgePosition.latitude, newEdgePosition.longitude));

        // Update _selectedCircle to be the updated CircleMarker

        _circleMarkers.removeAt(circleIndex);

        setState(() {});
        if (!dragging) {
          print(
              'updating circle from center marker: oldEdgePosition ${oldCM.edgeMarker.position}');
          print(
              'updating circle from center marker: newEdgePosition $newEdgePosition');
          await Future.delayed(Duration(milliseconds: 200));
          setState(() {});
        }
        _selectedCircle = oldCM;
        _circleMarkers.add(_selectedCircle!);
      }
    }
  }

  void _updateCircleRadius(String id, LatLng edgePosition) async {
    int circleIndex =
        _circleMarkers.indexWhere((cm) => cm.circle.circleId.value == id);
    if (circleIndex != -1) {
      if (mounted) {
        CircleMarker oldCM = _selectedCircle!;
        if (!dragging) {
          print(
              'updating circle from center marker: oldEdgePosition ${oldCM.edgeMarker.position}');
        }
        // Calculate the new radius based on the distance between the center and edge marker
        double newRadius = _calculateDistance(
          LatLng(oldCM.circle.center.latitude, oldCM.circle.center.longitude),
          edgePosition,
        );

        // print('New Radius: $newRadius');

        // Calculate the new position for the edge marker based on the new radius and center position
        LatLng newEdgePosition = _calculateEdgePosition(
          latlng.LatLng(
              oldCM.circle.center.latitude, oldCM.circle.center.longitude),
          latlng.LatLng(edgePosition.latitude, edgePosition.longitude),
          newRadius,
        );
        print(
            ' values going into newedgepostion ${latlng.LatLng(edgePosition.latitude, edgePosition.longitude)}, ${latlng.LatLng(oldCM.circle.center.latitude, oldCM.circle.center.longitude)}');

        // Update the properties of the old CircleMarker
        oldCM.circle = oldCM.circle.copyWith(radiusParam: newRadius);
        // oldCM.centerMarker = oldCM.centerMarker.copyWith(positionParam: latlng.LatLng(center.latitude, center.longitude));
        oldCM.edgeMarker = oldCM.edgeMarker.copyWith(
            positionParam: latlng.LatLng(
                newEdgePosition.latitude, newEdgePosition.longitude));

        // Update _selectedCircle to be the updated CircleMarker

        _circleMarkers.removeAt(circleIndex);

        setState(() {});
        if (!dragging) {
          print(
              'updating circle from center marker: oldEdgePosition ${oldCM.edgeMarker.position}');
          print(
              'updating circle from center marker: newEdgePosition $newEdgePosition');
          await Future.delayed(Duration(milliseconds: 200));
          setState(() {});
        }
        _selectedCircle = oldCM;
        _circleMarkers.add(_selectedCircle!);
      }
    }
  }

// Helper method to calculate the distance between two LatLng points.
  double _calculateDistance(LatLng point1, LatLng point2) {
    num distance = mt.SphericalUtil.computeDistanceBetween(
      mt.LatLng(point1.latitude, point1.longitude),
      mt.LatLng(point2.latitude, point2.longitude),
    );

    return distance.toDouble();
  }

  LatLng _calculateEdgePosition(
      latlng.LatLng center, latlng.LatLng? lastEdgePosition, double radius) {
    // Convert LatLng to maps' LatLng
    mt.LatLng start = mt.LatLng(center.latitude, center.longitude);

    double bearing;
    if (lastEdgePosition != null) {
      mt.LatLng end =
          mt.LatLng(lastEdgePosition.latitude, lastEdgePosition.longitude);
      // Calculate bearing
      bearing = mt.SphericalUtil.computeHeading(start, end).toDouble();
    } else {
      // Use a default bearing (like 0 degrees)
      bearing = 0.0;
    }

    // Calculate new edge position
    mt.LatLng newEdgePositionMaps =
        mt.SphericalUtil.computeOffset(start, radius, bearing);

    // Convert back to latlng.LatLng and return
    return LatLng(newEdgePositionMaps.latitude, newEdgePositionMaps.longitude);
  }

  void _addMarker(String id, LatLng location) async {
    IconData? newIcon = Icons.location_on_rounded;
    var icon = await getMarkerIcon(newIcon, 40);
    setState(() {
      MarkerMarker markerMarker;

      if (_selectedMarker != null && _currentMode == Mode.Editing) {
        markerMarker = _selectedMarker!;
        _markerMarkers.remove(markerMarker);
        markerMarker.marker = markerMarker.marker.copyWith(
            positionParam:
                latlng.LatLng(location.latitude, location.longitude));
      } else {
        markerMarker = MarkerMarker(
          marker: Marker(
            icon: icon,
            consumeTapEvents: true,
            visible: true,
            markerId: MarkerId(id),
            position: latlng.LatLng(location.latitude, location.longitude),
            onTap: () => _handleMarkerTap(id),
          ),
          color: FFAppState().selectedColor,
        );

        _currentMode = Mode.Editing;
        _selectedMarker = markerMarker;
      }

      _markerMarkers.add(markerMarker);
      configureMarkerMode();
    });
  }

//on tapp methods for the different types of geofences
  void _onPolygonTapped(String polygonId) {
    debugPrint('Tapped polygon $polygonId');
    if (geoFencetype == 'Polygon') {
      var pm = _polygonMarkers
          .lastWhere((element) => element.polygonId == polygonId);
      debugPrint('pm:$pm');
      setState(() {
        _selectedPolygonMarker = pm;

        _currentMode = Mode.Editing;
        FFAppState().selectedColor =
            _selectedPolygonMarker!.polygon.strokeColor;
        FFAppState().label = _selectedPolygonMarker!.label ??
            _selectedPolygonMarker!.polygon.polygonId.value;
        // FFAppState().selectedColor = _selectedPolygonMarker!.color!;

        FFAppState().AssignedUsersList = _selectedPolygonMarker!.taggedStaff;

        configurePolygonMode();
      });
    }
  }

  void _onCircleTapped(String circleId) {
    if (geoFencetype == 'Circle') {
      setState(() {
        _selectedCircle = _circleMarkers
            .lastWhere((element) => element.circle.circleId.value == circleId);
        _currentMode = Mode.Editing;
        FFAppState().selectedColor = _selectedCircle!.circle.strokeColor;
        FFAppState().label =
            _selectedCircle!.label ?? _selectedCircle!.circle.circleId.value;
        // FFAppState().selectedColor = _selectedCircle!.color!;
        configureCircleMode();
        // print('${circleUndoStack.length}');
        // print('circle tapped: ${_selectedCircle!.circle.center} , ${_selectedCircle!.circle.radius}');
        // print('_circleMarkers.length = ${_circleMarkers.length}');
        // print('circleUndoStack.length = ${circleUndoStack.length}');
        // for (var i = 0; i < circleUndoStack.length; i++) {
        //   print(
        //       'circleUndoStack[$i] = circle: ${circleUndoStack[i].circle} radius ${circleUndoStack[i].circle.radius} center ${circleUndoStack[i].circle.center} , centerMarker poistion: ${circleUndoStack[i].centerMarker.position} , edgeMarker position: ${circleUndoStack[i].edgeMarker.position}');
        // }
      });
    }
  }

  void _handleMarkerTap(String markerId) {
    //display the marker info here
    if (geoFencetype == 'Marker') {
      setState(() {
        _selectedMarker = _markerMarkers
            .lastWhere((element) => element.marker.markerId.value == markerId);
        _currentMode = Mode.Editing;
        FFAppState().selectedColor = _selectedMarker!.color!;
        FFAppState().label = _selectedMarker!.label ?? 'Marker: $markerId';
        FFAppState().AssignedUsersList = _selectedMarker!.taggedStaff;
        configureMarkerMode();
      });
    }
  }

  void _updatePolygonPoint(String markerIdVal, LatLng newPosition) {
    // debugPrint('Updating polygon point $markerIdVal to $newPosition');
    // Find the corresponding polygon marker.

    for (var pm in _polygonMarkers) {
      if (pm.polygonId == _selectedPolygonMarker!.polygonId) {
        List<latlng.LatLng> updatedPoints = List.from(pm.polygon.points);

        // Find the index of the marker with the given ID.
        var markerIndex = pm.markers
            .indexWhere((marker) => marker.markerId.value == markerIdVal);

        // If the marker with the given ID was found, update the corresponding point.
        if (markerIndex != -1) {
          updatedPoints[markerIndex] =
              latlng.LatLng(newPosition.latitude, newPosition.longitude);
        } else {
          // Handle the case where the marker was not found, if needed.
        }

        setState(() {
          // Update the polygon with the new points list.
          pm.polygon = Polygon(
            consumeTapEvents: true,
            polygonId: PolygonId(pm.polygonId),
            points: updatedPoints,
            strokeWidth: 2,
            strokeColor: pm.polygon.strokeColor,
            fillColor: pm.polygon.fillColor.withOpacity(0.15),
            onTap: () {
              _onPolygonTapped(pm.polygonId);
            },
          );

          // Also update the position of the corresponding marker.
          for (var m in pm.markers) {
            if (m.markerId.value == markerIdVal) {
              m = m.copyWith(
                  positionParam: latlng.LatLng(
                      newPosition.latitude, newPosition.longitude));
            }
          }
        });
        break;
      }
    }
  }

  void changeColor() {
    if (geoFencetype == 'Polygon') {
      _updatePolygonColor();
    }
    if (geoFencetype == 'Circle') {
      _updateCircleColor();
    }
    if (geoFencetype == 'Marker') {
      _updateMarkerColor();
    }
  }

// update Polygon Color
  void _updatePolygonColor() async {
    var icon = await getMarkerIcon(
        IconData(circleandpolygonmarkerIcon!.icon!.codePoint,
            fontFamily: circleandpolygonmarkerIcon!.icon!.fontFamily,
            fontPackage: circleandpolygonmarkerIcon!.icon!.fontPackage),
        20);
    setState(() {
      _selectedPolygonMarker!.polygon = _selectedPolygonMarker!.polygon
          .copyWith(
              strokeColorParam: FFAppState().selectedColor,
              fillColorParam: FFAppState().selectedColor.withOpacity(0.15));

      _polygonMarkers.remove(_polygonMarkers.lastWhere(
          (element) => element.polygonId == _selectedPolygonMarker!.polygonId));

      List<Marker> updatedMarkers = _selectedPolygonMarker!.markers
          .map((m) => m.copyWith(iconParam: icon))
          .toList();
      _selectedPolygonMarker!.markers = updatedMarkers;

      _polygonMarkers.add(_selectedPolygonMarker!);
    });
  }

  // update Circle Color
  void _updateCircleColor() async {
    var icon = await getMarkerIcon(
        IconData(circleandpolygonmarkerIcon!.icon!.codePoint,
            fontFamily: circleandpolygonmarkerIcon!.icon!.fontFamily,
            fontPackage: circleandpolygonmarkerIcon!.icon!.fontPackage),
        20);

    setState(() {
      _selectedCircle!.circle = _selectedCircle!.circle.copyWith(
          strokeColorParam: FFAppState().selectedColor,
          fillColorParam: FFAppState().selectedColor.withOpacity(0.15));
      _selectedCircle!.centerMarker =
          _selectedCircle!.centerMarker.copyWith(iconParam: icon);
      _selectedCircle!.edgeMarker =
          _selectedCircle!.edgeMarker.copyWith(iconParam: icon);

      _circleMarkers.remove(_circleMarkers.lastWhere((element) =>
          element.circle.circleId.value ==
          _selectedCircle!.circle.circleId.value));

      _circleMarkers.add(_selectedCircle!);
    });
  }

// update Marker icon Color
  void _updateMarkerColor() async {
    IconData? newIcon = Icons.location_on_rounded;
    var icon = await getMarkerIcon(newIcon, 40);
    setState(() {
      _selectedMarker!.marker =
          _selectedMarker!.marker.copyWith(iconParam: icon);
      _markerMarkers.remove(_markerMarkers.lastWhere((element) =>
          element.marker.markerId.value ==
          _selectedMarker!.marker.markerId.value));
      _markerMarkers.add(_selectedMarker!);
    });
  }

  void _updateSelectedGeofenceTypeProperties() {
    if (geoFencetype == 'Polygon') {
      _updatePolygonProperties();
    }
    if (geoFencetype == 'Circle') {
      _updateCircleProperties();
    }
    if (geoFencetype == 'Marker') {
      _updateMarkerProperties();
    }
  }

  _updatePolygonProperties() {
    setState(() {
      //update all _selectedPolygonMarker properties
      _selectedPolygonMarker!.polygon =
          _selectedPolygonMarker!.polygon.copyWith(
        strokeColorParam: FFAppState().selectedColor,
        fillColorParam: FFAppState().selectedColor.withOpacity(0.15),
      );
      _selectedPolygonMarker!.markers = _selectedPolygonMarker!.markers;
      _selectedPolygonMarker!.label = FFAppState().label;
      _selectedPolygonMarker!.taggedStaff = FFAppState().AssignedUsersList;
      _selectedPolygonMarker!.color = FFAppState().selectedColor;
      _polygonMarkers.remove(_polygonMarkers.lastWhere(
          (element) => element.polygonId == _selectedPolygonMarker!.polygonId));
      _polygonMarkers.add(_selectedPolygonMarker!);
    });
  }

  _updateCircleProperties() {
    setState(() {
      //update all _selectedCircle properties
      _selectedCircle!.circle = _selectedCircle!.circle.copyWith(
        strokeColorParam: FFAppState().selectedColor,
        fillColorParam: FFAppState().selectedColor.withOpacity(0.15),
      );
      _selectedCircle!.label = FFAppState().label;
      _selectedCircle!.taggedStaff = FFAppState().AssignedUsersList;
      _selectedCircle!.color = FFAppState().selectedColor;
      _circleMarkers.remove(_circleMarkers.lastWhere((element) =>
          element.circle.circleId.value ==
          _selectedCircle!.circle.circleId.value));
      _circleMarkers.add(_selectedCircle!);
    });
  }

  _updateMarkerProperties() {
    setState(() {
      //update all _selectedMarker properties
      _selectedMarker!.marker = _selectedMarker!.marker.copyWith(
        //TODO add functionality to change icon
        // iconParam: FFAppState().selectedIcon,
        infoWindowParam: InfoWindow(
          title: FFAppState().label,
          snippet: FFAppState().AssignedUsersList.toString(),
        ),
      );
      //TODO update logic to handle MarkerMarkers instead of Markers
      _selectedMarker!.label = FFAppState().label;
      _selectedMarker!.taggedStaff = FFAppState().AssignedUsersList;
      _selectedMarker!.color = FFAppState().selectedColor;
      _markerMarkers.remove(_markerMarkers.lastWhere((element) =>
          element.marker.markerId.value ==
          _selectedMarker!.marker.markerId.value));
      _markerMarkers.add(_selectedMarker!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: // create a floating action button to toggle between edit and add mode
          PointerInterceptor(
        intercepting: true,
        child: FloatingActionButton(
          onPressed: () {
            if (_currentMode == Mode.Adding) {
              _currentMode = Mode.Editing;
            } else {
              _selectedCircle = null;
              _selectedMarker = null;
              _selectedPolygonMarker = null;
              _currentMode = Mode.Adding;
              if (geoFencetype == 'Polygon') {
                configurePolygonMode();
              } else if (geoFencetype == 'Circle') {
                configureCircleMode();
              } else if (geoFencetype == 'Marker') {
                configureMarkerMode();
              }
            }
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              _currentMode == Mode.Adding ? Icons.edit : Icons.add,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 30,
            ),
          ),
          backgroundColor: FlutterFlowTheme.of(context).primary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: _mapStyleLoaded
          ? Stack(children: [
              GoogleMap(
                  zoomControlsEnabled: false,
                  initialCameraPosition: CameraPosition(
                    target: latlng.LatLng(
                        widget.initialCamaraPosition!.latitude,
                        widget.initialCamaraPosition!.longitude),
                    zoom: 16,
                  ),
                  mapType: MapType.normal,
                  markers: _getMarkers(),
                  circles: _getCircles(),
                  polygons: _getPolygons(),
                  myLocationEnabled: true,
                  mapToolbarEnabled: false,
                  onMapCreated: _onMapCreated,
                  onTap: (point) {
                    if (geoFencetype == 'Polygon') {
                      print('creating polygon');
                      _addPointToPolygon(point);
                    } else if (geoFencetype == 'Circle') {
                      //add Circle
                      print('creating circle');
                      _addCircleMarker(LatLng(point.latitude, point.longitude));
                    } else if (geoFencetype == 'Marker') {
                      //add marker
                      print('creating Marker');
                      _addMarker(generateUniqueId(),
                          LatLng(point.latitude, point.longitude));
                    }
                  }),
              Align(
                  alignment: AlignmentDirectional(0, 1),
                  child: PointerInterceptor(
                      intercepting: true,
                      debug: true,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 100,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            FlutterFlowIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 25,
                              borderWidth: 1,
                              buttonSize: 50,
                              icon: Icon(
                                Icons.delete_forever_outlined,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 25,
                              ),
                              onPressed: () async {
                                var confirmDialogResponse =
                                    await showDialog<bool>(
                                          context: context,
                                          builder: (alertDialogContext) {
                                            return PointerInterceptor(
                                              intercepting: true,
                                              child: AlertDialog(
                                                title: Text('Delete Item'),
                                                content: Text(
                                                    'Are you sure you want to delete this item?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            alertDialogContext,
                                                            false),
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      Navigator.pop(
                                                          alertDialogContext,
                                                          true);
                                                      setState(() {
                                                        //logic to delete the selected polygon, circle, or marker
                                                        if (_selectedPolygonMarker !=
                                                            null) {
                                                          _polygons.remove(
                                                              _selectedPolygonMarker!
                                                                  .polygon);
                                                          _polygonMarkers.remove(
                                                              _selectedPolygonMarker);
                                                        }
                                                        if (_selectedMarker !=
                                                            null) {
                                                          _markers.remove(
                                                              _selectedMarker);
                                                        }
                                                        if (_selectedCircle !=
                                                            null) {
                                                          _circles.remove(
                                                              _selectedCircle);
                                                        }
                                                      });
                                                    },
                                                    child: Text('Confirm'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ) ??
                                        false;
                              },
                            ),
                            FlutterFlowIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 25,
                              borderWidth: 1,
                              buttonSize: 50,
                              icon: FaIcon(
                                FontAwesomeIcons.userTag,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 25,
                              ),
                              onPressed: () async {
                                //this assigns users to the geoFence when saved we get the values from the FFAppState
                                await showModalBottomSheet(
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (context) {
                                    return Padding(
                                      padding:
                                          MediaQuery.of(context).viewInsets,
                                      child: SelectStaffWidget(),
                                    );
                                  },
                                ).then((value) => setState(() {}));
                              },
                            ),
                            FlutterFlowIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 30,
                              borderWidth: 1,
                              buttonSize: 50,
                              icon: FaIcon(
                                FontAwesomeIcons.hashtag,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 30,
                              ),
                              onPressed: () async {
                                //used to add a label to the geoFence when saved we get the values from the FFAppState
                                await showModalBottomSheet(
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (context) {
                                    return Padding(
                                      padding:
                                          MediaQuery.of(context).viewInsets,
                                      child: EnterFieldWidget(
                                        label: FFAppState().label,
                                      ),
                                    );
                                  },
                                ).then((value) => setState(() {}));
                              },
                            ),
                            FlutterFlowIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 35,
                              borderWidth: 1,
                              buttonSize: 60,
                              icon: Icon(
                                icons[currentIconIndex],
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 35,
                              ),
                              onPressed: () async {
                                HapticFeedback.selectionClick();
                                //need to set the geofence type here, this switches the editing mode from polygon,circle to marker

                                // Change the icon when button pressed
                                changeIcon();
                              },
                            ),
                            //this is the color picker button
                            Container(
                              width: 50,
                              height: 50,
                              child: custom_widgets.MyColorPickerIconButton(
                                width: 50,
                                height: 50,
                                colorset: Colors.transparent,
                                changeColor: changeColor,
                              ),
                            ),
                            //this is how the data is being saved to firebase
                            FlutterFlowIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 25,
                              borderWidth: 1,
                              buttonSize: 50,
                              icon: Icon(
                                Icons.save,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 25,
                              ),
                              onPressed: () async {
                                final geoFencesCreateData = {
                                  ...createGeoFencesRecordData(
                                    type: geoFencetype,
                                    label: FFAppState().label,
                                    color: color.toString(),
                                    dateCreated: getCurrentTimestamp,
                                    createdByUser: currentUserReference,
                                  ),
                                  'tagged_staff':
                                      FFAppState().AssignedUsersList,
                                };
                                await GeoFencesRecord.createDoc(widget.toDoRef!)
                                    .set(geoFencesCreateData);
                                HapticFeedback.selectionClick();
                                await showDialog(
                                  context: context,
                                  builder: (alertDialogContext) {
                                    return AlertDialog(
                                      title: Text('Saving...'),
                                      content: Text('Fence has been saved!'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(alertDialogContext),
                                          child: Text('Ok'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                setState(() => FFAppState().dummyState =
                                    FFAppState().dummyState + 1);
                              },
                            ),
                            FlutterFlowIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 25,
                              borderWidth: 1,
                              buttonSize: 50,
                              icon: Icon(
                                Icons.undo,
                                color: FlutterFlowTheme.of(context).primaryText,
                                size: 25,
                              ),
                              onPressed: () async {
                                undo = true;

                                if (geoFencetype == 'Polygon') {
                                  _selectedPolygonMarker!.polygon.points
                                      .removeLast();
                                  _selectedPolygonMarker!.markers.removeLast();
                                  _polygonMarkers.removeWhere((element) =>
                                      element.polygonId ==
                                      _selectedPolygonMarker!.polygonId);
                                  _polygonMarkers.add(_selectedPolygonMarker!);
                                  if (_selectedPolygonMarker!
                                          .polygon.points.length ==
                                      0) {
                                    _polygonMarkers.removeWhere((element) =>
                                        element.polygonId ==
                                        _selectedPolygonMarker!.polygonId);
                                    _currentMode = Mode.Adding;
                                  }
                                } else if (geoFencetype == 'Circle') {
                                  debugPrint('undoing circle');
                                  print(
                                      'circleUndoStack length: ${circleUndoStack.length}');
                                  for (int i = 0;
                                      i < circleUndoStack.length;
                                      i++) {
                                    print(
                                        'circleUndoStackItem: $i radius: ${circleUndoStack[i].circle.radius} center position: ${circleUndoStack[i].centerMarker.position} edge position: ${circleUndoStack[i].edgeMarker.position}');
                                  }

                                  setState(() {
                                    _circleMarkers.removeWhere((element) =>
                                        element.circle.circleId ==
                                        _selectedCircle!.circle.circleId);
                                    circleUndoStack.removeLast();
                                  });
                                  await Future.delayed(
                                      Duration(milliseconds: 100));

                                  print(
                                      '_selectedCircle: radius: ${_selectedCircle!.circle.radius} center position: ${_selectedCircle!.centerMarker.position} edge position: ${_selectedCircle!.edgeMarker.position}');

                                  CircleMarker _newselectedCircle =
                                      circleUndoStack.last;

                                  print(
                                      '_newselectedCircle: radius: ${_newselectedCircle.circle.radius} center position: ${_newselectedCircle.centerMarker.position} edge position: ${_newselectedCircle.edgeMarker.position}');

                                  // Create a new circle marker with the updated center and edge markers
                                  CircleMarker newCircleMarker = CircleMarker(
                                    centerMarker:
                                        _newselectedCircle.centerMarker.clone(),
                                    edgeMarker:
                                        _newselectedCircle.edgeMarker.clone(),
                                    circle: _newselectedCircle.circle.clone(),
                                    // Copy other properties of the circle marker
                                  );
                                  //set new circle marker as selected
                                  _selectedCircle = newCircleMarker;
                                  _circleMarkers.add(newCircleMarker);

                                  if (circleUndoStack.length == 1) {
                                    _circleMarkers.remove(_selectedCircle);
                                    _currentMode = Mode.Adding;
                                  }
                                } else if (geoFencetype == 'Marker') {
                                  _markers.removeWhere((element) =>
                                      element.markerId ==
                                      _selectedMarker!.marker.markerId);
                                }
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      )))
            ])
          : SizedBox(),
    );
  }
}

class PolygonMarker {
  String polygonId;
  Polygon polygon;
  List<Marker> markers;
  List<Marker>? midMarkers;
  List<DocumentReference> taggedStaff;
  String? label;
  Color? color;

  PolygonMarker({
    required this.polygonId,
    required this.polygon,
    required this.markers,
    this.midMarkers,
    this.color,
    this.taggedStaff = const [],
    this.label = '',
  });
}

class CircleMarker {
  Circle circle;
  Marker centerMarker;
  Marker edgeMarker;
  List<DocumentReference> taggedStaff;
  String? label;
  Color? color;

  CircleMarker({
    required this.circle,
    required this.centerMarker,
    required this.edgeMarker,
    this.color,
    this.taggedStaff = const [],
    this.label,
  });

  @override
  toString() {
    return 'CircleMarker: CircleShape: ${circle.circleId.value} - centermarker: ${centerMarker.markerId.value}-  edgemarker: ${edgeMarker.markerId.value}';
  }
}

class MarkerMarker {
  Marker marker;
  List<DocumentReference> taggedStaff;
  String? label;
  Color? color;

  MarkerMarker({
    required this.marker,
    this.color,
    this.taggedStaff = const [],
    this.label,
  });
}

enum Mode {
  Adding,
  Editing,
}
