//
//  AlertDetailViewController.swift
//  weatherlr
//
//  Created by Jean-Francois Dufour on 2016-05-16.
//  Copyright © 2016 Jean-Francois Dufour. All rights reserved.
//

import UIKit

class AlertDetailViewController: UIViewController {
    var alerts = [AlertInformation]()
    var popOver:AlertViewController?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Warning".localized()
        view.backgroundColor = .systemBackground

        setupScrollView()
        buildContent()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func buildContent() {
        for (index, alert) in alerts.enumerated() {
            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = .separator
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stackView.addArrangedSubview(separator)
            }
            stackView.addArrangedSubview(buildAlertView(alert))
        }

        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 24).isActive = true
        stackView.addArrangedSubview(spacer)

        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false

        let safariButton = UIButton(type: .system)
        safariButton.setTitle("Open in Safari".localized(), for: .normal)
        safariButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        safariButton.addTarget(self, action: #selector(openInSafari), for: .touchUpInside)
        safariButton.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(safariButton)

        NSLayoutConstraint.activate([
            safariButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            safariButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: -16),
            safariButton.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor)
        ])

        stackView.addArrangedSubview(buttonContainer)
    }

    private func buildAlertView(_ alert: AlertInformation) -> UIView {
        let container = UIView()

        let banner = UIView()
        banner.backgroundColor = bannerColor(for: alert.alertColourLevel)
        banner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(contentStack)

        let titleLabel = UILabel()
        titleLabel.text = capitalizedText(alert.alertText)
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        if !alert.eventIssueTime.isEmpty {
            let issuedLabel = UILabel()
            issuedLabel.text = "Issued".localized() + ": " + alert.eventIssueTime
            issuedLabel.font = .preferredFont(forTextStyle: .subheadline)
            issuedLabel.textColor = .secondaryLabel
            issuedLabel.numberOfLines = 0
            contentStack.addArrangedSubview(issuedLabel)
        }

        if !alert.expiryTime.isEmpty {
            let expiresLabel = UILabel()
            expiresLabel.text = "Expires".localized() + ": " + alert.expiryTime
            expiresLabel.font = .preferredFont(forTextStyle: .subheadline)
            expiresLabel.textColor = .secondaryLabel
            expiresLabel.numberOfLines = 0
            contentStack.addArrangedSubview(expiresLabel)
        }

        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: container.topAnchor),
            banner.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            banner.widthAnchor.constraint(equalToConstant: 6),
            banner.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: banner.trailingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func bannerColor(for level: String) -> UIColor {
        switch level.lowercased() {
        case "red":
            return .systemRed
        case "yellow":
            return .systemYellow
        case "orange":
            return .systemOrange
        default:
            return .systemGray
        }
    }

    private func capitalizedText(_ text: String) -> String {
        var t = text.lowercased()
        t.replaceSubrange(t.startIndex...t.startIndex, with: String(t[t.startIndex]).uppercased())
        return t
    }

    @objc private func openInSafari() {
        guard let firstAlert = alerts.first,
              let url = URL(string: firstAlert.url) else { return }
        UIApplication.shared.open(url)
    }

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: {()->Void in
                self.popOver?.dismiss(animated: true, completion: nil)
            })
    }

    override var preferredStatusBarStyle:UIStatusBarStyle {
        return .default
    }
}
