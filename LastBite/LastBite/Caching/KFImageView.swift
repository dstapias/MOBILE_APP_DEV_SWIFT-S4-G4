//
//  ImageCaching.swift
//  LastBite
//
//  Created by David Santiago on 22/04/25.
//

import SwiftUI
import Kingfisher

struct KFImageView: View {
    let urlString: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        if let urlString = urlString, let url = URL(string: urlString) {
            KFImage(url)
                .resizable()
                .placeholder {
                    ProgressView()
                }
                .fade(duration: 0.3)
                .cancelOnDisappear(true)
                .scaledToFit()
                .frame(width: width, height: height)
                .cornerRadius(cornerRadius)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: height)
                .cornerRadius(cornerRadius)
        }
    }
}
