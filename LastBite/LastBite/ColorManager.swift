//  ColorManager.swift
//  LastBite
//
//  Created by David Santiago on 5/03/25.
//

import Foundation
import SwiftUI

extension Color {
    static let primaryGreen = Color(hex: "53B175") // Your custom color

    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
