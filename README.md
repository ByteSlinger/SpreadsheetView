# SpreadsheetView
A read-only SpreadsheetView framework and 2 Demo apps for it

Look at **[SpreadsheetView.swift](./SpreadsheetView/SpreadsheetView.swift)** for an overview and the hierarchy of objects (tried to put them here but the text editing is limited and was not readable...)

SpreadsheetView is a framework for iOS that uses a UITableView object, which contains UITableViewCell objects which contain UICollectionView objects.  Each UICollectionView object has UICollectionViewCell objects, each containing a UILabel object, which are the cells of the spreadsheet.

The UITableViewCell objects are the rows of the spreadsheet and the UICollectionViewCell objects make up the columns of the spreadsheet.  The scrolling is synchronized so the rows and columns line up, as they do in typical spreadsheet implementations.

There are also 2 UICollectionView objects used for the horizontal row of column headings and the vertical column of row headings.

Included in the repo are 2 apps to demonstrate how to use the SpreadsheetView framework:

  * SpreadsheetViewDemo app - randomly generated data.
  * CSVDemo app - several sample CSV files

-----
ByteSlinger

Here is a screenshot from the SpreadsheetViewDemo app on an iPad.

![spreadsheetviewdemo](https://user-images.githubusercontent.com/2251646/32409648-dfad554c-c16c-11e7-80fa-f763b4663cc0.png)
