import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class DeviceList extends StatefulWidget {
  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<DeviceList> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  var devices = new HashMap<DeviceIdentifier, BluetoothDevice>();
  BluetoothDevice selectedDevice = null;

  StreamSubscription<ScanResult> scanSubscription;

  var serviceUUID = Guid("0000fff0-0000-1000-8000-00805f9b34fb");
  var characteristicUUID = Guid("0000fff4-0000-1000-8000-00805f9b34fb");

  @override
  initState() {
    super.initState();

    scanSubscription =
        flutterBlue.scan(scanMode: ScanMode.lowLatency).listen((scanResult) {
      var device = scanResult.device;
      if (!devices.containsKey(device.id) && device.name.contains("FOX")) {
        setState(() {
          devices[device.id] = device;
        });
      }
    });
  }

  void toggleScan() {
    setState(() {
      if (scanSubscription.isPaused) {
        scanSubscription.resume();
      } else {
        scanSubscription.pause();
      }
    });
  }

  BluetoothDevice getDevice(int index) {
    return devices[devices.keys.elementAt(index)];
  }

  Text bluetoothDevice(int index) {
    var device = getDevice(index);
    if (device.name != "") {
      return Text('${device.name} ${device.id.id}');
    } else {
      return Text(device.id.id);
    }
  }

  void selectDevice(index) {
    setState(() {
      selectedDevice = getDevice(index);

      flutterBlue.connect(selectedDevice).listen((s) async {
        if (s == BluetoothDeviceState.connected) {
          getSerivice().then((service) => {
                getCharacteristic(service)
                    .then((char) => {subscribbleNotifications(char)})
              });
        }
      });
    });
  }

  Future<BluetoothService> getSerivice() async {
    var services = await selectedDevice.discoverServices();
    return services.firstWhere((s) => s.uuid == serviceUUID);
  }

  Future<BluetoothCharacteristic> getCharacteristic(
      BluetoothService service) async {
    var characteristics = service.characteristics;
    return characteristics.firstWhere((c) => c.uuid == characteristicUUID);
  }

  Future subscribbleNotifications(char) async {
    await selectedDevice.setNotifyValue(char, true);
    selectedDevice.onValueChanged(char).listen((value) {
      print(new String.fromCharCodes(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Visibility(
          visible: selectedDevice == null,
          child: SizedBox(
            height: 400,
            child: ListView.builder(
              padding: EdgeInsets.all(20.0),
              physics: BouncingScrollPhysics(),
              itemCount: devices.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: ListTile(
                    onTap: () => selectDevice(index),
                    leading: Icon(Icons.bluetooth),
                    title: bluetoothDevice(index),
                  ),
                );
              },
            ),
          ),
        ),
        MaterialButton(
          child: Text(
              "${scanSubscription.isPaused ? 'Resume scan' : 'Pause scan'}"),
          onPressed: toggleScan,
        ),
        Text(
            'Selected device ${selectedDevice != null ? selectedDevice.name : 'null'}')
      ],
    );
  }
}
