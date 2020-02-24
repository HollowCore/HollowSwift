import HollowCoreGraphic

public struct Path: Hashable {
    // TODO: Enforce copy of object when needed! Not a real struct yet!
    private let reference: HCPathRef
    
    // MARK: - Support Types
    
    public struct Point: Hashable {
        var x: Double
        var y: Double
        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
    }
    
    public struct Size: Hashable {
        var width: Double
        var height: Double
        public init(width: Double, height: Double) {
            self.width = width
            self.height = height
        }
    }
    
    public struct Rectangle: Hashable {
        var origin: Point
        var size: Size
        public init(origin: Point, size: Size) {
            self.origin = origin
            self.size = size
        }
    }
    
    public enum Element: Hashable {
        case move(to: Point)
        case addLine(to: Point)
        case addQuadraticCurve(to: Point, control: Point)
        case addCubicCurve(to: Point, control1: Point, control2: Point)
        case close
    }
    
    // MARK: - Construction
    
    public init() {
        self.reference = HCPathCreateEmpty()
    }
    
    public init(svgPathData: String) {
        var reference: HCPathRef?
        svgPathData.withCString {
            reference = HCPathCreate($0)
        }
        self.reference = reference!
    }
    
    private init(reference: HCPathRef) {
        self.reference = reference
    }
    
    private init(referenceRetained: HCPathRef) {
        HCRetain(referenceRetained)
        self.reference = referenceRetained
    }
    
    private init(referenceReleased: HCPathRef) {
        self.reference = referenceReleased
        HCRelease(referenceReleased)
    }
    
    
    // TODO: Dealloc!
    
    // MARK: - Hashable, Equatable, LosslessStringConvertable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(HCPathHashValue(reference))
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return HCPathIsEqual(lhs.reference, rhs.reference)
    }
    
    // MARK: - Attributes
    
    public var elementCount: Int {
        return Int(HCPathElementCount(reference))
    }
    
    public func element(at index: Int) -> Element {
        let element = HCPathElementAt(reference, Int64(index))
        switch (element.command) {
        case HCPathCommandMove:
            return .move(to: Point(x: element.points[0].x, y: element.points[0].y))
        case HCPathCommandAddLine:
            return .addLine(to: Point(x: element.points[0].x, y: element.points[0].y))
        case HCPathCommandAddQuadraticCurve:
            return .addQuadraticCurve(
                to: Point(x: element.points[1].x, y: element.points[1].y),
                control: Point(x: element.points[0].x, y: element.points[0].y)
            )
        case HCPathCommandAddCubicCurve:
            return .addCubicCurve(
                to: Point(x: element.points[2].x, y: element.points[2].y),
                control1: Point(x: element.points[0].x, y: element.points[0].y),
                control2: Point(x: element.points[1].x, y: element.points[1].y)
            )
        case HCPathCommandCloseSubpath:
            return .close
        default:
            fatalError("\(Self.self) element at \(index) has unsupported command")
        }
    }
    
    public var elements: [Element] {
        var elements: [Element] = []
        for elementIndex in 0 ..< elementCount {
            elements.append(element(at: elementIndex))
        }
        return elements
    }
    
    public func elementPolyline(at index: Int) -> [Point] {
        let polylineData = HCPathElementPolylineDataRetained(reference, Int64(index))
        let polylineCount = Int(HCDataSize(polylineData)) / (MemoryLayout<Point>.size)
        let polylineBytes: UnsafePointer<UInt8> = HCDataBytes(polylineData)
        let polylinePoints = UnsafeBufferPointer(start: UnsafeRawPointer(polylineBytes).bindMemory(to: Point.self, capacity: polylineCount), count: polylineCount)
        let polyline = Array(polylinePoints)
        HCRelease(polylineData)
        return polyline
    }
    
    public var elementPolylines: [[Point]] {
        var elementPolylines: [[Point]] = []
        for elementIndex in 0 ..< elementCount {
            elementPolylines.append(elementPolyline(at: elementIndex))
        }
        return elementPolylines
    }
    
    public var currentPoint: Point {
        let currentPoint = HCPathCurrentPoint(reference)
        return Point(x: currentPoint.x, y: currentPoint.y)
    }
    
    public var bounds: Rectangle {
        let bounds = HCPathBounds(reference)
        return Rectangle(origin: Point(x: bounds.origin.x, y: bounds.origin.y), size: Size(width: bounds.size.width, height: bounds.size.height))
    }
    
    // MARK: Path Manipulation
    
    public mutating func move(to point: Point) {
        HCPathMoveToPoint(reference, point.x, point.y)
    }
    
    public mutating func addLine(to point: Point) {
        HCPathAddLine(reference, point.x, point.y)
    }
    
    public mutating func addQuadraticCurve(to point: Point, control: Point) {
        HCPathAddQuadraticCurve(reference, control.x, control.y, point.x, point.y)
    }
    
    public mutating func addCubicCurve(to point: Point, control1: Point, control2: Point) {
        HCPathAddCubicCurve(reference, control1.x, control1.y, control2.x, control2.y, point.x, point.y)
    }
    
    public mutating func close() {
        HCPathCloseSubpath(reference)
    }
    
    public mutating func removeLast() {
        HCPathRemoveLastElement(reference)
    }
    
    // MARK: Conversion
    
    public var svgPathData: String {
        // TODO: This, when FILE* is available
        return ""
    }
    
    // MARK: - Contours
    
    public func contourIsOpen(containingElementAt index: Int) -> (isOpen: Bool, startIndex: Int, endIndex: Int) {
        var startIndex: Int64 = 0
        var endIndex: Int64 = 0
        let isOpen = HCPathSubpathContainingElementIsOpen(reference, Int64(index), &startIndex, &endIndex)
        return (isOpen: isOpen, startIndex: Int(startIndex), endIndex: Int(endIndex))
    }
    
    public func contourIsClosed(containingElementAt index: Int) -> (isClosed: Bool, startIndex: Int, endIndex: Int) {
        var startIndex: Int64 = 0
        var endIndex: Int64 = 0
        let isClosed = HCPathSubpathContainingElementIsClosed(reference, Int64(index), &startIndex, &endIndex)
        return (isClosed: isClosed, startIndex: Int(startIndex), endIndex: Int(endIndex))
    }
    
//    public func contour(containingElementAt index: Int) -> (contour: Path, isOpen: Bool, startIndex: Int, endIndex: Int) {
//        var startIndex: Int64 = 0
//        var endIndex: Int64 = 0
//        var isOpen: Bool = false
//        let contourReference = HCPathSubpathContaingElementRetained(reference, Int64(index), &startIndex, &endIndex, &isOpen)!
//        let contour = Path(reference: contourReference)
//        return (contour: contour, isOpen: isOpen, startIndex: Int(startIndex), endIndex: Int(endIndex))
//    }
    
    public var contours: [Path] {
        var contours: [Path] = []
        let contourList = HCPathSubpathsRetained(reference);
        for contourIndex in 0 ..< HCListCount(contourList) {
            let contourReference = HCListObjectAtIndex(contourList, contourIndex).bindMemory(to: HCPath.self, capacity: 1)
            contours.append(Path(referenceRetained: contourReference))
        }
        HCRelease(contourList)
        return contours
    }

    public var openContours: [Path] {
        var openContours: [Path] = []
        let openContourList = HCPathOpenSubpathsRetained(reference);
        for contourIndex in 0 ..< HCListCount(openContourList) {
            let contourReference = HCListObjectAtIndex(openContourList, contourIndex).bindMemory(to: HCPath.self, capacity: 1)
            openContours.append(Path(referenceRetained: contourReference))
        }
        HCRelease(openContourList)
        return openContours
    }
    
    public var closedContours: [Path] {
        var closedContours: [Path] = []
        let closedContourList = HCPathClosedSubpathsRetained(reference);
        for contourIndex in 0 ..< HCListCount(closedContourList) {
            let contourReference = HCListObjectAtIndex(closedContourList, contourIndex).bindMemory(to: HCPath.self, capacity: 1)
            closedContours.append(Path(referenceRetained: contourReference))
        }
        HCRelease(closedContourList)
        return closedContours
    }
    
    public var openContourPath: Path {
        let openContourPathReference = HCPathOpenSubpathsAsPathRetained(reference)!
        let openContourPath = Path(reference: openContourPathReference)
        return openContourPath
    }
    
    public var closedContourPath: Path {
        let closedContourPathReference = HCPathClosedSubpathsAsPathRetained(reference)!
        let closedContourPath = Path(reference: closedContourPathReference)
        return closedContourPath
    }

    // MARK: - Intersection
   
    public func contains(point: Point) -> Bool {
        return HCPathContainsPoint(reference, HCPoint(x: point.x, y: point.y))
    }
    
    public func intersects(path: Path) -> Bool {
        return HCPathIntersectsPath(reference, path.reference)
    }
    
    public func intersections(path: Path, _ body: (Point) -> Bool) {
        HCPathIntersections(reference, path.reference, { context, continueSearching, path, other, point in
            // TODO: Call body closure
//            continueSearching = body(point)
        }, nil)
    }
    
        
    // typedef void (*HCPathIntersectionFunction)(void* context, HCBoolean* continueSearching, HCPathRef path, HCPathRef otherPath, HCPoint point);
    
//    void HCPathIntersections(HCPathRef self, HCPathRef other, HCPathIntersectionFunction intersection, void* context);
}
