//
//  PrepareVideoViewController.swift
//  VideoCat
//
//  Created by Vito on 25/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit

class PrepareVideoViewController: UIViewController {
    
    var trackItem: TrackItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        testWaveformView()
        textTimeRangePickerView()
    }

    // MARK: - Test
    
    var waveformView: WaveformScrollView!
    func testWaveformView() {
        waveformView = WaveformScrollView()
        waveformView.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
        
        if let url = Bundle.main.url(forResource: "Moon River", withExtension: "mp3") {
            waveformView.loadVoice(from: url)
        }
    }
    
    func textTimeRangePickerView() {
        let frame = CGRect(x: 20, y: 66, width: 300, height: 100)
        let timeRangePickerView = TimeRangePickerView(provider: waveformView)
        timeRangePickerView.frame = frame
        view.addSubview(timeRangePickerView)
        timeRangePickerView.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
    }
    
    @objc func valueChanged(_ sender: TimeRangePickerView) {
        print("TimeRangePicker startTime: \(sender.timeRange.start), endTime: \(sender.timeRange.end)")
    }

}
