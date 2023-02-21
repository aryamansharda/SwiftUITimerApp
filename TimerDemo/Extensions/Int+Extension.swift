//
//  Int+Extension.swift
//  TimerDemo
//
//  Created by Aryaman Sharda on 2/20/23.
//

import Foundation

extension Int {
    var asTimeString: String {
        let hour = self / 3600
        let minute = self / 60 % 60
        let second = self % 60

        return String(format: "%02i:%02i:%02i", hour, minute, second)
    }
}
