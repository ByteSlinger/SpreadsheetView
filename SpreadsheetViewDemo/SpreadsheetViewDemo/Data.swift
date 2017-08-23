//
//  Data.swift
//  SpreadsheetViewDemo
//
//      Sample SpreadsheetViewDataSource code.
//
//  Created by ByteSlinger on 2017-08-10.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import UIKit
import SpreadsheetView

struct Cell {
    var value: String? = nil
}

class Data: SpreadsheetViewDataSource {
    var data = [[Cell?]]()
    
    var randomText = [
        "Lorem ipsum dolor sit amet",
        "Consectetur adipiscing elit",
        "Praesent odio tortor",
        "Laoreet nec egestas eu.",
        "Gravida vel tellus",
        "Quisque ligula urna, gravida vitae lobortis quis",
        "Pharetra eu sem",
        "Nullam in tellus varius, pulvinar risus et",
        "Feugiat massa. Maecenas luctus",
        "Quam vel suscipit luctus",
        "Ex sem elementum nunc",
        "Vitae pulvinar quam erat eu purus",
        "Cras sodales ac odio eget placerat",
        "Orci varius natoque penatibus et magnis dis parturient montes",
        "Nascetur ridiculus mus",
        "Nulla lacinia risus eget fringilla porttitor",
        "Curabitur aliquet diam facilisis fringilla porttitor",
        "Pellentesque dolor risus",
        "Gravida vitae tellus et",
        "Accumsan porta justo",
        "Interdum et malesuada fames ac ante ipsum primis in faucibus",
        "Sed vel enim sit amet ex efficitur rutrum",
        "Nullam dictum nec risus sit amet tincidunt",
        "Phasellus maximus",
        "Erat sit amet malesuada laoreet",
        "Neque turpis maximus ex",
        "Vitae placerat massa mauris et odio",
        "Proin quis metus congue",
        "Pellentesque arcu non",
        "Pulvinar felis"]

    // generic initializer
    init() {
        
    }
    
    // initialize with data
    init(random: Bool, rows: Int, cols: Int, headingRow: Bool, headingColumn: Bool) {
        data = generateData(random: random, rows: rows, cols: cols, headingRow: headingRow, headingColumn: headingColumn)
    }
    
    // random:  True = generate random data, False = use column/row heading
    // row/cols:  The number of rows and columns to create
    // rowHeading:  True = fill row 0 with column headings, False = use random or col/row values
    // colHeading:  True = fill col 0 with row headings, False = use random or col/row values
    func generateData(random: Bool, rows: Int, cols: Int, headingRow: Bool, headingColumn: Bool) -> [[Cell?]] {
        
        var data: [[Cell?]] = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        
        for col in 0...cols - 1 {
            let type = generateRandomNumber(3)
            
            for row in 0...rows - 1  {
                var value = String()
                
                if (headingRow && headingColumn && row == 0 && col == 0) {
                    value = ""
                } else if (headingRow && row == 0) {
                    if (headingColumn) {
                        value = self.getColumnLetterHeading(col - 1)
                    } else {
                        value = self.getColumnLetterHeading(col)
                    }
                } else if (headingColumn && col == 0) {
                    value = String(row)
                } else {    // only data here
                    if (random == true) {
                        if (type == 1) {
                            let offset = generateRandomNumber(randomText.count)
                            
                            value = randomText[offset - 1]
                        } else if (type == 2) {
                            let offset = generateRandomNumber(randomText.count)
                            
                            value = randomText[offset - 1].components(separatedBy: " ").first!
                        } else {
                            let max = ((row * col) % 6) * 10
                            
                            value = String(generateRandomNumber(max))
                        }
                    } else {
                        // just use the column and row
                        let dataRow = headingRow ? row - 1 : row
                        let dataCol = headingColumn ? col - 1 : col
                        
                        value = self.getColumnLetterHeading(dataCol) + "-" + String(dataRow + 1)
                    }
                }

                data[row][col] = Cell(value: value)
            }
        }
        return data
    }

    func generateRandomNumber(_ max: Int) -> Int {
        return Int(arc4random_uniform(UInt32(max)) + 1)
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
        
        //print("col = \(col), heading  \(heading)")

        return heading
    }
    
    // return the number if rows
    func rows() -> Int {
        return self.data.count
    }
    
    // return the number if columns in the 1st row
    func cols() -> Int {
        if (self.data.count == 0) {
            return 0
        }
        
        return self.data[0].count
    }
    
    // return the Cell Struct for the passed row/col
    func validIndexes(row: Int, col: Int, msg: String) -> Bool {
        if (row < 0 || row > data.count - 1 ||
            col < 0 || col > data[0].count - 1) {
            print("Data.\(msg)(\(row), \(col)) - invalid row/col")
            
            return false
        }
        
        return true
    }

    // return the Cell Struct for the passed row/col
    func getCell(row: Int, col: Int) -> Cell? {
        if (self.validIndexes(row: row, col: col, msg: "getCell")) {
        
            let cell = self.data[row][col]
        
            return cell
        }
        
        return nil
    }
    
    // SpreadsheetViewDataSource protocol functions
    
    func numRows() -> Int {
        return self.rows()
    }
    
    func numCols() -> Int {
        return self.cols()
    }
    
    func getData(row: Int, col: Int) -> String {
        let cell = self.getCell(row: row, col: col)
        
        if (cell == nil) {
            return ""
        }
        
        return cell!.value ?? ""
    }
}
