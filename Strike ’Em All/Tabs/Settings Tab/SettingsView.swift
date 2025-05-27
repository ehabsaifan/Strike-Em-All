//
//  SettingsView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/24/25.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    // app‐wide DI if needed:
    @Environment(\.di) private var di
    @State private var showingFeedback = false
    @State private var needMailAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // MARK: – General Settings Section
                SectionBlock(title: "General") {
                    VStack(alignment: .leading, spacing: 12) {
                        // 1) Logging
                        NavigationLink {
                            CrashLogSettingsView()
                        } label: {
                            Label("Logging", systemImage: "doc.plaintext")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.black)
                        
                        DashedDivider()
                        
                        // 2) Send Feedback
                        Button {
                            showingFeedback = true
                        } label: {
                            Label("Send Feedback", systemImage: "envelope")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.black)
                        
                        DashedDivider()
                        // 3) Rate This App
                        Button {
                            // e.g. SKStoreReviewController.requestReview()
                            // di.appReviewService.requestReview()
                        } label: {
                            Label("Rate This App", systemImage: "star")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.black)
                    }
                }
                
                // MARK: – About
                SectionBlock(title: "App Info") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("v\(di.appMetaData.appVersion) (\(di.appMetaData.buildNumber))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .mailSheet(isPresented: $showingFeedback, onCannotSend: {
                needMailAlert = true
            }) {
                ComposeMailView(recipients: ["ehsaifan@gmail.com"],
                                subject: "Strike ’Em All Feedback",
                                body: nil,
                                attachments: [])}
            .alert("Mail not configured", isPresented: $needMailAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please configure Mail to send feedback.")
            }
        }
    }
}
