import SwiftUI

struct CategoryItemView: View {
    let item: CategoryItemData

    var body: some View {
        VStack {
            if let store = item.store {
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
