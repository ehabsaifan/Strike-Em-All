//
//  CrashLogSettingsView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/24/25.
//

import SwiftUI

struct CrashLogSettingsView: View {
    @Environment(\.di) private var di
    @StateObject private var vm = CrashLogSettingsViewModel()
    @State private var showingShareSheet = false
    @State private var showingLogMail = false
    @State private var logMailError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: – Logging Toggle + Level
                SectionBlock(title: "Logging") {
                    VStack(spacing: 12) {
                        Toggle("Enable Logging", isOn: $vm.isLoggingEnabled)
                            .tint(AppTheme.secondaryColor)
                        
                        if vm.isLoggingEnabled {
                            DashedDivider()
                            
                            HStack {
                                Text("Level")
                                Spacer()
                                Menu {
                                    ForEach(LogLevel.allCases, id: \.self) { level in
                                        Button(level.label) {
                                            vm.logLevel = level
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(vm.logLevel.label)
                                            .font(.footnote)
                                            .foregroundColor(AppTheme.secondaryColor)
                                        Image(systemName: "chevron.down")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: – Files List
                SectionBlock(title: "Log Files (\(vm.files.count))") {
                    VStack(spacing: 8) {
                        if vm.files.isEmpty {
                            Text("No log files yet.")
                        } else {
                            ForEach(vm.files, id: \.self) { url in
                                HStack {
                                    Image(systemName: "doc.plaintext")
                                    Text(url.lastPathComponent)
                                    Spacer()
                                    Text(String(format: "%.1f KB", vm.fileSizeKB(url)))
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryColor)
                                }
                            }
                        }
                    }
                }
                
                // MARK: – Actions
                SectionBlock(title: "Actions") {
                    VStack(spacing: 12) {
                        Button {
                            showingLogMail = true
                        } label: {
                            Label("Email Logs", systemImage: "envelope")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.black)
                        .disabled(!vm.canSendMail() || vm.files.isEmpty)
                        
                        DashedDivider()
                        
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share / Export Logs", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.black)
                        .disabled(vm.files.isEmpty)
                        
                        DashedDivider()
                        
                        Button(role: .destructive) {
                            vm.clearLogs()
                        } label: {
                            Label("Clear All Logs", systemImage: "trash")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.red)
                        .disabled(vm.files.isEmpty)
                    }
                }
                
                Spacer(minLength: 32)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Crash & Logs")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: vm.files)
        }
        .mailSheet(isPresented: $showingLogMail, onCannotSend: {
            logMailError = true
        }) {
            ComposeMailView( recipients: ["ehsaifan@gmail.com"],
                             subject: "Strike ’Em All Logs",
                             body: "Attached logs for debugging.",
                             attachments: vm.files.compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return .init(data: data,
                             mimeType: "text/plain",
                             fileName: url.lastPathComponent)
            })
        }
        .alert("Mail not configured", isPresented: $logMailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please configure Mail to send logs.")
        }
    }
}
