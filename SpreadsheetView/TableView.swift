//
//  TableView.swift
//  SpreadsheetView
//
//  Created by ByteSlinger on 2017-08-10.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import UIKit

// IMPORTANT:  set tags the same as what is in the storyboard
let TABLEVIEW_CELL_ID = "TableViewCell"      // TableViewCell reuse identifier

class TableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    // IMPORTANT:  need connection back to spreadSheetView in Storyboard
    @IBOutlet weak var spreadsheetView: SpreadsheetView!
    
    var rowBackgroundColor = UIColor()  // default is set by Storyboard background
    var rowAlternateColor = UIColor()   // default is set by Storyboard tint background

    var isScrolling = false             // semaphore to prevent infinite scroll loops
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // so we don't have to bother setting them in the storyboard
        self.dataSource = self
        self.delegate = self
        
        self.showsHorizontalScrollIndicator = true
        self.showsVerticalScrollIndicator = true
        self.isScrollEnabled = true                 // this must be true for vertical scrolling to work
        self.allowsMultipleSelection = true
        
        // setup the bouncing and touches so they work for the spreadsheetView
        self.bounces = false
        self.alwaysBounceHorizontal = false
        self.alwaysBounceVertical = false
        self.bouncesZoom = false
        self.delaysContentTouches = true
        self.canCancelContentTouches = true
        
        self.rowBackgroundColor = self.backgroundColor!
        self.rowAlternateColor = self.tintColor!
    }
    
    // SpreadsheetView can override things
    func overrideDefaults() {
        self.rowBackgroundColor = self.spreadsheetView.rowBackgroundColor
        self.rowAlternateColor = self.spreadsheetView.rowAlternateColor
        
        self.backgroundColor = self.rowBackgroundColor
    }
    
    // sometimes this is the best way to force the reload of cells
    func reloadVisible() {
         let visibleCells = self.visibleCells
        
         var indexPaths = [IndexPath]()
         
         for cell in visibleCells {
            indexPaths.append(IndexPath(row: cell.tag, section: 0))
         }
         
         self.reloadRows(at: indexPaths, with: .none)
    }
    
    // set the isSelected property for the passed column in all visible rows
    func setColumnSelected(col: Int, selected: Bool) {
        let visible = self.visibleCells
        
        for cell in visible {
            let tableViewCell = cell as! TableViewCell
            
            tableViewCell.dataRow.setColumnSelected(col: col, selected: selected)
        }
    }
    
    // set the isSelected property for the passed row (if it is visible)
    func setRowSelected(row: Int, selected: Bool) {
        let visible = self.visibleCells
        
        for cell in visible {
            if (cell.tag == row) {
                let tableViewCell = cell as! TableViewCell
            
                tableViewCell.dataRow.setRowSelected(selected: selected)
            }
        }
    }
    
    // scroll all visible rows to the passed offset
    func scrollHorizontal(_ offset: CGPoint) {
        if (self.isScrolling == false) {
            self.isScrolling = true             // turn on sempahore to prevent infinite loop
            
            let visible = self.visibleCells
            
            for cell in visible {
                let tableViewCell = cell as! TableViewCell
                let xOffset = CGPoint(x: offset.x, y: 0)        // only use the x component
                
                tableViewCell.dataRow.setContentOffset(xOffset, animated: false)
            }
            
            self.isScrolling = false            // turn off semaphore since all cells are scrolled
        }
    }
    
    // scroll all visible rows to the passed offset
    func scrollVertical(_ offset: CGPoint) {
        if (self.isScrolling == false) {
            self.isScrolling = true             // turn on sempahore to prevent infinite loop

            self.contentOffset.y = offset.y
            
            self.isScrolling = false            // turn off semaphore since all cells are scrolled
        }
    }
    
    // scroll to the passed row
    func scrollToRow(_ row: Int) {
        let numDataRows = self.spreadsheetView.numDataRows()
        var dataRow = row
        
        // sanity check
        if (row < 0) {
            dataRow = 0
        } else if (row >= numDataRows) {
            dataRow = numDataRows - 1
        }
        
        let indexPath = IndexPath(item: dataRow, section: 0)
        
        self.reloadData()
        
        self.scrollToRow(at: indexPath, at: .top, animated: false)
    }
    
    // scroll all visible rows to the passed column
    func scrollToCol(_ col: Int) {
        let visible = self.visibleCells
        let numDataCols = self.spreadsheetView.numDataCols()
        var dataCol = col
        
        // sanity check
        if (col < 0) {
            dataCol = 0
        } else if (col >= numDataCols) {
            dataCol = numDataCols - 1
        }
        
        for cell in visible {
            let tableViewCell = cell as! TableViewCell
            
            tableViewCell.dataRow.scrollToCell(dataCol)
        }
    }
    
    // MARK - UIScrollViewDelegate Methods
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        
        self.spreadsheetView.scrollVertical(offset,updateHeadingColumn: true, updateTableView: false)
    }
    
    // MARK - UITableViewDelegate and UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rows = self.spreadsheetView.numDataRows()
        
        return rows
    }
    
    // return another reusable TableView cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TABLEVIEW_CELL_ID, for: indexPath) as! TableViewCell
        
        return cell
    }
    
    // setup the TableViewCell
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TableViewCell else { return }
        
        tableViewCell.tag = indexPath.row
        
        tableViewCell.dataRow.tag = indexPath.row
        
        var offset = self.spreadsheetView.getCurrentOffset()
        offset.y = 0
        
        tableViewCell.dataRow.scrollHorizontal(offset)

        // alternate the bg color on rows
        if (indexPath.row % 2 == 0) {
            tableViewCell.dataRow.backgroundColor = self.rowBackgroundColor
        } else {
            tableViewCell.dataRow.backgroundColor = self.rowAlternateColor
        }
    }
}
