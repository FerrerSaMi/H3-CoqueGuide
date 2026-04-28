//
//  ScannerMissionSheetView.swift
//  H3-CoqueGuide
//
//  Sheet que muestra el progreso de la misión "Hide and Seek"
//  Visible desde el botón de misión en el escáner.
//

import SwiftUI

struct ScannerMissionSheetView: View {
    
    @StateObject private var viewModel = ScannerMissionViewModel()
    @Environment(\.dismiss) var dismiss
    
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
            .navigationTitle("Mi Misión")
            .navigationBarTitleDisplayMode(.inline)
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
                    Text("Progreso")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text("\(viewModel.mission.progress.found) de \(viewModel.mission.progress.total)")
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
                        
                        Text("completado")
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
            Text("Objetos a encontrar")
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
        let displayName = label.replacingOccurrences(of: "_", with: " ").capitalized
        
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
                    Text("✓ Encontrado")
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
                Text("Reiniciar misión")
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
}

#Preview {
    ScannerMissionSheetView()
}
