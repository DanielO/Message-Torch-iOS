//
//  MTService.swift
//  Message Torch
//
//  Created by Daniel O'Connor on 6/08/2015.
//  Copyright (c) 2015 Daniel O'Connor. All rights reserved.
//
// Heavily cribbed from http://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
let MTServiceUUID = CBUUID(string: "69B9AC8B-2F23-471A-BA62-0E3C9E8C0000")
let brightnessUUID = CBUUID(string: "69B9AC8B-2F23-471A-BA62-0E3C9E8C0001")
let messageUUID = CBUUID(string: "69B9AC8B-2F23-471A-BA62-0E3C9E8C0002")
let messageRGBUUID = CBUUID(string: "69B9AC8B-2F23-471A-BA62-0E3C9E8C0003")
let flameRGBUUID = CBUUID(string: "69B9AC8B-2F23-471A-BA62-0E3C9E8C0004")
let resetUUID = CBUUID(string: "69b9ac8b-2f23-471a-ba62-0e3c9e8c0005")

let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class MTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var brightnessCharacteristic: CBCharacteristic?
    var messageCharacteristic: CBCharacteristic?
    var messageRGBCharacteristic: CBCharacteristic?
    var flameRGBCharacteristic: CBCharacteristic?
    var resetCharacteristic: CBCharacteristic?

    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        print("MTService.initWithPeripheral called\n")
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }

    deinit {
        self.reset()
    }

    func startDiscoveringServices() {
        if let periph = self.peripheral {
            println("MTService discovering services");
            periph.discoverServices([MTServiceUUID])
        }
    }

    func reset() {
        if peripheral != nil {
            peripheral = nil
        }

        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }

    // Mark: - CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        println("did discover services")
        let uuidsForBTService: [CBUUID] = [brightnessUUID, messageUUID, messageRGBUUID, flameRGBUUID, resetUUID]

        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }

        if (error != nil) {
            return
        }

        if ((peripheral.services == nil) || (peripheral.services.count == 0)) {
            // No Services
            return
        }

        for service in peripheral.services {
            if service.UUID == MTServiceUUID {
                println("Found service, discovering characteritsics");
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service as! CBService)
            }
        }
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        println("Did discover characteristics")
        if (peripheral != self.peripheral) {
            println("discovered characteristics for wrong device")
            // Wrong Peripheral
            return
        }

        if (error != nil) {
            println("error during discovery ", error)
            return
        }

        for characteristic in service.characteristics {
            println("looking at ", characteristic)
            switch characteristic.UUID {
            case brightnessUUID:
                self.brightnessCharacteristic = (characteristic as! CBCharacteristic)
            case messageUUID:
                self.messageCharacteristic = (characteristic as! CBCharacteristic)
            case messageRGBUUID:
                self.messageRGBCharacteristic = (characteristic as! CBCharacteristic)
            case flameRGBUUID:
                self.flameRGBCharacteristic = (characteristic as! CBCharacteristic)
            case resetUUID:
                self.resetCharacteristic = (characteristic as! CBCharacteristic)
            default:
                continue
            }
            peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)
            // Send notification that Bluetooth is connected and all required characteristics are discovered
            self.sendBTServiceNotificationWithIsBluetoothConnected(true)
        }
    }

    // Mark: - Private
    func writeBrightness(brightness: UInt8) {
        if let peripheral = self.peripheral {
            peripheral.writeValue(NSData(bytes: [brightness], length: 1), forCharacteristic: self.brightnessCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }

    func writeMessage(message: String) {
        if let peripheral = self.peripheral {
        var data = message.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)

            peripheral.writeValue(data, forCharacteristic: self.messageCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }

    func writeColour(colour: UIColor, characteristic: CBCharacteristic?) {
        if let peripheral = self.peripheral, let characteristic_ = characteristic {
            var red, green, blue, alpha: CGFloat;
            red = 0;
            green = 0;
            blue = 0;
            alpha = 0;
            colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            var data: [UInt8] = [UInt8(red * 255), UInt8(green * 255), UInt8(blue * 255)]
            peripheral.writeValue(NSData(bytes: &data, length: data.count), forCharacteristic: characteristic_, type: CBCharacteristicWriteType.WithoutResponse)
            println("Writing ", colour, " to ", characteristic_);
        }
    }

    func writeMessageColour(colour: UIColor) {
        println("Message colour ", colour)
        self.writeColour(colour, characteristic: self.messageRGBCharacteristic)
    }
    
    func writeFlameColour(colour: UIColor) {
        println("Flame colour ", colour)
        self.writeColour(colour, characteristic: self.flameRGBCharacteristic)
    }

    func writeReset() {
        if let peripheral = self.peripheral {
            peripheral.writeValue(NSData(bytes: [0], length: 1), forCharacteristic: self.resetCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }

    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
}
