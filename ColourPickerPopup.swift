//
//  ColourPickerPopup.swift
//  Message Torch
//
//  Created by Daniel O'Connor on 6/09/2015.
//  Copyright (c) 2015 Daniel O'Connor. All rights reserved.
//

import Foundation
import UIKit

class ColourPickerPopup: UIViewController {
    @IBOutlet weak var OKButton: UIButton!
    @IBOutlet weak var CancelButton: UIButton!

    func configureView() {
        println("colour picker configure");
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        println("colour picker load");
    }

    func closePopup() {
        self.view.removeFromSuperview();
    }

    @IBAction func OKButtonClicked(sender: AnyObject) {
        println("OK");
        self.closePopup();
    }

    @IBAction func cancelButtonClicked(sender: AnyObject) {
        println("cancelled");
        self.closePopup();
    }
}
