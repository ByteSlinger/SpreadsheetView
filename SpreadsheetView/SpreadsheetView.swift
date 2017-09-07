//
//  SpreadsheetView.swift
//  SpreadsheetView
//
//  The SpreadsheetView contains:
//
//  SpreadsheetView (UIView)
//      - CornerView (UIView) - height and width constraints control HeadingRow height and HeadingColumn width
//          - CornerButton (UIButton) - Navigates to the 4 corners of the spreadsheet
//          - CornerHeading (UILabel) - Heading if column and row headings are in the data
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
let SPREADSHEETVIEW_MAX_CELL_WIDTH: CGFloat = 120.0
let SPREADSHEETVIEW_MIN_CELL_WIDTH: CGFloat = 40.0
let SPREADSHEETVIEW_DEFAULT_CELL_WIDTH: CGFloat = 64.0
let SPREADSHEETVIEW_DEFAULT_MARGIN: CGFloat = 8.0
let SPREADSHEETVIEW_DEFAULT_LABEL_FONT_SIZE: CGFloat = 18.0

// the dataSource returns the row/col data to fill the SpreadsheetView
public protocol SpreadsheetViewDataSource {
    func numRows() -> Int;
    func numCols() -> Int;
    func getData(row: Int, col: Int) -> String;
}

public class SpreadsheetView: UIView {

    @IBOutlet weak var cornerView: UIView!
    @IBOutlet weak var cornerButton: UIButton!
    @IBOutlet weak var cornerHeading: UILabel!
    @IBOutlet weak var headingRowView: HeadingRow!
    @IBOutlet weak var headingColumnView: HeadingColumn!
    @IBOutlet weak var tableView: TableView!

    // public vars caller can change
    public var maxCellWidth = SPREADSHEETVIEW_MAX_CELL_WIDTH
    
    // caller can override the colors and font sizes
    public var defaultsOverriden = false      // if true TableView and TableCell use following vars
    
    public var rowBackgroundColor = UIColor.white
    public var rowAlternateColor = UIColor.lightGray
    public var dataLabelHighlightedTextColor = UIColor.red
    public var dataLabelHighlightedBackgroundColor = UIColor.yellow.withAlphaComponent(0.25)
    public var dataLabelLeftMargin = SPREADSHEETVIEW_DEFAULT_MARGIN    // DOES NOT WORK
    public var dataLabelRightMargin = SPREADSHEETVIEW_DEFAULT_MARGIN   // DOES NOT WORK
    public var dataLabelFontSize = SPREADSHEETVIEW_DEFAULT_LABEL_FONT_SIZE
    public var dataLabelFontColor = UIColor.black
    public var headingBackgroundColor = UIColor.blue
    public var headingLabelFontColor = UIColor.white
    public var headingLabelFontSize = SPREADSHEETVIEW_DEFAULT_LABEL_FONT_SIZE
    
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
    private var headingColumnWidth: CGFloat = 0
    
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
        
        // sanity check
        if (self.dataSource == nil || self.numRows() <= 0 || self.numCols() <= 0) {
            return
        }
        
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
        var isCorner = false
        
        if (self.cornerRow == row && self.cornerCol == col) {
            isCorner = true
        }
        
        return isCorner
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        
        // put a thin border around our view
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.tableView.reloadVisible()
    }
    
    // force any color or font size changes
    public func overrideDefaults() {
        self.defaultsOverriden = true
        
        self.tableView.overrideDefaults()

        self.cornerButton.tintColor = self.headingLabelFontColor
        self.cornerView.backgroundColor = self.headingBackgroundColor
        self.headingRowView.backgroundColor = self.headingBackgroundColor
        self.headingColumnView.backgroundColor = self.headingBackgroundColor
    }
    
    // set the dataSource to the passed object, set the first row/col heading vars
    public func setDataSource(dataSource: SpreadsheetViewDataSource, firstDataRowIsHeading: Bool, firstDataColumnIsHeading: Bool) {
        self.dataSource = dataSource
        self.firstDataRowIsHeading = firstDataRowIsHeading
        self.firstDataColumnIsHeading = firstDataColumnIsHeading
        
        // get the corner heading if there is one
        if (firstDataColumnIsHeading && firstDataRowIsHeading) {
            self.cornerHeading.font = UIFont.boldSystemFont(ofSize: self.headingLabelFontSize)
            self.cornerHeading.textColor = self.headingLabelFontColor
            self.cornerHeading.text = self.getData(row: 0, col: 0, headingRow: false, headingColumn: false)
        } else {
            self.cornerHeading.text = ""
        }
        
        // make sure we free any previous array
        self.isSelected = Array(repeating: Array(repeating: false, count: dataSource.numCols()), count: dataSource.numRows())
        
        self.updateMaxWidth()       // need to know the largest cell in each column
        
        // set width of the heading column
        self.setHeadingColumnWidth()
        
        self.reloadData()
    }
    
    // set the dataSource to the passed object
    public func setDataSource(_ dataSource: SpreadsheetViewDataSource) {
        self.setDataSource(dataSource: dataSource, firstDataRowIsHeading: false, firstDataColumnIsHeading: false)
    }
    
    // reload the data for my components
    public func reloadData() {
        self.headingRowView.reloadData()
        self.headingColumnView.reloadData()
        self.tableView.reloadData()
    }
    
    // allow caller to scroll to the last line
    public func scrollToBottom() {
        if (self.dataSource != nil && self.numDataRows() > 0) {
            self.tableView.scrollToRow(self.numDataRows() - 1)
        
            self.reloadData()
        }
    }
    
    // call this after the data has been preloaded so we know the largest cell width for first column
    func setHeadingColumnWidth() {
        let lWidth = self.getHeadingColumnWidth()

        // This is the magic for resizing HeadingColumn, HeadingRow and TableView
        // In the Storyboard, CornerView constraints - width controls headingColumn width, height controls headingRow height
        // and TableView is resized by the HeadingColumn to the left and the HeadingRow on the top

        // remove old width constraint from CornerView
        for constraint in self.cornerView.constraints {
            if (constraint.firstAttribute == .width) {
                self.cornerView.removeConstraint(constraint)
            }
        }

        // add new width contstraint - this will force HeadingColumn, HeadingRow and TableView to resize
        self.cornerView.widthAnchor.constraint(equalToConstant: lWidth).isActive = true
    }
    
    // return the height of the TableView row
    func getRowHeight() -> CGFloat {
        let lHeight = self.tableView.rowHeight
        
        return lHeight
    }
    
    // return the width of the HeadingColumn
    func getHeadingColumnWidth() -> CGFloat {
        // only need to go thru here once
        if (self.headingColumnWidth < SPREADSHEETVIEW_MIN_CELL_WIDTH) {

           // if 1st col is a heading set the width to the max width
            if (self.firstDataColumnIsHeading) {
                var columnWidth = self.getColumnWidth(forCol: 0)
                
                if (self.firstDataRowIsHeading) {
                    let heading = self.getData(row: 0, col: 0, headingRow: false, headingColumn: false)
                    let headingWidth = self.calculateColumnWidth(heading, isHeading: true) + self.cornerButton.frame.width
                    
                    if (headingWidth > columnWidth) {
                        columnWidth = headingWidth
                    }
                }
                
                self.headingColumnWidth = columnWidth
            } else {
                // set width to width of widest row number 
                // highest number not necessarily widest depending on font
                // row nums 8, 88, 888, 8888, etc, tend to be the widest for example
                for row in 0 ... self.numRows() {
                    let value = String(row)
                    let lWidth = self.calculateColumnWidth(value, isHeading: true)
                    
                    if (lWidth > self.headingColumnWidth) {
                        self.headingColumnWidth = lWidth
                    }
                }
            }
        }
        
        return self.headingColumnWidth
    }
    
    // return the pre-calculated width for the passed column
    func getColumnWidth(forCol col: Int) -> CGFloat {
        var lWidth = SPREADSHEETVIEW_DEFAULT_CELL_WIDTH
        
        if (self.maxWidth.count > 0 && self.maxWidth[col] != nil) {
            lWidth = self.maxWidth[col]!
        }
        
        // ensure that its within app boundaries
        if (lWidth < SPREADSHEETVIEW_MIN_CELL_WIDTH) {
            lWidth = SPREADSHEETVIEW_MIN_CELL_WIDTH
        } else if (lWidth > self.maxCellWidth) {
            lWidth = self.maxCellWidth
        }
        
        return lWidth
    }
    
    // return the width for the passed data column
    func getDataColumnWidth(forCol col: Int) -> CGFloat {
        var dataCol = col
        
        if (self.firstDataColumnIsHeading) {
            dataCol = col + 1
        }
        
        return self.getColumnWidth(forCol: dataCol)
    }
    
    // use a UILabel to get the actual size needed to display the passed text in a label
    func calculateColumnWidth(_ value: String, isHeading: Bool) -> CGFloat {
        let label = UILabel()   // use a temporary label to figure out how big a label would be
        let margins = self.dataLabelLeftMargin + self.dataLabelRightMargin
        var lWidth = margins + SPREADSHEETVIEW_DEFAULT_CELL_WIDTH
        
        if (isHeading) {
            label.font = UIFont.boldSystemFont(ofSize: self.headingLabelFontSize)
        } else {
            label.font = UIFont.systemFont(ofSize: self.dataLabelFontSize)
        }
        
        label.text = value.trimmingCharacters(in: .whitespaces)
        
        // let UILabel tell me how big it could be
        lWidth = margins + label.intrinsicContentSize.width
       
        return lWidth
    }
    
    // set the max column width
    func setMaxColumnWidth(col: Int, width: CGFloat) {
        let oldWidth = self.maxWidth[col] ?? 0
        
        if (oldWidth == 0 || width > oldWidth) {
            self.maxWidth[col] = width
        }
    }
    
    // called the first time in getMaxColumnWidth()
    func updateMaxWidth() {
        var isHeading = false
        
        // spin thru all data (and optionally headers) and recalc the max width for each column
        if (self.numRows() > 0 && self.numCols() > 0) {
            for row in 0 ... self.numRows() - 1 {
                for col in 0 ... self.numCols() - 1 {
                    let value = self.getData(row: row, col: col, headingRow: false, headingColumn: false)
                
                    if (self.firstDataColumnIsHeading && col == 0) {
                        isHeading = true
                    } else if (self.firstDataRowIsHeading && row == 0) {
                        isHeading = true
                    } else {
                        isHeading = false
                    }
                    
                    // calculate the width based on a filled UILabel
                    let calculatedWidth = self.calculateColumnWidth(value, isHeading: isHeading)
                    
                    if (self.firstDataColumnIsHeading && row == 0 && col == 0) {
                        // skip the top right corner width if 1st col is heading
                    } else {
                        self.setMaxColumnWidth(col: col, width: calculatedWidth)
                    }
                }
            }
        }
    }
    
    // return the current content offset
    func getCurrentOffset() -> CGPoint {
        return self.currentOffset
    }
    
    // scroll the tableView and headingRow horizontally
    func scrollHorizontal(_ offset: CGPoint, updateHeadingRow: Bool, updateTableView: Bool) {
        if (self.isScrolling == false) {
            self.isScrolling = true                 // turn on semaphore
            
            if (self.currentOffset.x != offset.x) {
                self.cornerCol = -1
                self.cornerRow = -1
                
                let xOffset = CGPoint(x: offset.x, y: 0)
                
                self.currentOffset.x = xOffset.x
                if (updateHeadingRow) {
                    self.headingRowView.scrollHorizontal(xOffset)
                }
                if (updateTableView) {
                    self.tableView.scrollHorizontal(xOffset)
                }
            }
            
            self.isScrolling = false                // turn off semaphore
        }
    }
    
    // scroll the headingColumn vertically (tableView handles itself)
    func scrollVertical(_ offset: CGPoint, updateHeadingColumn: Bool, updateTableView: Bool) {
        if (self.isScrolling == false) {
            self.isScrolling = true                 // turn on semaphore
            
            if (self.currentOffset.y != offset.y) {
                self.cornerCol = -1
                self.cornerRow = -1

                let yOffset = CGPoint(x: 0, y: offset.y)
                
                self.currentOffset.y = offset.y
                
                if (updateHeadingColumn) {
                    self.headingColumnView.scrollVertical(yOffset)    // sync heading column with tableView
                }
                if (updateTableView) {
                    self.tableView.scrollVertical(yOffset)
                }
            }
            
            self.isScrolling = false              // turn off semaphore
        }
    }
    
    // scroll the TableView to the passed row and all the DataRow to the passed column
    func scrollToCell(_ row: Int, _ col: Int) {
        self.tableView.scrollToRow(self.checkIndex(index: row, lower: 0, upper: self.numDataRows()))
        self.tableView.scrollToCol(self.checkIndex(index: col, lower: 0, upper: self.numDataCols()))
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
            
            let width = self.calculateColumnWidth(heading, isHeading: true)
            
            self.setMaxColumnWidth(col: col, width: width)
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
    
    // make sure isSelected array is as large as needed to prevent Index out of range errors
    func getSetIsSelected(row: Int, col: Int, set: Bool, isSelected: Bool) -> Bool {
        var existingCols = self.isSelected.count > 0 ? self.isSelected[0].count : 0
        
        // sanity check
        if (row < 0 || col < 0) {
            return false
        }
        
        // get a max column count
        if (existingCols < col) {
            existingCols = col
        }
        
        // add new rows until we have enough
        while (self.isSelected.count <= row) {
            self.isSelected.append(Array(repeating: false, count: existingCols))
        }
        
        // add new cols to all rows until we have enough
        for i in 0 ... self.isSelected.count - 1 {
            while (self.isSelected[i].count <= existingCols) {
                self.isSelected[i].append(false)
            }
        }
        
        // now set the new isSelected value
        if (set) {
            self.isSelected[row][col] = isSelected
        }
        
        return self.isSelected[row][col]
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

        _ = self.getSetIsSelected(row: dataRow, col: dataCol, set: true, isSelected: selected)
    }
    
    // return the selected status of the passed cell
    func isSelected(row: Int, col: Int) -> Bool {
        let dataRow = self.checkIndex(index: row, lower: 0, upper: self.numDataRows())
        let dataCol = self.checkIndex(index: col, lower: 0, upper: self.numDataCols())
        var isSelected = false
        
        isSelected = self.getSetIsSelected(row: dataRow, col: dataCol, set: false, isSelected: false)
        
        return isSelected
    }
    
    // set all cells in the passed row to the passed selected value
    func setRowSelected(row: Int, selected: Bool) {
        let dataRow = self.checkIndex(index: row, lower: 0, upper: self.numDataRows())

        for col in 0 ... self.numCols() - 1 {
            _ = self.getSetIsSelected(row: dataRow, col: col, set: true, isSelected: selected)
        }
        
        self.tableView.setRowSelected(row: row, selected: selected)
    }
    
    // set all cells in the passed column to the passed selected value
    func setColumnSelected(col: Int, selected: Bool) {
        let dataCol = self.checkIndex(index: col, lower: 0, upper: self.numDataCols())

        for row in 0 ... self.numRows() - 1 {
            _ = self.getSetIsSelected(row: row, col: dataCol, set: true, isSelected: selected)
        }

        self.tableView.setColumnSelected(col: col, selected: selected)
    }
}
