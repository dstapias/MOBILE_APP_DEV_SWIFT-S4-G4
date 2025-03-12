import SwiftUI

struct LocationView: View {
    @Binding var showLocationView: Bool // ✅ Controls manual navigation
    @Binding var showSignInView: Bool // ✅ Binding to transition to SignInView
    @State private var selectedZone: String = "" // ✅ Stores selected zone name
    @State private var selectedArea: String = "" // ✅ Stores selected area
    @State private var showFinalSignUpView = false // ✅ Controls navigation to the next screen
    @State private var zones: [ZoneService.Zone] = [] // ✅ Store full Zone object
    @State private var areas: [String] = [] // ✅ Store area names
    @State private var isLoading = true // ✅ Track loading state

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // ✅ Back Button
                HStack {
                    Button(action: {
                        showLocationView = false
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 10)

                    Spacer()
                }

                // ✅ Location Icon
                Image("location_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 20)

                // ✅ Title & Subtitle
                Text("Select Your Location")
                    .font(.title2)
                    .bold()
                    .padding(.top, 10)

                Text("Switch on your location to stay in tune with what’s happening in your area")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 5)

                if isLoading {
                    ProgressView("Loading...")
                        .padding(.top, 20)
                } else {
                    // ✅ Zone Picker
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Zone")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        Menu {
                            ForEach(zones, id: \.zone_id) { zone in
                                Button(action: {
                                    selectedZone = zone.zone_name // ✅ Store `zone_name`
                                    fetchAreas(for: zone.zone_id) // ✅ Fetch areas using `zone_id`
                                }) {
                                    Text(zone.zone_name)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedZone.isEmpty ? "Select a zone" : selectedZone)
                                    .font(.headline)
                                    .foregroundColor(selectedZone.isEmpty ? .gray : .black)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .frame(height: 40)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    // ✅ Area Picker
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your Area")
                            .font(.footnote)
                            .foregroundColor(.gray)

                        Menu {
                            ForEach(areas, id: \.self) { area in
                                Button(action: { selectedArea = area }) {
                                    Text(area)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedArea.isEmpty ? "Select an area" : selectedArea)
                                    .font(.headline)
                                    .foregroundColor(selectedArea.isEmpty ? .gray : .black)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .frame(height: 40)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }

                Spacer()

                // ✅ Next Button
                Button(action: {
                    showFinalSignUpView = true
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .onAppear {
                fetchZones()
            }
        }
        .fullScreenCover(isPresented: $showFinalSignUpView) {
            FinalSignUpView(showFinalSignUpView: $showFinalSignUpView)
        }
    }

    // ✅ Fetch zones from API
    private func fetchZones() {
        ZoneService.shared.fetchZones { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedZones):
                    self.zones = fetchedZones // ✅ Store full Zone objects
                    
                    if let firstZone = fetchedZones.first {
                        self.selectedZone = firstZone.zone_name // ✅ Use `zone_name`
                        fetchAreas(for: firstZone.zone_id) // ✅ Pass `zone_id` to fetch areas
                    }
                case .failure(let error):
                    print("Failed to fetch zones:", error.localizedDescription)
                }
            }
        }
    }

    // ✅ Fetch areas based on selected zone_id
    private func fetchAreas(for zoneId: Int) { // ✅ Accepts Int
        ZoneService.shared.fetchAreas(forZoneId: zoneId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedAreas):
                    self.areas = fetchedAreas
                case .failure(let error):
                    print("Failed to fetch areas:", error.localizedDescription)
                }
            }
        }
    }
}

// ✅ Preview
struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView(
            showLocationView: .constant(true),
            showSignInView: .constant(false)
        )
    }
}
