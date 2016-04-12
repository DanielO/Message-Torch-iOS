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
            print("Detail item set in detail view")
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {

        // Update the user interface for the detail item.
        if let detail: MTService = self.detailItem {
            print("MTService configureView");
            self.title = detail.peripheral!.name;
            self.view.alpha = 1.0
            self.view.userInteractionEnabled = true
            self.view.backgroundColor = UIColor.whiteColor()
        } else {
            self.view.alpha = 0.3
            self.view.userInteractionEnabled = false
            self.view.backgroundColor = UIColor.grayColor()
        }
        if let msgText = self.messageText {
            print("setting message Text delegate")
            msgText.delegate = self
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

//    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
//        print("touchesBegan")
//        self.messageText.endEditing(true)
//        super.touchesBegan(touches, withEvent:event)
//    }

    @IBAction func changeBrightness(sender: AnyObject) {
        // Rate limit brightness settings to not spam the device
        if let limiter = self.brightnessRateLmitTimer {
            if limiter.valid {
                return
            }
        }
        self.actuallyChangeBrightness()
        self.brightnessRateLmitTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(DetailViewController.actuallyChangeBrightness), userInfo: nil, repeats: false)
    }

    func actuallyChangeBrightness() {
        print("Brightness \(brightness.value)")
        self.detailItem!.writeBrightness(UInt8(self.brightness.value))
    }

    @IBAction func messageTextEdited(sender: AnyObject) {
        print("Message changed to \(messageText.text)")
        self.detailItem!.writeMessage(messageText!.text!)
        messageText.resignFirstResponder()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        self.messageText.resignFirstResponder()
        return true
    }

    @IBAction func pickMessageColour(sender: AnyObject) {
        print("pickMessageColour");
        let colourPicker = FCColorPickerViewController.colorPickerWithColor(self.messageColour, delegate: self);
        self.colourToSet = .Message;

        self.presentViewController(colourPicker, animated: true, completion: nil);
    }

    @IBAction func pickFlameColour(sender: AnyObject) {
        print("pickFlameColour");
        let colourPicker = FCColorPickerViewController.colorPickerWithColor(self.messageColour, delegate: self);
        self.colourToSet = .Flame

        self.presentViewController(colourPicker, animated: true, completion: nil);
    }

    @IBAction func resetSettings(sender: AnyObject) {
        print("Resetting settings")
        self.detailItem!.writeReset()
    }

    // FCColorPickerViewControllerDelegate
    func colorPickerViewController(colorPicker: FCColorPickerViewController, didSelectColor: UIColor) {
        print("Selected colour", didSelectColor);
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
        print("Cancelled selection");
        self.dismissViewControllerAnimated(true, completion: nil);
    }
}

