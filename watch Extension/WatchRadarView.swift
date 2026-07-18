//
//  WatchRadarView.swift
//  watch Extension
//
//  Created by drvolks on 2026-07-18.
//  Copyright © 2026 drvolks. All rights reserved.
//

import SwiftUI

/// Radar page shown when swiping left from the main forecast view: the
/// latest Environment Canada radar frame composited over a CBMT basemap,
/// with play/pause animation and Digital Crown scrubbing.
struct WatchRadarView: View {
    @Environment(WatchWeatherModel.self) private var model
    @State private var radarModel = WatchRadarModel()
    @State private var crownValue = 0.0
    @State private var viewSize = CGSize(width: 180, height: 200)

    private var city: City? {
        model.wrapper.city ?? PreferenceHelper.getCityToUse()
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear {
                    viewSize = geometry.size
                    radarModel.load(for: city, sizePoints: geometry.size)
                }
        }
        .onDisappear {
            radarModel.cancel()
        }
        .onChange(of: model.wrapper.city?.id) {
            radarModel.load(for: city, sizePoints: viewSize)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch radarModel.state {
        case .idle, .loading:
            ZStack {
                basemapBackground
                ProgressView()
            }
        case .unavailable:
            VStack(spacing: 8) {
                Image(systemName: "cloud.rain")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Radar unavailable".localized())
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        case .failed(let message):
            VStack(spacing: 8) {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try Again".localized()) {
                    radarModel.retry(for: city, sizePoints: viewSize)
                }
            }
        case .loaded:
            radarStack
        }
    }

    private var radarStack: some View {
        ZStack {
            ZStack {
                basemapBackground

                if let frame = radarModel.currentImage {
                    Image(uiImage: frame)
                        .resizable()
                        .scaledToFill()
                }

                cityDot
            }
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            controlBar
                .padding(.bottom, 30)
        }
        .focusable(true)
        .digitalCrownRotation($crownValue,
                              from: 0,
                              through: Double(max(radarModel.timeSteps.count - 1, 0)),
                              by: 1,
                              sensitivity: .medium,
                              isContinuous: false,
                              isHapticFeedbackEnabled: true)
        .onChange(of: crownValue) {
            let index = Int(crownValue.rounded())
            if index != radarModel.currentIndex {
                radarModel.scrub(to: index)
            }
        }
        .onChange(of: radarModel.currentIndex) {
            crownValue = Double(radarModel.currentIndex)
        }
    }

    @ViewBuilder
    private var basemapBackground: some View {
        if let basemap = radarModel.basemap {
            Image(uiImage: basemap)
                .resizable()
                .scaledToFill()
        } else {
            Color.black
        }
    }

    private var cityDot: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 7, height: 7)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
            )
    }

    private var controlBar: some View {
        HStack {

            Text(radarModel.currentTimeLabel)
                .font(.footnote.monospacedDigit())
                .padding(.vertical, 5)
        }
        .padding(.horizontal, 4)
    }
}
