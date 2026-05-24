//
//  PortraitLockedView.swift
//  Agil10.0
//
//  Created by Christiane Roth on 24.05.26.
//


import SwiftUI

/// Sperrt den eingebetteten Inhalt aufs Hochformat.
/// Die App-Rotation wird nur für diesen Controller eingeschränkt.
struct PortraitLockedView<Content: View>: UIViewControllerRepresentable {
    @ViewBuilder let content: () -> Content

    func makeUIViewController(context: Context) -> UIViewController {
        PortraitHostingController(rootView: content())
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        (controller as? PortraitHostingController<Content>)?.rootView = content()
    }

    private final class PortraitHostingController<C: View>: UIHostingController<C> {
            override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
                .portrait
            }
            override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
                .portrait
            }
            override var shouldAutorotate: Bool {
                false
            }

            override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                setNeedsUpdateOfSupportedInterfaceOrientations()
            }

            override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
                guard let scene = view.window?.windowScene else { return }
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
}
