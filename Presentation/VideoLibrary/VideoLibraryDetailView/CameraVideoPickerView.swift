//
//  CameraVideoPickerView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 05.04.26.
//


//
//  CameraVideoPickerView.swift
//  Agil
//

import SwiftUI
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

struct CameraVideoPickerView: UIViewControllerRepresentable {
    let onVideoRecorded: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIViewController {
            #if targetEnvironment(simulator)
            // Simulator: leerer ViewController
            let vc = UIViewController()
            DispatchQueue.main.async { dismiss() }
            return vc
            #else
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = [UTType.movie.identifier]
            picker.videoQuality = .typeHigh
            picker.videoMaximumDuration = 300
            picker.allowsEditing = false
            picker.delegate = context.coordinator
            return picker
            #endif
        }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraVideoPickerView
        
        init(_ parent: CameraVideoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let url = info[.mediaURL] as? URL {
                parent.onVideoRecorded(url)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
