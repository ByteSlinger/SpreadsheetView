//
//  TableRow.swift
//  SpreadsheetView
//
//  Created by ByteSlinger on 2017-08-10.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import UIKit

let DATA_ROW_ID = "DataRow"

class DataRow: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var spreadsheetView: SpreadsheetView!
    
    let reuseIdentifier = DATA_ROW_ID
    
    private var isScrolling = false             // semaphore to prevent infinite scroll loops

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // so we don't have to bother setting them in the storyboard
        self.dataSource = self
        self.delegate = self
        
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false       
        self.allowsMultipleSelection = true
        
        // turn off all bouncing so scrolling/syncing works cleanly
        self.bounces = false
        self.alwaysBounceVertical = false
        self.alwaysBounceHorizontal = false
    }
    
    // ScrollViewDelegate Method - let SpreadsheetView scroll all visible DataRows
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset

        // tell the spreadsheetView to scroll all visible DataRows
        self.spreadsheetView.scrollHorizontal(offset,updateHeadingRow: true, updateTableView: true)
    }
    
    // set the contentOffset and tell SpreadsheetView to scroll all visible rows
    func scrollHorizontal(_ offset: CGPoint) {
        if (self.isScrolling == false) {
            self.isScrolling = true             // turn on sempahore to prevent infinite loop
            
            if (offset.x != self.contentOffset.x) {
                self.contentOffset = offset
            }
            
            self.reloadData()   // for cornerButton scrolling to work properly
            
            self.isScrolling = false            // turn off semaphore since all cells are scrolled
        }
    }
    
    // scroll the CollectionView to the passed item (column)
    func scrollToCell(_ item: Int) {
        let indexPath = IndexPath(item: item, section: 0)
        
        self.scrollToItem(at: indexPath, at: .right, animated: false)
    }

    // set all cells to the passed selected value
    func setRowSelected(selected: Bool) {
        let indexPaths = self.indexPathsForVisibleItems
        
        for indexPath in indexPaths {
            let cell = self.cellForItem(at: indexPath) as! TableCell
            
            cell.setIsSelected(selected)
            
            if (selected) {
                self.selectItem(at: indexPath, animated: true, scrollPosition: .top)
            } else {
                self.deselectItem(at: indexPath, animated: true)
            }
        }
    }
    
    // set only the passed item(col) to the passed selected value
    func setColumnSelected(col: Int, selected: Bool) {
        let indexPaths = self.indexPathsForVisibleItems
        
        for indexPath in indexPaths {
            if (indexPath.item == col) {
                let cell = self.cellForItem(at: indexPath) as! TableCell
                
                cell.setIsSelected(selected)
                
                if (selected) {
                    self.selectItem(at: indexPath, animated: true, scrollPosition: .top)
                } else {
                    self.deselectItem(at: indexPath, animated: true)
                }
                
                return
            }
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout protocol
    
    // return the size of the requested cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let height = collectionView.frame.height
        let width = self.spreadsheetView.getDataColumnWidth(forCol: indexPath.row)
        
        return CGSize(width: width, height: height)
    }
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.spreadsheetView.numDataCols()
    }
    
    // get a reusable cell for this index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // get a reusable storyboard cell
        let tableCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! TableCell
        
        return tableCell
    }
    
    // fill the cell accordingly
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let tableCell = cell as! TableCell
        let row = collectionView.tag
        let col = indexPath.row
        let value = self.spreadsheetView.getData(row: row, col: col)
        let selected = self.spreadsheetView.isSelected(row: row, col: col)
        
        tableCell.setup(row: row, col: col, value: value, heading: false, selected: selected, adjustWidth: true)
    }
    
    // MARK: - UICollectionViewDelegate protocol
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! TableCell

        cell.setIsSelected(true)
        
        self.spreadsheetView.setSelected(row: collectionView.tag, col: indexPath.row, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! TableCell

        cell.setIsSelected(false)

        self.spreadsheetView.setSelected(row: collectionView.tag, col: indexPath.row, selected: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
}
