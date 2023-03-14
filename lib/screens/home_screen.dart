import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';

//import 'package:location_permissions/location_permissions.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var deviceId; //연결을 위한 임시 id
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription? subscription; //검색 중지를 위한 변수

  final nameList = <String>{}; // LinkedHashSet 중복불가 순서있음. 블루투스 연결 가능 목록.

  //BLE 디바이스의 Service UUID , characteristicId를 사용해서 응답값을 읽어오는 부분
  // final characteristic = QualifiedCharacteristic(serviceId: serviceUuid, characteristicId: characteristicUuid, deviceId: foundDeviceId);
  // final response = await flutterReactiveBle.readCharacteristic(characteristic);

  //권한 요청
  //왜 처음에 확인을 하면 바로 안될까? 나갔다 오고 다시 눌러줘야됨 ->위치 권한 따로 만듦
  void requestGranted() async {
    // List<Permission> statuses = await [
    //   Permission.location, //위치
    //   Permission.bluetooth, //ios 근처 기기 연결 기기간 상대적 위치 파악
    //   Permission.bluetoothConnect, //android
    //   Permission.bluetoothScan, //스캔
    // ];
    //
    // for(var permisson in statuses){
    //   if(await permisson.status.isDenied){ //권한이 거부되었다면 요청
    //     permisson.request();
    //   }
    // }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth, //ios 근처 기기 연결 기기간 상대적 위치 파악 //거부됨-> 안드로이드라서?
      Permission.bluetoothConnect, //android
      Permission.bluetoothScan, //스캔
      //Permission.location, //위치
    ].request();
    print(
        'hhhhhhhh${statuses}'); //{Permission.location: PermissionStatus.granted, Permission.bluetooth: PermissionStatus.denied,..}
  }

  void startScan() {
    requestGranted();
    //subscription= flutterReactiveBle as StreamSubscription?;

    //위치 권한 나타나긴하는데...... 한번물어보고 오류 같은거 뜸
    // bool permGranted = false;
    // PermissionStatus permission;
    // if (Platform.isAndroid) {
    //   permission = await LocationPermissions().requestPermissions();
    //   if (permission == PermissionStatus.granted) permGranted = true;
    // } else if (Platform.isIOS) {
    //   permGranted = true;
    // }
    // print(permGranted);

    //상태 관찰
    flutterReactiveBle.statusStream.listen((status) {
      if (BleStatus.poweredOff == status) {
        print("sssssspoweredOff");
      } else if (BleStatus.ready == status) {
        print("ssssssready");
      } else if (BleStatus.unauthorized == status) {
        print("ssssssunauthorized");
      }

      //스캔 검색
      flutterReactiveBle
          .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
          .where((event) => event.name.contains("VRing")) //필터링
          .listen((device) {
            //같은 기기 중복 문제
            print(
                'detect ${device.name} // device id: ${device.id} // device.rssi: ${device.rssi}');

            //목록에 추가
            setState(() {
              nameList.add(device.name);
              print("nnnnnnnn ${nameList.length}"); //set으로 중복 해결
            });

            //deviceId = device.id;
          });
    }, onError: (e) {
      print("error!!!!!!!!!!!${e.toString()}");
    });
  }

  //검색 중지 -안됨..?
  // void stopScan() {
  //   subscription?.cancel();
  //
  //   print("ssssscancel??");
  //   subscription = null;
  // }

  //연결 설정
  // void startConnect() {
  //   flutterReactiveBle
  //       .connectToDevice(
  //     id: foundDeviceId,
  //     servicesWithCharacteristicsToDiscover: {
  //       serviceId: [char1, char2],
  //     },
  //     connectionTimeout: const Duration(seconds: 2),
  //   )
  //       .listen((connectionState) {
  //     // Handle connection state updates
  //   }, onError: (Object error) {
  //     // Handle a possible error
  //   });
  // }

  //Future<Position>
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission; //여기서 권한체크를 따로 해줘야되나??

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission(); //권한 체크
    if (permission == LocationPermission.denied) {
      //거부되면 요청
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        //그래도 거부되면
        return Future.error('Location permissions are denied');
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    //위도, 경도 출력
    print("holeeee ${position.latitude.toString()}");
    print("holeeee ${position.longitude.toString()}");

    var lat = position.latitude.toString();
    var lon = position.longitude.toString();

    Map<String, String> myHeaders = {
      "X-NCP-APIGW-API-KEY-ID": "di37sadm10",
      // 개인 클라이언트 아이디
      "X-NCP-APIGW-API-KEY": "jzp60gFrWh8gnFk0OZhEdrjMj2LptXLVMBaVW3Ir"
      // 개인 시크릿 키
    };

    //128.2439084,36.4938906
    Response response = await get(
      Uri.parse(
          "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?request=coordsToaddr&coords=${lon},${lat}&sourcecrs=epsg:4326&orders=admcode,legalcode,addr,roadaddr&output=json"),
      headers: myHeaders,
    );
    print("holeeee ${response.body}");
    var si= jsonDecode(response.body)["results"][1]['region']['area1']['name']; //서울특별시
    var gu= jsonDecode(response.body)["results"][1]['region']['area2']['name']; //강서구

    print("holeeee ${si}");
    print("holeeee ${gu}");
    return position;
    // return await Geolocator.getCurrentPosition(
    //   desiredAccuracy: LocationAccuracy.high,
    // );
  }

  @override
  void initState() {
    super.initState();
    Future<Position> position = _determinePosition();
    print("holeee000e ${position}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          //현재 위치 맵에 찍히도록
          Text("jjj"),

          GestureDetector(
            onTap: startScan,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.green,
              ),
            ),
          ),
          //리스트
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.vertical,
              itemCount: nameList.length,
              itemBuilder: (BuildContext context, int index) {
                return Text(nameList.elementAt(index)); //리턴을 해야 보인다
              },
              separatorBuilder: (BuildContext context, int index) => SizedBox(
                height: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
