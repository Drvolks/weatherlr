//
//  PrecipitationChartView.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2025-02-13.
//  Copyright © 2025 Jean-Francois Dufour. All rights reserved.
//

#if ENABLE_WEATHERKIT
import UIKit

class PrecipitationChartView: UIView {
    private var precipitationData: [(minuteOffset: Int, intensity: Double)] = []

    func configure(with data: [(minuteOffset: Int, intensity: Double)]) {
        self.precipitationData = data
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)

        let titleHeight: CGFloat = 20
        let labelHeight: CGFloat = 14
        let titleBottomPadding: CGFloat = 8
        let chartTop = titleHeight + titleBottomPadding
        let chartBottom = rect.height - labelHeight - 4
        let chartHeight = chartBottom - chartTop
        let barWidth = rect.width / 60.0
        let barSpacing: CGFloat = 1

        // Title
        let title = "Precipitation next hour".localized()
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ]
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        let titleX = (rect.width - titleSize.width) / 2
        (title as NSString).draw(at: CGPoint(x: titleX, y: 2), withAttributes: titleAttrs)

        // Scale so max bar reaches ~1/3 height (first guide line)
        let dataMax = precipitationData.prefix(60).map { $0.intensity }.max() ?? 0
        let scaleMax = max(dataMax * 3.0, 0.3)

        // Horizontal guide lines
        let guideColor = UIColor.white.withAlphaComponent(0.15).cgColor
        context.setStrokeColor(guideColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [3, 3])
        for fraction in [1.0 / 3.0, 2.0 / 3.0, 1.0] {
            let y = chartBottom - CGFloat(fraction) * chartHeight
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
        }
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])

        // Bars
        let barColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.9)
        for i in 0..<min(precipitationData.count, 60) {
            let entry = precipitationData[i]
            let normalizedIntensity = min(entry.intensity / scaleMax, 1.0)
            let barHeight = CGFloat(normalizedIntensity) * chartHeight
            let effectiveHeight = barHeight > 0 ? max(barHeight, 2) : 0

            if effectiveHeight > 0 {
                let x = CGFloat(i) * barWidth
                let y = chartBottom - effectiveHeight
                let barRect = CGRect(x: x + barSpacing / 2, y: y, width: barWidth - barSpacing, height: effectiveHeight)
                context.setFillColor(barColor.cgColor)
                context.fill(barRect)
            }
        }

        // Time labels
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.7),
            .font: UIFont.systemFont(ofSize: 10)
        ]
        let labelY = chartBottom + 4
        for minute in [0, 15, 30, 45, 60] {
            let label: String
            if minute == 0 {
                label = "Now".localized()
            } else {
                label = "\(minute)m"
            }
            let x = CGFloat(minute) * barWidth
            let labelSize = (label as NSString).size(withAttributes: labelAttrs)
            let labelX = min(max(x - labelSize.width / 2, 0), rect.width - labelSize.width)
            (label as NSString).draw(at: CGPoint(x: labelX, y: labelY), withAttributes: labelAttrs)
        }
    }
}
#endif
