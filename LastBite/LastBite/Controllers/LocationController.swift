//
//  LocationController.swift
//  LastBite
//
//  Created by Andrés Romero on 14/04/25.
//  Updated by ChatGPT on 23/05/25.
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
    
    // MARK: - In‐Memory Cache
    private var areasCache: [Int:[Area]] = [:]
    
    // MARK: - Computed Properties
    var selectedZoneName: String {
        zones.first(where: { $0.id == selectedZoneId })?.zone_name ?? "Select a zone"
    }
    var selectedAreaName: String {
        guard let id = selectedAreaId else { return "Select an area" }
        return areas.first(where: { $0.id == id })?.area_name ?? "Select an area"
    }
    var canProceed: Bool { selectedAreaId != nil }
    
    // MARK: - Designated Initializer
    init(
        userService: SignupUserService,
        zoneRepository: ZoneRepository
    ) {
        self.userService = userService
        self.zoneRepository = zoneRepository
        print("📍 LocationController initialized with Repository.")
        fetchZonesAndAllAreasOnce()
    }
    
    // MARK: - Convenience Initializer
    /// Use this when you want to pull from the shared singleton
    convenience init(zoneRepository: ZoneRepository) {
        self.init(
            userService: SignupUserService.shared,
            zoneRepository: zoneRepository
        )
    }
    
    // MARK: - One‐time Fetch & Cache
    private func fetchZonesAndAllAreasOnce() {
        guard !isLoadingZones else { return }
        isLoadingZones = true
        errorMessage   = nil
        
        Task {  // runs on MainActor
            do {
                // 1️⃣ Fetch all zones
                let fetchedZones = try await zoneRepository.fetchZones()
                
                // 2️⃣ Concurrently fetch areas for each zone
                var tempCache: [Int:[Area]] = [:]
                try await withThrowingTaskGroup(of: (Int,[Area]).self) { group in
                    for zone in fetchedZones {
                        group.addTask {
                            let areas = try await self.zoneRepository.fetchAreas(zoneId: zone.id)
                            return (zone.id, areas)
                        }
                    }
                    for try await (zoneId, list) in group {
                        tempCache[zoneId] = list
                    }
                }
                
                // 3️⃣ Commit to state & cache
                self.zones      = fetchedZones
                self.areasCache = tempCache
                if let first = fetchedZones.first {
                    self.selectedZoneId = first.id
                    self.areas         = tempCache[first.id] ?? []
                }
            }
            catch {
                self.errorMessage = "Could not load locations: \(error.localizedDescription)"
            }
            self.isLoadingZones = false
        }
    }
    
    // MARK: - Zone Selection
    func selectZone(zone: Zone) {
        guard zone.id != selectedZoneId else { return }
        selectedZoneId = zone.id
        
        if let cached = areasCache[zone.id] {
            areas = cached
            isLoadingAreas = false
        } else {
            loadAreas(for: zone.id)
        }
    }
    
    // MARK: - Area Loading Fallback
    private func loadAreas(for zoneId: Int) {
        guard !isLoadingAreas else { return }
        isLoadingAreas = true
        errorMessage   = nil
        areas          = []
        
        Task {  // runs on MainActor
            do {
                let fetched = try await zoneRepository.fetchAreas(zoneId: zoneId)
                self.areasCache[zoneId] = fetched
                self.areas              = fetched
            }
            catch {
                self.errorMessage = "Could not load areas for zone \(zoneId): \(error.localizedDescription)"
            }
            self.isLoadingAreas = false
        }
    }
    
    // MARK: - Area Selection
    func selectArea(area: Area) {
        selectedAreaId = area.id
        userService.selectedAreaId = area.id
    }
    
    // MARK: - Navigation
    func proceedToNextStep() {
        guard let areaId = selectedAreaId else {
            errorMessage = "Please select an area before continuing."
            return
        }
        userService.selectedAreaId = areaId
        showFinalSignUpView = true
    }
}

