//
//  Font+AnybodyFont.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 26/09/23.
//

import Foundation
import SwiftUI

extension Font {
    static func anybodyBold(size: CGFloat) -> Font {
        return Font.custom("Anybody-Bold", size: size)
    }
    static func anybodySemiBold(size: CGFloat) -> Font {
        return Font.custom("Anybody-SemiBold", size: size)
    }
    static func anybodyRegular(size: CGFloat) -> Font {
        return Font.custom("Anybody-Regular", size: size)
    }
    static func anybodyMedium(size: CGFloat) -> Font {
        return Font.custom("Anybody-Medium", size: size)
    }
    static func anybodyLight(size: CGFloat) -> Font {
        return Font.custom("Anybody-Light", size: size)
    }
}
