//
//  ControlPanelViewController.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/9/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import UIKit
import CoreBluetooth

class ControlPanelViewController: UIViewController {

    @IBOutlet weak var releaseAndLaunchButton: UIButton!

    @IBOutlet weak var latchButton: UIButton!
    @IBOutlet weak var unlatchButton: UIButton!
    @IBOutlet weak var releaseBirdButton: UIButton!
    @IBOutlet weak var latchPositionLabel: UILabel!
    
    @IBOutlet weak var retractLauncherButton: UIButton!
    @IBOutlet weak var extendLauncherButton: UIButton!
    @IBOutlet weak var launchBirdButton: UIButton!
    @IBOutlet weak var launcherPostionLabel: UILabel!
    
    @IBOutlet weak var autoRaiseButton: UIButton!
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var autoLowerButton: UIButton!
    @IBOutlet weak var robotPositionLabel: UILabel!
    
    @IBOutlet weak var emergencyStopButton: UIButton!
    
    @IBOutlet weak var disconnectedBlurCoverView: UIVisualEffectView!
    
    lazy var controlPanelManager: ControlPanelViewManager = ControlPanelViewManager(managedView: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        controlPanelManager.refresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    func showDisconnectedView(show: Bool) {
        UIView.animate(withDuration: 1.0) {
            self.disconnectedBlurCoverView.alpha = show ? 1.0 : 0.0
        }
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: IBActions
    
    @IBAction func releaseAndLaunchButtonTapped(_ sender: UIButton) {
        controlPanelManager.releaseAndLaunchBird()
    }
    
    @IBAction func latchButtonAction(_ sender: UIButton, forEvent event: UIEvent) {
        controlPanelManager.latchBird()
    }

    @IBAction func unlatchButtonAction(_ sender: UIButton, forEvent event: UIEvent) {
        controlPanelManager.releaseBird()
    }
    
    @IBAction func releaseBirdButtonTapped(_ sender: UIButton) {
        controlPanelManager.releaseBird()
    }
    
    @IBAction func retractButtonAction(_ sender: UIButton, forEvent event: UIEvent) {
        controlPanelManager.retractLauncher()
    }
    
    @IBAction func extendButtonAction(_ sender: UIButton, forEvent event: UIEvent) {
        controlPanelManager.launchBird()
    }
    
    @IBAction func launchBirdButtonTapped(_ sender: UIButton) {
        controlPanelManager.launchBird()
    }
    
    @IBAction func autoRaiseButtonTapped(_ sender: UIButton) {
        controlPanelManager.autoRaiseToTop()
    }
    
    @IBAction func upButtonAction(_ sender: UIButton, forEvent event: UIEvent) {
        controlPanelManager.upButtonChangedState()
    }
    
    @IBAction func downButtonAction(_ sender: UIButton, forEvent event: UIEvent) {
        controlPanelManager.downButtonChangedState()
    }
    
    @IBAction func autoLowerButtonTapped(_ sender: UIButton) {
        controlPanelManager.autoLowerToBottom()
    }
    
    @IBAction func emergencyStopButtonPressed(_ sender: UIButton) {
        controlPanelManager.emergencyStopAll()
    }
    
}
