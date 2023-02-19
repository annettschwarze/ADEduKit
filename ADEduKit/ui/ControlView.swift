//
//  ControlView.swift
//  ADEduKit
//
//  Created by Schwarze on 01.01.22.
//

import UIKit
import OSLog

@objc
public protocol ControlViewDelegate: AnyObject {
    func controlViewDoPrev()
    func controlViewDoNext()
    func controlViewDoStop()
    func controlViewDoReset()
}

@objc @objcMembers
@IBDesignable
public class ControlView: UIView {
    // var progressState: ProgressState = ProgressState()

    // Private:
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var taskInfoLabel: UILabel!
    @IBOutlet weak var taskProgressLabel: UILabel!

    // Public:
    @IBInspectable public weak var controlViewDelegate: ControlViewDelegate?
    @IBInspectable public var controlViewBackgroundColor: UIColor? {
        didSet {
            os_log(.info, "\(#function)")
            if let cv = containerView {
                cv.backgroundColor = controlViewBackgroundColor
            }
        }
    }

    // Basic view related methods:

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadFromXib()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadFromXib()
    }

    func loadFromXib() {
        let b = Bundle(for: Self.self)
        let _ = b.loadNibNamed("ControlView", owner: self, options: nil)
        // containerView is now "wired"
        self.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        let cons = [
            containerView.topAnchor.constraint(equalTo: self.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ]
        NSLayoutConstraint.activate(cons)
    }

    // Private:
    @IBAction func didTapPrevButton(_ sender: Any) {
        controlViewDelegate?.controlViewDoPrev()
    }
    @IBAction func didTapNextButton(_ sender: Any) {
        controlViewDelegate?.controlViewDoNext()
    }
    @IBAction func didTapStopButton(_ sender: Any) {
        controlViewDelegate?.controlViewDoStop()
    }
    @IBAction func didTapResetButton(_ sender: Any) {
        controlViewDelegate?.controlViewDoReset()
    }
    
    // Public:
    public func updateTask(index: Int, count: Int, correct: Int) {
        let ratio = (count > 0) ? Float(index) / Float(count) : 0.0
        // C2 A4 = ¤
        let indexStr = (index < 0) ? "-" : ( (index >= count) ? "\u{A4}" : "@\(index+1)" )
        taskProgressLabel.text = "\(indexStr) | \(count) (\(correct)✓)"
        progressView.progress = ratio
        prevButton.isEnabled = index > 0
        nextButton.isEnabled = index < count
        resetButton.isEnabled = index > 0
        stopButton.isEnabled = true
    }

    public func updateTask(progressState: ProgressState) {
        updateTask(index: progressState.taskIndex, count: progressState.taskCount, correct: progressState.taskCorrect)
    }

    public func updateTask(info: String) {
        taskInfoLabel.text = info
    }
}
