//
//  CGNavigationCoordinator.swift
//  CoqueGuideAI
//
//  Coordina la navegación desde tarjetas de acción del asistente
//  hacia las pantallas principales de la app.
//

import SwiftUI

@Observable
final class CGNavigationCoordinator {
    var pendingDestination: CGAppDestination? = nil

    func navigate(to destination: CGAppDestination) {
        pendingDestination = destination
    }

    func consumeDestination() -> CGAppDestination? {
        let dest = pendingDestination
        pendingDestination = nil
        return dest
    }
}
