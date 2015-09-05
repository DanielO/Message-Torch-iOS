//
//  DetailViewController.swift
//  Message Torch
//
//  Created by Daniel O'Connor on 3/08/2015.
//  Copyright (c) 2015 Daniel O'Connor. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    var detailItem: MTService? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: MTService = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = "Some stuff here"
                self.title = detail.peripheral!.name
            }
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


}

