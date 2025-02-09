//
//  ContentView.swift
//  Ntags
//
//  Created by Lasse Durucz on 09/02/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var nfcReader = NFCReaderViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text(nfcReader.tagMessage)
                .padding()
                .multilineTextAlignment(.center)

            if !nfcReader.detectedMessage.isEmpty {
                ScrollView {
                    Text(nfcReader.detectedMessage)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxHeight: 200)
            }

            Button(action: {
                nfcReader.startScanning()
            }) {
                Text("Start Scan")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
