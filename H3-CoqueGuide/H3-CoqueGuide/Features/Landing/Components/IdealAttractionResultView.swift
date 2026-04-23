import SwiftUI

struct IdealAttractionResultView: View {
    let attraction: Attraction
    var onMap: (() -> Void)? = nil
    var onAskCoque: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(attraction.color.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: attraction.icon)
                        .scalingFont(size: 24, weight: .bold)
                        .foregroundStyle(attraction.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(attraction.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(attraction.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(attraction.message)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    if let onMap = onMap { onMap() }
                    else { NotificationCenter.default.post(name: .openMapFromIdealAttraction, object: nil) }
                } label: {
                    Text("Ir al mapa")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange))
                        .foregroundStyle(.white)
                }

                Button {
                    if let onAsk = onAskCoque { onAsk() }
                    else { NotificationCenter.default.post(name: .askCoqueFromIdealAttraction, object: nil, userInfo: ["name": attraction.name]) }
                } label: {
                    Text("Preguntarle a Coque")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor, lineWidth: 1))
                }
            }
        }
        .padding(20)
    }
}

#Preview {
    IdealAttractionResultView(attraction: Attraction.museumAttractions.first!)
}
