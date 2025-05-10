//
//  LocationController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//

import Foundation
import Combine

@MainActor
class LocationController: ObservableObject {

    // MARK: - Published State
    @Published var zones: [Zone] = []
    @Published var areas: [Area] = []
    @Published var selectedZoneId: Int? = nil
    @Published var selectedAreaId: Int? = nil
    @Published var isLoadingZones: Bool = false
    @Published var isLoadingAreas: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showFinalSignUpView: Bool = false

    // MARK: - Dependencies
    private let userService: SignupUserService
    private let zoneRepository: ZoneRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var selectedZoneName: String {
        var nameToReturn: String = "Select a zone"
        for zone in zones { if zone.id == selectedZoneId { nameToReturn = zone.zone_name; break } }
        return nameToReturn
    }

    var selectedAreaName: String {
        guard let idToFind = selectedAreaId else { return "Select an area" }
        return areas.first(where: { $0.id == idToFind })?.area_name ?? "Select an area"
    }

    var canProceed: Bool {
        selectedAreaId != nil
    }

    // MARK: - Initialization (Recibe Repositorio)
    init(
        userService: SignupUserService = SignupUserService.shared,
        zoneRepository: ZoneRepository
    ) {
        self.userService = userService
        self.zoneRepository = zoneRepository
        print("📍 LocationController initialized with Repository.")
        loadZones()
    }

    // MARK: - Data Loading (Async con Repositorio)

    func loadZones() {
        guard !isLoadingZones else { return }
        print("⏳ Loading zones via Repository...")
        isLoadingZones = true
        errorMessage = nil
        areas = []

        // ❗️NO borres la selección si ya existe
        if userService.selectedAreaId == nil {
            userService.selectedAreaId = nil
        }
        Task { // Lanza la tarea asíncrona
            var fetchedZones: [Zone] = [] // Variable local para zonas
            do {
                // Llama al REPOSITORIO
                fetchedZones = try await zoneRepository.fetchZones()
                print("✅ Fetched \(fetchedZones.count) zones via Repo.")
                self.zones = fetchedZones // Actualiza estado

                // Selecciona la primera zona y carga sus áreas
                if let firstZone = fetchedZones.first {
                    // selectZone llama internamente a fetchAreas async
                    self.selectZone(zone: firstZone)
                } else {
                     print("ℹ️ No zones fetched or list is empty.")
                     self.isLoadingZones = false // Termina carga si no hay zonas
                }

            } catch { // Error al buscar zonas
                print("❌ Failed to fetch zones via Repo:", error.localizedDescription)
                self.errorMessage = "Could not load locations."
                self.isLoadingZones = false // Termina la carga en error
            }
        }
    }

    // Ahora es async y usa el repositorio
    func fetchAreas(for zoneId: Int) async {
        // Evita cargas concurrentes para la misma zona si ya está en proceso
        guard !isLoadingAreas else { return }
        print("⏳ Loading areas via Repository for zone ID: \(zoneId)...")
        isLoadingAreas = true
        errorMessage = nil // Limpia errores específicos de áreas
        areas = [] // Limpia áreas anteriores

        do {
            // Llama al REPOSITORIO
            let fetchedAreas = try await zoneRepository.fetchAreas(zoneId: zoneId)
            print("✅ Fetched \(fetchedAreas.count) areas via Repo for zone \(zoneId).")
            self.areas = fetchedAreas // Actualiza estado

        } catch { // Error al buscar áreas
            print("❌ Failed to fetch areas via Repo for zone \(zoneId):", error.localizedDescription)
            self.errorMessage = "Could not load areas for the selected zone."
        }
        // Termina la carga de áreas
        isLoadingAreas = false
        // Si loadZones inició esta carga, termina la carga general de zonas también
        if isLoadingZones { isLoadingZones = false }
    }

    // MARK: - User Selections (Llama a fetchAreas async)

    func selectZone(zone: Zone) {
        print("👉 Zone selected: \(zone.zone_name) (ID: \(zone.id))")
        // Solo actualiza si es diferente para evitar recargas innecesarias
        guard zone.id != self.selectedZoneId else { return }

        self.selectedZoneId = zone.id
        // Lanza una Task para llamar a la función async fetchAreas
        Task {
            await fetchAreas(for: zone.id)
        }
    }

    // selectArea (sin cambios, solo actualiza userService)
    func selectArea(area: Area) {
        print("👉 Area selected: \(area.area_name) (ID: \(area.id))")
        self.selectedAreaId = area.id
        self.userService.selectedAreaId = area.id
    }

    // MARK: - Navigation (Sin cambios)
    func proceedToNextStep() {
        if let areaId = selectedAreaId {
            print("🚀 Proceeding with area ID: \(areaId)")
            print("🧪 Saved in userService before navigation:", userService.selectedAreaId ?? -1)
            userService.selectedAreaId = areaId
            self.showFinalSignUpView = true
        } else {
            print("⚠️ Cannot proceed, area not selected.")
            self.errorMessage = "Please select an area before continuing."
        }
    }

}
