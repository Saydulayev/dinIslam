//
//  DefaultStartVisualEffectsManager.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation
import SwiftUI

@MainActor
final class DefaultStartVisualEffectsManager: StartVisualEffectsManaging {
    var logoGlowIntensity: Double = 0.5
    var isGlowAnimationStarted: Bool = false
    
    func startGlowAnimationIfNeeded() {
        guard !isGlowAnimationStarted else { return }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            logoGlowIntensity = 1.0
        }
        isGlowAnimationStarted = true
    }
}

