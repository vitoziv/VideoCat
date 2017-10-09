//
//  PrepareVideoViewController.swift
//  VideoCat
//
//  Created by Vito on 25/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import CoreMedia

class PrepareVideoViewController: UIViewController {
    
    var trackItem: TrackItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        testWaveformView()
        textTimeRangePickerView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Test
    
    var waveformView: WaveformScrollView!
    func testWaveformView() {
        waveformView = WaveformScrollView()
        waveformView.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
        
        if let url = Bundle.main.url(forResource: "Moon River", withExtension: "mp3") {
            waveformView.loadVoice(from: url, completion: { [weak self] (asset) in
                guard let strongSelf = self else { return }
                strongSelf.timeRangePickerView?.rangeView.setRangeValue(start: 0.25, end: 0.75)
                
                let duration = asset.duration.seconds
                let time = CMTime(seconds: duration / 2, preferredTimescale: 1000)
                strongSelf.timeRangePickerView?.moveTo(time: time)
            })
        }
    }
    
    var timeRangePickerView: TimeRangePickerView?
    func textTimeRangePickerView() {
        let frame = CGRect(x: 20, y: 66, width: 300, height: 100)
        let timeRangePickerView = TimeRangePickerView(provider: waveformView)
        timeRangePickerView.frame = frame
        view.addSubview(timeRangePickerView)
        timeRangePickerView.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        
        self.timeRangePickerView = timeRangePickerView
    }
    
    @objc func valueChanged(_ sender: TimeRangePickerView) {
        print("TimeRangePicker startTime: \(sender.timeRange.start.seconds), endTime: \(sender.timeRange.end.seconds)")
    }

}
