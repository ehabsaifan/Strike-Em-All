//
//  CustomSegmentedControl.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/1/25.
//

import SwiftUI

struct CustomSegmentedControlSettings {
    let selectedTintColor: UIColor
    let normalTextColor: UIColor
    let selectedTextColor: UIColor
    
    init(selectedTintColor: UIColor = .white,
         normalTextColor: UIColor = .black,
         selectedTextColor: UIColor = .black) {
        self.selectedTintColor = selectedTintColor
        self.normalTextColor = normalTextColor
        self.selectedTextColor = selectedTextColor
    }
}

struct CustomSegmentedControl: UIViewRepresentable {
    @Binding var selectedSegment: Int
    var items: [String]
    var settings: CustomSegmentedControlSettings = CustomSegmentedControlSettings()

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedSegment: $selectedSegment)
    }
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = selectedSegment
        control.selectedSegmentTintColor = settings.selectedTintColor
        control.setTitleTextAttributes([.foregroundColor: settings.normalTextColor], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: settings.selectedTextColor], for: .selected)
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        uiView.selectedSegmentIndex = selectedSegment
    }
    
    class Coordinator: NSObject {
        @Binding var selectedSegment: Int
        
        init(selectedSegment: Binding<Int>) {
            self._selectedSegment = selectedSegment
        }
        
        @objc func valueChanged(_ sender: UISegmentedControl) {
            selectedSegment = sender.selectedSegmentIndex
        }
    }
}
