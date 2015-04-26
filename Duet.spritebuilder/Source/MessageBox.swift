//
//  Messagebox.swift
//  Duet
//
//  Created by George Shamugia on 29/10/2014.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

import Foundation

class MessageBox: CCNode {
   
    var _titleLb:CCLabelTTF!
    var _scoreLb:CCLabelTTF!
    var _highScoreLb:CCLabelTTF!
    
    
    internal func display(msgTitle title:String, currentScore score:Int? = nil, usersHighScore highScore:Int)
    {
        _titleLb.string = title;
        if let s = score
        {
            _scoreLb.string = "Score: \(s)"
            _highScoreLb.string = "High Score: \(highScore)"
        }
        else
        {
            _scoreLb.string = "High Score: \(highScore)"
            _highScoreLb.string = ""
        }
    }
    
    func play()
    {
        NSNotificationCenter.defaultCenter().postNotificationName("CloseMsgNotification", object: self);
    }
    
}
