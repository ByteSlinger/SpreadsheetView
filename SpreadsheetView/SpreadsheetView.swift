//
//  SpreadsheetView.swift
//  SpreadsheetView
//
//  The SpreadsheetView contains:
//
//  SpreadsheetView (UIView)
//      - HeadingRow (UICollectionView - horizontal)
//          - TableCell (UICollectionViewCell)
//          ...
//          - TableCell (UICollectionViewCell)
//      - HeadingColumn (UICollectionView = vertical)
//          - TableCell (UICollectionViewCell)
//          ...
//          - TableCell (UICollectionViewCell)
//      - TableView (UITableView)
//          - TableViewCell (UITableViewCell)
//              - DataRow (UICollectionView)
//                  - TableCell (UICollectionViewCell)
//                  ...
//                  - TableCell (UICollectionViewCell)
//          ...
//          - TableCell (UITableViewCell)
//              - DataRow (UiCollectionView)
//                  - TableCell (UICollectionViewCell)
//                  ...
//                  - TableCell (UICollectionViewCell)
//
// The HeadingRow is fixed at the top and scrolls horizontally.
// The HeadingColumn is fixed at the left and scrolls vertically.
// Vertical scrolling is handled natively by the TableView.
// Horizontally scrolling is handled by the SpreadsheetView syncing the
// HeadingRow and the visible TableView Rows.
//
// NOTE:  the dataSource (SpreadsheetViewDataSource) must exist and conform to the protocol for anything to work
//
//  Created by ByteSlinger on 2017-08-10.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import UIKit

let me = "SpreadsheetView"

// for all CollectionViewCells
let DEFAULT_MAX_CELL_WIDTH: CGFloat = 120.0
let DEFAULT_MARGIN: CGFloat = 8.0
let DEFAULT_LABEL_FONT_SIZE: CGFloat = 18.0

// the dataSource returns the row/col data to fill the SpreadsheetView
public protocol SpreadsheetViewDataSource {
    func numRows() -> Int;
    func numCols() -> Int;
    func getData(row: Int, col: Int) -> String;
}

public class SpreadsheetView: UIView {

    @IBOutlet weak var cornerButton: UIButton!
    @IBOutlet weak var headingRowView: HeadingRow!
    @IBOutlet weak var headingColumnView: HeadingColumn!
    @IBOutlet weak var tableView: TableView!

    // public vars caller can change
    public var maxCellWidth = DEFAULT_MAX_CELL_WIDTH
    
    // caller can override the colors and font sizes
    public var defaultsOverriden = false      // if true TableView and TableCell use following vars
    
    public var rowBackgroundColor = UIColor.white
    public var rowAlternateColor = UIColor.lightGray
    public var dataLabelHighlightedTextColor = UIColor.red
    public var dataLabelHighlightedBackgroundColor = UIColor.yellow.withAlphaComponent(0.25)
    public var dataLabelLeftMargin = DEFAULT_MARGIN    // DOES NOT WORK
    public var dataLabelRightMargin = DEFAULT_MARGIN   // DOES NOT WORK
    public var dataLabelFontSize = DEFAULT_LABEL_FONT_SIZE
    public var dataLabelFontColor = UIColor.black
    public var headingBackgroundColor = UIColor.blue
    public var headingLabelFontColor = UIColor.white
    public var headingLabelFontSize = DEFAULT_LABEL_FONT_SIZE
    
    // call should set these if there are headings in their data
    private var firstDataRowIsHeading = false         // set this to true if the first row has column headings
    private var firstDataColumnIsHeading = false      // set this to true if the first column has row headings

    // the dataSource must be set for anything to work (setDataSource())
    private var dataSource: SpreadsheetViewDataSource? = nil
    
    // 2D array of Bool to manage selected cells:  isSelected[row][col]
    private var isSelected = [[Bool]]()
    
    // array of max column widths by column
    //  NOTE:  may include a header column depending on firstDataColumnIsHeading
    private var maxWidth = [Int: CGFloat]()
    
    private var currentOffset = CGPoint(x: -1.0, y: -1.0) // used for scrolling
    
    private var isScrolling = false                     // semaphore to prevent infinite scroll loops

    // for the corner button
    private var cornerRow = -1
    private var cornerCol = -1
    
    // It can be time consuming to page thru large amounts of data.
    // Use the corner button to scroll to each corner or back to the top
    @IBAction func scrollToCorner(_ sender: UIButton) {
        let maxCol = self.numDataCols() - 1
        let maxRow = self.numDataRows() - 1
        var newRow = 0
        var newCol = 0
        
        if (self.cornerRow == 0 && self.cornerCol == 0) {
            // go to top right
            newRow = 0
            newCol = maxCol
        } else if (self.cornerRow == 0 && self.cornerCol == maxCol) {
            // go to bottom right
            newRow = maxRow
            newCol = maxCol
        } else if (self.cornerRow == maxRow && self.cornerCol == maxCol) {
            // go to bottom left
            newRow = maxRow
            newCol = 0
        }

        self.scrollToCell(newRow,newCol)    // forces reset of cornerRow and cornerCol
        
        self.cornerRow = newRow
        self.cornerCol = newCol
        
        self.tableView.reloadData()
    }
    
    // for TableCell to blink current corner
    func isCurrentCorner(_ row: Int, _ col: Int) -> Bool {
        if (self.cornerRow == row && self.cornerCol == col) {
            return true
        }
        
        return false
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        
        // put a thin border around our view
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    // force any color or font size changes
    public func overrideDefaults() {
        self.defaultsOverriden = true
        
        self.tableView.overrideDefaults()

        self.cornerButton.tintColor = self.headingLabelFontColor
        self.cornerButton.backgroundColor = self.headingBackgroundColor
        self.headingRowView.backgroundColor = self.headingBackgroundColor
        self.headingColumnView.backgroundColor = self.headingBackgroundColor
    }
    
    // set the dataSource to the passed object, set the first row/col heading vars
    public func setDataSource(dataSource: SpreadsheetViewDataSource, firstDataRowIsHeading: Bool, firstDataColumnIsHeading: Bool) {
        self.setDataSource(dataSource)
        
        self.firstDataRowIsHeading = firstDataRowIsHeading
        self.firstDataColumnIsHeading = firstDataColumnIsHeading
    }
    
    // set the dataSource to the passed object
    public func setDataSource(_ dataSource: SpreadsheetViewDataSource) {
        self.firstDataRowIsHeading = false      // in case dataSoure changed
        self.firstDataColumnIsHeading = false   // ditto
        
        self.dataSource = dataSource
        
        // make sure we free any previous array
        self.isSelected = Array(repeating: Array(repeating: false, count: dataSource.numCols()), count: dataSource.numRows())
        
        self.updateMaxWidth()       // important - need to know the largest cell in each column
    }
    
    // calc the width for the passed column and return
    // NOTE:  this is called by CollectionViewCell so the width is based on fontsize and margins
    func updateMaxColumnWidth(forCol col: Int, width: CGFloat) {
        let oldWidth = maxWidth[col] ?? 0
        var newWidth = width
        
        if (newWidth > self.maxCellWidth) {
            newWidth = self.maxCellWidth
        }
        if (oldWidth == 0 || newWidth > oldWidth) {
            maxWidth[col] = newWidth
        }
    }
    
    // update the maxWidth for the passed column and return
    func getMaxColumnWidth(forCol col: Int, width: CGFloat) -> CGFloat {
        // preload the column sizes the first time when displaying the first cell
        if (maxWidth.count == 0) {
            updateMaxWidth()
        }
 
        let dataCol = self.firstDataColumnIsHeading ? col + 1 : col

        self.updateMaxColumnWidth(forCol: dataCol, width: width)
        
        return maxWidth[dataCol]!
    }
    
    // called the first time in getMaxColumnWidth()
    func updateMaxWidth() {
        // spin thru all data (and optionally headers) and recalc the max width for each column
        for row in 0 ... self.numRows() - 1 {
            for col in 0 ... self.numCols() - 1 {
                let value = self.getData(row: row, col: col, headingRow: false, headingColumn: false)
                let length = value.lengthOfBytes(using: .ascii)
                let width = (CGFloat(length) * self.dataLabelFontSize)
                let cellWidth = width + self.dataLabelLeftMargin + self.dataLabelRightMargin
                
                self.updateMaxColumnWidth(forCol: col, width: cellWidth)
            }
        }
    }
    
    // return the width for the passed column
    func getColumnWidth(forCol col: Int) -> CGFloat {
        return self.getMaxColumnWidth(forCol: col, width: 0)
    }
    
    // return the current content offset
    func getCurrentOffset() -> CGPoint {
        return self.currentOffset
    }
    
    // scroll the tableView and headingRow horizontally
    func scrollHorizontal(_ offset: CGPoint) {
        if (self.isScrolling == false) {
            self.isScrolling = true                 // turn on semaphore
            
            if (self.currentOffset.x != offset.x) {
                //print("\(me).ScrollHorizontal offset = \(offset.x)/\(offset.y), current = \(self.currentOffset.x)/\(self.currentOffset.y)")
                
                self.cornerCol = -1
                self.cornerRow = -1
                
                let xOffset = CGPoint(x: offset.x, y: 0)
                
                self.currentOffset.x = xOffset.x
                
                self.tableView.scrollTo(xOffset)
                
                self.headingRowView.scrollTo(xOffset)
            }
            
            self.isScrolling = false                // turn off semaphore
        }
    }
    
    // scroll the headingColumn vertically (tableView handles itself)
    func scrollVertical(_ offset: CGPoint) {
        if (self.isScrolling == false) {
            self.isScrolling = true                 // turn on semaphore
            
            if (self.currentOffset.y != offset.y) {
                //print("\(me).ScrollVertical offset = \(offset.x)/\(offset.y), current = \(self.currentOffset.x)/\(self.currentOffset.y)")

                self.cornerCol = -1
                self.cornerRow = -1

                let yOffset = CGPoint(x: 0, y: offset.y)
                
                self.currentOffset.y = offset.y
                
                self.headingColumnView.scrollTo(yOffset)    // sync heading column with tableView
            }
            
            self.isScrolling = false              // turn off semaphore
        }
    }
    
    // scroll the TableView to the passed row and all the DataRow to the passed column
    func scrollToCell(_ row: Int, _ col: Int) {
        self.tableView.scrollToCol(self.checkIndex(index: col, lower: 0, upper: self.numDataCols()))
        self.tableView.scrollToRow(self.checkIndex(index: row, lower: 0, upper: self.numDataRows()))
    }
    
    // convert a numeric column heading to alpha (1 = A)
    func getColumnLetterHeading(_ col: Int) -> String {
        let headingA = Int(UnicodeScalar("A").value)
        let headingZ = Int(UnicodeScalar("Z").value)
        var heading = String(col)   // fallback
        let baseHeading = col % (headingZ - headingA + 1)   // get 0-25
        
        if let myUnicodeScalar = UnicodeScalar(headingA + baseHeading) {
            heading = String(Character(myUnicodeScalar))
        }
        
        // if greater than 26, use A1, B1, ... up to Znnn
        if (col > baseHeading) {
            heading += String(col / (headingZ - headingA + 1))
        }
        
        return heading
    }
    
    // return the actual number of rows in the data array
    private func numRows() -> Int {
        if (self.dataSource == nil) {
            return 0
        }
        
        let rows = self.dataSource!.numRows()
        
        return rows
    }
    
    // return the number of data rows (subtract 1 if there is a header row)
    func numDataRows() -> Int {
        var rows = self.numRows()
        
        if (rows > 0) {
            // don't include the heading row in the count
            if (self.firstDataRowIsHeading) {
                rows -= 1
            }
        }
        
        return rows
    }

    // return the actual number of cols in the data array
    private func numCols() -> Int {
        if (self.dataSource == nil) {
            return 0
        }
        
        return self.dataSource!.numCols()
    }
    
    // return the number of data columns (subtract 1 if there is a header column)
    func numDataCols() -> Int {
        var cols = self.numCols()
        
        if (cols > 0) {
            if (self.firstDataColumnIsHeading) {
                cols -= 1
            }
        }
        
        return cols
    }
    
    // return the value from the dataSource for the passed row/col
    func getData(row: Int, col: Int) -> String {
        return self.getData(row: row, col: col, headingRow: self.firstDataRowIsHeading, headingColumn: self.firstDataColumnIsHeading)
    }
    
    // return the value from the dataSource for the passed row/col and allow for column headings in data
    func getData(row: Int, col: Int, headingRow: Bool, headingColumn: Bool) -> String {
        if (self.dataSource == nil) {
            return ""
        }
        
        // increment row by 1 to skip row 0 if it's a heading row
        let dataRow = headingRow ? row + 1 : row
        
        // increment row by 1 to skip col 0 if it's a heading col
        let dataCol = headingColumn ? col + 1 : col
        
        let data = self.dataSource!.getData(row: dataRow, col: dataCol)
        
        return data
    }
    
    // return the heading for the passed column
    func getColumnHeading(col: Int) -> String {
        let headingCol = self.firstDataColumnIsHeading ? col + 1 : col
        var heading = self.getColumnLetterHeading(col)
        
        if (self.numRows() > 0 &&
            self.firstDataRowIsHeading &&
            headingCol < self.numCols()) {
                
            heading = self.dataSource!.getData(row: 0, col: headingCol)
        }
        
        return heading
    }
    
    // return the heading for the passed row
    func getRowHeading(row: Int) -> String {
        let headingRow = self.firstDataRowIsHeading ? row + 1 : row
        var heading = String(row + 1)
        
        if (self.numRows() > 0 &&
            self.firstDataColumnIsHeading &&
            self.numCols() > 0 &&
            headingRow < self.numRows()) {
            
            heading = self.dataSource!.getData(row: headingRow, col: 0)
        }

        return heading
    }
    // sanity check an index
    func checkIndex(index: Int, lower: Int, upper: Int) -> Int {
        var result = index
        
        if (index < lower) {
            result = lower
        } else if (index >= upper) {
            result = upper - 1
        }
        
        return result
    }
    
    // set passed cell as selected
    func setSelected(row: Int, col: Int, selected: Bool) {
        let dataRow = self.checkIndex(index: row, lower: 0, upper: self.numDataRows())
        let dataCol = self.checkIndex(index: col, lower: 0, upper: self.numDataCols())
        
        self.isSelected[dataRow][dataCol] = selected
    }
    
    // return the selected status of the passed cell
    func isSelected(row: Int, col: Int) -> Bool {
        let dataRow = self.checkIndex(index: row, lower: 0, upper: self.numDataRows())
        let dataCol = self.checkIndex(index: col, lower: 0, upper: self.numDataCols())
        var isSelected = false
        
        isSelected = self.isSelected[dataRow][dataCol]
        
        return isSelected
    }
    
    // set all cells in the passed row to the passed selected value
    func setRowSelected(row: Int, selected: Bool) {
        let dataRow = self.checkIndex(index: row, lower: 0, upper: self.numDataRows())

        for col in 0 ... self.numCols() - 1 {
            self.isSelected[dataRow][col] = selected
        }
        
        self.tableView.setRowSelected(row: row, selected: selected)
    }
    
    // set all cells in the passed column to the passed selected value
    func setColumnSelected(col: Int, selected: Bool) {
        let dataCol = self.checkIndex(index: col, lower: 0, upper: self.numDataCols())

        for row in 0 ... self.numRows() - 1 {
            self.isSelected[row][dataCol] = selected
        }

        self.tableView.setColumnSelected(col: col, selected: selected)
    }
}
