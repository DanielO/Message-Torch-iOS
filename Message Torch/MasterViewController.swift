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

    var detailViewController: DetailViewController? = nil

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
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }

        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
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

    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        // Be sure to retain the peripheral or it will fail during connection.
        print("Found peripheral ");
        println(peripheral);
        // Validate peripheral information
        if ((peripheral == nil) || (peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        if (!self.peripherals!.containsObject(peripheral)) {
            self.peripherals!.addObject(MTService(initWithPeripheral: peripheral))
            self.tableView.reloadData()
        }

        //central.connectPeripheral(peripheral, options: nil)
    }

    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {

        if (peripheral == nil) {
            return;
        }

        // Create new service class
        if (peripheral == self.peripheralBLE) {
        }

        // Stop scanning for new devices
        stopScanning()
    }

    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {

        if (peripheral == nil) {
            return;
        }

        // See if it was our peripheral that disconnected
        if (self.peripherals!.containsObject(peripheral)) {
            self.peripherals!.removeObject(peripheral)
            self.tableView.reloadData()
        }

        // Start scanning for new devices
        //self.startScanning()
    }

    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch (central.state) {
        case CBCentralManagerState.PoweredOff:
            println("BT powered off")
            self.clearDevices()

        case CBCentralManagerState.Unauthorized:
            println("BT not supported")
            // Indicate to user that the iOS device does not support BLE.

        case CBCentralManagerState.Unknown:
            println("BT unknown event")
            // Wait for another event

        case CBCentralManagerState.PoweredOn:
            println("BT powered on")
            self.startScanning()

        case CBCentralManagerState.Resetting:
            println("BT resetting")
            self.clearDevices()

        case CBCentralManagerState.Unsupported:
            println("BT unsupported")

        default:
            break
        }
    }

    // MARK: - Private
    func startScanning() {
        if (self.scanning) {
            return
        }
        if let central = centralManager {
            var timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "refreshDone", userInfo: nil, repeats: false)
            
            println("Started scanning")
            self.clearDevices()
            central.scanForPeripheralsWithServices([MTServiceUUID], options: nil)
            self.scanning = true
        }
    }

    func stopScanning() {
        if let central = centralManager {
            println("Stopped scanning")
            central.stopScan()
        }
        self.scanning = false
    }

    func clearDevices() {
        println("Clearing devices")
        self.peripherals?.removeAllObjects()
        self.tableView.reloadData()
    }

    func refresh(sender:AnyObject)
    {
        println("Refresh")
        self.startScanning()
    }

    func refreshDone() {
        println("Refresh done")
        self.refreshControl!.endRefreshing()
        self.stopScanning()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let device = self.peripherals?.objectAtIndex(indexPath.row) as! MTService
                println("device ", device)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = device
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
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

