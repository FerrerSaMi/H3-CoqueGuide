//
//  ScannerMissionSheetView.swift
//  H3-CoqueGuide
//
//  Sheet que muestra el progreso de la misión "Hide and Seek"
//  Visible desde el botón de misión en el escáner.
//

import SwiftUI

struct ScannerMissionSheetView: View {

    /// Recibe el VM ya creado por `CamScannerViewModel` para que el progreso
    /// se actualice en vivo cuando se escanea un objeto con la sheet abierta.
    @ObservedObject var viewModel: ScannerMissionViewModel
    @Environment(\.dismiss) var dismiss

    /// Mapa label → título a mostrar en el idioma del dispositivo.
    /// Se popula al abrir la sheet via `.task`. Mientras se carga, mostramos
    /// el label tal cual (en español) para no bloquear la UI.
    @State private var localizedTitles: [String: String] = [:]

    /// Catálogo cargado del bundle. Se usa para mapear el label CoreML al
    /// título "humano" del museo (ej: "Vagón Torpedo" en lugar de un ID raw).
    private let catalog = MuseumObjectsCatalog.load()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Barra de progreso
                        progressSection
                            .padding(.horizontal, 20)
                        
                        // Lista de objetos
                        objectsListSection
                            .padding(.horizontal, 20)
                        
                        // Botón de reinicio (si misión completada)
                        if viewModel.mission.isComplete {
                            resetButton
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(L10n.missionSheetNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadLocalizedTitles()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.mission.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(viewModel.mission.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.missionProgressLabel)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(L10n.missionProgressFraction(viewModel.mission.progress.found, viewModel.mission.progress.total))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.mission.progressPercentage * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                        
                        Text(L10n.missionPercentCompleted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Animated progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.93, green: 0.45, blue: 0.15),
                                         Color(red: 0.85, green: 0.35, blue: 0.10)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.mission.progressPercentage, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.mission.progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Objects List
    
    private var objectsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.missionObjectsToFind)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            
            VStack(spacing: 10) {
                ForEach(viewModel.mission.targetObjectLabels, id: \.self) { label in
                    objectRow(label: label)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Object Row
    
    private func objectRow(label: String) -> some View {
        let isFound = viewModel.mission.isObjectFound(label)
        // Preferir el título traducido (cargado en .task). Si todavía no está,
        // caer al título del catálogo (español). Último recurso: el label crudo.
        let displayName = localizedTitles[label]
            ?? catalog.objects[label]?.title
            ?? label.replacingOccurrences(of: "_", with: " ").capitalized
        
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isFound ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isFound ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isFound ? Color.orange : Color.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isFound ? .secondary : .primary)
                    .strikethrough(isFound)
                
                if isFound {
                    Text(L10n.missionObjectFoundLabel)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Spacer()
            
            if isFound {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(isFound ? Color.orange.opacity(0.08) : Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button {
            viewModel.resetMission()
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(L10n.missionResetButton)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.93, green: 0.45, blue: 0.15),
                             Color(red: 0.85, green: 0.35, blue: 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color(red: 0.93, green: 0.45, blue: 0.15).opacity(0.3), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Localización de títulos

    /// Carga el título de cada `targetObjectLabel` en el idioma del dispositivo.
    /// Si es español, usa directamente el título del catálogo (sin red).
    /// En otro idioma, llama al servicio de traducción (con cache, así objetos
    /// ya escaneados aparecen instantáneos).
    private func loadLocalizedTitles() async {
        let isSpanish = AppLanguage.device == .spanish
        var result: [String: String] = [:]
        for label in viewModel.mission.targetObjectLabels {
            guard let entry = catalog.objects[label] else { continue }
            if isSpanish {
                result[label] = entry.title
            } else {
                let translated = await MuseumTranslationService.shared.translateForDevice(
                    label: label,
                    title: entry.title,
                    era: entry.era,
                    description: entry.description
                )
                result[label] = translated.title
            }
        }
        localizedTitles = result
    }
}

#Preview {
    ScannerMissionSheetView(viewModel: ScannerMissionViewModel())
}
