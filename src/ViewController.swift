//
//  ViewController.swift
//  CoreMotionExample
//
//  Created by Maxim Bilan on 1/21/16.
//  Copyright © 2016 Maxim Bilan. All rights reserved.
//

import UIKit
import CoreMotion
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate
{
    //--------------------------------
    @IBOutlet var accLabelX: UILabel!
    @IBOutlet var accLabelY: UILabel!
    @IBOutlet var accLabelZ: UILabel!
    //--------------------------------
    let motionManager = CMMotionManager()
    var timer: Timer!
    //--------------------------------
    override func viewDidLoad()
    {
        super.viewDidLoad()
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        motionManager.startDeviceMotionUpdates()
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
        startPeripheral(peripheralName: "")
    }
    
    @objc func update() {
        if let accelerometerData = motionManager.accelerometerData
        {
            accLabelX.text = String(format: "%.2f", accelerometerData.acceleration.x)
            accLabelY.text = String(format: "%.2f", accelerometerData.acceleration.y)
            accLabelZ.text = String(format: "%.2f", accelerometerData.acceleration.z)
            
            if((currentCentral) != nil)
            {
                updateCharacteristic(value: Float32(accelerometerData.acceleration.x))
            }
        }
        if let gyroData = motionManager.gyroData {
            //			print(gyroData)
        }
        if let magnetometerData = motionManager.magnetometerData {
            //			print(magnetometerData)
        }
        if let deviceMotion = motionManager.deviceMotion {
            //			print(deviceMotion)
        }
    }
    
    //--------------------------------------------------------------------------
    // MARK: Bluetooth Peripheral Vars
    let serviceId = "29D7544B-6870-45A4-BB7E-D981535F4525"
    let characteristicId  = "B81672D5-396B-4803-82C2-029D34319015" //"A181"
    
    var localPeripheralManager: CBPeripheralManager! = nil
    var localService:CBService? = nil
    var accCharacteristic: CBMutableCharacteristic! = nil
    var localPeripheral:CBPeripheral? = nil
    var createdService:CBService? = nil
    var currentCentral:CBCentral! = nil
    var peripheralDiscoverableName = ""
    var powerOn = false
    var rescanTimer: Timer?
    
    //--------------------------------------------------------------------------
    // MARK: Bluetooth Peripheral Methods
    func startPeripheral(peripheralName: String)
    {
        peripheralDiscoverableName = peripheralName
        print("start Peripheral")
        print("Discoverable name : " + peripheralName)
        localPeripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    //--------------------------------------------------------------------------
    func stopPeripheral()
    {
        print("Stop advertising")
        print("Stop peripheral Service")
        stopServices()
    }
    //--------------------------------------------------------------------------
    func stopServices()
    {
        print("Stopping BLE services...")
        self.localPeripheralManager.removeAllServices()
        self.localPeripheralManager.stopAdvertising()
    }
    //--------------------------------------------------------------------------
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        if (peripheral.state == CBManagerState.poweredOn)
        {
            print("peripheral is on")
            self.powerOn = true
            self.startServices()
        }
    }
    //--------------------------------------------------------------------------
    func startServices()
    {
        print("starting services")
        print("Service UUID: " + serviceId)
        print("Characteristic: read UUID: " + characteristicId)
        
        let characteristicCBUUID = CBUUID(string: characteristicId)
        accCharacteristic = CBMutableCharacteristic(type: characteristicCBUUID,
                                                    properties: [.read, .notify],
                                                    value: nil,
                                                    permissions: [.readable])
        
        let serviceUUID = CBUUID(string: serviceId)
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        service.characteristics = [accCharacteristic]
        createdService = service
        
        localPeripheralManager.add(service)
    }
    //--------------------------------------------------------------------------
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didAdd service: CBService,
                           error: Error?){
        
        if error != nil {
            print(("Error adding services: \(error?.localizedDescription)"))
        }
        else
        {
            localService = service
            let advertisement: [String : Any] = [CBAdvertisementDataLocalNameKey: UIDevice.current.name + "test",
                                                 CBAdvertisementDataServiceUUIDsKey : [service.uuid]]
            
            self.localPeripheralManager.startAdvertising(advertisement)
        }
    }
    //--------------------------------------------------------------------------
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager,
                                              error: Error?){
        if error != nil {
            print(("Error while advertising: \(error?.localizedDescription)"))
        }
        else {
            print("adversiting done. no error")
        }
        //peripheral.stopAdvertising()
    }
    //--------------------------------------------------------------------------
    // called when CBCentral manager request to read
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveRead request: CBATTRequest)
    {
        
        print("CB Central Manager request from central: ")
        print(request)
    }
    //--------------------------------------------------------------------------
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
    {
        print("CB Central Manager request write from central: ")
        
        if requests.count > 0
        {
            let str = NSString(data: requests[0].value!, encoding:String.Encoding.utf8.rawValue)!
            print("value sent by central Manager : " + String(describing: str))
        }
    }
    //--------------------------------------------------------------------------
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic)
    {
        print("Connected!")
        currentCentral = central;
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic)
    {
        print("Disconnected!")
        currentCentral = nil;
    }
    //--------------------------------------------------------------------------
    func respond(to request: CBATTRequest, withResult result: CBATTError.Code)
    {
        print("respnse requested")
    }
    //--------------------------------------------------------------------------
    func updateCharacteristic(value: Float32)
    {
        self.localPeripheralManager.updateValue(withUnsafeBytes(of: value, {Data($0)}),
                                                for: accCharacteristic,
                                                onSubscribedCentrals: [currentCentral])
    }
}