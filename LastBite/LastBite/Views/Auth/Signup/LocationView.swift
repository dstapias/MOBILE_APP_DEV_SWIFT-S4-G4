import SwiftUI

struct LocationView: View {
    @Binding var showLocationView: Bool
    @Binding var showSignInView: Bool
    @Binding var isLoggedIn: Bool

    // 1. El Controller maneja el estado y la lógica
    @StateObject private var controller: LocationController

    // 2. El servicio de usuario se usa indirectamente a través del controller
    @ObservedObject var userService = SignupUserService.shared

    init(showLocationView: Binding<Bool>, showSignInView: Binding<Bool>, isLoggedIn: Binding<Bool>) {
            self._showLocationView = showLocationView
            self._showSignInView = showSignInView
            self._isLoggedIn = isLoggedIn

            // 1. Crear instancia del Repositorio
            let zoneRepository = APIZoneRepository()

            let userService = SignupUserService.shared

            // 3. Crear el Controller inyectando el Repositorio
            let locationController = LocationController(
                userService: userService,
                zoneRepository: zoneRepository
            )

            // 4. Asignar al StateObject
            self._controller = StateObject(wrappedValue: locationController)
            print("📍 LocationView initialized and injected ZoneRepository into Controller.")
        }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Button(action: { showLocationView = false }) {
                        Image(systemName: "chevron.left").foregroundColor(.black).font(.title2)
                    }
                    .padding(.leading, 20).padding(.top, geometry.safeAreaInsets.top + 10)
                    Spacer()
                }

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
                                Text(controller.selectedAreaName)
                                    .font(.headline)
                                    .foregroundColor(controller.selectedAreaId == nil ? .gray : .black)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .frame(height: 40).padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1)).cornerRadius(10)
                        }
                        // Deshabilita si no hay áreas cargadas o si las zonas están cargando
                        .disabled(controller.areas.isEmpty || controller.isLoadingZones || controller.isLoadingAreas)
                    }
                    .padding(.horizontal, 40).padding(.top, 10)
                }

                if let errorMessage = controller.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 40)
                        .padding(.top, 5)
                }


                Spacer()

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
            }
            // 9. fullScreenCover usa la propiedad publicada del controller
            .fullScreenCover(isPresented: $controller.showFinalSignUpView) {
                FinalSignUpView(
                    showFinalSignUpView: $controller.showFinalSignUpView,
                    isLoggedIn: $isLoggedIn
                )
            }
            .animation(.default, value: controller.zones)
            .animation(.default, value: controller.areas)
            .animation(.default, value: controller.isLoadingZones)
            .animation(.default, value: controller.isLoadingAreas)
            .animation(.default, value: controller.errorMessage)

        }
    } 

}

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView(
            showLocationView: .constant(true),
            showSignInView: .constant(false),
            isLoggedIn: .constant(false)
        )
        .environmentObject(SignupUserService.shared)
    }
}
