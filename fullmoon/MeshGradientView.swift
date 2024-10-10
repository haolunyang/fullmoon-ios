//
//  MeshGradientView.swift
//  fullmoon
//
//  Created by Haolun Yang on 10/9/24.
//

import SwiftUI

struct MeshGradientView: View {
    @State var t: Float = 0.0
    @State var timer: Timer?

    var body: some View {
        MeshGradient(width: 3, height: 3, points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            [sinInRange(-0.8...(-0.2), offset: 0.439, timeScale: 0.342, t: t), sinInRange(0.3...0.7, offset: 3.42, timeScale: 0.984, t: t)],
            [sinInRange(0.1...0.8, offset: 0.239, timeScale: 0.084, t: t), sinInRange(0.2...0.8, offset: 5.21, timeScale: 0.242, t: t)],
            [sinInRange(1.0...1.5, offset: 0.939, timeScale: 0.084, t: t), sinInRange(0.4...0.8, offset: 0.25, timeScale: 0.642, t: t)],
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ], colors: [
            .init(red: 83/255, green: 108/255, blue: 220/255),
            .init(red: 169/255, green: 125/255, blue: 158/255),
            .init(red: 195/255, green: 151/255, blue: 146/255),
            .init(red: 36/255, green: 37/255, blue: 81/255),
            .init(red: 31/255, green: 50/255, blue: 168/255),
            .init(red: 106/255, green: 88/255, blue: 164/255),
            .init(red: 1/255, green: 1/255, blue: 1/255),
            .init(red: 1/255, green: 1/255, blue: 1/255),
            .init(red: 1/255, green: 1/255, blue: 1/255)
        ])
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                t += 0.02
            }
        }
        .background(.black)
    }

    func sinInRange(_ range: ClosedRange<Float>, offset: Float, timeScale: Float, t: Float) -> Float {
        let amplitude = (range.upperBound - range.lowerBound) / 2
        let midPoint = (range.upperBound + range.lowerBound) / 2
        return midPoint + amplitude * sin(timeScale * t + offset)
    }
}

#Preview {
    MeshGradientView()
}
