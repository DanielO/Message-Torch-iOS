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

let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class MTService: NSObject, CBPeripheralDelegate {
  var peripheral: CBPeripheral?
  var positionCharacteristic: CBCharacteristic?

  init(initWithPeripheral peripheral: CBPeripheral) {
    super.init()
    print("initWithPeripheral called\n")
    self.peripheral = peripheral
    self.peripheral?.delegate = self
  }

  deinit {
    self.reset()
  }

  func startDiscoveringServices() {
    self.peripheral?.discoverServices([MTServiceUUID])
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
    let uuidsForBTService: [CBUUID] = [brightnessUUID, messageUUID, messageRGBUUID, flameRGBUUID]

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
        peripheral.discoverCharacteristics(uuidsForBTService, forService: service as! CBService)
      }
    }
  }

  func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
    if (peripheral != self.peripheral) {
      // Wrong Peripheral
      return
    }

    if (error != nil) {
      return
    }

    for characteristic in service.characteristics {
      if characteristic.UUID == brightnessUUID {
        self.positionCharacteristic = (characteristic as! CBCharacteristic)
        peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)

        // Send notification that Bluetooth is connected and all required characteristics are discovered
        self.sendBTServiceNotificationWithIsBluetoothConnected(true)
      }
    }
  }

  // Mark: - Private

  func writePosition(position: UInt8) {
    // See if characteristic has been discovered before writing to it
    if self.positionCharacteristic == nil {
      return
    }

    // Need a mutable var to pass to writeValue function
    var positionValue = position
    let data = NSData(bytes: &positionValue, length: sizeof(UInt8))
    self.peripheral?.writeValue(data, forCharacteristic: self.positionCharacteristic, type: CBCharacteristicWriteType.WithResponse)
  }

  func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
    let connectionDetails = ["isConnected": isBluetoothConnected]
    NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
  }

}
