//
//  Main.swift
//  Duet
//
//  Created by George Shamugia on 29/10/2014.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

import Foundation

@UIApplicationMain class ApplicationDelegate : CCAppDelegate, UIApplicationDelegate {
    
    override func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]!) -> Bool {
        
        if let configPath = NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("Published-iOS").stringByAppendingPathComponent("configCocos2d.plist")
        {
            var cocos2dSetup = NSDictionary(contentsOfFile:configPath);
            
            #if APPORTABLE
                if cocos2dSetup[CCSetupScreenMode] == CCScreenModeFixed
                {
                UIScreen.mainScreen().currentMode = UIScreenMode.emulatedMode(UIScreenAspectFitEmulationMode);
                }
                else
                {
                UIScreen.mainScreen().currentMode = UIScreenMode.emulatedMode(UIScreenScaledAspectFitEmulationMode);
                }
            #endif
            
            CCBReader.configureCCFileUtils();
            
            self.setupCocos2dWithOptions(cocos2dSetup);
            
            return true;
        }
        
        return false;
    }
    
    override func startScene() -> (CCScene)
    {
        return CCBReader.loadAsScene("MainScene");
    }
}