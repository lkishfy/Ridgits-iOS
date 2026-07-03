import SwiftUI

/// Interactive 3D hero stack — matches Ridgits web landing `hero-stack` with app screenshots.
struct RidgitsHeroImageStack: View {
    @State private var isFanningOut = false
    @State private var isFingerDown = false
    @GestureState private var dragTranslation: CGSize = .zero

    private let cardSize: CGFloat = 180

    var body: some View {
        ZStack {
            heroCard(image: "HeroStack4", layer: .back)
            heroCard(image: "HeroStack3", layer: .third)
            heroCard(image: "HeroStack2", layer: .second)
            heroCard(image: "HeroStack1", layer: .front)
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .padding(.trailing, 48)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragTranslation) { value, state, _ in
                    state = value.translation
                }
                .onChanged { _ in
                    if !isFingerDown {
                        isFingerDown = true
                        RidgitsHaptics.play(.soft)
                    }
                    withAnimation(.easeOut(duration: 0.25)) {
                        isFanningOut = true
                    }
                }
                .onEnded { _ in
                    isFingerDown = false
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isFanningOut = false
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isFanningOut.toggle()
            }
        }
        .accessibilityLabel("Ridgits app preview carousel")
        .accessibilityHint("Tap or drag to fan the cards")
    }

    @ViewBuilder
    private func heroCard(image: String, layer: HeroLayer) -> some View {
        let transform = layer.transform(fanned: isFanningOut, drag: dragTranslation)

        Image(image)
            .resizable()
            .scaledToFill()
            .frame(width: cardSize, height: cardSize)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RidgitsColors.border.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 12)
            .rotation3DEffect(.degrees(transform.rotationY), axis: (x: 0, y: 1, z: 0))
            .rotationEffect(.degrees(transform.rotationZ))
            .offset(x: transform.offset.width, y: transform.offset.height)
            .scaleEffect(transform.scale)
            .opacity(transform.opacity)
            .zIndex(transform.zIndex)
    }
}

private enum HeroLayer {
    case front, second, third, back

    struct Transform {
        let offset: CGSize
        let rotationY: Double
        let rotationZ: Double
        let scale: CGFloat
        let opacity: Double
        let zIndex: Double
    }

    func transform(fanned: Bool, drag: CGSize) -> Transform {
        let dragBoost = min(max(drag.width / 120, -1), 1)
        let fan: CGFloat = fanned ? 1 : 0

        switch self {
        case .front:
            return Transform(
                offset: CGSize(
                    width: (fanned ? 0 : 0) + drag.width * 0.08,
                    height: (fanned ? -4 : 0) + drag.height * 0.05
                ),
                rotationY: (fanned ? 0 : 0) + dragBoost * 4,
                rotationZ: (fanned ? 2 : 0) + dragBoost * 2,
                scale: 1,
                opacity: 1,
                zIndex: 4
            )
        case .second:
            return Transform(
                offset: CGSize(
                    width: 40 * fan + drag.width * 0.12 + dragBoost * 12,
                    height: 30 * fan + drag.height * 0.08
                ),
                rotationY: -4 - fan * 2 + dragBoost * 3,
                rotationZ: -3 - fan * 2,
                scale: 0.98,
                opacity: 0.95,
                zIndex: 3
            )
        case .third:
            return Transform(
                offset: CGSize(
                    width: 80 * fan + drag.width * 0.16 + dragBoost * 20,
                    height: 60 * fan + drag.height * 0.1
                ),
                rotationY: -8 - fan * 3 + dragBoost * 2,
                rotationZ: -6 - fan * 3,
                scale: 0.96,
                opacity: 0.9,
                zIndex: 2
            )
        case .back:
            return Transform(
                offset: CGSize(
                    width: 120 * fan + drag.width * 0.2 + dragBoost * 28,
                    height: 90 * fan + drag.height * 0.12
                ),
                rotationY: -12 - fan * 4 + dragBoost * 1,
                rotationZ: -10 - fan * 4,
                scale: 0.94,
                opacity: 0.85,
                zIndex: 1
            )
        }
    }
}
