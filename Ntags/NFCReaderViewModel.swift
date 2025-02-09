//
//  NFCReaderViewModel.swift
//  Ntags
//
//  Created by Lasse Durucz on 09/02/2025.
//

import Foundation
import CoreNFC

class NFCReaderViewModel: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var tagMessage: String = "Tap 'Start Scan' to read an NFC tag."
    @Published var detectedMessage: String = ""  // Store the detected tag content
    private var session: NFCNDEFReaderSession?

    func startScanning() {
        if NFCNDEFReaderSession.readingAvailable {
            tagMessage = "Hold your iPhone near the NFC tag."
            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)  // Changed to false for continuous scanning
            session?.alertMessage = "Hold your iPhone near the NFC tag."
            session?.begin()
        } else {
            tagMessage = "NFC is not supported on this device."
        }
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            self.tagMessage = "NFC Reader is active. Ready to scan!"
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.tagMessage = "Scan failed: \(error.localizedDescription)"
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            var messageContent = ""
            for message in messages {
                for record in message.records {
                    if let payloadString = String(data: record.payload, encoding: .utf8) {
                        messageContent += payloadString + "\n"
                    }
                }
            }
            self.detectedMessage = messageContent.isEmpty ? "No readable data found on the tag." : messageContent
            self.tagMessage = "Scan complete. Hold near another tag to continue scanning."
        }
    }
}
