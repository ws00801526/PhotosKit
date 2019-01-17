//
//  ViewController.swift
//  PhotosKit
//
//  Created by ws00801526 on 01/15/2019.
//  Copyright (c) 2019 ws00801526. All rights reserved.
//

import UIKit
import PhotosKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let path = Bundle.main.path(forResource: "Picker", ofType: "bundle") ?? ""
//        let bundle = Bundle(path: path)
//        PKPhotoConfig.default.lanuageBundle = bundle ?? Bundle.main
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func presentPhoto(_ sender: Any) {
        let controller = PKPhotoController(nibName: nil, bundle: nil)
        present(controller, animated: true, completion: nil)
    }
    
}

