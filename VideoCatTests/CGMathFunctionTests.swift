//
//  CGMathFunctionTests.swift
//  VideoCatTests
//
//  Created by Vito on 28/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import XCTest
@testable import VideoCat

class CGMathFunctionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAspectFit() {
        let size1 = CGSize(width: 100, height: 50)
        let size2 = CGSize(width: 100, height: 100)
        let size3 = CGSize(width: 50, height: 100)
        let fitSize1 = CGSize(width: 100, height: 50)
        let fitSize2 = CGSize(width: 100, height: 100)
        let fitSize3 = CGSize(width: 50, height: 100)
        
        let fitResult11 = size1.aspectFit(in: fitSize1)
        XCTAssert(fitResult11.equalTo(CGSize(width: 100, height: 50)))
        let fitResult12 = size1.aspectFit(in: fitSize2)
        XCTAssert(fitResult12.equalTo(CGSize(width: 100, height: 50)))
        let fitResult13 = size1.aspectFit(in: fitSize3)
        XCTAssert(fitResult13.equalTo(CGSize(width: 50, height: 25)))
        
        
        let fitResult21 = size2.aspectFit(in: fitSize1)
        XCTAssert(fitResult21.equalTo(CGSize(width: 50, height: 50)))
        let fitResult22 = size2.aspectFit(in: fitSize2)
        XCTAssert(fitResult22.equalTo(CGSize(width: 100, height: 100)))
        let fitResult23 = size2.aspectFit(in: fitSize3)
        XCTAssert(fitResult23.equalTo(CGSize(width: 50, height: 50)))
        
        
        let fitResult31 = size3.aspectFit(in: fitSize1)
        XCTAssert(fitResult31.equalTo(CGSize(width: 25, height: 50)))
        let fitResult32 = size3.aspectFit(in: fitSize2)
        XCTAssert(fitResult32.equalTo(CGSize(width: 50, height: 100)))
        let fitResult33 = size3.aspectFit(in: fitSize3)
        XCTAssert(fitResult33.equalTo(CGSize(width: 50, height: 100)))
    }
    
    func testAspectFill() {
        let size1 = CGSize(width: 100, height: 50)
        let size2 = CGSize(width: 100, height: 100)
        let size3 = CGSize(width: 50, height: 100)
        let fillSize1 = CGSize(width: 100, height: 50)
        let fillSize2 = CGSize(width: 100, height: 100)
        let fillSize3 = CGSize(width: 50, height: 100)
        
        let fitResult11 = size1.aspectFill(in: fillSize1)
        XCTAssert(fitResult11.equalTo(CGSize(width: 100, height: 50)))
        let fitResult12 = size1.aspectFill(in: fillSize2)
        XCTAssert(fitResult12.equalTo(CGSize(width: 200, height: 100)))
        let fitResult13 = size1.aspectFill(in: fillSize3)
        XCTAssert(fitResult13.equalTo(CGSize(width: 200, height: 100)))
        
        
        let fitResult21 = size2.aspectFill(in: fillSize1)
        XCTAssert(fitResult21.equalTo(CGSize(width: 100, height: 100)))
        let fitResult22 = size2.aspectFill(in: fillSize2)
        XCTAssert(fitResult22.equalTo(CGSize(width: 100, height: 100)))
        let fitResult23 = size2.aspectFill(in: fillSize3)
        XCTAssert(fitResult23.equalTo(CGSize(width: 100, height: 100)))
        
        
        let fitResult31 = size3.aspectFill(in: fillSize1)
        XCTAssert(fitResult31.equalTo(CGSize(width: 100, height: 200)))
        let fitResult32 = size3.aspectFill(in: fillSize2)
        XCTAssert(fitResult32.equalTo(CGSize(width: 100, height: 200)))
        let fitResult33 = size3.aspectFill(in: fillSize3)
        XCTAssert(fitResult33.equalTo(CGSize(width: 50, height: 100)))
    }
}
