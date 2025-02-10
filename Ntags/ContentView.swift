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
    @State private var showPopup = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text(nfcReader.tagMessage)
                .padding()
                .multilineTextAlignment(.center)

            // Show detected messages in a pop-up
            if !nfcReader.detectedMessages.isEmpty {
                Button("Show Tags") {
                    showPopup = true
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            // TextField to enter message for writing to NFC tag
            TextField("Enter message to write", text: $inputMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            // Button to write message to NFC tag
            Button(action: {
                nfcReader.startWriting(to: inputMessage)
                inputMessage = ""  // Clear input field after writing
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
        .alert(isPresented: $showPopup) {
            Alert(title: Text("Tags"), message: Text(nfcReader.detectedMessages.joined(separator: "\n")), dismissButton: .default(Text("OK")))
        }
    }
}
