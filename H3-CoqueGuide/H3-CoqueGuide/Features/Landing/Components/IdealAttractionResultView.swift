import SwiftUI

struct IdealAttractionResultView: View {
    let attraction: Attraction
    var onMap: (() -> Void)? = nil
    var onAskCoque: (() -> Void)? = nil
    @State private var appeared: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            // Header con ícono grande centrado
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(attraction.color.opacity(0.15))
                        .frame(width: 92, height: 92)
                    Image(systemName: attraction.icon)
                        .scalingFont(size: 38, weight: .bold)
                        .foregroundStyle(attraction.color)
                        .pulsingGlow(attraction.color)
                }

                VStack(spacing: 4) {
                    Text(attraction.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text(attraction.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 4)

            // Mensaje central — la pregunta sugerida para Coque
            Text(attraction.message)
                .font(.callout)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Spacer(minLength: 4)

            // Botones de acción
            HStack(spacing: 12) {
                Button {
                    if let onMap = onMap { onMap() }
                    else { NotificationCenter.default.post(name: .openMapFromIdealAttraction, object: nil) }
                } label: {
                    Text(L10n.idealAttractionGoToMap)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange))
                        .foregroundStyle(.white)
                }
                .buttonStyle(PressableButtonStyle())

                Button {
                    if let onAsk = onAskCoque { onAsk() }
                    else { NotificationCenter.default.post(name: .askCoqueFromIdealAttraction, object: nil, userInfo: ["name": attraction.name]) }
                } label: {
                    Text(L10n.idealAttractionAskCoqueButton)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor, lineWidth: 1))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(20)
        .scaleEffect(appeared ? 1 : 0.98)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }
}

#Preview {
    IdealAttractionResultView(attraction: Attraction.museumAttractions.first!)
}
