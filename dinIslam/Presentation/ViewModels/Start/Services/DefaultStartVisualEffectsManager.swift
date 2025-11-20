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
    var particles: [StartViewModel.Particle] = []
    var isGlowAnimationStarted: Bool = false
    
    private let particleVelocityRange: ClosedRange<Double> = -0.35...0.35
    private let particleSpeedMultiplier: Double = 0.65
    private var lastParticleUpdate: Date?
    
    func startGlowAnimationIfNeeded() {
        guard !isGlowAnimationStarted else { return }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            logoGlowIntensity = 1.0
        }
        isGlowAnimationStarted = true
    }
    
    func createParticlesIfNeeded() {
        guard particles.isEmpty else { return }
        particles = (0..<12).map { _ in
            StartViewModel.Particle(
                x: Double.random(in: -80...80),
                y: Double.random(in: -80...80),
                opacity: Double.random(in: 0.3...0.8),
                size: Double.random(in: 2...6),
                velocityX: Double.random(in: particleVelocityRange),
                velocityY: Double.random(in: particleVelocityRange),
                life: Double.random(in: 0.5...1.0)
            )
        }
        lastParticleUpdate = nil
    }
    
    func updateParticles(at date: Date) {
        guard !particles.isEmpty else {
            lastParticleUpdate = date
            return
        }
        
        let delta: Double
        if let lastParticleUpdate {
            delta = date.timeIntervalSince(lastParticleUpdate)
        } else {
            delta = 0
        }
        self.lastParticleUpdate = date
        
        guard delta > 0 else { return }
        
        let frameFactor = min(delta * 60.0, 1.0)
        
        for index in particles.indices {
            particles[index].x += particles[index].velocityX * frameFactor * particleSpeedMultiplier
            particles[index].y += particles[index].velocityY * frameFactor * particleSpeedMultiplier
            particles[index].life -= 0.01 * frameFactor
            particles[index].opacity = max(0, particles[index].life * 0.8)
            
            if particles[index].life <= 0 {
                particles[index] = StartViewModel.Particle(
                    x: Double.random(in: -80...80),
                    y: Double.random(in: -80...80),
                    opacity: Double.random(in: 0.3...0.8),
                    size: Double.random(in: 2...6),
                    velocityX: Double.random(in: particleVelocityRange),
                    velocityY: Double.random(in: particleVelocityRange),
                    life: Double.random(in: 0.5...1.0)
                )
            }
        }
    }
    
    func particlesSnapshot(for date: Date) -> [StartViewModel.Particle] {
        updateParticles(at: date)
        return particles
    }
}

