//
//  StartVisualEffectsManaging.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol StartVisualEffectsManaging: AnyObject {
    var logoGlowIntensity: Double { get set }
    var isGlowAnimationStarted: Bool { get set }
    
    func startGlowAnimationIfNeeded()
}

