//
//  PrepareVideoViewController.swift
//  VideoCat
//
//  Created by Vito on 25/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import CoreMedia
import VIPlayer

class PrepareVideoViewController: UIViewController {
    

    @IBOutlet weak var playerView: VIPlayerView!
    @IBOutlet weak var timeRangePickerView: TimeRangePickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        timeRangePickerView.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        
//        setupWaveformView()
        setupVideoTimeLineView()
    }
    var originInteractiveDelegate: UIGestureRecognizerDelegate?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        originInteractiveDelegate = navigationController?.interactivePopGestureRecognizer?.delegate
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = originInteractiveDelegate
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
    }
    // MARK: - Test
    
    var waveformView: WaveformScrollView!
    func setupWaveformView() {
        waveformView = WaveformScrollView()
        timeRangePickerView.timeRangeProvider = waveformView
        waveformView.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
        waveformView.minWidth = UIScreen.main.bounds.width
        
        if let url = Bundle.main.url(forResource: "Moon River", withExtension: "mp3") {
            waveformView.loadVoice(from: url, completion: { [weak self] (asset) in
                guard let strongSelf = self else { return }
                strongSelf.timeRangePickerView?.rangeView.setRangeValue(start: 0.25, end: 0.75)
                
                let duration = asset.duration.seconds
                let time = CMTime(seconds: duration / 2, preferredTimescale: asset.duration.timescale)
                strongSelf.timeRangePickerView?.moveTo(time: time)
            })
        }
    }
    
    var videoTimeLineView: VideoTimelineView!
    func setupVideoTimeLineView() {
        videoTimeLineView = VideoTimelineView()
        timeRangePickerView.timeRangeProvider = videoTimeLineView
        
        videoTimeLineView.backgroundColor = UIColor.lightGray
        videoTimeLineView.viewModel.minWidth = UIScreen.main.bounds.width * 4
        
        if let url = Bundle.main.url(forResource: "Marvel Studios", withExtension: "mp4") {
            videoTimeLineView.configure(with: url)
            timeRangePickerView?.rangeView.setRangeValue(start: 0.25, end: 0.75)
        }
    }
    
    @objc func valueChanged(_ sender: TimeRangePickerView) {
        print("TimeRangePicker startTime: \(sender.timeRange.start.seconds), endTime: \(sender.timeRange.end.seconds)")
    }

}
