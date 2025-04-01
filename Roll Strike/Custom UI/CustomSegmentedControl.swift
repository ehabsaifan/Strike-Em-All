//
//  CustomSegmentedControl.swift
//  Roll Strike
//
//  Created by Ehab Saifan on 4/1/25.
//

import SwiftUI

struct CustomSegmentedControl: UIViewRepresentable {
    @Binding var selectedSegment: Int
    var items: [String]
    var selectedTintColor: UIColor = .yellow
    var normalTextColor: UIColor = .white
    var selectedTextColor: UIColor = .black

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedSegment: $selectedSegment)
    }
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = selectedSegment
        control.selectedSegmentTintColor = selectedTintColor
        control.setTitleTextAttributes([.foregroundColor: normalTextColor], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: selectedTextColor], for: .selected)
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
