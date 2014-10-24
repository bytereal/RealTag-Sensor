RealTag-Sensor
==============
(All information found [here](http://www.aliexpress.com/item/Realtag-BLE-sensor-wearable-CC2541-MPU6050-BMP180-iBeacon-given/1934305869.html))
## Usage
1. Open Wearable Platform wearable platform
2. Motion Tracker motion tracking, pedometer, sports bracelet assisted teaching
3. iBeacon station
4. a small four axis aircraft, smart car, smart robots

## Realtag V1.0 Sensor specifications:
* **TI CC-2541**: Bluetooth Low Energy Chip
 * [specs](http://www.ti.com/lit/ds/symlink/cc2541.pdf)
* **MPU6050**: MEMS accelerometer (3DOF) and a MEMS gyro (3DOF)
 * [specs](http://www.invensense.com/mems/gyro/documents/PS-MPU-6000A-00v3.4.pdf)
 * [Reading raw values is easy, the rest is not](http://playground.arduino.cc/Main/MPU-6050#easy)
* **BMP180**: Digital pressure(and temperature) sensor
 * [specs](http://ae-bst.resource.bosch.com/media/products/dokumente/bmp180/BST-BMP180-DS000-09.pdf) 
* panel filters and integrated ceramic antenna balun (??)
* CR2032 supply, with power switch, two buttons and blue LED
* Size: 3cm * 3cm, thickness 7mm

## Realtag iBeacon firmware instructions
* the modified parameters, Tag need to re-power [power off and then open]
* the operating state, the blue LED D1 broadcast frequency signal among the flashing
* work, press 52 button stop / start broadcasting [radio automatically when power is tumed on by default]
* the connected state will not broadcast resumed broadcasting that disconnected
* after connecting the battery power can be viewed by Battery Service

## Realtag iBeacon firmware description
* the default UUID: `0xE2C56DB5-DFFB-48D2-B060-D0F5A71096AEO`
* iBeacon parameters:
        0xFFA0 -> 0xFFB0 Read / Write - passkey
        0xFFA0 -> 0xFFB1 Read / Write - Major ID + Minor ID
        0xFFA0 -> 0xFFB2 Read / Write iBeacon UUID
        0xFFA0 -> 0xFFB3 Read / Write - broadcast interval
        0xFFA0 -> 0xFFB4 Read / Write - Device Name Device ID
        0xFFA0 -> 0xFFB5 Read / Write - deployment mode
        0xFFA0 -> 0xFFB8 Read / Write Power
        0x180F -> 0x2A19 Read / Notify-Battery life
* support OAD, the firmware can be upgraded online

## Realtag iBeacon API
* Service UUID: `0xFFA0`
* `0xFFB0`: pairing code [Read / Write]
  * ex: 000000 [000000 = default connection without a password]
* `0xFFB1`: Major + MinorID [Read / Write]
  * ex: 0x01020304 [0x0102 = Major ID, 0x0304 = Minor ID]
* `0xFFB2`: UUID [Read / Write]
  * ex: 0xE2C56DB5-DFFB-48D2-B060-D0F5A71096E0 [not recommended modification]
* `0xFFB3`: Advertising Interval [Read / Write]
  * ex: 0x05 [100 ms interval is an integer multiple of the broadcast, the default 0x05 = 500ms
* `0xFFB4`: Device Name DevicelD [Read / Write]
   * ex: iBeacons # [with "#" End]
* `0xFFB5`: deployment mode [Read / Write]
   * ex: write 0x00 into deployment mode [default 0x01: non-deployment mode]
* `0xFFB6`: Sensor MPU6050 data [Realtag Sensor]
  * ex: Hex 0xA0009C02983E40F7FDFFBC00FFF
* `0xFFB7`: Sensor BMP180 data [Realtag Sensor]
  * ex: Hex 0x16010000CA8901O0
* `0xFFB8`: TX Power [Read / Write]
  * ex: 0xC5 [default value: 0xC5, namely TX Power= -59]
  
### Data output adresses
## MPU6050 raw data output (7):
* XYZ accelerometer. `ax`, `ay`, `az`
* Temperature: `aTemp`
* XYZ angular velocity: `gx`, `gy`, `gz`
* Each value occupies 2 bytes [Big Endian]
* ex: Hex 0xA0009C02983E40F7FDFFBC00FFFF
 * ax = 0x00 A0 
 * ay = 0x02 9C
 * az = 0x3E 98
 * aTemp = 0xF7 40
 * gx = 0xFF FD 
 * gy = 0x00 BC
 * gz = 0xFF FF

## BMP180 data output [temperature and pressure]:
* Each value occupies four bytes [Big Endian]
 * ex: Hex 0x16010000CA890100
* Temperature = 0x00000116 = 278 * 0.1 = 27.8 °C
* Pressure= 0x000189CA = 100810 pa

