//
//  BLEConnection.swift
//  WT901BLECL_Demo
//
//  Created by transistorgit on 26.11.20.
//
//  Bluetooth Access WIT Motion WT901BLECL IMU
//
//  Datasheet: https://drive.google.com/drive/folders/1NlOFHSTYNy2bRAfaA0S25BEaXK4uvia9

import Foundation
import UIKit
import CoreBluetooth

//https://stackoverflow.com/questions/58239721/render-list-after-bluetooth-scanning-starts-swiftui
open class BLEConnection: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate, ObservableObject {
    @Published var imuData: String?
    @Published var showAlert = false
    @Published var imuPitch: Double?
    @Published var imuRoll: Double?

    // Properties
    private var centralManager: CBCentralManager! = nil
    private var peripheral: CBPeripheral!
    private var writeChar: CBCharacteristic!
    private var sampleCnt: Int = 0

    public static let bleServiceUUID = CBUUID.init(string: "0000FFE5-0000-1000-8000-00805F9A34FB")//service id for imu
    public static let bleWriteCharacteristicUUID = CBUUID.init(string: "0000FFE9-0000-1000-8000-00805F9A34FB")
    public static let bleReadCharacteristicUUID = CBUUID.init(string: "0000FFE4-0000-1000-8000-00805F9A34FB")
    public static let bleCharacteristicUUID = [bleReadCharacteristicUUID, bleWriteCharacteristicUUID]

    
    func startCentralManager() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }


    // Handles BT Turning On/Off
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
            case .poweredOn:
                print("Central scanning for", BLEConnection.bleServiceUUID);
                self.centralManager.scanForPeripherals(withServices: [BLEConnection.bleServiceUUID],options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])

            default:
                print("centralManagerDidUpdateState unknown state");
        }
    }


    // scan callback
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("Peripheral Name: \(String(describing: peripheral.name ?? "unknown"))  RSSI: \(String(RSSI.doubleValue))")

        guard let name = peripheral.name else {
            return
        }

        if(name.starts(with: "WT901BLE")) {
            // We've found it so stop scan
            self.centralManager.stopScan()
            print("\(name) found ")
            //Copy the peripheral instance
            self.peripheral = peripheral
            self.peripheral.delegate = self
            // Connect!
            self.centralManager.connect(self.peripheral, options: nil)
        }
    }


    // connect callback
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to your BLE Board")
            peripheral.discoverServices([BLEConnection.bleServiceUUID])
        }
    }

    // connect failed callback
    public func centralManager(_ central: CBCentralManager, didFailToConnectPeripheral error: Error?) {
        print("failed to connect: ", error ?? "no error")
    }

    // disconnect callback
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: ", error ?? "no error")
        showAlert = true
    }


    // service discovery callback
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == BLEConnection.bleServiceUUID {
                    //print("BLE Service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics(BLEConnection.bleCharacteristicUUID, for: service)
                    return
                }
            }
        }
    }


    // characteristics discovery callback
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if BLEConnection.bleCharacteristicUUID.contains(characteristic.uuid) {
                    //print("BLE service characteristic \(characteristic.uuid) found. Desc: ", characteristic.description)

                    if characteristic.uuid == BLEConnection.bleReadCharacteristicUUID {
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                    if characteristic.uuid == BLEConnection.bleWriteCharacteristicUUID {
                        self.writeChar = characteristic
                        self.setUpdateRate(frequency: 1)
                    }

                } else {
                    print("Characteristic not found.", characteristic.uuid)
                }
            }
        }
    }

    //write callback - notifies if write failed
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let e = error else{
            return
        }
        print("didWriteValueFor: ", characteristic, e)
    }

    // data update callback - here the data from device arrives
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        guard let data = characteristic.value
        else {
            print("Error: didUpdateValueFor: ", characteristic, error ?? "no error")
            return
        }

        guard characteristic.uuid == BLEConnection.bleReadCharacteristicUUID else {
            print("Unknown Char: \(characteristic.uuid)")
            return
        }

        switch data[1] {
        case 0x61:
            //receive IMU data
            let xAcc = (Double)((Int16)(data[2])|(Int16)(data[3])<<8) / 32768.0 * 16.0 * 9.81
            let yAcc = (Double)((Int16)(data[4])|(Int16)(data[5])<<8) / 32768.0 * 16.0 * 9.81
            let zAcc = (Double)((Int16)(data[6])|(Int16)(data[7])<<8) / 32768.0 * 16.0 * 9.81


            let xVel = (Double)((Int16)(data[8])|(Int16)(data[9])<<8) / 32768.0 * 2000.0
            let yVel = (Double)((Int16)(data[10])|(Int16)(data[11])<<8) / 32768.0 * 2000.0
            let zVel = (Double)((Int16)(data[12])|(Int16)(data[13])<<8) / 32768.0 * 2000.0

            let roll  = (Double)((Int16)(data[14])|(Int16)(data[15])<<8) / 32768.0 * 180.0
            let pitch = (Double)((Int16)(data[16])|(Int16)(data[17])<<8) / 32768.0 * 180.0
            let yaw   = (Double)((Int16)(data[18])|(Int16)(data[19])<<8) / 32768.0 * 180.0

            let str = String(format: "X %6.1fg    Y %6.1fg    Z %6.1fg\nRoll %6.1f°    Pitch %6.1f°    Yaw %6.1f°", xAcc, yAcc, zAcc, roll, pitch, yaw)
            self.sampleCnt += 1

            imuData = str //updates view
            imuPitch = pitch
            imuRoll = roll

            print(String(format: "Acc[g]: %6.1f, %6.1f, %6.1f     AngVel[°/s]  %6.1f, %6.1f, %6.1f     Ang[°] %6.1f, %6.1f, %6.1f", xAcc, yAcc, zAcc, xVel, yVel, zVel, roll, pitch, yaw))

            peripheral.writeValue(Data([0xFF, 0xAA, 0x27, 0x3a, 0x00]), for: self.writeChar, type: .withResponse)//request magnetic field

        case 0x71:
            switch data[2] {
                case 0x3a:
                    //magnetic field
                    let x = (Int16)(data[4])|(Int16)(data[5])<<8
                    let y = (Int16)(data[6])|(Int16)(data[7])<<8
                    let z = (Int16)(data[8])|(Int16)(data[9])<<8
                    print(String(format: "Hx: %5d   Hy: %5d   Hz: %5d", x, y, z))

                    peripheral.writeValue(Data([0xFF, 0xAA, 0x27, 0x51, 0x00]), for: self.writeChar, type: .withResponse)//request quaternion

                case 0x51:
                    //quaternion
                    let q0 = (Double)((Int16)(data[4])|(Int16)(data[5])<<8) / 32768.0
                    let q1 = (Double)((Int16)(data[6])|(Int16)(data[7])<<8) / 32768.0
                    let q2 = (Double)((Int16)(data[8])|(Int16)(data[9])<<8) / 32768.0
                    let q3 = (Double)((Int16)(data[10])|(Int16)(data[11])<<8) / 32768.0

                    print(String(format:"Q0: %6.1f   Q1: %6.1f   Q2: %6.1f   Q3: %6.1f", q0, q1, q2, q3))

                    peripheral.writeValue(Data([0xFF, 0xAA, 0x27, 0x40, 0x00]), for: self.writeChar, type: .withResponse)//request temperature

                case 0x40:
                    //temperature
                    let temp = (Double)((Int16)(data[4])|(Int16)(data[5])<<8) / 100.0
                    print("Temperature[°C]: \(temp)")

                default:
                    print(String(format: "Unknown sub data flag: 0x%0X",(data[2])))
            }
        default:
            print(String(format: "Unknown data flag: 0x%0X",(data[1])))
        }
    }


    func setUpdateRate(frequency: UInt8){//1-50 Hz (ignore 0.2 and 0.5Hz for simplicity)
        guard self.writeChar != nil else {
            return
        }

        switch frequency {
        case 1:
            peripheral.writeValue(Data([0xFF, 0xAA, 0x03, 0x03, 0x00]), for: self.writeChar, type: .withResponse)
        case 2:
            peripheral.writeValue(Data([0xFF, 0xAA, 0x03, 0x04, 0x00]), for: self.writeChar, type: .withResponse)
        case 5:
            peripheral.writeValue(Data([0xFF, 0xAA, 0x03, 0x05, 0x00]), for: self.writeChar, type: .withResponse)
        case 10:
            peripheral.writeValue(Data([0xFF, 0xAA, 0x03, 0x06, 0x00]), for: self.writeChar, type: .withResponse)
        case 20:
            peripheral.writeValue(Data([0xFF, 0xAA, 0x03, 0x07, 0x00]), for: self.writeChar, type: .withResponse)
        case 50:
            peripheral.writeValue(Data([0xFF, 0xAA, 0x03, 0x08, 0x00]), for: self.writeChar, type: .withResponse)
        default:
            //default to 10 Hz
            peripheral.writeValue(Data([0xFF, 0xAA, 0x03, 0x06, 0x00]), for: self.writeChar, type: .withResponse)
        }
    }


    func saveCurrentConfig(){
        guard self.writeChar != nil else {
            return
        }
        peripheral.writeValue(Data([0xFF, 0xAA, 0x00, 0x00, 0x00]), for: self.writeChar, type: .withResponse)//save current config
    }


    func restoreDefaultConfig(){
        guard self.writeChar != nil else {
            return
        }
        peripheral.writeValue(Data([0xFF, 0xAA, 0x00, 0x01, 0x00]), for: self.writeChar, type: .withResponse)//restore default config and save
    }


    func calibrateAccelerometer(){
        guard self.writeChar != nil else {
            return
        }
        peripheral.writeValue(Data([0xFF, 0xAA, 0x01, 0x01, 0x00]), for: self.writeChar, type: .withResponse)//accelerometer calibration
    }


    func calibrateMagnetics(){
        guard self.writeChar != nil else {
            return
        }
        peripheral.writeValue(Data([0xFF, 0xAA, 0x01, 0x07, 0x00]), for: self.writeChar, type: .withResponse)//magnetic calibration
    }


    func quitCalibration(){
        guard self.writeChar != nil else {
            return
        }
        peripheral.writeValue(Data([0xFF, 0xAA, 0x01, 0x00, 0x00]), for: self.writeChar, type: .withResponse)//quit calibration
    }

    func calibrate(){
        calibrateMagnetics()
        calibrateAccelerometer()
    }
}
