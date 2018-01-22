//
//  ViewController.swift
//  SpreadsheetViewDemo
//
//  The view controller contains the SpreadSheetView.
//
//  Created by ByteSlinger on 2017-08-10.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//
import UIKit
import SpreadsheetView

class ViewController: UIViewController {
    
    @IBOutlet weak var spreadsheetView: SpreadsheetView!
    
    // despite the Info.plist settings, this is required to get upside down orientation to work
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewDidLoad() {
        //print("ViewController.viewDidLoad()")
        
        // demonstrate how to override whatever was in the Storyboard
        self.spreadsheetView.maxCellWidth = 80.0
        
        UIApplication.shared.statusBarStyle = .lightContent
        self.view.backgroundColor = UIColor.black
        self.spreadsheetView.rowBackgroundColor = UIColor.black
        self.spreadsheetView.rowAlternateColor = UIColor.black.withAlphaComponent(0.8)
        self.spreadsheetView.dataLabelHighlightedBackgroundColor = UIColor.blue.withAlphaComponent(0.5)
        self.spreadsheetView.dataLabelHighlightedTextColor = UIColor.yellow
        self.spreadsheetView.dataLabelFontSize = 16.0
        self.spreadsheetView.dataLabelFontColor = UIColor.white
        self.spreadsheetView.headingLabelFontSize = 14.0
        self.spreadsheetView.headingLabelFontColor = UIColor.yellow
        self.spreadsheetView.headingBackgroundColor = UIColor.darkGray
        
        // to make these things take effect in TableView and TableCell
        self.spreadsheetView.overrideDefaults()
        
        // use a random array
        let data = Data(random: true, rows: 100, cols: 28, headingRow: true, headingColumn: true)
        
        self.spreadsheetView.setDataSource(dataSource: data, firstDataRowIsHeading: true, firstDataColumnIsHeading: true)
    }
}
