//
//  main.swift
//  adventofcode6
//
//  Created by Cruse, Si on 12/6/18.
//  Copyright © 2018 Cruse, Si. All rights reserved.
//

import Foundation

let input = [
    (83, 153),
    (201, 74),
    (291, 245),
    (269, 271),
    (222, 337),
    (291, 271),
    (173, 346),
    (189, 184),
    (170, 240),
    (127, 96),
    (76, 46),
    (92, 182),
    (107, 160),
    (311, 142),
    (247, 321),
    (303, 295),
    (141, 310),
    (147, 70),
    (48, 41),
    (40, 276),
    (46, 313),
    (175, 279),
    (149, 177),
    (181, 189),
    (347, 163),
    (215, 135),
    (103, 159),
    (222, 304),
    (201, 184),
    (272, 354),
    (113, 74),
    (59, 231),
    (302, 251),
    (127, 312),
    (259, 259),
    (41, 244),
    (43, 238),
    (193, 172),
    (147, 353),
    (332, 316),
    (353, 218),
    (100, 115),
    (111, 58),
    (210, 108),
    (101, 175),
    (185, 98),
    (256, 311),
    (142, 41),
    (68, 228),
    (327, 194)
]

//    --- Day 6: Chronal Coordinates ---
//    The device on your wrist beeps several times, and once again you feel like you're falling.
//
//    "Situation critical," the device announces. "Destination indeterminate. Chronal interference detected. Please specify new target coordinates."
//
//    The device then produces a list of coordinates (your puzzle input). Are they places it thinks are safe or dangerous? It recommends you check manual page 729. The Elves did not give you a manual.
//
//    If they're dangerous, maybe you can minimize the danger by finding the coordinate that gives the largest distance from the other points.
//
//    Using only the Manhattan distance, determine the area around each coordinate by counting the number of integer X,Y locations that are closest to that coordinate (and aren't tied in distance to any other coordinate).
//
//    Your goal is to find the size of the largest area that isn't infinite. For example, consider the following list of coordinates:
//
//    1, 1
//    1, 6
//    8, 3
//    3, 4
//    5, 5
//    8, 9
//    If we name these coordinates A through F, we can draw them on a grid, putting 0,0 at the top left:
//
//    ..........
//    .A........
//    ..........
//    ........C.
//    ...D......
//    .....E....
//    .B........
//    ..........
//    ..........
//    ........F.
//    This view is partial - the actual grid extends infinitely in all directions. Using the Manhattan distance, each location's closest coordinate can be determined, shown here in lowercase:
//
//    aaaaa.cccc
//    aAaaa.cccc
//    aaaddecccc
//    aadddeccCc
//    ..dDdeeccc
//    bb.deEeecc
//    bBb.eeee..
//    bbb.eeefff
//    bbb.eeffff
//    bbb.ffffFf
//    Locations shown as . are equally far from two or more coordinates, and so they don't count as being closest to any.
//
//    In this example, the areas of coordinates A, B, C, and F are infinite - while not shown here, their areas extend forever outside the visible grid. However, the areas of coordinates D and E are finite: D is closest to 9 locations, and E is closest to 17 (both including the coordinate's location itself). Therefore, in this example, the size of the largest area is 17.
//
//    What is the size of the largest area that isn't infinite?

extension Character {
    public static let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
    
    var uppercase: Character {
        return Character(String(self).uppercased())
    }
    
    var isUppercase: Bool {
        return "A"..."Z" ~= self
    }
}

struct Matrix<T> {
    let rows: Int, columns: Int
    var grid: [T]
    init(rows: Int, columns: Int,defaultValue: T) {
        self.rows = rows
        self.columns = columns
        grid = Array(repeating: defaultValue, count: rows * columns)
    }
    func indexIsValid(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rows && column >= 0 && column < columns
    }
    subscript(row: Int, column: Int) -> T {
        get {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            return grid[(row * columns) + column]
        }
        set {
            assert(indexIsValid(row: row, column: column), "Index out of range")
            grid[(row * columns) + column] = newValue
        }
    }
    var row_range: ClosedRange<Int> { return 0...self.rows - 1 }
    var column_range: ClosedRange<Int> { return 0...self.columns - 1 }
}

class Point: Hashable, CustomDebugStringConvertible {
//    private static var label_idx = 0
//    let label: Character
    
    let column: Int
    let row: Int
    
    init(_ column: Int, _ row: Int) {
        self.row = row
        self.column = column
//        self.label = Character.alphabet[Point.label_idx]
//        Point.label_idx+=1
    }
    
    convenience init(_ coord: (column: Int, row: Int)) {
        self.init(coord.column, coord.row)
    }
 
    static func == (lhs: Point, rhs: Point) -> Bool {
        return lhs.column == rhs.column && lhs.row == rhs.row
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(column)
        hasher.combine(row)
    }
    
    static func manhattanDistanceBetweenPoints(a: (row: Int, column: Int), b: (row: Int, column: Int)) -> Int {
        // Cribbing from https://en.wikipedia.org/wiki/Taxicab_geometry
        // distance between (p1, p2) & (q1, q2) = |p1 - q1| + |p2 - q2|
        return abs(a.column - b.column)+abs(a.row - b.row)
    }
    
    func manhattanDistanceToPoint(row: Int, column: Int) -> Int {
        return Point.manhattanDistanceBetweenPoints(a: (row: row, column: column), b: (row: self.row, column: self.column))
    }
    
    var debugDescription: String {
        return "row \(row), column \(column)"
    }
}

class Points /*: CustomDebugStringConvertible*/ {
    let points: [Point]
    let proximity: Int
    lazy var distantmap: Matrix<Point?> = calculatedistantmap()
    lazy var proximalmap: Matrix<Int> = calculateproximalmap()

    init(coords: [(y: Int, x: Int)], proximity: Int) {
        self.proximity = proximity
        self.points = coords.map{ Point($0) }
    }
    
    private func calculatedistantmap() -> Matrix<Point?> {
        let height = points.max(by: {$0.row < $1.row})!.row + 1
        let width = points.max(by: {$0.column < $1.column})!.column + 2
        var map = Matrix<Point?>(rows: height, columns: width, defaultValue: nil)

        for row in map.row_range {
            for column in map.column_range {
                let pointdistances = self.points.map{(p) in (p, p.manhattanDistanceToPoint(row: row, column: column)) }.sorted { $0.1 < $1.1 }
                if pointdistances[0].1 != pointdistances[1].1 {
                    map[row, column] = pointdistances.first!.0
                }
            }
        }
        
        return map
    }
    
    private func calculateproximalmap() -> Matrix<Int> {
        let height = points.max(by: {$0.row < $1.row})!.row + 1
        let width = points.max(by: {$0.column < $1.column})!.column + 2
        var map = Matrix<Int>(rows: height, columns: width, defaultValue: 0)
        
        for row in map.row_range {
            for column in map.column_range {
                let distances = self.points.map{(p) in p.manhattanDistanceToPoint(row: row, column: column)}
                let sumdistance = distances.reduce(0,+)
                map[row,column] = sumdistance < self.proximity ? 1 : 0
            }
        }
        
        return map
    }
    
    private func perimiterpoints(map: Matrix<Point?>) -> Set<Point?> {
        var points: Set<Point?> = []
        for row in map.row_range {
            for column in [map.column_range.first!, map.column_range.last!] {
                points.insert(map[row, column])
            }
        }
        for column in map.column_range {
            for row in [map.row_range.first!, map.row_range.last!] {
                points.insert(map[row, column])
            }
        }
        return points
    }
    
    func mostdistantarea() -> Int {
        let filter = perimiterpoints(map: self.distantmap).filter{ $0 != nil }
        let validpoints = points.filter{ !filter.contains($0) }
        let areas = validpoints.map { (p) in self.distantmap.grid.filter{ $0 == p } }.sorted { $0.count < $1.count }
        return areas.map { $0.count }.max()!
    }

    func proximalarea() -> Int {
        return self.proximalmap.grid.reduce(0,+)
    }
    
    var debugDescription: String {
        var result = ""
        for row in proximalmap.row_range {
            var line = ""
            for column in proximalmap.column_range {
                line += String(proximalmap[row, column])
            }
            result += line + "\n"
        }
        return result
    }

}

// Test Scenarios
let challenge_test_1 = ([
    (1, 1),
    (1, 6),
    (8, 3),
    (3, 4),
    (5, 5),
    (8, 9)
    ], 17)

// Utility function for running tests
func testit(scenario: (input: [(Int, Int)], expected: Int), process: ([(Int, Int)]) -> Int) -> String {
    let result = process(scenario.input)
    return "\(result == scenario.expected ? "\u{1F49A}" : "\u{1F6D1}")\tresult \(result)\tinput: \(scenario.input)"
}

func test1(coordinates: [(Int, Int)]) -> Int {
    let points = Points(coords: coordinates, proximity: 32)
    return points.mostdistantarea()
}

print(testit(scenario: challenge_test_1, process: test1))

let points2 = Points(coords: input, proximity: 10000)
let distantarea = points2.mostdistantarea()
print("The FIRST CHALLENGE answer is \(distantarea)\n")

//        --- Part Two ---
//    On the other hand, if the coordinates are safe, maybe the best you can do is try to find a region near as many coordinates as possible.
//
//    For example, suppose you want the sum of the Manhattan distance to all of the coordinates to be less than 32. For each location, add up the distances to all of the given coordinates; if the total of those distances is less than 32, that location is within the desired region. Using the same coordinates as above, the resulting region looks like this:
//
//    ..........
//    .A........
//    ..........
//    ...###..C.
//    ..#D###...
//    ..###E#...
//    .B.###....
//    ..........
//    ..........
//    ........F.
//    In particular, consider the highlighted location 4,3 located at the top middle of the region. Its calculation is as follows, where abs() is the absolute value function:
//
//    Distance to coordinate A: abs(4-1) + abs(3-1) =  5
//    Distance to coordinate B: abs(4-1) + abs(3-6) =  6
//    Distance to coordinate C: abs(4-8) + abs(3-3) =  4
//    Distance to coordinate D: abs(4-3) + abs(3-4) =  2
//    Distance to coordinate E: abs(4-5) + abs(3-5) =  3
//    Distance to coordinate F: abs(4-8) + abs(3-9) = 10
//    Total distance: 5 + 6 + 4 + 2 + 3 + 10 = 30
//    Because the total distance to all coordinates (30) is less than 32, the location is within the region.
//
//    This region, which also includes coordinates D and E, has a total size of 16.
//
//    Your actual region will need to be much larger than this example, though, instead including all locations with a total distance of less than 10000.
//
//    What is the size of the region containing all locations which have a total distance to all given coordinates of less than 10000?

// Test Scenarios
let challenge_test_2 = ([
    (1, 1),
    (1, 6),
    (8, 3),
    (3, 4),
    (5, 5),
    (8, 9)
    ], 16)

func test2(coordinates: [(Int, Int)]) -> Int {
    let points = Points(coords: coordinates, proximity: 32)
    return points.proximalarea()
}

print(testit(scenario: challenge_test_2, process: test2))

let proximalarea = points2.proximalarea()
print("The SECOND CHALLENGE answer is \(proximalarea)\n")
