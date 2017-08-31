//
//  HeadingRow.swift
//  SpreadsheetView
//
//  Created by ByteSlinger on 2017-08-10.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import UIKit

let HEADING_ROW_ID = "HeadingRow"

class HeadingRow: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var spreadsheetView: SpreadsheetView!
    
    let reuseIdentifier = HEADING_ROW_ID
    
    private var isScrolling = false             // semaphore to prevent infinite scroll loops
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // so we don't have to bother setting them in the storyboard
        self.dataSource = self
        self.delegate = self
        
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.isScrollEnabled = true
        self.allowsMultipleSelection = true
        
        // turn off all bouncing so scrolling/syncing works properly
        self.bounces = false
        self.alwaysBounceVertical = false
        self.alwaysBounceHorizontal = false
     }
    
    // sync the heading row with the passed contentOffset
    func scrollHorizontal(_ offset: CGPoint) {
        if (self.isScrolling == false) {
            self.isScrolling = true

            if (offset.x != self.contentOffset.x) {
                self.contentOffset.x = offset.x
            }
            
            self.isScrolling = false
        }
    }
    
    // scroll the CollectionView to the passed item (column)
    func scrollToCell(_ item: Int) {
        let indexPath = IndexPath(item: item, section: 0)
        
        self.scrollToItem(at: indexPath, at: .left, animated: false)
    }
    
    // MARK: - UIScrollViewDelegate Methods
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        
        self.spreadsheetView.scrollHorizontal(offset,updateHeadingRow: false, updateTableView: true)
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
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // get a reference to our storyboard cell
        let tableCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! TableCell
        
        return tableCell
    }
    
    // setup the cell accordingly
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let tableCell = cell as! TableCell
        let row = collectionView.tag
        let col = indexPath.row

        let value = self.spreadsheetView.getColumnHeading(col: indexPath.row)
        
        tableCell.setup(row: row, col: col, value: value, heading: true, selected: false, adjustWidth: true)
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.spreadsheetView.setColumnSelected(col: indexPath.row, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.spreadsheetView.setColumnSelected(col: indexPath.row, selected: false)
    }

}
