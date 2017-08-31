//
//  TableCell.swift
//  SpreadsheetView
//
//  Created by ByteSlinger on 2017-08-10.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import UIKit

class TableCell: UICollectionViewCell {
    @IBOutlet weak var spreadsheetView: SpreadsheetView!
    @IBOutlet weak var label: UILabel!
    
    // defaults gotten from Storyboard settings, caller can change them
    var normalBackgroundColor = UIColor.white.withAlphaComponent(0.0)
    var fontSize = CGFloat()
    var textColor = UIColor()
    var leftMargin = CGFloat()
    var rightMargin = CGFloat()
    var highlightedBackgroundColor = UIColor()
    var highlightedTextColor = UIColor()
    
    // is this a heading cell
    var isHeading = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
        if (self.backgroundColor != nil) {
            self.normalBackgroundColor = self.backgroundColor!.withAlphaComponent(0.0)  // transparent so alt row color works
        }
        self.highlightedBackgroundColor = UIColor.yellow.withAlphaComponent(0.25)
        self.highlightedTextColor = self.label.highlightedTextColor ?? UIColor.black
        self.fontSize = self.label.font!.pointSize
        self.textColor = self.label.textColor ?? UIColor.black
        self.leftMargin = self.label.layoutMargins.left
        self.rightMargin = self.label.layoutMargins.right
        
        if (self.spreadsheetView.defaultsOverriden) {
            self.overrideDefaults()
        }
    }
    
    // allow the ViewController that owns the SpreadsheetView to override the default colors
    func overrideDefaults() {
        if (self.reuseIdentifier == DATA_ROW_ID) {
            self.fontSize = self.spreadsheetView.dataLabelFontSize
            self.textColor = self.spreadsheetView.dataLabelFontColor
            self.leftMargin = self.spreadsheetView.dataLabelLeftMargin
            self.rightMargin = self.spreadsheetView.dataLabelRightMargin
            self.highlightedTextColor = self.spreadsheetView.dataLabelHighlightedTextColor
            self.highlightedBackgroundColor = self.spreadsheetView.dataLabelHighlightedBackgroundColor
        } else if (self.reuseIdentifier == HEADING_ROW_ID || self.reuseIdentifier == HEADING_COLUMN_ID) {
            self.fontSize = self.spreadsheetView.headingLabelFontSize
            self.textColor = self.spreadsheetView.headingLabelFontColor
            self.normalBackgroundColor = self.spreadsheetView.headingBackgroundColor
        }
    }
    
    // setup this TableCell.  Use the filled label.text to adjust the cell / column size
    func setup(row: Int, col: Int, value: String, heading: Bool, selected: Bool,  adjustWidth: Bool) {
        var newWidth: CGFloat = 0
        
        self.isHeading = heading
        
        self.label.text = value
        
        // initially from Storyboard but may be overriden by SpreadsheetView
        self.label.textColor = self.textColor
        self.label.backgroundColor = self.normalBackgroundColor
        self.label.layoutMargins.left = self.leftMargin
        self.label.layoutMargins.right = self.rightMargin
        
        if (heading) {
            self.label.font = UIFont.boldSystemFont(ofSize: self.fontSize)
            self.label.textAlignment = .center
            self.label.textColor = self.textColor
            self.backgroundColor = self.normalBackgroundColor
        } else {
            self.label.font = UIFont.systemFont(ofSize: self.fontSize)
            let number = Double(self.label.text!)
            
            if (number == nil) {  //  not numeric
                self.label.textAlignment = .left
            } else {
                self.label.textAlignment = .right
            }
            
            self.setIsSelected(selected)
        }
        
        if (adjustWidth) {
            // max column widths were preloaded - get them from SpreadsheetView
            if (self.reuseIdentifier == HEADING_COLUMN_ID) {
                newWidth = self.spreadsheetView.getHeadingColumnWidth()
            } else {
                newWidth = self.spreadsheetView.getDataColumnWidth(forCol: col)
            }
            
            self.frame.size.width = newWidth
        }
        
        // set the border around each cell
        if(heading == false && self.spreadsheetView.isCurrentCorner(row, col)) {
            // special border if it is the currentCorner cell
            self.layer.borderWidth = 1.0
            self.layer.borderColor = UIColor.red.cgColor
        } else {
            self.layer.borderWidth = 0.25
            self.layer.borderColor = UIColor.lightGray.cgColor
        }
    }
    
    // set this tableCell as selected or not
    func setIsSelected(_ selected: Bool) {
        self.isSelected = selected
        self.isHighlighted = selected
        self.label.isHighlighted = selected
        
        if (selected) {
            self.label.highlightedTextColor = self.highlightedTextColor
            self.backgroundColor = self.highlightedBackgroundColor
        } else {
            self.label.textColor = self.textColor
            self.backgroundColor = self.normalBackgroundColor   // should be transparent woth alpha 0.0
        }
    }
}
