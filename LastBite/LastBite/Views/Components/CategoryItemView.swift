import SwiftUI
import SDWebImageSwiftUI

struct CategoryItemView: View {
    let item: CategoryItemData
    
    var body: some View {
        VStack {
            WebImage(url: URL(string: item.imageName)) // ✅ Load image from URL
                .resizable()
                .indicator(.activity) // ✅ Show loading spinner
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .onAppear {
                    print("Image loaded successfully: \(item.imageName)") // ✅ Debugging
                }
                .overlay( // ✅ Placeholder if image fails
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                        .opacity(item.imageName.isEmpty ? 1 : 0) // Hide if image exists
                )
            
            Text(item.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 100, height: 120)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

struct CategoryItemView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryItemView(item: CategoryItemData(title: "Hornitos", imageName: "https://example.com/logo.png"))
    }
}
