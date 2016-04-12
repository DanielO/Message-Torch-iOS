//
//  MasterViewController.swift
//  Message Torch
//
//  Created by Daniel O'Connor on 3/08/2015.
//  Copyright (c) 2015 Daniel O'Connor. All rights reserved.
//

import CoreBluetooth
import UIKit

class MasterViewController: UITableViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager?
    private var peripheralBLE: CBPeripheral?
    private var mainCharacteristic: CBCharacteristic?
    private var peripherals: NSMutableArray?
    private var scanning = false

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let split = self.splitViewController {
            _ = split.viewControllers
        }

        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: #selector(MasterViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl!)

        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripherals = NSMutableArray()
    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
    }
    func connectionChanged(notification: NSNotification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = notification.userInfo as! [String: Bool]

        dispatch_async(dispatch_get_main_queue(), {
            // Set image based on connection status
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    //self.imgBluetoothStatus.image = UIImage(named: "Bluetooth_Connected")
                    print("connected\n")

                    // Send current slider position
                    //self.sendPosition(UInt8( self.positionSlider.value))
                } else {
                    //self.imgBluetoothStatus.image = UIImage(named: "Bluetooth_Disconnected")
                    print("disconnected\n");
                }
            }
        });
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        //objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - CBCentralManagerDelegate

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        // Be sure to retain the peripheral or it will fail during connection.
        print("Found peripheral \(peripheral.name) at \(RSSI) dBm");
        // Validate peripheral information
        if peripheral.name == nil || peripheral.name == "" {
            return
        }
        if (!self.peripherals!.containsObject(peripheral)) {
            self.peripherals!.addObject(MTService(initWithPeripheral: peripheral))
            self.tableView.reloadData()
        }
    }

    // XXX: terrible, should call connect when the user taps, add busy spinner, then transistion to detail view when this triggers
    // XXX: also should sort out the scanning - just scan until the user taps on a device
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Peripheral connected: \(peripheral.name)")

        peripheral.discoverServices([MTServiceUUID])


        // Stop scanning for new devices
        stopScanning()
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // See if it was our peripheral that disconnected
        if (self.peripherals!.containsObject(peripheral)) {
            self.peripherals!.removeObject(peripheral)
            self.tableView.reloadData()
        }

        // Start scanning for new devices
        //self.startScanning()
    }
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
        case CBCentralManagerState.PoweredOff:
            print("BT powered off")
            self.clearDevices()

        case CBCentralManagerState.Unauthorized:
            print("BT not supported")
            // Indicate to user that the iOS device does not support BLE.

        case CBCentralManagerState.Unknown:
            print("BT unknown event")
            // Wait for another event

        case CBCentralManagerState.PoweredOn:
            print("BT powered on")
            self.startScanning()

        case CBCentralManagerState.Resetting:
            print("BT resetting")
            self.clearDevices()

        case CBCentralManagerState.Unsupported:
            print("BT unsupported")
        }
    }

    // MARK: - Private
    func startScanning() {
        if (self.scanning) {
            return
        }
        if let central = centralManager {
            var _ = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(MasterViewController.refreshDone), userInfo: nil, repeats: false)
            
            print("Started scanning")
            self.clearDevices()
            central.scanForPeripheralsWithServices([MTServiceUUID], options: nil)
            self.scanning = true
        }
    }

    func stopScanning() {
        if let central = centralManager {
            print("Stopped scanning")
            central.stopScan()
        }
        self.scanning = false
    }

    func clearDevices() {
        print("Clearing devices")
        self.peripherals?.removeAllObjects()
        self.tableView.reloadData()
    }

    func refresh(sender:AnyObject)
    {
        print("Refresh")
        self.startScanning()
    }

    func refreshDone() {
        print("Refresh done")
        self.refreshControl!.endRefreshing()
        self.stopScanning()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let indexPath = self.tableView.indexPathForSelectedRow!
            let device = self.peripherals?.objectAtIndex(indexPath.row) as! MTService
            print("Connecting device \(device.peripheral!.name)")
            self.centralManager!.connectPeripheral(device.peripheral!, options: nil)
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            controller.detailItem = device
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> DeviceCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath:indexPath) as! DeviceCell

        //We set the cell title according to the peripheral's name
        let peripheral = self.peripherals?.objectAtIndex(indexPath.row) as! MTService
        cell.title.text = peripheral.peripheral!.name;
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
}

