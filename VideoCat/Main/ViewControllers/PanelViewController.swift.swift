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
    var editToolView: EditToolView!
    
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
        
        navigationController?.navigationBar.tintColor = UIColor.white
        
        timeLineView.bindPlayer(videoView.player.player)
        
        editContext = EditContext.init(timelineView: timeLineView, videoView: videoView, viewModel: viewModel)
        editContext?.editToolView = self.editToolView
        
        editToolView.itemsProvider = PassingThroughEditItemProvider()
        editToolView.hideBackButton()
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        timeLineView.resignVideoRangeView()
    }
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ExportViewController")
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func demoAction(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Demo", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "DemoNavigationController")
        present(viewController, animated: true, completion: nil)
    }
    
}

