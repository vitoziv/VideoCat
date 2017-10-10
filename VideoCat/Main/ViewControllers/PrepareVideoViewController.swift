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

    @IBOutlet weak var playerView: VIPlayerView!
    @IBOutlet weak var timeRangePickerView: TimeRangePickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        timeRangePickerView.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        
        // TODO: 实现视频滚动视图
        
        setupWaveformView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Test
    
    var waveformView: WaveformScrollView!
    func setupWaveformView() {
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
    
    @objc func valueChanged(_ sender: TimeRangePickerView) {
        print("TimeRangePicker startTime: \(sender.timeRange.start.seconds), endTime: \(sender.timeRange.end.seconds)")
    }

}
