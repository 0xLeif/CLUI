import EKit
import Later

import SwiftShell

print("Hello, \(E.panda.rawValue)!")

let debug = false

var isRunning = true
var lines = 0
var cols = 0

Later.scheduleRepeatedTask(initialDelay: .zero,
                           delay: .milliseconds(250)) { (task) in
    try! step()
}

while isRunning {} // MARK: End of Code.

// MARK: Objects

struct Rect {
    let x: Int
    let y: Int
    var z: Int = 0
    
    let width: Int
    let height: Int
    
    var backgroundCharacter: Character = "-"
    var borderCharacter: Character = "*"
    var cornerCharacter: Character = "X"
}


// MARK: Logic

enum CLUIError: Error {
    case invalid_size
    case padding_size
}

func step() throws {
    let size = run("stty", "size").stdout.split(separator: " ")

    guard let sttyLines = Int(size[0]),
          let sttyCols = Int(size[1]) else {
        fatalError("[Error] `stty size` failed to give expected output!")
    }

    if debug {
    print("Current Lines: \(sttyLines)")
    print("Current Columns: \(sttyCols)")
    }
        
    guard sttyLines > 0,
          sttyCols > 0 else {
        throw CLUIError.invalid_size
    }
    
    lines = sttyLines
    cols = sttyCols

    clearScreen()
    print(boxOutput())
}

func build(rect: Rect) -> [[Character?]]? {
    var box: [[Character?]] = [[Character?]](repeating:
                                                [Character?](repeating: nil,
                                                             count: cols),
                                             count: lines)
    let lineStart = rect.y
    let lineEnd = lineStart + rect.height
    
    let colStart = rect.x
    let colEnd = colStart + rect.width
    
    for line in lineStart ... lineEnd {
        for col in colStart ... colEnd {
            guard line >= 0,
                line < lines,
                col >= 0,
                col < cols else {
                break
            }
                  
            
            let isLeadingBottom = line == lineEnd && col == colStart
            let isLeadingTop = line == lineStart && col == colStart
            let isTrailingBottom = line == lineEnd && col == colEnd
            let isTrailingTop = line == lineStart && col == colEnd
            if isLeadingBottom || isLeadingTop || isTrailingBottom || isTrailingTop {
                box[line][col] = rect.cornerCharacter
            } else if line == lineStart ||
                        line == lineEnd ||
                        col == colStart ||
                        col == colEnd {
                box[line][col] = rect.borderCharacter
            } else {
                box[line][col] = rect.backgroundCharacter
            }
        }
    }
    
    return box
}

func buildBox(padding: Int = 4,
              rects: [Rect] = []) -> [[Character]]? {
    // Build Bound Box
    
    var box: [[Character]] = [[Character]](repeating:
                                            [Character](repeating: " ",
                                                        count: cols),
                                           count: lines)
    
    let lineStart = 0 + padding
    let lineEnd = lines - padding - 1
    
    let colStart = 0 + padding
    let colEnd = cols - padding - 1
    
    guard lineStart >= 0,
          lineStart < lineEnd,
          lineEnd < lines,
          colStart >= 0,
          colStart < colEnd,
          colEnd < cols else {
        return nil
    }
    
    for line in lineStart ... lineEnd {
        for col in colStart ... colEnd {
            box[line][col] = Character("*")
        }
    }
    
    return rects
        .sorted { (lhs, rhs) -> Bool in
            lhs.z < rhs.z
        }
        .compactMap { build(rect: $0) }
        .reduce(into: box) { (box, object) in
            for (lineIndex, line) in object.enumerated() {
                for (colIndex, _) in line.enumerated() {
                    if let value = object[lineIndex][colIndex] {
                        box[lineIndex][colIndex] = value
                    }
                }
            }
        }
}

func boxOutput() -> String {
    // Build stdout String
    let padding = 4
    guard let box = buildBox(padding: padding, rects: [
        
        Rect(x: padding,
             y: padding,
             z: -1,
             
             width: cols - (padding * 2),
             height: lines - (padding * 2),
             
             backgroundCharacter: " ",
             borderCharacter: "*",
             cornerCharacter: "X"),
    
        Rect(x: 64, y: 16, z: 0, width: 43, height: 24, backgroundCharacter: "▬"),
        Rect(x: 48, y: 8, z: 1, width: 43, height: 43, backgroundCharacter: "▯"),
        Rect(x: 44, y: 32, z: 5, width: 16, height: 16, backgroundCharacter: "▮")
        
    ]) else {
        defer {
            isRunning = false
        }
        return "Padding is too big!"
    }
    
    var output: String = ""
    
    for line in 0 ..< lines {
        
        for col in 0 ..< cols {
            output.append(box[line][col])
        }
        
        output.append("\n")
    }
    
    return output
}

func clearScreen() {
    run("tput", "reset")
}
