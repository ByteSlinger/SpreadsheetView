//
//  ViewController.swift
//  CSVDemo
//
//  Created by ByteSlinger on 8/23/17.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var headingRow: UISwitch!
    @IBOutlet weak var headingColumn: UISwitch!
    @IBOutlet weak var maxColumnWidthValue: UILabel!
    @IBOutlet weak var maxColumnWidthSlider: UISlider!
    @IBOutlet weak var viewButton: UIButton!
    
    // despite the Info.plist settings, this is required to get upside down orientation to work
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all;
    }
    
    var fileName: String? = nil
    
    // pass the selected fileName to the csv view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let csvViewController = segue.destination as! CSVViewController
        
        if (self.fileName == nil) {
            self.fileName = self.fileNames[0]   // for safety - 1st is displayed but not necessarily selected
        }
        csvViewController.fileName = self.fileName!
        csvViewController.firstRowIsHeading = self.headingRow.isOn
        csvViewController.firstColumnIsHeading = self.headingColumn.isOn
        csvViewController.maxColumnWidth = Int(self.maxColumnWidthSlider.value)
    }
    
    @IBAction func changeMaxColumnValue(_ sender: UISlider) {
        self.maxColumnWidthValue.text = String(Int(self.maxColumnWidthSlider.value))
    }
    
    // make sure there are the same number of items in each array
    var pickerDataSource = ["Cities", "GPS Data", "Female Oscars", "Male Oscars", "MLB Players",  "People", "Stationary", "Row/Col Sample"];
    var fileNames = ["cities", "gps", "oscar_age_female", "oscar_age_male", "mlb_players", "people", "stationary", "sample"];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.pickerView.dataSource = self;
        self.pickerView.delegate = self;
        
        self.maxColumnWidthValue.text = String(Int(self.maxColumnWidthSlider.value))
        
        viewButton.layer.cornerRadius = viewButton.frame.size.width / 4;
    }

    // UIPickerViewDataSource methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count;
    }

    // UIPickerViewDataDelegate methods
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if (row >= 0 || row < self.fileNames.count) {
            self.fileName = self.fileNames[row]
        }
        
        //print("main filename = \(self.fileName ?? "?")")
    }
}

