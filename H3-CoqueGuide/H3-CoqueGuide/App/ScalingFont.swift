//
//  ScalingFont.swift
//  H3-CoqueGuide
//
//  Helper para aplicar fuentes de tamaño personalizado que **sí** escalan
//  con la configuración de Dynamic Type del iPhone (Ajustes → Accesibilidad
//  → Tamaño del texto).
//
//  PROBLEMA QUE RESUELVE:
//  SwiftUI no escala por defecto las fuentes creadas con
//  `Font.system(size: X)` — esas son de tamaño fijo. Para respetar el
//  tamaño de texto que el usuario configuró en iOS, hay que usar text
//  styles (.body, .headline, etc.) o envolver el tamaño en @ScaledMetric.
//
//  USO:
//     .scalingFont(size: 14, weight: .semibold)
//
//  …reemplaza a:
//     .font(.system(size: 14, weight: .semibold))
//
//  …manteniendo el tamaño base pero escalando proporcionalmente.
//

import SwiftUI

// MARK: - View modifier

private struct ScalingFontModifier: ViewModifier {

    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

// MARK: - Extensión ergonómica

extension View {

    /// Aplica una fuente del sistema de tamaño personalizado que escala
    /// con Dynamic Type. Equivalente a `.font(.system(size:weight:design:))`
    /// pero respetando la configuración de accesibilidad del usuario.
    ///
    /// - Parameters:
    ///   - size: Tamaño base en pt (a Dynamic Type neutral).
    ///   - weight: Peso de la fuente. Por defecto `.regular`.
    ///   - design: Diseño de la fuente. Por defecto `.default`.
    ///   - relativeTo: Text style al que se referencia para escalar. Por defecto `.body`.
    func scalingFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo style: Font.TextStyle = .body
    ) -> some View {
        self.modifier(
            ScalingFontModifier(size: size, weight: weight, design: design, relativeTo: style)
        )
    }
}
