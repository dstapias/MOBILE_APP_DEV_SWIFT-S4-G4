import SwiftUI

struct CategoryItemView: View {
    let item: CategoryItemData
    let homeController : HomeController
    
    init(item: CategoryItemData, homeController: HomeController) {
        self.item = item
        self.homeController = homeController
    }

    var body: some View {
        let _ = print("➡️➡️ CategoryItemView body: HomeController instance = \(Unmanaged.passUnretained(homeController).toOpaque()) for item: \(item.title)")

        VStack {
            if let store = item.store {
                NavigationLink(destination: ProductView(store: store, owned: item.isOwned, homeController: homeController)) {
                    content
                }
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack {
            KFImageView(
                urlString: item.imageName,
                width: 60,
                height: 60,
                cornerRadius: 8
            )

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
