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
    @Published var detectedMessages: [String] = []  // Store the detected tag contents as a list
    private var session: NFCNDEFReaderSession?
    private var isWritingMode: Bool = false

    func startScanning() {
        if NFCNDEFReaderSession.readingAvailable {
            tagMessage = "Hold your iPhone near the NFC tag to read."
            isWritingMode = false
            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
            session?.alertMessage = "Hold your iPhone near the NFC tag to read."
            session?.begin()
        } else {
            tagMessage = "NFC is not supported on this device."
        }
    }

    func startWriting(to message: String) {
        if NFCNDEFReaderSession.readingAvailable {
            tagMessage = "Hold your iPhone near the NFC tag to write."
            isWritingMode = true
            session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
            session?.alertMessage = "Hold your iPhone near the NFC tag to write."
            session?.begin()
            self.writeMessage = message
        } else {
            tagMessage = "NFC is not supported on this device."
        }
    }

    private var writeMessage: String?

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            self.tagMessage = self.isWritingMode ? "NFC Writer is active. Ready to write!" : "NFC Reader is active. Ready to scan!"
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.tagMessage = "Session ended: \(error.localizedDescription)"
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard !isWritingMode else { return }  // Ensure we only process this in read mode

        DispatchQueue.main.async {
            self.detectedMessages.removeAll()
            for message in messages {
                for (index, record) in message.records.enumerated() {
                    if let payloadString = String(data: record.payload, encoding: .utf8) {
                        self.detectedMessages.append("\(index + 1). \(payloadString)")
                    }
                }
            }
            if self.detectedMessages.isEmpty {
                self.detectedMessages.append("No readable data found on the tag.")
            }
            self.tagMessage = "Scan complete. Hold near another tag to continue scanning."
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { (error: Error?) in
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }

            if self.isWritingMode {
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

                        tag.readNDEF { existingMessage, error in
                            if let error = error {
                                session.invalidate(errorMessage: "Failed to read existing records: \(error.localizedDescription)")
                                return
                            }

                            var newRecords = existingMessage?.records ?? []

                            let newPayload = NFCNDEFPayload(format: .nfcWellKnown, type: "T".data(using: .utf8)!, identifier: Data(), payload: writeMessage.data(using: .utf8)!)
                            newRecords.append(newPayload)

                            let newMessage = NFCNDEFMessage(records: newRecords)

                            tag.writeNDEF(newMessage) { error in
                                if let error = error {
                                    session.invalidate(errorMessage: "Failed to write: \(error.localizedDescription)")
                                } else {
                                    session.alertMessage = "Successfully added a new record to the tag!"
                                    session.invalidate()
                                    DispatchQueue.main.async {
                                        self.tagMessage = "Write successful!"
                                        self.writeMessage = nil
                                    }
                                }
                            }
                        }
                    case .notSupported:
                        session.invalidate(errorMessage: "Tag is not NDEF compatible.")
                    @unknown default:
                        session.invalidate(errorMessage: "Unknown tag status.")
                    }
                }
            } else {
                tag.readNDEF { (message, error) in
                    if let error = error {
                        session.invalidate(errorMessage: "Failed to read: \(error.localizedDescription)")
                        return
                    }

                    if let message = message {
                        DispatchQueue.main.async {
                            self.detectedMessages.removeAll()
                            for (index, record) in message.records.enumerated() {
                                if let payloadString = String(data: record.payload, encoding: .utf8) {
                                    self.detectedMessages.append("\(index + 1). \(payloadString)")
                                }
                            }
                            if self.detectedMessages.isEmpty {
                                self.detectedMessages.append("No readable data found on the tag.")
                            }
                            self.tagMessage = "Scan complete. Hold near another tag to continue scanning."
                        }
                    } else {
                        // No records exist, create the first one
                        guard let writeMessage = self.writeMessage else {
                            session.invalidate(errorMessage: "No message to write.")
                            return
                        }
                        let newPayload = NFCNDEFPayload(format: .nfcWellKnown, type: "T".data(using: .utf8)!, identifier: Data(), payload: writeMessage.data(using: .utf8)!)
                        let newMessage = NFCNDEFMessage(records: [newPayload])

                        tag.writeNDEF(newMessage) { error in
                            if let error = error {
                                session.invalidate(errorMessage: "Failed to write: \(error.localizedDescription)")
                            } else {
                                session.alertMessage = "Successfully created and added a new record to the tag!"
                                session.invalidate()
                                DispatchQueue.main.async {
                                    self.tagMessage = "Write successful!"
                                    self.writeMessage = nil
                                }
                            }
                        }
                    }
                    session.invalidate()
                }
            }
        }
    }
}
