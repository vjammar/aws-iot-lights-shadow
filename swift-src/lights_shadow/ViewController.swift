//
//  ViewController.swift
//  lights_shadow
//
//  Created by VJ Ammar on 1/28/16.
//  Copyright © 2016 VJ Ammar. All rights reserved.
//

import UIKit
import AWSCore
import AWSIoT
import SwiftyJSON

let controlThingName="YOUR THING NAME"

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var lightsButton: UIButton!
    weak var pollingTimer: NSTimer?;
    var currentLightStatus:Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view
        currentLightStatus = nil
        pollingTimer = NSTimer.scheduledTimerWithTimeInterval( 3.0, target: self, selector: "getThingStates", userInfo: nil, repeats: true )
    }
    
    func updateThingShadow( thingName: String, jsonData: JSON )
    {
        statusLabel.text = "Updating Shadow..."
        let updateThingShadowRequest = AWSIoTDataUpdateThingShadowRequest()
        updateThingShadowRequest.thingName = thingName
        do {
            let tmpVal = try jsonData.rawData()
            
            let IoTData = AWSIoTData.defaultIoTData()
            
            updateThingShadowRequest.payload = tmpVal
            IoTData.updateThingShadow(updateThingShadowRequest).continueWithBlock { (task) -> AnyObject? in
                if let error = task.error {
                    print("failed: [\(error)]")
                }
                if let exception = task.exception {
                    print("failed: [\(exception)]")
                }
                if (task.error == nil && task.exception == nil) {
                    // let result = task.result!
                    // let json = JSON(data: result.payload as NSData!)
                    //
                    // The latest state of the device shadow is in 'json'
                    //
                }
                //
                // Re-enable polling
                //
                dispatch_async( dispatch_get_main_queue()) {
                    if (self.pollingTimer == nil) {
                        self.pollingTimer = NSTimer.scheduledTimerWithTimeInterval( 3.0, target: self, selector: "getThingStates", userInfo: nil, repeats: true )
                    }
                }
                
                return nil
            }
        }
        catch {
            print("couldn't convert to raw")
        }
    }
    
    func getThingStates() {
        getThingState(controlThingName, completion: statusThingShadowCallback)
    }
    
    func getThingState( thingName: String, completion: (String, JSON) -> Void ){
        let IoTData = AWSIoTData.defaultIoTData()
        
        let getThingShadowRequest = AWSIoTDataGetThingShadowRequest()
        getThingShadowRequest.thingName = thingName
        IoTData.getThingShadow(getThingShadowRequest).continueWithBlock { (task) -> AnyObject? in
            if let error = task.error {
                print("failed: [\(error)]")
            }
            if let exception = task.exception {
                print("failed: [\(exception)]")
            }
            if (task.error == nil && task.exception == nil) {
                dispatch_async( dispatch_get_main_queue()) {
                    let result = task.result!
                    let json = JSON(data: result.payload as! NSData!)
                    completion( thingName, json )
                }
            }
            return nil
        }
    }
    
    func statusThingShadowCallback( thingName: String, json: JSON ) -> Void {
        if let lightsOn = json["state"]["reported"]["lightsOn"].bool {
            if(currentLightStatus != lightsOn){
                currentLightStatus = lightsOn
                if(lightsOn){
                    statusLabel.text = "Light Status: On!"
                    self.lightsButton.setBackgroundImage(UIImage(named: "lightbulb_on"), forState: UIControlState.Normal)
                }else{
                    statusLabel.text = "Light Status: Off!"
                    self.lightsButton.setBackgroundImage(UIImage(named: "lightbulb_off"), forState: UIControlState.Normal)
                }
            }
        }
    }
    
    @IBAction func lightsButtonTapped(sender: AnyObject) {
        if ((self.currentLightStatus) != nil && self.currentLightStatus == false){
            let controlJson = JSON(["state": ["desired": [ "lightsOn": true]]])
            updateThingShadow( controlThingName, jsonData: controlJson )
        }else{
            let controlJson = JSON(["state": ["desired": [ "lightsOn": false]]])
            updateThingShadow( controlThingName, jsonData: controlJson )
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

