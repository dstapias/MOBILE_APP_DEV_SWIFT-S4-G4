import SwiftUI
import SDWebImageSwiftUI

struct CategoryItemView: View {
    let item: CategoryItemData

    var body: some View {
        VStack {
            if let store = item.store { // ✅ If it's a store, make it clickable
                NavigationLink(destination: ProductView(store: store)) {
                    content
                }
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack {
            WebImage(url: URL(string: item.imageName))
                .resizable()
                .indicator(.activity)
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(8)

            Text(item.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.black)
        }
        .frame(width: 100, height: 120)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// ✅ Debugging Preview
struct CategoryItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CategoryItemView(
                item: CategoryItemData(
                    title: "Hornitos",
                    imageName: "https://example.com/logo.png",
                    store: StoreService.Store(
                        store_id: 1,
                        name: "Example Store",
                        address: "123 Street, City",
                        latitude: 0.0,
                        longitude: 0.0,
                        logo: "https://example.com/logo.png",
                        nit: "900123456-1"
                    )
                )
            )
        }
    }
}
