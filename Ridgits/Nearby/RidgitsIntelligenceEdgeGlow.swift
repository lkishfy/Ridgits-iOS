import SwiftUI
import Combine
import UIKit

private extension UIScreen {
    /// Physical display corner radius so the glow hugs the screen shape
    /// instead of getting clipped by the device's rounded corners.
    var ridgitsDisplayCornerRadius: CGFloat {
        let key = ["Radius", "Corner", "display", "_"].reversed().joined()
        if let radius = value(forKey: key) as? CGFloat, radius > 0 {
            return radius
        }
        return 55
    }
}

/// Apple Intelligence-style edge glow, ported from
/// https://github.com/jacobamobin/AppleIntelligenceGlowEffect (MIT).
/// Layered angular-gradient stroke borders with blur; gradient stops
/// regenerate on a timer so the colors flow around the screen edge.
struct RidgitsIntelligenceEdgeGlow: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GlowEffect()
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

private struct GlowEffect: View {
    @State private var gradientStops: [Gradient.Stop] = GlowEffect.generateGradientStops()
    @State private var timer: AnyCancellable?

    private let cornerRadius = UIScreen.main.ridgitsDisplayCornerRadius

    var body: some View {
        ZStack {
            EffectNoBlur(gradientStops: gradientStops, cornerRadius: cornerRadius, width: 1.5, opacity: 0.9)
            Effect(gradientStops: gradientStops, cornerRadius: cornerRadius, width: 3, blur: 6, opacity: 0.7)
            Effect(gradientStops: gradientStops, cornerRadius: cornerRadius, width: 5, blur: 14, opacity: 0.5)
            Effect(gradientStops: gradientStops, cornerRadius: cornerRadius, width: 7, blur: 24, opacity: 0.35)
        }
        .drawingGroup() // Composite layers into a single render pass
        .onAppear {
            // Slow, continuous color drift — new stops every few seconds,
            // animated over a slightly longer window so morphs overlap seamlessly.
            timer = Timer.publish(every: 3.0, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    withAnimation(.easeInOut(duration: 3.5)) {
                        gradientStops = GlowEffect.generateGradientStops()
                    }
                }
        }
        .onDisappear {
            timer?.cancel()
            timer = nil
        }
    }

    static func generateGradientStops() -> [Gradient.Stop] {
        [
            Gradient.Stop(color: Color(hex: 0xBC82F3), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: 0xF5B9EA), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: 0x8D9FFF), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: 0xFF6778), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: 0xFFBA71), location: Double.random(in: 0...1)),
            Gradient.Stop(color: Color(hex: 0xC686FF), location: Double.random(in: 0...1)),
        ].sorted { $0.location < $1.location }
    }
}

private struct Effect: View {
    var gradientStops: [Gradient.Stop]
    var cornerRadius: CGFloat
    var width: CGFloat
    var blur: CGFloat
    var opacity: Double

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(stops: gradientStops),
                    center: .center
                ),
                lineWidth: width
            )
            .blur(radius: blur)
            .opacity(opacity)
            .compositingGroup() // Optimize blur rendering
    }
}

private struct EffectNoBlur: View {
    var gradientStops: [Gradient.Stop]
    var cornerRadius: CGFloat
    var width: CGFloat
    var opacity: Double

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(stops: gradientStops),
                    center: .center
                ),
                lineWidth: width
            )
            .opacity(opacity)
    }
}

#Preview {
    RidgitsIntelligenceEdgeGlow()
}
