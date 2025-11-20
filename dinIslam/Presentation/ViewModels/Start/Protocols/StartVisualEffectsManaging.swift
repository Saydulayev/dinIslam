//
//  StartVisualEffectsManaging.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol StartVisualEffectsManaging: AnyObject {
    var logoGlowIntensity: Double { get set }
    var particles: [StartViewModel.Particle] { get set }
    var isGlowAnimationStarted: Bool { get set }
    
    func startGlowAnimationIfNeeded()
    func createParticlesIfNeeded()
    func updateParticles(at date: Date)
    func particlesSnapshot(for date: Date) -> [StartViewModel.Particle]
}

