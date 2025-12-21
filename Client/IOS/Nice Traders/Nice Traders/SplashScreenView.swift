//
//  SplashScreenView.swift
//  Nice Traders
//
//  Launch screen view
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        Image("SplashScreen")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
    }
}
