import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'dart:io';

import 'package:bluetooth/model/ReverseGC.dart';
import 'package:bluetooth/screens/map_widget.dart';
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
  late double lat, lon; //위도, 경도
  late Future<String> position; //현재 위치
  bool isMap = false;

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
    setState(() {
      isMap= false;
    });

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
  Future<String> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission; //여기서 위치 권한체크를 따로 해주기

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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

    //위도, 경도 출력 37.5608604 126.8293889
    print("holeeee ${position.latitude.toString()}");
    print("holeeee ${position.longitude.toString()}");

    lat = position.latitude;
    lon = position.longitude;

    Map<String, String> myHeaders = {
      "X-NCP-APIGW-API-KEY-ID": "입력",
      // 개인 클라이언트 아이디
      "X-NCP-APIGW-API-KEY": "입력"
      // 개인 시크릿 키
    };

    Response response = await get(
      Uri.parse(//admcode,legalcode,addr,
          "https://naveropenapi.apigw.ntruss.com/map-reversegeocode/v2/gc?request=coordsToaddr&coords=${lon},${lat}&sourcecrs=epsg:4326&orders=roadaddr&output=json"),
      headers: myHeaders,
    );
    print("holeeee ${response.body}");
    final gc = jsonDecode(response.body);
    //gc 확인하기
    //print("holeee3 ${gc["results"][1]['region']['area1']['name']}"); //잘나옴

    final gcModel = ReverseGC.fromJson(gc); //모델 생성자 전달
    print(
        "holeeee  ${gcModel.si} ${gcModel.gu} ${gcModel.dong} ${gcModel.road} ${gcModel.buildingName} "); //서울특별시 강서구 마곡동 마곡중앙6로 이너매스마곡Ⅰ

    String address;
    address =
        "${gcModel.si} ${gcModel.gu} ${gcModel.dong} ${gcModel.road} ${gcModel.buildingName}";
    print("holeee ${address}");
    return address;
  }

  //출력 json
  // {"status":{"code":0,"name":"ok","message":"done"},"results":[{"name":"roadaddr","code":{"id":"1150010500","type":"L","mappingId":"09500105"},
  // "region":{"area0":{"name":"kr","coords":{"center":{"crs":"","x":0.0,"y":0.0}}},
  // "area1":{"name":"서울특별시","coords":{"center":{"crs":"EPSG:4326","x":126.9783882,"y":37.5666103}},"alias":"서울"},
  // "area2":{"name":"강서구","coords":{"center":{"crs":"EPSG:4326","x":126.849642,"y":37.550937}}},
  // "area3":{"name":"마곡동","coords":{"center":{"crs":"EPSG:4326","x":126.8304,"y":37.5738}}},
  // "area4":{"name":"","coords":{"center":{"crs":"","x":0.0,"y":0.0}}}},
  // "land":{"type":"","number1":"21","number2":"","addition0":{"type":"building","value":"이너매스마곡Ⅰ"},
  // "addition1":{"type":"zipcode","value":"07801"},"addition2":{"type":"roadGroupCode","value":"115003155054"},"addition3":{"type":"","value":""},
  // "addition4":{"type":"","value":""},
  // "name":"마곡중앙6로","coords":{"center":{"crs":"","x":0.0,"y":0.0}}}}]}

  @override
  void initState() {
    super.initState();
    //Future<Position> position = _determinePosition();
    position = _determinePosition();
    print("holeee000e ${position}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          //현재 위치
          FutureBuilder(
            future: position,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data.toString());
              }
              return Text("no location");
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NaverMapTest(
                        lat: lat,
                        lon: lon,
                      ),
                    ),
                  );
                  setState(() {
                    isMap= true;
                  });
                },
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          //리스트
          Expanded(
              child: isMap //블루투스 버튼일때 목록, 맵버튼일때 맵보여주기
                  ? NaverMapTest(lat: lat, lon: lon)
                  : ListView.separated(
                      scrollDirection: Axis.vertical,
                      itemCount: nameList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Text(nameList.elementAt(index)); //리턴을 해야 보인다
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          SizedBox(
                        height: 20,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
