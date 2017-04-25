//
//  SystemMonitorViewController.swift
//  PoleControlPanel
//
//  Created by Steven Knodl on 4/9/17.
//  Copyright © 2017 Steve Knodl. All rights reserved.
//

import UIKit
import CoreBluetooth

class SystemMonitorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var systemMonitorStackView: UIStackView!
    
    @IBOutlet weak var connectedLabelStackView: UIStackView!
    @IBOutlet weak var connectedValueLabel: UILabel!
    
    @IBOutlet weak var deviceNameValueLabel: UILabel!
    @IBOutlet weak var deviceIdentifierValueLabel: UILabel!
    
    @IBOutlet weak var scanForDevicesButton: UIButton!
    
    @IBOutlet weak var activityIndicatorStackView: UIStackView!
    @IBOutlet weak var activityTypeLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var batteryLevelStackView: UIStackView!
    @IBOutlet weak var batteryValueLabel: UILabel!
    
    @IBOutlet weak var rssiLevelStackView: UIStackView!
    @IBOutlet weak var rssiValueLabel: UILabel!
    
    @IBOutlet weak var liftCountStackView: UIStackView!
    @IBOutlet weak var liftCountValueLabel: UILabel!
    
    @IBOutlet weak var discoveredDevicesTableView: UITableView!
    
    lazy var systemMonitorManager: SystemMonitorViewManager = SystemMonitorViewManager(managedView: self)
    
    lazy private var disconnectGesture = { () -> UILongPressGestureRecognizer in 
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(SystemMonitorViewController.disconnect))
        gestureRecognizer.minimumPressDuration = 5.0
        return gestureRecognizer
    }()
    
    var discoveredPeripherals = [PeripheralCellData]() {
        didSet {
            if discoveredPeripherals.isEmpty {
                self.activityIndicatorStackView.isHidden = true
                self.scanForDevicesButton.isHidden = false
            } else {
                self.discoveredDevicesTableView.alpha = 0.0
                UIView.animate(withDuration: 0.25, animations: {
                    self.activityIndicatorStackView.isHidden = true
                }, completion: { _ in
                    UIView.animate(withDuration: 0.75, animations: {
                        self.discoveredDevicesTableView.isHidden = false
                        self.discoveredDevicesTableView.alpha = 1.0
                    })
                })
                discoveredDevicesTableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectedLabelStackView.isHidden = false
        connectedValueLabel.text = "No"
        
        deviceNameValueLabel.isHidden = true
        deviceIdentifierValueLabel.isHidden = true
        deviceIdentifierValueLabel.font = UIFont.boldSystemFontWithMonospacedNumbers(size: 12.0)
        rssiLevelStackView.addGestureRecognizer(disconnectGesture)
        
        scanForDevicesButton.isHidden = false
        activityIndicatorStackView.isHidden = true
        
        batteryLevelStackView.isHidden = true
        rssiLevelStackView.isHidden = true 
        liftCountStackView.isHidden = true
        
        discoveredDevicesTableView.isHidden = true
        
        discoveredDevicesTableView.estimatedRowHeight = 40
        discoveredDevicesTableView.rowHeight = UITableViewAutomaticDimension
        discoveredDevicesTableView.tableFooterView = UIView()
        discoveredDevicesTableView.delegate = self
        discoveredDevicesTableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func connectFailed() {
        UIView.animate(withDuration: 0.50) {
            self.discoveredDevicesTableView.isHidden = true
            self.scanForDevicesButton.isHidden = false
        }
    }
    
    func connectSucceeded(deviceName: String?, deviceIdentifier: String) {
        UIView.animate(withDuration: 0.35) {
            self.connectedValueLabel.text = "Yes"
            self.activityIndicatorStackView.isHidden = true
            self.deviceNameValueLabel.text = deviceName ?? "<Device Name Not Available>"
            self.deviceNameValueLabel.isHidden = false
            self.deviceIdentifierValueLabel.text = deviceIdentifier
            self.deviceIdentifierValueLabel.isHidden = false
        }
    }
    
    func deviceDisconnected() {
        UIView.animate(withDuration: 0.35) {
            self.connectedValueLabel.text = "No"
            self.deviceNameValueLabel.isHidden = true
            self.deviceIdentifierValueLabel.isHidden = true
            self.rssiLevelStackView.isHidden = true
            self.scanForDevicesButton.isHidden = false
        }
    }
    
    func showRSSI(_ show: Bool) {
        UIView.animate(withDuration: 0.35) {
            if !(self.rssiLevelStackView.isHidden == !show) {
                self.rssiLevelStackView.isHidden = !show
            }
        }
    }
    
    func updateRssiLabel(value: String) {
        rssiValueLabel.text = value
    }
    
    
    //MARK: - IBActions
    
    @IBAction func scanForDevicesTapped(_ sender: Any) {
        systemMonitorManager.scanForDevices()
        UIView.animate(withDuration: 0.35) {
            self.scanForDevicesButton.isHidden = true
            self.activityIndicatorStackView.isHidden = false
            self.activityTypeLabel.text = "Scanning..."
        }
    }
    
    @IBAction func cancelDeviceSelectionTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.35) {
            self.scanForDevicesButton.isHidden = false
            self.discoveredDevicesTableView.isHidden = true
        }
    }
    
    //MARK: - Selectors
    
    func disconnect() {
        print("Disconnect requested")
    }
    
    //MARK: - Tableview Datasource / Delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoveredPeripheralTableViewCell", for: indexPath) as! DiscoveredPeripheralTableViewCell
        cell.configureCell(withData: discoveredPeripherals[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        systemMonitorManager.selectDeviceForConnection(atIndex: indexPath.row)
        UIView.animate(withDuration: 0.25) { 
            self.discoveredDevicesTableView.isHidden = true
            self.activityIndicatorStackView.isHidden = false
            self.activityTypeLabel.text = "Connecting..."
        }
    }
}



