//
//  DetailViewController.swift
//  Message Torch
//
//  Created by Daniel O'Connor on 3/08/2015.
//  Copyright (c) 2015 Daniel O'Connor. All rights reserved.
//

import UIKit

enum ColourToSet {
    case Message
    case Flame
}

class DetailViewController: UIViewController, FCColorPickerViewControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var brightness: UISlider!
    @IBOutlet weak var messageText: UITextField!
    @IBOutlet weak var messageColourButton: UIButton!
    @IBOutlet weak var flameColourButton: UIButton!

    var messageColour: UIColor!
    var flameColour: UIColor!
    var colourToSet : ColourToSet = .Flame
    var brightnessRateLmitTimer : NSTimer!

    var detailItem: MTService? {
        didSet {
            println("Detail item set in detail view")
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: MTService = self.detailItem {
            println("MTService configureView");
            self.title = detail.peripheral!.name;
        }
        if let msgText = self.messageText {
            println("setting message Text delegate")
            self.messageText.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        println("touchesBegan")
        self.messageText.endEditing(true)
        super.touchesBegan(touches, withEvent:event)
    }

    @IBAction func changeBrightness(sender: AnyObject) {
        // Rate limit brightness settings to not spam the device
        if let limiter = self.brightnessRateLmitTimer {
            if limiter.valid {
                return
            }
        }
        self.actuallyChangeBrightness()
        self.brightnessRateLmitTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "actuallyChangeBrightness", userInfo: nil, repeats: false)
    }

    func actuallyChangeBrightness() {
        println("Brightness \(brightness.value)")
        self.detailItem!.writeBrightness(UInt8(self.brightness.value))
    }

    @IBAction func messageTextEdited(sender: AnyObject) {
        println("Message changed to \(messageText.text)")
        self.detailItem!.writeMessage(messageText.text)
        messageText.resignFirstResponder()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        println("textFieldShouldReturn")
        self.messageText.resignFirstResponder()
        return true
    }

    @IBAction func pickMessageColour(sender: AnyObject) {
        println("pickMessageColour");
        let colourPicker = FCColorPickerViewController.colorPickerWithColor(self.messageColour, delegate: self);
        self.colourToSet = .Message;

        self.presentViewController(colourPicker, animated: true, completion: nil);
    }

    @IBAction func pickFlameColour(sender: AnyObject) {
        println("pickFlameColour");
        let colourPicker = FCColorPickerViewController.colorPickerWithColor(self.messageColour, delegate: self);
        self.colourToSet = .Flame

        self.presentViewController(colourPicker, animated: true, completion: nil);
    }

    @IBAction func resetSettings(sender: AnyObject) {
        println("Resetting settings")
        self.detailItem!.writeReset()
    }

    // FCColorPickerViewControllerDelegate
    func colorPickerViewController(colorPicker: FCColorPickerViewController, didSelectColor: UIColor) {
        println("Selected colour", didSelectColor);
        switch self.colourToSet {
        case .Message:
            self.messageColour = didSelectColor
            self.messageColourButton.backgroundColor = didSelectColor
            self.detailItem!.writeMessageColour(didSelectColor)
        case .Flame:
            self.flameColour = didSelectColor
            self.flameColourButton.backgroundColor = didSelectColor
            self.detailItem!.writeFlameColour(didSelectColor)
        }
        self.dismissViewControllerAnimated(true, completion: nil);
    }

    func colorPickerViewControllerDidCancel(colorPicker: FCColorPickerViewController) {
        println("Cancelled selection");
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}

