//
//  VideoCatTests.swift
//  VideoCatTests
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import XCTest
@testable import VideoCat
import AVFoundation

class VideoCatTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResourceClassType() {
        let path = Bundle(for: type(of: self)).path(forResource: "black_empty", ofType: "mp4")!
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)
        let videoResource = TrackVideoResource(asset: asset)
        
        let json = videoResource.encodeToJSON()
        
        guard let resource = TrackResource.createResource(from: json) else {
            XCTAssert(false, "Should create resource successful")
            return
        }
        
        guard resource is TrackVideoResource else {
            XCTAssert(false, "Should be a AVAssetTrackResource type")
            return
        }
        
    }
    
}
