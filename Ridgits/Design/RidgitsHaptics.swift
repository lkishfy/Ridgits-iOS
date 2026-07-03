import SwiftUI
import UIKit

enum RidgitsHaptics {
    enum Feedback {
        case soft
        case light
        case medium
        case heavy
        case selection
        case success
        case warning
        case error
    }

    static func play(_ feedback: Feedback) {
        switch feedback {
        case .soft:
            impact(.soft)
        case .light:
            impact(.light)
        case .medium:
            impact(.medium)
        case .heavy:
            impact(.heavy)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        case .success:
            notification(.success)
        case .warning:
            notification(.warning)
        case .error:
            notification(.error)
        }
    }

    static func withFeedback(_ feedback: Feedback = .light, _ action: () -> Void) {
        play(feedback)
        action()
    }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

struct RidgitsCircularIconButtonStyle: ButtonStyle {
    var feedback: RidgitsHaptics.Feedback = .light

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(configuration.isPressed ? RidgitsColors.hoverSurface : Color.clear)
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    RidgitsHaptics.play(feedback)
                }
            }
    }
}

struct RidgitsHapticPlainButtonStyle: ButtonStyle {
    var feedback: RidgitsHaptics.Feedback = .light

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    RidgitsHaptics.play(feedback)
                }
            }
    }
}

struct RidgitsHapticPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    RidgitsHaptics.play(.medium)
                }
            }
    }
}

extension View {
    func ridgitsTapHaptic(
        _ feedback: RidgitsHaptics.Feedback = .light,
        perform action: @escaping () -> Void
    ) -> some View {
        onTapGesture {
            RidgitsHaptics.play(feedback)
            action()
        }
    }

    func ridgitsSelectionHaptic<V: Equatable>(trigger value: V) -> some View {
        onChange(of: value) { _, _ in
            RidgitsHaptics.play(.selection)
        }
    }
}
