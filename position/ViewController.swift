//
//  ViewController.swift
//  position
//
//  Created by 冯丽文 on 2017/6/18.
//  Copyright © 2017年 Apple Inc. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import AVFoundation

class ViewController: UIViewController, CLLocationManagerDelegate, UIAccelerometerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    //motion variables
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var rollLabel: UILabel!
    @IBOutlet weak var yawLabel: UILabel!
    var isRunning = false
    let manager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1
        return manager
    }()
    
    //location variables
    let locationManager: CLLocationManager = CLLocationManager()
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    
    //camera variables
    var callBack :((_ face: UIImage) ->())?
    let captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    var timer : Timer!
    var upOrdown = true
    var isStart = false
    
    //compass variables
    @IBOutlet weak var compassView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
        //location setting
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
        locationManager.requestAlwaysAuthorization()
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.startUpdatingLocation()
            print("starting positioning!")
        }
        
        //motion setting
        manager.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: .main) { (data, error) in
            //print("Roll: \(data!.attitude.roll), Pitch: \(data!.attitude.pitch), Yaw: \(data!.attitude.yaw)")
            guard error == nil else {
                print(error!)
                return
            }
            if self.manager.isDeviceMotionActive {
                self.pitchLabel.text = "Roll: \(data!.attitude.roll)"
                self.rollLabel.text = "Pitch: \(data!.attitude.pitch)"
                self.yawLabel.text = "Yaw: \(data!.attitude.yaw)"
            }
            
        }

        
        //camera settings
        captureSession.sessionPreset = AVCaptureSessionPresetLow
        let devices = AVCaptureDevice.devices()
        for device in devices! {
            if ((device as AnyObject).hasMediaType(AVMediaTypeVideo)) {
                if ((device as AnyObject).position == AVCaptureDevicePosition.back) {
                    captureDevice = device as?AVCaptureDevice
                    if captureDevice != nil {
                        print("Capture Device found")
                        beginSession()
                    }
                }
            }
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ViewController.isStartTrue), userInfo: nil, repeats: false)
        
        //compass settings
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }else {
            print("当前磁力计设备损坏")
        }

    }

    //present location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation: CLLocation = locations.last!
        self.longitudeLabel.text = "经度:\(currentLocation.coordinate.longitude)"
        self.latitudeLabel.text = "纬度:\(currentLocation.coordinate.latitude)"
    }
    
    
    
    //control motion
//    @IBAction func starMotion(_ sender: Any) {
//        if isRunning {
//            stopMotionUpdates()
//        } else {
//            startMotionUpdates()
//        }
//        isRunning = !isRunning
//    }
    
//    //start motion
//    func startMotionUpdates() {
//            }
    
    //stop motion
//    func stopMotionUpdates() {
//        manager.stopDeviceMotionUpdates()
//    }
    
    //campass
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print(newHeading)
        // 1.获取真北方向
        let trueHeading = newHeading.trueHeading
        
        // 2.让指南针指向南面
        // 2.1.将真北方向的角度转成angle
        let angle = M_PI / 180 * trueHeading
        
        // 2.2.创建transform
        let transform = CGAffineTransform(rotationAngle: CGFloat(-angle))
        
        // 2.3.进行旋转
        
        UIView.animate(withDuration: 0.5) {
            self.compassView.transform = transform
        }
        
        // Damping : 阻力系数 (0~1.0)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 5.0, options: [], animations: {
            self.compassView.transform = transform
        }, completion: nil)    }
    
    //camera
    func isStartTrue(){
        self.isStart = true
    }
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
        captureSession.stopRunning()
        
    }
    
    
    func beginSession() {
        do {
            let tpinput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(tpinput)
        }catch{
            print("error: \(error)")
        }
        let output = AVCaptureVideoDataOutput()
        
        let cameraQueue = DispatchQueue(label: "cameraQueue", attributes: [])
        output.setSampleBufferDelegate(self, queue: cameraQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
        captureSession.addOutput(output)
        
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = "AVLayerVideoGravityResizeAspect"
        previewLayer?.frame = CGRect(x:300, y:0, width:400, height:600)
        self.view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }


}
