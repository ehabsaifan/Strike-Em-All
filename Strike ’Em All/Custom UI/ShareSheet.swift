//
//  ShareSheet.swift
//  Strike ’Em All
//
//  Created by Ehab Saifan on 5/7/25.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]    
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
      UIActivityViewController(
        activityItems: activityItems,
        applicationActivities: applicationActivities
      )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
      // nothing
    }
  }
