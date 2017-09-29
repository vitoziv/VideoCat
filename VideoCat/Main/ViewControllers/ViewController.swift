//
//  ViewController.swift
//  VideoCat
//
//  Created by Vito on 27/08/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import Photos
import MBProgressHUD

class ViewController: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        testWaveformView()
        textTimeRangePickerView()
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AssetsViewController {
            viewController.delegate = self
        }
    }
    
    // MARK: - Test
    
    var waveformView: WaveformScrollView!
    func testWaveformView() {
        waveformView = WaveformScrollView()
        waveformView.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
        
        if let url = Bundle.main.url(forResource: "Moon River", withExtension: "mp3") {
            waveformView.loadVoice(from: url, secondsWidth: 10)
        }
    }
    
    
    func textTimeRangePickerView() {
        let frame = CGRect(x: 20, y: 66, width: 300, height: 100)
        let timeRangePickerView = TimeRangePickerView(provider: waveformView)
        timeRangePickerView.frame = frame
        view.addSubview(timeRangePickerView)
    }
}

extension ViewController: AssetsViewControllerDelegate {
    func assetsViewControllerDidCancel(_ viewController: AssetsViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func assetsViewController(_ viewController: AssetsViewController, didPicked asset: PHAsset) {
        viewController.dismiss(animated: true, completion: nil)
        
        let resource = TrackVideoAssetResource(asset: asset)
        MBProgressHUD.showLoading()
        resource.loadMedia { [weak self] (status) in
            guard let strongSelf = self else { return }
            if status == .avaliable {
                MBProgressHUD.dismiss()
                let trackItem = TrackItem(resource: resource)
            } else {
                MBProgressHUD.showError(title: NSLocalizedString("Can't use this video", comment: ""))
            }
        }
        
    }
}

