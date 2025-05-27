//
//  ComposeMailView.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/24/25.
//

import SwiftUI
import MessageUI

struct ComposeMailView: UIViewControllerRepresentable {
  @Environment(\.presentationMode) private var presentation
  let recipients: [String]
  let subject: String
  let body: String?
  let attachments: [MailAttachment]  // new struct below

  struct MailAttachment {
    let data: Data
    let mimeType: String
    let fileName: String
  }

  class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    var parent: ComposeMailView
    init(_ parent: ComposeMailView) { self.parent = parent }
    func mailComposeController(
      _ controller: MFMailComposeViewController,
      didFinishWith result: MFMailComposeResult,
      error: Error?
    ) {
      controller.dismiss(animated: true) {
        self.parent.presentation.wrappedValue.dismiss()
      }
    }
  }

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  func makeUIViewController(context: Context) -> MFMailComposeViewController {
    let composer = MFMailComposeViewController()
    composer.setToRecipients(recipients)
    composer.setSubject(subject)
    if let body = body {
      composer.setMessageBody(body, isHTML: false)
    }
    attachments.forEach {
      composer.addAttachmentData($0.data,
                                 mimeType: $0.mimeType,
                                 fileName: $0.fileName)
    }
    composer.mailComposeDelegate = context.coordinator
    return composer
  }

  func updateUIViewController(
    _ uiViewController: MFMailComposeViewController,
    context: Context
  ) {}
  
  /// convenience check
  static func canSendMail() -> Bool {
    MFMailComposeViewController.canSendMail()
  }
}
