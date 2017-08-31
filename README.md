# SpreadsheetView
A read-only SpreadsheetView framework and 2 Demo apps for it

From SpreadsheetView/SpreadsheetView.swift:

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

SpreadsheetView is a framework for iOS that uses a UITableView object, which contains UITableViewCell objects which contain UICollectionView objects.  Each UICollectionView object has UICollectionViewCell objects, each containing a UILabel object, which are the cells of the spreadsheet.

The UITableViewCell objects are the rows of the spreadsheet and the UICollectionViewCell objects make up the columns of the spreadsheet.  The scrolling is synchronized so the rows and columns line up, as they do in typical spreadsheet implementations.

There are also 2 UICollectionView objects used for the horizontal row of column headings and the vertical column of row headings.

Included in the repo are 2 apps to demonstrate how to use the SpreadsheetView framework:

  * SpreadsheetViewDemo app - randomly generated data.
  * CSVDemo app - several sample CSV files

-----
ByteSlinger
