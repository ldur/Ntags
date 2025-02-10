//
//  ContentView.swift
//  Ntags - from github
//
//  Created by Lasse Durucz on 09/02/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var nfcReader = NFCReaderViewModel()
    @State private var inputMessage: String = ""

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

            // TextField to enter message for writing to NFC tag
            TextField("Enter message to write", text: $inputMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Button to write message to NFC tag
            Button(action: {
                nfcReader.startWriting(to: inputMessage)
            }) {
                Text("Write to NFC Tag")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            // Button to start scanning NFC tags
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
