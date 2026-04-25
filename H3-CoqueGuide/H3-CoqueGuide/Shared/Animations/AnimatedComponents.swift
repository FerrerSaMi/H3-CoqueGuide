import SwiftUI

// Reusable button with tactile press animation
public struct PressableButtonStyle: ButtonStyle {
    public var scaleAmount: CGFloat = 0.96

    public init(scaleAmount: CGFloat = 0.96) {
        self.scaleAmount = scaleAmount
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .opacity(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Option card style used for survey option buttons
public struct OptionCardStyle: ButtonStyle {
    public var isSelected: Bool
    public var cornerRadius: CGFloat = 24

    public init(isSelected: Bool = false, cornerRadius: CGFloat = 24) {
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.primary.opacity(0.48) : Color.clear, lineWidth: 3)
                    .animation(.easeInOut(duration: 0.18), value: isSelected)
            )
            .shadow(color: .orange.opacity(configuration.isPressed || isSelected ? 0.22 : 0.14), radius: configuration.isPressed || isSelected ? 14 : 8, x: 0, y: configuration.isPressed || isSelected ? 8 : 5)
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// Small pulsing glow modifier
public struct PulsingGlow: ViewModifier {
    public var color: Color = .accentColor
    @State private var pulse = false

    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(pulse ? 0.45 : 0.14), radius: pulse ? 20 : 6, x: 0, y: pulse ? 10 : 4)
            .scaleEffect(pulse ? 1.006 : 1.0)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

public extension View {
    func pulsingGlow(_ color: Color = .accentColor) -> some View {
        modifier(PulsingGlow(color: color))
    }
}

// Fancy loading indicator: rotating arc + pulsing dot
public struct FancyLoadingView: View {
    @State private var isAnimating = false
    public var size: CGFloat = 44

    public init(size: CGFloat = 44) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: 0.28)
                .stroke(
                    LinearGradient(colors: [Color.accentColor, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 0.95).repeatForever(autoreverses: false), value: isAnimating)

            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .offset(y: -size/2)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 0.95).repeatForever(autoreverses: false), value: isAnimating)
        }
        .onAppear { isAnimating = true }
    }
}

// Animated progress bar with subtle bounce
public struct AnimatedProgressBar: View {
    public var fraction: Double // 0.0 - 1.0
    public var height: CGFloat = 6

    @State private var animFraction: Double = 0

    public init(fraction: Double, height: CGFloat = 6) {
        self.fraction = fraction
        self.height = height
        self._animFraction = State(initialValue: fraction)
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: height)

                Capsule()
                    .fill(LinearGradient(colors: [Color.accentColor.opacity(0.95), Color.orange], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, CGFloat(animFraction) * geo.size.width), height: height)
                    .shadow(color: Color.accentColor.opacity(0.25), radius: 6, x: 0, y: 3)
                    .animation(.easeInOut(duration: 0.45), value: animFraction)
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
        .onChange(of: fraction) { newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { animFraction = newValue }
        }
        .onAppear {
            animFraction = fraction
        }
    }
}
