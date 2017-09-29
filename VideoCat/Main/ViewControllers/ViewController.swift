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
        
    }
    var audioFile: EZAudioFile!
    var waveformView: WaveformScrollView!
    func testWaveformView() {
        let frame = CGRect(x: 20, y: 66, width: 300, height: 100)
        waveformView = WaveformScrollView(frame: frame)
        waveformView.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
        view.addSubview(waveformView)
        
        if let url = Bundle.main.url(forResource: "Moon River", withExtension: "mp3") {
            audioFile = EZAudioFile(url: url)
            audioFile?.getWaveformData(withNumberOfPoints: UInt32(frame.width), completion: { [weak self] (buffers, bufferSize) in
                guard let strongSelf = self else { return }
                if let points = buffers?[0] {
                    var wavefromPoints = [Float]()
                    for index in 0..<bufferSize {
                        wavefromPoints.append(points[Int(index)])
                    }
                    strongSelf.waveformView.updatePoints(wavefromPoints)
                }
            })
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AssetsViewController {
            viewController.delegate = self
        }
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

