//
//  LocationController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

class LocationController: ObservableObject {

    // MARK: - Published State
    @Published var zones: [Zone] = []
    @Published var areas: [Area] = [] // Usamos el struct Area
    @Published var selectedZoneId: Int? = nil // ID de la zona seleccionada
    // selectedAreaId se manejará directamente en SignupUserService para este ejemplo

    @Published var isLoadingZones: Bool = false
    @Published var isLoadingAreas: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showFinalSignUpView: Bool = false // Para controlar la navegación

    // MARK: - Dependencies
    private let userService: SignupUserService // Para actualizar el areaId seleccionado
    private let zoneService: ZoneService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties (Helper para la Vista)
    var selectedZoneName: String {
        print("Calculating selectedZoneName. Current selectedZoneId: \(selectedZoneId ?? -1)")
        var nameToReturn: String = "Select a zone" // Valor por defecto

        // Recorre el array manualmente
        for zone in zones {
            if zone.zone_id == selectedZoneId { // Compara con el ID seleccionado
                nameToReturn = zone.zone_name // Encontrado, guarda el nombre
                break // Sal del bucle, ya lo encontramos
            }
        }

        print("Final name selectedZoneName will return: \(nameToReturn)")
        return nameToReturn
    }

    var selectedAreaName: String {
        // Lee el ID del área seleccionada desde el servicio compartido
        let targetAreaId = userService.selectedAreaId
        print("Calculating selectedAreaName. Current selectedAreaId from userService: \(targetAreaId ?? -1)")

        // Si no hay ningún área seleccionada en el servicio, devuelve el texto por defecto
        guard let idToFind = targetAreaId else {
            print("No area selected in userService, returning default name.")
            return "Select an area"
        }

        // Valor por defecto si no encontramos el área en nuestra lista local 'areas'
        var nameToReturn: String = "Select an area"

        // Busca el área correspondiente en el array 'areas' del controlador
        for area in areas {
            if area.area_id == idToFind {
                nameToReturn = area.area_name // Área encontrada, guarda su nombre
                break // Sal del bucle, ya no necesitamos buscar más
            }
        }

        print("Final name selectedAreaName will return: \(nameToReturn)")
        return nameToReturn
    }

    var canProceed: Bool {
        userService.selectedAreaId != nil // La lógica para habilitar "Next"
    }


    // MARK: - Initialization
    init(
        userService: SignupUserService = SignupUserService.shared,
        zoneService: ZoneService = ZoneService.shared
    ) {
        self.userService = userService
        self.zoneService = zoneService
        print("📍 LocationController initialized.")
        // Carga inicial de zonas
        loadZones()
    }

    // MARK: - Data Loading
    func loadZones() {
        guard !isLoadingZones else { return }
        print("⏳ Loading zones...")
        DispatchQueue.main.async {
            self.isLoadingZones = true
            self.errorMessage = nil
            self.areas = [] // Limpia áreas al cargar zonas
            self.userService.selectedAreaId = nil // Deselecciona área
        }

        zoneService.fetchZones { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoadingZones = false
                switch result {
                case .success(let fetchedZones):
                    print("✅ Fetched \(fetchedZones.count) zones.")
                    self.zones = fetchedZones
                    // Selecciona automáticamente la primera zona y carga sus áreas
                    if let firstZone = fetchedZones.first {
                        self.selectZone(zone: firstZone) // Llama a la función de selección
                    }
                case .failure(let error):
                    print("❌ Failed to fetch zones:", error.localizedDescription)
                    self.errorMessage = "Could not load locations."
                }
            }
        }
    }

    func fetchAreas(for zoneId: Int) {
        guard !isLoadingAreas else { return }
        print("⏳ Loading areas for zone ID: \(zoneId)...")
         DispatchQueue.main.async {
             self.isLoadingAreas = true
             self.errorMessage = nil // Limpia errores al buscar áreas
             self.areas = [] // Limpia áreas anteriores
             self.userService.selectedAreaId = nil // Deselecciona área al cambiar zona
         }

        zoneService.fetchAreas(forZoneId: zoneId) { [weak self] result in
            guard let self = self else { return }
             DispatchQueue.main.async {
                 self.isLoadingAreas = false
                 switch result {
                 case .success(let fetchedAreas):
                    print("✅ Fetched \(fetchedAreas.count) areas.")
                    self.areas = fetchedAreas // Almacena los objetos Area completos
                 case .failure(let error):
                     print("❌ Failed to fetch areas:", error.localizedDescription)
                     self.errorMessage = "Could not load areas for the selected zone."
                 }
             }
        }
    }

    // MARK: - User Selections
    func selectZone(zone: Zone) {
        print("👉 Zone selected: \(zone.zone_name) (ID: \(zone.zone_id))")
        self.selectedZoneId = zone.zone_id // Actualiza el ID seleccionado
        // Inicia la carga de áreas para la nueva zona
        fetchAreas(for: zone.zone_id)
    }

    func selectArea(area: Area) {
        print("👉 Area selected: \(area.area_name) (ID: \(area.area_id))")
        // Actualiza directamente el ID en el servicio compartido
        self.userService.selectedAreaId = area.area_id
        // canProceed se actualizará automáticamente porque depende de userService.selectedAreaId
    }

    // MARK: - Navigation
    func proceedToNextStep() {
        if canProceed {
            print("🚀 Proceeding to final sign up...")
            self.showFinalSignUpView = true
        } else {
            print("⚠️ Cannot proceed, area not selected.")
        }
    }
}
