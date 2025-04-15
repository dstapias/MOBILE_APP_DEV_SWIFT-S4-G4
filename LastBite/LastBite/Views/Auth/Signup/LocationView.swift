import SwiftUI

struct LocationView: View {
    // Bindings para control parental (sin cambios)
    @Binding var showLocationView: Bool
    @Binding var showSignInView: Bool // Parece no usarse aquí, ¿quizás en FinalSignUpView?
    @Binding var isLoggedIn: Bool

    // 1. El Controller maneja el estado y la lógica
    @StateObject private var controller: LocationController

    // 2. El servicio de usuario se usa indirectamente a través del controller
    //    o directamente para leer el estado compartido (selectedAreaId)
    @ObservedObject var userService = SignupUserService.shared // Lo mantenemos para leer selectedAreaId directamente

    // 3. Inicializador (asume que userService es singleton o inyectado antes)
    init(showLocationView: Binding<Bool>, showSignInView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
        self._showLocationView = showLocationView
        self._showSignInView = showSignInView
        self._isLoggedIn = isLoggedIn
        // Crea el controller, pasándole las dependencias necesarias si no usa singletons
        self._controller = StateObject(wrappedValue: LocationController(userService: SignupUserService.shared))
         print("📍 LocationView initialized.")
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // Botón de volver (sin cambios)
                HStack {
                    Button(action: { showLocationView = false }) {
                        Image(systemName: "chevron.left").foregroundColor(.black).font(.title2)
                    }
                    .padding(.leading, 20).padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                }

                // Icono y Títulos (sin cambios)
                Image("location_icon").resizable().scaledToFit().frame(width: 80, height: 80).padding(.top, 20)
                Text("Select Your Location").font(.title2).bold().padding(.top, 10)
                Text("Switch on your location to stay in tune with what’s happening in your area")
                    .font(.footnote).foregroundColor(.gray).multilineTextAlignment(.center)
                    .padding(.horizontal, 40).padding(.top, 5)

                // 4. Indicador de Carga del Controller
                if controller.isLoadingZones || controller.isLoadingAreas {
                    ProgressView("Loading locations...")
                        .padding(.top, 20)
                } else {
                    // 5. Zone Picker (usa datos y acciones del controller)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Zone").font(.footnote).foregroundColor(.gray)
                        Menu {
                            // Itera sobre las zonas del controller
                            ForEach(controller.zones) { zone in
                                Button(action: {
                                    // Llama a la acción del controller
                                    controller.selectZone(zone: zone)
                                }) {
                                    Text(zone.zone_name)
                                }
                            }
                        } label: {
                            HStack {
                                // Muestra el nombre calculado por el controller
                                Text(controller.selectedZoneName)
                                    .font(.headline)
                                    // Colorea basado en si hay una selección
                                    .foregroundColor(controller.selectedZoneId == nil ? .gray : .black)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            // Estilos del label (sin cambios)
                            .frame(height: 40).padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1)).cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 40).padding(.top, 20)

                    // 6. Area Picker (usa datos y acciones del controller)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Area").font(.footnote).foregroundColor(.gray)
                        Menu {
                            // Itera sobre las áreas del controller
                            ForEach(controller.areas) { area in
                                Button(action: {
                                    // Llama a la acción del controller
                                    controller.selectArea(area: area)
                                }) {
                                    Text(area.area_name)
                                }
                            }
                        } label: {
                            HStack {
                                // Muestra nombre basado en userService.selectedAreaId
                                // (o podrías usar controller.selectedAreaName si prefieres)
                                Text(controller.selectedAreaName)
                                    .font(.headline)
                                    .foregroundColor(userService.selectedAreaId == nil ? .gray : .black)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                             // Estilos del label (sin cambios)
                            .frame(height: 40).padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1)).cornerRadius(10)
                        }
                        // Deshabilita si no hay áreas cargadas o si las zonas están cargando
                        .disabled(controller.areas.isEmpty || controller.isLoadingZones || controller.isLoadingAreas)
                    }
                    .padding(.horizontal, 40).padding(.top, 10)
                } // Fin else (no isLoading)

                // Muestra errores del controller
                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 40)
                        .padding(.top, 5)
                }


                Spacer() // Empuja el botón "Next" hacia abajo

                // 7. Next Button (acción y estado disabled del controller)
                Button(action: {
                    // Llama a la acción del controller
                    controller.proceedToNextStep()
                }) {
                    Text("Next")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        // Color y estado disabled basados en controller.canProceed
                        .background(controller.canProceed ? Color.green : Color.gray)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40).padding(.bottom, 20)
                // Usa la propiedad computada del controller
                .disabled(!controller.canProceed)

            } // Fin VStack principal
            .onAppear {
                // 8. Llama a la carga inicial del controller si es necesario
                // (El init del controller ya llama a loadZones)
                // controller.loadZones() // Podría no ser necesario si el init lo hace
            }
            // 9. fullScreenCover usa la propiedad publicada del controller
            .fullScreenCover(isPresented: $controller.showFinalSignUpView) {
                 // La vista final recibe sus propios bindings
                FinalSignUpView(showFinalSignUpView: $controller.showFinalSignUpView, isLoggedIn: $isLoggedIn)
            }
             // 10. Animaciones (si Zone y Area son Equatable)
            .animation(.default, value: controller.zones)
            .animation(.default, value: controller.areas)
            .animation(.default, value: controller.isLoadingZones)
            .animation(.default, value: controller.isLoadingAreas)
            .animation(.default, value: controller.errorMessage)

        } // Fin GeometryReader
    } // Fin body

    // 11. Ya no necesitas las funciones fetchZones / fetchAreas aquí
} // Fin struct LocationView

// --- Preview ---
struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView(
            showLocationView: .constant(true),
            showSignInView: .constant(false), // Pasa el binding aunque no se use activamente aquí
            isLoggedIn: .constant(false)
        )
         // La preview necesita el servicio si el controller o la vista lo usan
        .environmentObject(SignupUserService.shared)
    }
}
