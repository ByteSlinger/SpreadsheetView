//
//  ViewController.swift
//  SpreadSheetView
//
//  The view controller contains the SpreadSheetView.
//
//  Created by ByteSlinger on 2017-08-10.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var spreadsheetView: SpreadsheetView!

    // despite the Info.plist settings, this is required to get upside down orientation to work
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all;
    }
    
    override func viewDidLoad() {
        //print("ViewController.viewDidLoad()")
        

        // demonstrate how to override whatever was in the Storyboard
        self.spreadsheetView.maxCellWidth = 175.0
        
        self.spreadsheetView.rowBackgroundColor = UIColor.black
        self.spreadsheetView.rowAlternateColor = UIColor.init(hex: 0x222222)
        self.spreadsheetView.dataLabelHighlightedBackgroundColor = UIColor.white.withAlphaComponent(0.75)
        self.spreadsheetView.dataLabelHighlightedTextColor = UIColor.yellow
        self.spreadsheetView.dataLabelFontSize = 16.0
        self.spreadsheetView.dataLabelFontColor = UIColor.white
        self.spreadsheetView.headingLabelFontSize = 14.0
        self.spreadsheetView.headingLabelFontColor = UIColor.yellow
        self.spreadsheetView.headingBackgroundColor = UIColor.darkGray
        
        // to make these things take effect in TableView and TableCell
        self.spreadsheetView.overrideDefaults()
        
        let data = Data(random: true, rows: 100, cols: 28, headingRow: true, headingColumn: true)
        self.spreadsheetView.setData(data: data, firstDataRowIsHeading: true, firstDataColumnIsHeading: true)
    }
}
