//
//  Toast.swift
//  ToastsSwiftUI
//
//  Created by Thanh Sau on 17/12/2023.
//

import SwiftUI

struct RootView<Content: View>: View {
    
    @ViewBuilder var content: Content
    
    @State private var overlayWindow: UIWindow?
    
    var body: some View {
        content
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   overlayWindow == nil {
                    let window = Passthrough(windowScene: windowScene)
                    
                    /// controller
//                    let rootViewController = UIHostingController(rootView: ToastGroup())
//                    rootViewController.view.frame = windowScene.keyWindow?.frame ?? .zero
//                    window.rootViewController = rootViewController
                    
                    window.backgroundColor = .clear
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    window.tag = 1009
                    
                    overlayWindow = window
                }
            }
    }
}

fileprivate class Passthrough: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        
        return rootViewController?.view == view ? nil : view
    }
}

@Observable
class Toast {
    static let shared: Toast = .init()
    
    private init() {}
    fileprivate var toasts: [ToastItem] = []
    
    func present (title: String, symbol: String?, tint: Color = .primary, isUserInteractionEnabled: Bool = false, timing: ToastTime = .medium) {
        withAnimation {
            toasts.append(.init(title: title, symbol: symbol, tint: tint, isUserInteractionEnabled: isUserInteractionEnabled, timing: timing))
        }
        
    }
}

struct ToastItem: Identifiable {
    let id: UUID = .init()
    
    var title: String
    var symbol: String?
    var tint: Color
    var isUserInteractionEnabled: Bool
    var timing: ToastTime = .medium
}

enum ToastTime: CGFloat {
    case short = 1.0
    case medium = 2.0
    case long = 3.0
}

fileprivate struct ToastGroup: View {
    
    var model = Toast.shared
    var body: some View {
        GeometryReader(content: { geometry in
            let size = geometry.size
            let safeArea = geometry.safeAreaInsets
            
            ZStack {
                ForEach(model.toasts) { item in
                    ToastView(size: size, item: item)
                        .scaleEffect(scale(item))
                        .offset(y: offsetY(item))
                }
            }
            .padding(safeArea.top == .zero ? 15 : 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        })
    }
    
    func offsetY(_ item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat (model.toasts.count) - 1
        return (totalCount - index) >= 2 ? -20 : ((totalCount - index) * -10)
    }
    
    func scale(_ item: ToastItem) -> CGFloat {
        let index = CGFloat(model.toasts.firstIndex(where: { $0.id == item.id }) ?? 0)
        let totalCount = CGFloat (model.toasts.count) - 1
        return 1.0 - ((totalCount - index) >= 2 ? 0.2 : ((totalCount - index) * 0.1))
    }
}

fileprivate struct ToastView: View {
    var size: CGSize
    var item: ToastItem
    @State private var animationIn = false
    @State private var animationOut = false
    var body: some View {
        HStack(spacing: 0) {
            if let symbol = item.symbol {
                Image (systemName: symbol)
                    .font(.title3)
                    .padding(.trailing, 10)
            }
            
            Text(item.title)
                .foregroundStyle(item.tint)
                .padding (.horizontal, 15)
                .padding (.vertical, 8)
                .background(
                    .background
                        .shadow(.drop(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5))
                        .shadow(.drop(color: .primary.opacity(0.06), radius: 8, x: -5, y: -5)),
                    in: . capsule
                )
                .contentShape (.capsule)
        }
        .gesture(
            DragGesture (minimumDistance: 0)
                .onEnded ({ value in
                    let endY = value.translation.height
                    let velocityY = value.velocity.height
                    if (endY + velocityY) > 100 {
                        removeToast()
                    }
                }
            )
        )
        .offset(y: animationIn ? 0 : 150)
        .offset(y: !animationOut ? 0 : 150)
        .task {
            guard !animationIn else { return }
            withAnimation {
                animationIn = true
            }
            
            try? await Task.sleep(for: .seconds(item.timing.rawValue))
            removeToast()
        }
    }
    
    func removeToast() {
        guard !animationOut else { return }
        withAnimation {
            animationOut = true
        } completion: {
            removeItem()
        }
    }
    
    func removeItem() {
        Toast.shared.toasts.removeAll(where: { $0.id == item.id })
    }
}


#Preview(body: {
    RootView {
        ContentView()
    }
})
