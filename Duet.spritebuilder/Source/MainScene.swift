//
//  MainScene.swift
//  Duet
//
//  Created by George Shamugia on 29/10/2014.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

import Foundation


class MainScene : CCScene, CCPhysicsCollisionDelegate, BLEDelegate {
    
    var ble_device:BLE?
    
    let rotationAngle:Float = 45.0;
    
    var _statusLb:CCLabelTTF!
    var _scoreLb:CCLabelTTF!
    var _physicsNode:CCPhysicsNode!
    var _dimmNode:CCNode!
    
    var _msgBox:MessageBox!;
    var _blueDotNode:CCNode!;
    var _redDotNode:CCNode!;
    
    enum GameState {
        case START
        case PLAY
        case OVER
    }
    
    var currentGameStae = GameState.START;
    
    var hScore:Int = 0;
    var cScore:Int = 0;
    
    var rockArray = Array<RockObject>();
    
    
    
    override init()
    {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveNotification:", name: "CloseMsgNotification", object: nil);
        
        currentGameStae = GameState.START;
    }
    
    func didLoadFromCCB()
    {
        cScore = 0;
        _scoreLb.string = "0";
        _physicsNode.collisionDelegate = self;
        
        _dimmNode = CCNodeColor.node() as CCNode;
        _msgBox = CCBReader.load("MessageBox") as MessageBox;
        
        var usrdef:NSUserDefaults = NSUserDefaults.standardUserDefaults();
        if let record = usrdef.objectForKey("HIGHSCORE") as? NSNumber
        {
            hScore = record.integerValue;
        }
        
        connectToBLEDevice();
    }
    
    func connectToBLEDevice()
    {
        _statusLb.string = "Connecting...";
        
        self.ble_device = BLE();
        self.ble_device?.controlSetup(1);
        self.ble_device?.delegate = self;
        tryToConnectToBLEShield();
    }
    
    override func onEnterTransitionDidFinish()
    {
        _blueDotNode = CCBReader.load("BlueDotNode") as CCNode;
        _blueDotNode.position = CGPointMake(161, 150);
        _blueDotNode.anchorPoint = CGPointMake(0.5, 0.5)
        _physicsNode.addChild(_blueDotNode);

        _redDotNode = CCBReader.load("RedDotNode") as CCNode;
        _redDotNode.position = CGPointMake(161, 150);
        _redDotNode.anchorPoint = CGPointMake(0.5, 0.5)
        _physicsNode.addChild(_redDotNode);
        
        currentGameStae = GameState.START;
        displayMessageBox("Duet Game", score: nil, highScore: hScore);
    }
    
    override func update(delta:CCTime)
    {
        if currentGameStae == GameState.PLAY
        {
            if rockArray.count > 0
            {
                var rk = rockArray[rockArray.count - 1] as RockObject;
                if (rk.position.y < 242)
                {
                    dropNewRock();
                }
                
                rk = rockArray[0] as RockObject;
                if (rk.position.y < 0)
                {
                    rk.removeFromParentAndCleanup(true);
                    rockArray.removeAtIndex(0);
                    cScore++;
                    _scoreLb.string = String(cScore);
                }
            }
            else
            {
                dropNewRock();
            }
        }
    }
    
    func dropNewRock()
    {
        var viewSz:CGSize = CCDirector.sharedDirector().viewSize()
        var x_pos:CGFloat = CGFloat(arc4random_uniform(UInt32(viewSz.width - 30))); //30 - rock.width
        var y_pos = viewSz.height;
        
        var rk = CCBReader.load("Rock") as RockObject;
        rk.position = CGPointMake(x_pos, y_pos);
        _physicsNode.addChild(rk)
        rockArray.append(rk);
    }
    
    func displayMessageBox(title:String, score:Int? = nil, highScore:Int)
    {
        var viewSz:CGSize = CCDirector.sharedDirector().viewSize()
        
        _dimmNode.contentSize = CGSizeMake(viewSz.width, viewSz.height);
        _dimmNode.anchorPoint = CGPointMake(0, 0);
        _dimmNode.opacity = 0.5;
        _dimmNode.zOrder = 100;
        self.addChild(_dimmNode);
        
        _msgBox.position = CGPointMake((viewSz.width / 2) - (_msgBox.contentSize.width / 2), (viewSz.height / 2) - (_msgBox.contentSize.height / 2));
        _msgBox.zOrder = 110;
        self.addChild(_msgBox);
        _msgBox.display(msgTitle: title, currentScore: score, usersHighScore: highScore);
    }
    
    func receiveNotification(notification:NSNotification)
    {
        if notification.name == "CloseMsgNotification"
        {
            _msgBox.removeFromParentAndCleanup(true);
            _dimmNode.removeFromParentAndCleanup(true);
            
            cScore = 0;
             _scoreLb.string = "0";
            
            currentGameStae = GameState.PLAY;
        }
    }
    
    func ccPhysicsCollisionBegin(pair:CCPhysicsCollisionPair, rock nodeA:RockObject, circle nodeB:CCNode) -> Bool
    {
        if currentGameStae == GameState.PLAY
        {
            currentGameStae = GameState.OVER;
            
            _blueDotNode.rotation = 0;
            _redDotNode.rotation = 0;
            
            if cScore > hScore
            {
                hScore = cScore;
                storeNewHighScore(NSNumber(integer: cScore));
            }
            
            if rockArray.count > 0
            {
                for rk:RockObject in rockArray
                {
                    rk.removeFromParentAndCleanup(true);
                }
                rockArray.removeAll(keepCapacity: false);
            }
            
            displayMessageBox("Game Over", score: cScore, highScore: hScore);
        }
        return false;
    }
    
    /*func ccPhysicsCollisionPostSolve(pair:CCPhysicsCollisionPair, rock nodeA:RockObject, circle nodeB:CCNode)
    {}*/
    
    func storeNewHighScore(nHScore:NSNumber)
    {
        var usrdef:NSUserDefaults = NSUserDefaults.standardUserDefaults();
        usrdef.setObject(nHScore, forKey: "HIGHSCORE");
        usrdef.synchronize();
    }
    
    func tryToConnectToBLEShield()
    {
        if self.ble_device?.CM.state != CBCentralManagerState.PoweredOn
        {
            waitAndTryConnectingToBLE();
        }
        
        if self.ble_device?.peripherals == nil || self.ble_device?.peripherals.count == 0
        {
            self.ble_device?.findBLEPeripherals(2);
        }
        else if !(self.ble_device?.activePeripheral != nil)
        {
            self.ble_device?.connectPeripheral(self.ble_device?.peripherals[0] as CBPeripheral);
        }
        waitAndTryConnectingToBLE();
    }
    
    func waitAndTryConnectingToBLE()
    {
        if self.ble_device?.CM.state != CBCentralManagerState.PoweredOn
        {
            var timer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: Selector("tryToConnectToBLEShield"), userInfo: nil, repeats: false);
        }
        else
        {
            var timer = NSTimer.scheduledTimerWithTimeInterval(0.20, target: self, selector: Selector("tryToConnectToBLEShield"), userInfo: nil, repeats: false);
        }
    }
    
    func bleDidConnect() {
        println("Connected to BLE Device");
        _statusLb.string = "Connected";
    }
    
    func bleDidDisconnect() {
        println("Disconnected from BLE Device");
        _statusLb.string = "Disconnected"
    }
    
    func bleDidUpdateRSSI(rssi: NSNumber!) {
        //println("Did RSSI: \(rssi)");
    }
    
    func bleDidReceiveData(data: UnsafeMutablePointer<CChar>, length: Int32) {
        if currentGameStae == GameState.PLAY
        {
            if let str:NSString = String.fromCString(data)
            {
                var rotaryValue = str.floatValue;
                if rotaryValue > 0
                {
                    println(">>> Rotate Counter Clockwise.");
                    
                    _blueDotNode.runAction(CCActionRotateBy(duration: 0.1, angle: -rotationAngle));
                    _redDotNode.runAction(CCActionRotateBy(duration: 0.1, angle: -rotationAngle));
                    
                    //_blueDotNode.rotation = _blueDotNode.rotation - rotationAngle;
                    //_redDotNode.rotation = _redDotNode.rotation - rotationAngle;
                }
                else if rotaryValue < 0
                {
                    println(">>> Rotate Clockwise.");
                    
                    _blueDotNode.runAction(CCActionRotateBy(duration: 0.1, angle: rotationAngle));
                    _redDotNode.runAction(CCActionRotateBy(duration: 0.1, angle: rotationAngle));
                    
                    //_blueDotNode.rotation = _blueDotNode.rotation + rotationAngle;
                    //_redDotNode.rotation = _redDotNode.rotation + rotationAngle;
                }
            }
        }
    }
    
}