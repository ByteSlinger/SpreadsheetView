//
//  CSVViewController.swift
//  CSVDemo
//
//  Created by ByteSlinger on 8/23/17.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import UIKit
import SpreadsheetView

class CSVViewController: UIViewController, SpreadsheetViewDataSource {
    @IBOutlet weak var spreadsheetView: SpreadsheetView!

    // set these in prepare for segue function of main view controller
    var fileName: String? = nil
    var firstRowIsHeading = false
    var firstColumnIsHeading = false
    var maxColumnWidth = 120
    
    private var csvFile: CSVFile? = nil
    
    // despite the Info.plist settings, this is required to get upside down orientation to work
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        if (self.fileName != nil) {
            csvFile = CSVFile.init(fileName: self.fileName!, ofType: ".csv", inDocumentDirectory: false)

            if (csvFile != nil) {
                self.spreadsheetView.maxCellWidth = CGFloat(maxColumnWidth)
                self.spreadsheetView.setDataSource(dataSource: self, firstDataRowIsHeading: self.firstRowIsHeading, firstDataColumnIsHeading: self.firstColumnIsHeading)
            }
        }
    }
    
    // SpreadsheetViewDataSource methods
    func numRows() -> Int {
        if (self.csvFile == nil) {
            return 0
        }
        
        return self.csvFile!.numLines()
    }
    
    func numCols() -> Int {
        if (self.csvFile == nil) {
            return 0
        }
        
        return self.csvFile!.numItemsPerLine()
    }

    func getData(row: Int, col: Int) -> String {
        if (self.csvFile == nil) {
            return ""
        }
        
        return csvFile!.getItem(lineNum: row, itemNum: col)
    }
}
