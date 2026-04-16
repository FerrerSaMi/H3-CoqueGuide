//
//  KeyboardPrewarmer.swift
//  H3-CoqueGuide
//
//  Utilidades para pre-calentar subsistemas costosos de iOS al inicio de la app,
//  evitando lag perceptible cuando el usuario abre el chat de CoqueGuide.
//
//  INCLUYE:
//  1. Pre-warm del sistema de texto (teclado + TextInput).
//  2. Pre-warm de los assets de imagen que usa el panel (avatar Coque).
//
//  CÓMO FUNCIONA EL KEYBOARD PREWARM:
//  La primera vez que un UITextField se vuelve first responder, iOS carga
//  de forma perezosa el servicio RemoteTextInput, los bundles del teclado
//  y los diccionarios de autocorrección. Ese trabajo agrega ~300–500 ms al
//  primer tap. Si hacemos becomeFirstResponder/resignFirstResponder en un
//  TextField oculto nada más arrancar, cargamos todo antes de que el usuario
//  llegue al chat — sin que el teclado llegue a mostrarse visualmente.
//
//  CÓMO FUNCIONA EL ASSETS PREWARM:
//  UIImage(named:) cachea globalmente tras la primera carga. Decodificar una
//  imagen de Assets la primera vez puede costar decenas de ms. Si pre-cargamos
//  el avatar "Coque" al inicio, el sheet del panel (que lo usa en el header,
//  cada bubble y el typing indicator) no paga ese costo al abrirse.
//

import SwiftUI
import UIKit

enum KeyboardPrewarmer {

    private static var didPrewarm = false

    /// Ejecuta una vez el pre-calentamiento del sistema de texto.
    /// Es seguro llamar múltiples veces; solo corre la primera.
    @MainActor
    static func prewarmIfNeeded() {
        guard !didPrewarm else { return }
        didPrewarm = true

        // Esperamos al siguiente ciclo de runloop para asegurar que haya una
        // key window disponible (la app ya terminó de lanzarse).
        DispatchQueue.main.async {
            guard let window = Self.keyWindow else {
                // Si aún no hay ventana, reintentamos una vez tras un delay corto.
                didPrewarm = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    prewarmIfNeeded()
                }
                return
            }

            let field = UITextField(frame: .zero)
            field.isHidden = true
            window.addSubview(field)
            field.becomeFirstResponder()
            field.resignFirstResponder()
            field.removeFromSuperview()
        }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
    }
}

// MARK: - Assets prewarmer

enum AssetsPrewarmer {

    private static var didPrewarm = false

    /// Pre-carga los assets más usados por el chat para que su primera
    /// aparición no pague el costo de decodificación.
    @MainActor
    static func prewarmIfNeeded() {
        guard !didPrewarm else { return }
        didPrewarm = true

        // Cargar en background para no bloquear el hilo principal.
        // UIImage(named:) usa su propio cache thread-safe global.
        DispatchQueue.global(qos: .userInitiated).async {
            let names = ["Coque"]
            for name in names {
                // Fuerza la decodificación accediendo a .cgImage.
                _ = UIImage(named: name)?.cgImage
            }
        }
    }
}

// MARK: - View modifier

extension View {

    /// Pre-calienta el teclado y los assets del chat al aparecer la vista.
    /// Idempotente: solo corre la primera vez en la sesión.
    func prewarmKeyboardOnAppear() -> some View {
        self.onAppear {
            KeyboardPrewarmer.prewarmIfNeeded()
            AssetsPrewarmer.prewarmIfNeeded()
        }
    }
}
