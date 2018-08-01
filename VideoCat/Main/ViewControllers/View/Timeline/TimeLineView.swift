//
//  TimeLineView.swift
//  VideoCat
//
//  Created by Vito on 13/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import RxCocoa
import RxSwift
import VFCabbage

class TimeLineView: UIView {

    private(set) var scrollView: UIScrollView!
    private(set) var contentView: UIView!
    fileprivate(set) var videoListContentView: UIView!
    private(set) var centerLineView: UIView!
    private(set) var totalTimeLabel: UILabel!
    
    private(set) var scrollContentHeightConstraint: NSLayoutConstraint!
    
    private(set) var rangeViews: [VideoRangeView] = []
    private(set) var trackItems: [TrackItem] = []
    
    // Player
    fileprivate(set) var player: AVPlayer?
    fileprivate var timeObserver: Any?
    fileprivate var playerDisposeBag: DisposeBag?
    fileprivate var timelinePlayerItem: AVPlayerItem?
    fileprivate var currentClipPlayerItem: AVPlayerItem?
    
    var rangeViewsIndex: Int {
        var index = 0
        let center = centerLineView.center
        for (i, view) in rangeViews.enumerated() {
            let rect = view.superview!.convert(view.frame, to: centerLineView.superview!)
            if rect.contains(center) {
                index = i
                break
            }
        }
        
        return index
    }
    var videoRangeViewEarWidth: CGFloat = 24
    var widthPerSecond: CGFloat = 60
    
    @objc dynamic var isScrolling: Bool = false
    var isFocusMode: Bool = false {
        didSet {
            if !isFocusMode {
                resignVideoRangeView()
            }
        }
    }
    var activeNextClipHandler: (() -> Bool)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        scrollView = UIScrollView()
        addSubview(scrollView)
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.contentSize = CGSize(width: 0, height: bounds.height)
        scrollView.delegate = self
        
        contentView = UIView()
        scrollView.addSubview(contentView)
        
        videoListContentView = UIView()
        contentView.addSubview(videoListContentView)
        
        centerLineView = UIView()
        addSubview(centerLineView)
        centerLineView.isUserInteractionEnabled = false
        centerLineView.backgroundColor = UIColor.orange
        
        totalTimeLabel = UILabel()
        addSubview(totalTimeLabel)
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.font = UIFont.systemFont(ofSize: 16)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        scrollContentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 60)
        scrollContentHeightConstraint.isActive = true
        
        videoListContentView.translatesAutoresizingMaskIntoConstraints = false
        videoListContentView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        videoListContentView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        videoListContentView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        videoListContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        centerLineView.translatesAutoresizingMaskIntoConstraints = false
        centerLineView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        centerLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        centerLineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        centerLineView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        let timeLabelRightConstraint = totalTimeLabel.rightAnchor.constraint(equalTo: rightAnchor)
        timeLabelRightConstraint.constant = -15
        timeLabelRightConstraint.isActive = true
        let timeLabelBottomConstraint = totalTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        timeLabelBottomConstraint.constant = -10
        timeLabelBottomConstraint.isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLineViewAction(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = bounds.width * 0.5 - videoRangeViewEarWidth
        scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    // MARK: - Actions
    
    @objc private func tapContentAction(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            if let view = recognizer.view as? VideoRangeView, !view.isEditActive {
                view.superview?.bringSubview(toFront: view)
                view.isEditActive = true
                rangeViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
            }
        }
    }
    
    @objc private func tapLineViewAction(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: recognizer.view)
        var tapOnVideoRangeView = false
        for view in rangeViews {
            let rect = view.superview!.convert(view.frame, to: self)
            if rect.contains(point) {
                tapOnVideoRangeView = true
                break
            }
        }
        if !tapOnVideoRangeView {
            resignVideoRangeView()
        }
    }
    
    // MARK: - Data
    
    private let loadImageQueue: DispatchQueue = DispatchQueue(label: "com.videocat.loadimage")
    func reload(with trackItems: [TrackItem]) {
        self.trackItems = trackItems
        removeAllRangeViews()
        for (index, trackItem) in trackItems.enumerated() {
            appendVideoRangeView(configuration: { (rangeView) in
                let contentView = VideoRangeContentView()
                if trackItem.resource.isMember(of: ImageResource.self) {
                    contentView.supportUnlimitTime = true
                }
                let timeRange = trackItem.resourceTargetTimeRange
                contentView.loadImageQueue = loadImageQueue
                if let renderSize = editContext?.viewModel.renderSize, let imageGenerator = trackItem.generateFullRangeImageGenerator(size: renderSize) {
                    contentView.imageGenerator = ImageGenerator.createFrom(imageGenerator)
                }
                contentView.startTime = timeRange.start
                contentView.endTime = timeRange.end
                
                if index > 0 {
                    let previousClip = trackItems[index - 1]
                    if let transitionDuration = previousClip.videoTransition?.duration {
                        contentView.leftInsetDuration = transitionDuration / 2
                    }
                }
                if index < trackItems.count - 1 {
                    if let transitionDuration = trackItem.videoTransition?.duration {
                        contentView.rightInsetDuration = transitionDuration / 2
                    }
                }
                
                rangeView.loadContentView(contentView)
                
                rangeView.reloadUI()
            })
        }
        
        rangeViews.enumerated().forEach { (offset, view) in
            view.leftPaddingViewConstraint.constant = 2
            view.rightPaddingViewConstraint.constant = 2
            if offset == 0 {
                view.leftPaddingViewConstraint.constant = 0
            } else if offset == rangeViews.count - 1 {
                view.rightPaddingViewConstraint.constant = 0
            }
        }
    }
    
    func resignVideoRangeView() {
        rangeViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
    }
    
    func appendVideoRangeView(configuration: (VideoRangeView) -> Void, at index: Int = Int.max) {
        // 添加到当前时间点，最接近的地方。
        let videoRangeView = VideoRangeView()
        configuration(videoRangeView)
        videoRangeView.contentView.widthPerSecond = widthPerSecond
        videoRangeView.contentInset = UIEdgeInsetsMake(2, videoRangeViewEarWidth, 2, videoRangeViewEarWidth)
        videoRangeView.delegate = self
        videoRangeView.isEditActive = false
        let tapContentGesture = UITapGestureRecognizer(target: self, action: #selector(tapContentAction(_:)))
        videoRangeView.addGestureRecognizer(tapContentGesture)
        videoListContentView.insertSubview(videoRangeView, at: 0)
        
        videoRangeView.translatesAutoresizingMaskIntoConstraints = false
        videoRangeView.topAnchor.constraint(equalTo: videoListContentView.topAnchor).isActive = true
        videoRangeView.bottomAnchor.constraint(equalTo: videoListContentView.bottomAnchor).isActive = true
        if rangeViews.count == 0 {
            rangeViews.append(videoRangeView)
            videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: videoListContentView.leftAnchor)
            videoRangeView.leftConstraint?.isActive = true
            videoRangeView.rightConstraint = videoRangeView.rightAnchor.constraint(equalTo: videoListContentView.rightAnchor)
            videoRangeView.rightConstraint?.isActive = true
        } else {
            if index >= rangeViews.count {
                let leftVideoRangeView = rangeViews.last!
                rangeViews.append(videoRangeView)
                if let rightConstraint = leftVideoRangeView.rightConstraint {
                    rightConstraint.isActive = false
                }
                let leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: leftVideoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                videoRangeView.leftConstraint = leftConstraint
                
                videoRangeView.rightConstraint = videoRangeView.rightAnchor.constraint(equalTo: videoListContentView.rightAnchor)
                videoRangeView.rightConstraint?.isActive = true
            } else if index == 0 {
                rangeViews.insert(videoRangeView, at: index)
                let rightVideoRangeView = rangeViews[index + 1]
                if let leftConstraint = rightVideoRangeView.leftConstraint {
                    leftConstraint.isActive = false
                }
                let leftConstraint = rightVideoRangeView.leftAnchor.constraint(equalTo: videoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                rightVideoRangeView.leftConstraint = leftConstraint
                
                videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: videoListContentView.leftAnchor)
                videoRangeView.leftConstraint?.isActive = true
            } else {
                rangeViews.insert(videoRangeView, at: index)
                let leftVideoRangeView = rangeViews[index - 1]
                videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: leftVideoRangeView.rightAnchor)
                videoRangeView.leftConstraint?.constant = -videoRangeViewEarWidth * 2
                videoRangeView.leftConstraint?.isActive = true
                
                let rightVideoRangeView = rangeViews[index + 1]
                if let leftConstraint = rightVideoRangeView.leftConstraint {
                    leftConstraint.isActive = false
                }
                let leftConstraint = rightVideoRangeView.leftAnchor.constraint(equalTo: videoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                rightVideoRangeView.leftConstraint = leftConstraint
            }
        }
    }
    
    func removeAllRangeViews() {
        rangeViews.forEach { (view) in
            view.removeFromSuperview()
        }
        rangeViews.removeAll()
    }
    
    
    fileprivate func timeDidChanged() {
        var duration: CGFloat = 0
        rangeViews.forEach { (view) in
            duration = duration + view.frame.size.width / widthPerSecond
        }
        totalTimeLabel.text = String.init(format: "%.1f", duration)
    }
    
    
}

// MARK: - player
extension TimeLineView {
    
    func bindPlayer(_ player: AVPlayer?) {
        removePlayerObserable()
        self.player = player
        addPlayerObserable()
    }
    
    fileprivate func removePlayerObserable() {
        guard let player = player else { return }
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        playerDisposeBag = nil
    }
    
    fileprivate func addPlayerObserable() {
        guard let player = player else { return }
        if playerDisposeBag == nil {
            playerDisposeBag = DisposeBag()
        }
        
        _ = player.rx.observe(Float.self, "rate").subscribe(onNext: { [weak self] (rate) in
            guard let s = self else { return }
            if rate == 0 {
                s.displayRangeViewsIfNeed()
            } else {
                if s.shouldCancelLoadThumb() {
                    s.cancelLoadThumb()
                }
            }
        }).disposed(by: playerDisposeBag!)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: DispatchQueue.main, using: { [weak self] (time) in
            guard let s = self else { return }
            s.playerTimeChanged()
        })
        
        playerTimeChanged()
    }
    
    func cancelLoadThumb() {
        rangeViews.forEach { (rangeView) in
            if let v = rangeView.contentView as? VideoRangeContentView {
                v.workitems.forEach({ (key, workitem) in
                    workitem.cancel()
                })
                v.workitems.removeAll()
            }
        }
    }
    
    func playerTimeChanged() {
        if isScrolling { return }
        if currentClipPlayerItem != nil { return }
        guard let player = player else { return }
        adjustCollectionViewOffset(time: player.fl_currentTime())
    }
    
    func adjustCollectionViewOffset(time: CMTime) {
        if !time.isValid { return }
        let time = max(time, kCMTimeZero)
        let offsetX = getOffsetX(at: time).0
        if !offsetX.isNaN {
            scrollView.delegate = nil
            scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
            displayRangeViewsIfNeed()
            activeCurrentVideoRangeView(time: time)
            scrollView.delegate = self
        }
    }
    
    fileprivate func activeCurrentVideoRangeView(time: CMTime) {
        if isFocusMode {
            if let view = rangeView(at: time) {
                if !view.isEditActive {
                    resignVideoRangeView()
                    if let handler = activeNextClipHandler {
                        if handler() {
                            view.superview?.bringSubview(toFront: view)
                            view.isEditActive = true
                        }
                    } else {
                        view.superview?.bringSubview(toFront: view)
                        view.isEditActive = true
                    }
                }
            }
        }
    }
    
    fileprivate func displayRangeViewsIfNeed() {
        let showingRangeViews = showingRangeView()
        var canLoadImageAsync = (player?.rate ?? 0) == 0
        if !shouldCancelLoadThumb(showingRangeViews) {
            canLoadImageAsync = true
        }
        showingRangeViews.forEach({
            $0.contentView.canLoadImageAsync = canLoadImageAsync
            $0.contentView.updateDataIfNeed()
        })
    }
    
    // 是否可以加载缩略图(超出5个就不加载
    fileprivate func shouldCancelLoadThumb(_ rangeViews: [VideoRangeView] = []) -> Bool {
        return ((rangeViews.count == 0) ? showingRangeView() : rangeViews).count > 7
    }
    
    // MARK: offset
    
    func getOffsetX(at time: CMTime) -> (CGFloat, Int) {
        var offsetX: CGFloat = -scrollView.contentInset.left
        guard time.isValid else { return (offsetX, 0) }
        
        var duration = time
        var index = 0
        for (i, rangeView) in rangeViews.enumerated() {
            let contentDuration = rangeView.contentView.endTime - rangeView.contentView.startTime
            if duration <= contentDuration {
                index = i
                break
            } else {
                duration = duration - contentDuration
            }
        }
        offsetX = offsetX + CGFloat(time.seconds) * widthPerSecond
        
        return (offsetX, index)
    }
    
    func getTime(at offsetX: CGFloat) -> (CMTime, Int) {
        var offsetX = offsetX + scrollView.contentInset.left
        let duration = CMTime(seconds: Float(offsetX / widthPerSecond))
        var index = 0
        for (i, rangeView) in rangeViews.enumerated() {
            let width = rangeView.contentView.contentWidth
            if offsetX <= width {
                index = i
                break
            } else {
                offsetX = offsetX - width
            }
        }
        
        return (duration, index)
    }
    
}

// MARK: - VideoRangeViewDelegate

extension TimeLineView: VideoRangeViewDelegate {
    
    fileprivate func replacePlayerItemToCurrentClipItem(view: VideoRangeView) {
        guard let index = rangeViews.index(of: view) else {
            return
        }
        if !view.contentView.supportUnlimitTime {
            let clip = trackItems[index]
            currentClipPlayerItem = clip.generateFullRangePlayerItem(size: editContext!.viewModel.renderSize)
            if let player = player {
                timelinePlayerItem = player.currentItem
                removePlayerObserable()
                player.replaceCurrentItem(with: currentClipPlayerItem)
                addPlayerObserable()
            }
        }
    }
    
    fileprivate func updateCurrentClipPlayerItem(time: CMTime, view: VideoRangeView) {
        if !view.contentView.supportUnlimitTime {
            player?.fl_seekSmoothly(to: time)
        }
        
        let center = view.convert(view.leftEar.center, to: self)
        centerLineView.center = CGPoint(x: center.x + view.leftEar.bounds.width * 0.5, y: center.y)
    }
    
    fileprivate func restoreTimePlayerItem(view: VideoRangeView) {
        if !view.contentView.supportUnlimitTime {
            player?.replaceCurrentItem(with: timelinePlayerItem)
            currentClipPlayerItem = nil
            timelinePlayerItem = nil
        }
        
        centerLineView.center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
    }
    
    func videoRangeViewBeginUpdateLeft(_ view: VideoRangeView) {
        // TODO: 替换当前显示的 player，要能做到预览当前选中片段的完整视频
        scrollView.delegate = nil
//        delegate?.clipTimelineBeginClip(self)
//        VideoEditManager.shared.beginClipVideo()
        replacePlayerItemToCurrentClipItem(view: view)
    }
    
    func videoRangeViewBeginUpdateRight(_ view: VideoRangeView) {
        // TODO: 替换当前显示的 player，要能做到预览当前选中片段的完整视频
        scrollView.delegate = nil
//        delegate?.clipTimelineBeginClip(self)
//        VideoEditManager.shared.beginClipVideo()
        replacePlayerItemToCurrentClipItem(view: view)
    }
    
    func videoRangeView(_ view: VideoRangeView, updateLeftOffset offset: CGFloat, auto: Bool) {
//        delegate?.clipTimelineDidChange(self)
        updateCurrentClipPlayerItem(time: view.contentView.startTime, view: view)
        if auto {
            return
        }
        
        var inset = scrollView.contentInset
        inset.left = scrollView.frame.width
        scrollView.contentInset = inset
        
        var contentOffset = scrollView.contentOffset
        contentOffset.x -= offset
        scrollView.setContentOffset(contentOffset, animated: false)
    }
    
    func videoRangeViewDidEndUpdateLeftOffset(_ view: VideoRangeView) {
        removePlayerObserable()
        restoreTimePlayerItem(view: view)
        scrollView.delegate = self
        var inset = scrollView.contentInset
        inset.left = inset.right
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentInset = inset
        }
        view.contentView.endExpand()
        endUpdate(view: view, isLeft: true)
        addPlayerObserable()
    }
    
    func videoRangeView(_ view: VideoRangeView, updateRightOffset offset: CGFloat, auto: Bool) {
//        delegate?.clipTimelineDidChange(self)
        updateCurrentClipPlayerItem(time: view.contentView.endTime, view: view)
        let center = view.convert(view.rightEar.center, to: self)
        centerLineView.center = CGPoint(x: center.x - view.rightEar.frame.size.width * 0.5, y: center.y)
        if auto {
            var contentOffset = scrollView.contentOffset
            contentOffset.x += offset
            scrollView.setContentOffset(contentOffset, animated: false)
        } else {
            var inset = scrollView.contentInset
            inset.right = scrollView.frame.width
            scrollView.contentInset = inset
        }
    }
    
    func videoRangeViewDidEndUpdateRightOffset(_ view: VideoRangeView) {
        removePlayerObserable()
        restoreTimePlayerItem(view: view)
        scrollView.delegate = self
        var inset = scrollView.contentInset
        inset.right = inset.left
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentInset = inset
        }
        endUpdate(view: view, isLeft: false)
        addPlayerObserable()
    }
    
    private func endUpdate(view: VideoRangeView, isLeft: Bool) {
        if let index = rangeViews.index(of: view) {
            let track = trackItems[index]
            let timeRange = CMTimeRangeFromTimeToTime(view.contentView.startTime, view.contentView.endTime)
            if track.timeRange.start != timeRange.start || track.timeRange.duration != timeRange.duration {
                
                track.resourceTargetTimeRange = timeRange
                if let context = editContext {
                    context.viewModel.reloadTimelineTimeRange()
                    context.viewModel.reloadPlayerItem()
                    context.videoView.player.replaceCurrentItem(context.viewModel.playerItem)
                    reload(with: context.viewModel.trackItems)
                }
            }
        }
//        delegate?.clipTimelineEndClip(self)
    }
}

// MARK: - Helper

extension TimeLineView {
    
    var nextRangeViewIndex: Int {
        var index = 0
        let center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
        for (i, view) in rangeViews.enumerated() {
            let rect = view.superview!.convert(view.frame, to: centerLineView.superview!)
            if rect.contains(center) {
                if center.x - rect.origin.x < rect.maxX - center.x {
                    // On left side
                    index = i
                } else {
                    // On right side
                    index = i + 1
                }
                break
            }
        }
        
        return index
    }
    
    func showingRangeView() -> [VideoRangeView] {
        let showingRangeViews = rangeViews.filter { (view) -> Bool in
            let rect = view.superview!.convert(view.frame, to: scrollView)
            let intersects = scrollView.bounds.intersects(rect)
            return intersects
        }
        return showingRangeViews
    }
    
    func rangeView(at time: CMTime) -> VideoRangeView? {
        var duration = kCMTimeZero
        for view in rangeViews {
            duration = duration + view.contentView.endTime - view.contentView.startTime - view.contentView.rightInsetDuration - view.contentView.leftInsetDuration
            if duration > time {
                return view
            }
        }
        return nil
    }
    
}

// MARK: UIScrollViewDelegate
extension TimeLineView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
        if let player = player, player.rate != 0 {
            player.rate = 0
        }
//        actionDelegate?.clipTimelineStartDragScrollView(self)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // Update video range view
        displayRangeViewsIfNeed()
        
        // Update player
        guard let player = player, let currentItem = player.currentItem else { return }
        if currentItem.duration == kCMTimeZero { return }
        if player.rate != 0 { return }
        if player.status != .readyToPlay { return }
        let duration = adjustTime(getTime(at: scrollView.contentOffset.x).0)
        player.fl_seekSmoothly(to: duration)
        
        activeCurrentVideoRangeView(time: duration)
    }
    
    // 设备 iPhone 7 往上
    // asset 的末尾段
    // CustomVideoCompositor sourceFrame 取出的 frame 不再发生变化
    // 下面的方法是如果是 clip 末尾，则时间做下偏移
    fileprivate func adjustTime(_ time: CMTime) -> CMTime {
        var res = time
        for clip in trackItems {
            let endTime = clip.timeRange.end
            if abs((time - endTime).seconds) < 0.1 {
                if clip.resource.duration.seconds <= 0.1 {
                    break
                }
                if time > endTime {
                    res = endTime + CMTime(seconds: 0.1)
                } else {
                    res = endTime - CMTime(seconds: 0.1)
                }
                break
            }
        }
        return res
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }
}
