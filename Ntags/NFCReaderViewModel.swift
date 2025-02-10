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
    @Published var detectedMessage: String = ""
    private var session: NFCNDEFReaderSession?

    // Start reading NFC tags
    func startScanning() {
        if NFCNDEFReaderSession.readingAvailable {
            tagMessage = "Hold your iPhone near the NFC tag."
            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
            session?.alertMessage = "Hold your iPhone near the NFC tag."
            session?.begin()
        } else {
            tagMessage = "NFC is not supported on this device."
        }
    }

    // Start writing to NFC tags
    func startWriting(to message: String) {
        if NFCNDEFReaderSession.readingAvailable {
            tagMessage = "Hold your iPhone near the NFC tag to write."
            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
            session?.alertMessage = "Hold your iPhone near the NFC tag to write."
            session?.begin()
            
            self.writeMessage = message
        } else {
            tagMessage = "NFC is not supported on this device."
        }
    }

    private var writeMessage: String?

    // Called when the NFC reader session becomes active
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            self.tagMessage = "NFC Reader is active. Ready to scan/write!"
        }
    }

    // Handle detected NFC tags
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

    // Handle tag detection for writing
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { (error: Error?) in
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }

            tag.queryNDEFStatus { (status, capacity, error) in
                if let error = error {
                    session.invalidate(errorMessage: "Failed to query tag status: \(error.localizedDescription)")
                    return
                }

                switch status {
                case .readOnly:
                    session.invalidate(errorMessage: "Tag is read-only.")
                case .readWrite:
                    guard let writeMessage = self.writeMessage else {
                        session.invalidate(errorMessage: "No message to write.")
                        return
                    }
                    
                    let payload = NFCNDEFPayload(format: .nfcWellKnown, type: "T".data(using: .utf8)!, identifier: Data(), payload: writeMessage.data(using: .utf8)!)
                    let message = NFCNDEFMessage(records: [payload])

                    tag.writeNDEF(message) { error in
                        if let error = error {
                            session.invalidate(errorMessage: "Failed to write: \(error.localizedDescription)")
                        } else {
                            session.alertMessage = "Successfully wrote to the tag!"
                            session.invalidate()
                        }
                    }
                case .notSupported:
                    session.invalidate(errorMessage: "Tag is not NDEF compatible.")
                @unknown default:
                    session.invalidate(errorMessage: "Unknown tag status.")
                }
            }
        }
    }

    // Handle session errors
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.tagMessage = "Session ended: \(error.localizedDescription)"
        }
    }
}
