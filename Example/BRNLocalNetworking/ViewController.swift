//
//  ViewController.swift
//  BRNLocalNetworking
//
//  Created by brendaninnis on 04/17/2021.
//  Copyright (c) 2021 brendaninnis. All rights reserved.
//

import UIKit
import BRNLocalNetworking

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        BRNLocalNetworking.sharedInstance.startAutoJoinOrHost()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

