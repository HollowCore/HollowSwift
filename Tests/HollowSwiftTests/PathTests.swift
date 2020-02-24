import XCTest
import HollowSwift

final class PathTests: XCTestCase {
    func testCreation() {
        let path = Path()
        XCTAssert(path.elementCount == 0)
    }

    func testAttributes() {
        let path = Path(svgPathData: "M 10 5 Q 15 0 20 5 L 20 15 C 17 20 13 20 10 15 Z")
        
        XCTAssert(path.elementCount == 5)
        XCTAssert(path.element(at: 0) == .move(to: .init(x: 10.0, y: 5.0)))
        XCTAssert(path.element(at: 1) == .addQuadraticCurve(to: .init(x: 20.0, y: 5.0), control: .init(x: 15.0, y: 0.0)))
        XCTAssert(path.element(at: 2) == .addLine(to: .init(x: 20.0, y: 15.0)))
        XCTAssert(path.element(at: 3) == .addCubicCurve(to: .init(x: 10.0, y: 15.0), control1: .init(x: 17.0, y: 20.0), control2: .init(x: 13.0, y: 20.0)))
        XCTAssert(path.element(at: 4) == .close)
        XCTAssert(zip(path.elements.indices, path.elements).allSatisfy({ $0.1 == path.element(at: $0.0) }))
        
        XCTAssert(path.elementPolyline(at: 0) == [])
        XCTAssert(path.elementPolyline(at: 1).first == Path.Point(x: 10.0, y: 5.0))
        XCTAssert(path.elementPolyline(at: 1).last == Path.Point(x: 20.0, y: 5.0))
        XCTAssert(path.elementPolyline(at: 1).count > 5)
        XCTAssert(path.elementPolyline(at: 2) == [Path.Point(x: 20.0, y: 5.0), Path.Point(x: 20.0, y: 15.0)])
        XCTAssert(path.elementPolyline(at: 3).first == Path.Point(x: 20.0, y: 15.0))
        XCTAssert(path.elementPolyline(at: 3).last == Path.Point(x: 10.0, y: 15.0))
        XCTAssert(path.elementPolyline(at: 3).count > 5)
        XCTAssert(path.elementPolyline(at: 4) == [Path.Point(x: 10.0, y: 15.0), Path.Point(x: 10.0, y: 5.0)])
        XCTAssert(zip(path.elementPolylines.indices, path.elementPolylines).allSatisfy({ $0.1 == path.elementPolyline(at: $0.0) }))
        
        XCTAssert(path.currentPoint == path.elementPolylines.last?.last)
        XCTAssert(path.bounds != Path.Rectangle(origin: .init(x: 10.0, y: 5.0), size: .init(width: 10.0, height: 10.0)))
    }
    
    func testPathManipulation() {
        var path = Path()
        path.move(to: .init(x: 5.0, y: 10.0))
        path.addLine(to: .init(x: 2.0, y: 20.0))
        path.addQuadraticCurve(to: .init(x: 30.0, y: 30.0), control: .init(x: 20.0, y: 5.0))
        path.addCubicCurve(to: .init(x: 1.0, y: 50.0), control1: .init(x: 35.0, y: 60.0), control2: .init(x: 45.0, y: 70.0))
        path.close()
        
        XCTAssert(path.elementCount == 5)
        XCTAssert(path.element(at: 0) == .move(to: .init(x: 5.0, y: 10.0)))
        XCTAssert(path.element(at: 1) == .addLine(to: .init(x: 2.0, y: 20.0)))
        XCTAssert(path.element(at: 2) == .addQuadraticCurve(to: .init(x: 30.0, y: 30.0), control: .init(x: 20.0, y: 5.0)))
        XCTAssert(path.element(at: 3) == .addCubicCurve(to: .init(x: 1.0, y: 50.0), control1: .init(x: 35.0, y: 60.0), control2: .init(x: 45.0, y: 70.0)))
        XCTAssert(path.element(at: 4) == .close)
        
        // TODO: Enable once bug in HollowCore is fixed
//        path.removeLast()
//        XCTAssert(path.elementCount == 4)
//        XCTAssert(path.element(at: 0) == .move(to: .init(x: 5.0, y: 10.0)))
//        XCTAssert(path.element(at: 1) == .addLine(to: .init(x: 2.0, y: 20.0)))
//        XCTAssert(path.element(at: 2) == .addQuadraticCurve(to: .init(x: 30.0, y: 30.0), control: .init(x: 20.0, y: 5.0)))
//        XCTAssert(path.element(at: 3) == .addCubicCurve(to: .init(x: 1.0, y: 50.0), control1: .init(x: 35.0, y: 60.0), control2: .init(x: 45.0, y: 70.0)))
//
//        path.removeLast()
//        path.removeLast()
//        path.removeLast()
//        path.removeLast()
//        XCTAssert(path.elementCount == 0)
    }
    
    func testContours() {
        let path = Path(svgPathData: "M 10 10 L 20 20 M 30 10 Q 40 5 50 10 Z M 60 10 L 70 20 80 10 C 75 3 85 6 60 10 Z")
        XCTAssert(path.contourIsOpen(containingElementAt: 1) == (isOpen: true, startIndex: 0, endIndex: 2))
        XCTAssert(path.contourIsClosed(containingElementAt: 1) == (isClosed: false, startIndex: 0, endIndex: 2))
        XCTAssert(path.contourIsOpen(containingElementAt: 3) == (isOpen: false, startIndex: 2, endIndex: 5))
        XCTAssert(path.contourIsClosed(containingElementAt: 3) == (isClosed: true, startIndex: 2, endIndex: 5))
        XCTAssert(path.contourIsOpen(containingElementAt: 6) == (isOpen: false, startIndex: 5, endIndex: 10))
        XCTAssert(path.contourIsClosed(containingElementAt: 6) == (isClosed: true, startIndex: 5, endIndex: 10))
        
        XCTAssert(path.contours.count == 3)
        XCTAssert(path.openContours.count == 1)
        XCTAssert(path.closedContours.count == 2)
        XCTAssert(path.contours[0] == path.openContours[0])
        XCTAssert(path.contours[1] == path.closedContours[0])
        XCTAssert(path.contours[2] == path.closedContours[1])
        XCTAssert(path.openContourPath == path.openContours[0])
        XCTAssert(path.closedContourPath.elements.first == path.closedContours[0].elements.first)
        XCTAssert(path.closedContourPath.elements.last == path.closedContours[1].elements.last)
    }
    
    func testConversion() {
        // TODO: Test once FILE* is available
    }

    func testIntersection() {
        let path = Path(svgPathData: "M 10 5 Q 15 0 20 5 L 20 15 C 17 20 13 20 10 15 Z")
        XCTAssert(path.contains(point: .init(x: 15.0, y: 10.0)))
        XCTAssert(!path.contains(point: .init(x: 2.0, y: 2.0)))
        XCTAssert(!path.contains(point: .init(x: 20.0, y: 20.0)))
        XCTAssert(path.contains(point: .init(x: 15.0, y: 17.0)))
        
        XCTAssert(path.intersects(path: Path(svgPathData: "M 5 5 L 25 25")))
        XCTAssert(!path.intersects(path: Path(svgPathData: "M 5 5 L 5 20")))
    }
    
    static var allTests = [
        ("testCreation", testCreation),
        ("testBox", testAttributes),
        ("testPathManipulation", testPathManipulation),
        ("testContours", testContours),
        ("testConversion", testConversion),
    ]
}
