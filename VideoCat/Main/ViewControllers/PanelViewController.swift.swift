//
//  PanelViewController.swift
//  VideoCat
//
//  Created by Vito on 27/08/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import Photos
import MBProgressHUD
import RxCocoa

class EditContext {
    var timelineView: TimeLineView
    var videoView: VideoView
    var viewModel: TimelineViewModel
    
    init(timelineView: TimeLineView, videoView: VideoView, viewModel: TimelineViewModel) {
        self.timelineView = timelineView
        self.videoView = videoView
        self.viewModel = viewModel
    }
}

var editContext: EditContext?

class PanelViewController: UIViewController {
    
    @IBOutlet weak var timeLineView: TimeLineView!
    @IBOutlet weak var videoView: VideoView!
    @IBOutlet weak var editToolView: EditToolView!
    private let viewModel = TimelineViewModel()
    
    deinit {
        editContext = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let inset = UIScreen.main.bounds.width / 2 - 24
        timeLineView.scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        bindAction()
        
        editContext = EditContext.init(timelineView: timeLineView, videoView: videoView, viewModel: viewModel)
        
        editToolView.itemsProvider = PassingThroughEditItem()
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        timeLineView.resignVideoRangeView()
    }
    
    @IBAction func debugAction(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Demo", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PlayerTestViewController")
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Helper
    fileprivate var timeObserver: Any?
    fileprivate func bindAction() {
        timeObserver = videoView.player.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: DispatchQueue.main, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            strongSelf.playerTimeDidChanged(time: time)
        })
        _ = timeLineView.scrollView.rx.observeWeakly(CGPoint.self, "contentOffset").takeUntil(rx.deallocated).subscribe(onNext: { [weak self] (offset) in
            guard let strongSelf = self else { return }
            guard let offset = offset else { return }
            switch strongSelf.videoView.player.status {
            case .playing:
                break
            default:
                let time = strongSelf.timeLineView.getTime(at: offset.x)
                strongSelf.videoView.player.player.fl_seekSmoothly(to: time.0)
            }
        })
        // TODO: 开始拖拽后暂停播放
//        _ = timeLineView.scrollView.rx.observeWeakly(Bool.self, "isDragging").takeUntil(rx.deallocated).subscribe(onNext: { [weak self] (isDragging) in
//            guard let strongSelf = self else { return }
//            if let isDragging = isDragging, isDragging {
//                strongSelf.videoView.player.pause()
//            }
//        })
    }
    
    fileprivate func playerTimeDidChanged(time: CMTime) {
        timeLineView.adjustCollectionViewOffset(time: time)
    }
    
}
