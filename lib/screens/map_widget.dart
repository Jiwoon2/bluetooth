import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class NaverMapTest extends StatefulWidget {
  final double lat, lon;

  const NaverMapTest({
    super.key,
    required this.lat,
    required this.lon,
  });

  @override
  State<NaverMapTest> createState() => _NaverMapTestState();

}

class _NaverMapTestState extends State<NaverMapTest> {
  Completer<NaverMapController> _controller = Completer();
  MapType _mapType = MapType.Basic;

  late double lat, lon;

  @override
  void initState() {
    super.initState();
    lat = widget.lat; //넘겨받은 값 할당
    lon = widget.lon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NaverMap Test')),
      body: Container(
        child: NaverMap(
          initialCameraPosition: CameraPosition( //카메라 초기 위치-> 현재 위치로 지정
            target: LatLng(lat, lon),
          ),
          onMapCreated: onMapCreated,
          //initLocationTrackingMode: ,
           markers: [
             Marker(markerId: "markerId", position: LatLng(lat, lon),
             alpha: 1.0,
             captionColor: Colors.red, //캡션은 글자색
               captionText: "현재  위치",
             iconTintColor: Colors.green, //마커 색상
             flat: false,
             ),
           ],
          mapType: _mapType,
        ),
      ),
    );
  }

  void onMapCreated(NaverMapController controller) {
    if (_controller.isCompleted) _controller = Completer();
    _controller.complete(controller);
  }
}

