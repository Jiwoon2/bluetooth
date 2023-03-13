import 'dart:async';
import 'dart:collection';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

//import 'package:location_permissions/location_permissions.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var deviceId; //연결을 위한 임시 id
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice>? subscription; //이게 맞나..??

  final nameList = <String>{}; // LinkedHashSet //블루투스 연결 가능 목록. 왜 size()로 안하지

  //BLE 디바이스의 Service UUID , characteristicId를 사용해서 응답값을 읽어오는 부분
  // final characteristic = QualifiedCharacteristic(serviceId: serviceUuid, characteristicId: characteristicUuid, deviceId: foundDeviceId);
  // final response = await flutterReactiveBle.readCharacteristic(characteristic);

  //권한 요청
  void requestGranted() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    print('hhhhhhhh${statuses[Permission.location]}');
  }

  void startScan() {
    requestGranted();

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
              //여기다하는게 맞나..?

              nameList.add(device.name);
              print("nnnnnnnn ${nameList.length}"); //set으로 중복 해결
            });

            deviceId = device.id;
          });
    }, onError: (e) {
      print("error!!!!!!!!!!!${e.toString()}");
    });
  }

  //검색 중지
  void stopScan() {
    subscription?.cancel();
    subscription = null;
  }

  //연결 설정
  void startConnect() {
    // flutterReactiveBle
    //     .connectToDevice(
    //   id: foundDeviceId,
    //   servicesWithCharacteristicsToDiscover: {
    //     serviceId: [char1, char2],
    //   },
    //   connectionTimeout: const Duration(seconds: 2),
    // )
    //     .listen((connectionState) {
    //   // Handle connection state updates
    // }, onError: (Object error) {
    //   // Handle a possible error
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          GestureDetector(
            onTap: startScan,
            child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.green,
                ),
                child: Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.vertical,
                    itemCount: nameList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Text("ㅓㅑ"); //리턴을 해야 보이나? 그것도 아니네
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        SizedBox(
                      height: 20,
                    ),
                  ),
                ),
            ),
          ),
          Text('hi'),
          //Text(nameList[0]), //rangeError
        ],
      ),
    );
  }
}
