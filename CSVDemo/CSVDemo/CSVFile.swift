//
//  CSVFile.swift
//  CSVFile
//
//      Return data from a CSV File.  Minimal memory is used to store only the current line.
//      Every [row][col] (aka, [line][item]) is read from the file as needed.  An initial
//      pass is made through the file to save the offset for each line (row).
//
//  Created by ByteSlinger on 8/24/17.
//  Copyright © 2017 ByteSlinger. All rights reserved.
//

import Foundation

let CSVFILE_DEFAULT_DELIMITER: Character = ","

public class CSVFile {
    private let me = "CSVFile"

    private var fileName = "sample"
    private var fileType = ".csv"
    private var inDocumentDirectory = true
    private var fileURL: URL? = nil
    private var fileHandle: FileHandle? = nil
    private var delimiter: Character = CSVFILE_DEFAULT_DELIMITER
    private var lineCount = 0                   // number of lines (rows) in the file
    private var itemCount = 0                   // items (columns) in first line (row) (this can get larger - see parseLine())
    private var fileLength = 0                  // total number of bytes in file
    private var offsets = [Int]()               // offset of beginning of each line
    private var currentLineNum = -1             // line number (row) of currently read and parsed line (zero relative)
    private var currentLineItems = [String]()   // array of items parsed from current line
    
    // open the file and load the line offsets
    public init(fileName: String, ofType: String, delimiter: Character, inDocumentDirectory: Bool) {
        self.fileName = fileName
        self.fileType = ofType
        self.delimiter = delimiter
        self.inDocumentDirectory = inDocumentDirectory
        
        // allow for files in 2 places:  The App Bundle or the Document Directory
        //
        // TODO:  add capability to read web URLs
        //
        if (inDocumentDirectory) {
            self.fileURL = self.createDocumentURL(fileName: fileName, ofType: ofType)
        } else {    // assume it's in the app Bundle
            self.fileURL = self.createBundleURL(fileName: fileName, ofType: ofType)
        }
        
        if (self.fileURL == nil) {
            print("\(me).init(\(fileName),\(ofType),\(inDocumentDirectory)) Failed!")
        } else {
            self.loadOffsets()
            
            // read the first line to get the number of items (columns) in each line (row)
            let line = self.readLine(0)
            if (line != nil) {
                self.currentLineItems = self.parseLine(line!)
                self.itemCount = self.currentLineItems.count
            }
        }
    }
    
    public convenience init(fileName: String, ofType: String, inDocumentDirectory: Bool) {
        self.init(fileName: fileName, ofType: ofType, delimiter: CSVFILE_DEFAULT_DELIMITER, inDocumentDirectory: inDocumentDirectory)
    }
    
    // return my private internal variables
    public func numLines() -> Int {
        return lineCount
    }
    
    public func numItemsPerLine() -> Int {
        return itemCount
    }
    
    public func getFileName() -> String {
        return self.fileName
    }
    
    public func getFileType() -> String {
        return self.fileType
    }
    
    public func getFileURL() -> URL? {
        return self.fileURL
    }
    
    public func path() -> String? {
        return self.fileURL!.path
    }
    // end of private internal variables
    
    // return a URL from a file in the App Bundle
    private func createBundleURL(fileName: String, ofType: String) -> URL? {
        var newURL: URL? = nil
        let bundlePath = Bundle.main.path(forResource: fileName, ofType: ofType)

        if (bundlePath == nil) {
            print("\(me).createBundleURL(\(fileName),\(ofType)) - Failed!")
        } else {
            newURL = URL.init(fileURLWithPath: bundlePath!)
        }
        
        return newURL   // may be nil
    }
    
    // return a URL from a file in the Document Directory
    private func createDocumentURL(fileName: String, ofType: String) -> URL? {
        var newURL: URL? = nil
        let dir = try? FileManager.default.url(for: .documentDirectory,
                                                in: .userDomainMask, appropriateFor: nil, create: true)
        
        if (dir == nil) {
            print("\(me).create:  Failed to get directory URL!")
        } else {
            newURL = dir?.appendingPathComponent(fileName + ofType)
        }
        
        return newURL   // may be nil
    }
    
    // spin thru the file and save the offsets to the beginning of each line
    private func loadOffsets() {
        self.lineCount = 0
        self.fileLength = 0
        self.offsets.removeAll()
        
        self.fileHandle = try? FileHandle.init(forReadingFrom: self.fileURL!)
        if (self.fileHandle == nil) {
            print("\(me).loadOffsets:  Failed to open \(self.fileURL?.relativeString ?? "?") for reading!")
        } else {
            var data = Data.init(capacity: 4096)
            
            // my loop vars
            var done = false
            var lines = 0
            var pos = 0
            var eol = false
            self.offsets.append(pos)   // always the first line
            lines += 1
            
            while (done == false) {
                data = fileHandle!.readData(ofLength: 4096)
                
                if (data.count <= 0) {
                    done = true
                } else {
                    //let buffer = String(data: data, encoding: .utf8)
                    
                    //print("data (\(data.count)) = \(buffer ?? "?")")
                    while(data.count > 0) {
                        let char = data.first
                        
                        if (char == 0x0A || char == 0x0D) {
                            eol = true
                        } else {            // non eol char
                            if (eol) {      // this is what we're looking for - beginning of a line
                                eol = false
                                self.offsets.append(pos)
                                lines += 1
                            }
                        }
                        
                        // get the next char
                        data.removeFirst()
                        pos += 1
                    }
                }   // else
            }   // while done == false
            
            //print("\(me).loadOffsets: file = \(self.fileName + self.fileType), lines = \(lines), pos = \(pos)")
            
            //for i in 0 ... self.offsets.count - 1 {
            //    print("row \(i) = offset \(self.offsets[i])")
            //}
            
            self.lineCount = lines
            self.fileLength = pos   // needed for length of last line
        }   // else
    }
    
    // get the requested line from the file
    public func readLine(_ lineNum: Int) -> String? {
        var offset = -1
        var length = 0
        var line: String? = nil
        
        if (self.fileHandle == nil) {
            return nil
        }
        
        if (lineNum >= 0 && lineNum < self.offsets.count) {
            offset = self.offsets[lineNum]
        } else {
            print("\(me).readLine(\(lineNum)) - lineNum out of range (0 - \(self.offsets.count - 1))")
        }
        
        if (offset >= 0) {
            if (lineNum >= self.offsets.count - 1) {
                length = self.fileLength - offset       // last line of file
            } else {
                length = self.offsets[lineNum + 1] - offset
            }
            
            if (length > 0) {
                self.fileHandle?.seek(toFileOffset: UInt64(offset)) // seek to previously read file offset
            
                let data = self.fileHandle?.readData(ofLength: length)
                
                if (data == nil) {
                    print("\(me).readLine(\(lineNum)) Failed! - offset = \(offset), length = \(length)")
                } else {
                    line = String(data: data!, encoding: .ascii)
                    if (line == nil) {
                        print("\(me).readLine(\(lineNum)) - Failed to convert to ascii")
                    } else {
                        line = line!.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            } else {
                print("\(me).readLine(\(lineNum)) - invalid length (\(length)), offset = \(offset)")
            }
        }
        
        return line
    }
    
    // parse the passed line into an array of strings
    func parseLine(_ inputLine: String) -> [String] {
        var line = inputLine    // so we can use popFirst
        var items = [String]()
        var item: String = ""
        var inQuotes = false
        var quoteCount = 0
        var char: Character? = nil
        
        while(line.characters.count > 0) {
            char = line.characters.popFirst()
            
            if (char != nil) {                  // should not happen, but check anyway
                if (char == "\"") {
                    if (inQuotes) {
                        if (quoteCount == 0) {
                            quoteCount += 1     // may be end of item or 1st of 2 double quotes
                        } else {
                            // must be 2nd of double quote - save 1
                            item.append(char!)
                            quoteCount = 0
                        }
                    } else {
                        inQuotes = true
                    }
                } else if (char == self.delimiter) {
                    if (inQuotes == false ||
                        (inQuotes == true && quoteCount == 1)) {
                        // end of item, trim whitespace and save it
                        items.append(item.trimmingCharacters(in: .whitespaces))
                        quoteCount = 0
                        inQuotes = false
                        item.removeAll()    // clear for next item
                    } else {
                        item.append(char!)
                    }
                } else {            // add char to item
                    item.append(char!)
                }
            }   // if (char != nil)
        }
        
        // there should be one more item at the end
        if (item.isEmpty == false) {
            items.append(item.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        // see if this line is larger than our previous item count
        if (items.count > self.itemCount) {
            self.itemCount = items.count
        } else {
            // Some CSV files are messed up and do not have the same number of items
            // on each line.  If so, we need to pad the array with empty strings.
            while(items.count < self.itemCount) {
                items.append("")
            }
        }
        
        return items
    }
    
    // get the requested item from the requested line
    public func getItem(lineNum: Int, itemNum: Int) -> String {
        var item = ""
        
        // sanity check
        if (lineNum < 0 || lineNum >= self.lineCount || itemNum < 0) {
            return item
        }
        
        // see if we have this line already
        if (lineNum != self.currentLineNum) {
            let line = self.readLine(lineNum)
            
            if (line != nil) {
                self.currentLineNum = lineNum
                self.currentLineItems = self.parseLine(line!)
            }
        }
        
        // get the item
        if (lineNum == self.currentLineNum) {
            if (itemNum < self.currentLineItems.count) {
                item = self.currentLineItems[itemNum]
            }
        }
        
        return item
    }
}
