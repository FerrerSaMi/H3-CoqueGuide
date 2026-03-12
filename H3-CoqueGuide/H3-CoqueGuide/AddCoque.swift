



import SwiftUI
import SwiftData


struct AddCoque: View {
    @Environment(\.modelContext) private var modelContext
    @State private var name: String = ""
    @State private var description: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Información de la funda")) {
                TextField("Nombre", text: $name)
                TextField("Descripción", text: $description)
            }
            
            Button(action: addCoque) {
                Text("Agregar funda")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Agregar funda")
        .padding()
    }
    
    private func addCoque() {
        let newCoque = CoqueGuide(name: name)
        modelContext.insert(newCoque)
        
        // Limpiar los campos después de agregar
        name = ""
        
    }
    
}


