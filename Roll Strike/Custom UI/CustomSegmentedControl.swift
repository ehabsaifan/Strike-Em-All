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
    
    init(selectedTintColor: UIColor = UIColor(AppTheme.secondaryColor),
         normalTextColor: UIColor = .black,
         selectedTextColor: UIColor = UIColor(AppTheme.tertiaryColor)) {
        self.selectedTintColor = selectedTintColor
        self.normalTextColor = normalTextColor
        self.selectedTextColor = selectedTextColor
    }
}

struct CustomSegmentedControl<T: Hashable>: UIViewRepresentable {
    @Binding var selectedSegment: T
    var items: [T]
    var label: (T) -> String
    var settings: CustomSegmentedControlSettings = CustomSegmentedControlSettings()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedSegment: $selectedSegment, items: items)
    }
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let titles = items.map(label)
        let control = UISegmentedControl(items: titles)
        control.selectedSegmentIndex = items.firstIndex(of: selectedSegment) ?? 0
        control.selectedSegmentTintColor = settings.selectedTintColor
        control.setTitleTextAttributes([.foregroundColor: settings.normalTextColor], for: .normal)
        control.setTitleTextAttributes([.foregroundColor: settings.selectedTextColor], for: .selected)
        control.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return control
    }
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        guard let idx = items.firstIndex(of: selectedSegment),
              uiView.selectedSegmentIndex != idx
        else {
            return
        }
        uiView.selectedSegmentIndex = idx
    }
        
    class Coordinator: NSObject {
        @Binding var selectedSegment: T
        let items: [T]
        
        init(selectedSegment: Binding<T>, items: [T]) {
            self._selectedSegment = selectedSegment
            self.items = items
        }
        
        @objc func valueChanged(_ sender: UISegmentedControl) {
            let idx = sender.selectedSegmentIndex
            guard items.indices.contains(idx) else { return }
            selectedSegment = items[idx]
        }
    }
}
