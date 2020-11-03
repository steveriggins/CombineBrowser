//
//  ViewController.swift
//  CombineWebBrowser
//
//  Created by Steven W. Riggins on 11/2/20.
//

import UIKit

import Combine
import Foundation
import UIKit
import WebKit
import QuartzCore

class ViewController: UIViewController {
    
    let spinner = UIActivityIndicatorView(style: .large)
    let webView = WKWebView()
    let manager = Manager()
    let inputField = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        manager.$loadingStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                switch status {
                case .loading:
                    self?.webView.loadHTMLString("", baseURL: nil)
                    self?.spinner.isHidden = false
                    self?.spinner.startAnimating()
                case .idle:
                    self?.spinner.isHidden = true
                    self?.spinner.stopAnimating()
                }
            }
            .store(in: &cancellables)
        
        manager.$currentHTML
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success((let html, let url)):
                    self.webView.loadHTMLString(html, baseURL: url)
                case .failure(let error):
                    self.webView.loadHTMLString(
                        """
<!DOCTYPE html>
<html>
<head>
<style>
body {
  background-color: lightgray;
}

p {
  font-size: 48px;
}

p.error {
    color: red;
}
</style>
</head>
<body>
<p class="error">Oh no, an error happened!</p>
<p>\(error)</p>
</body>
</html>
""", baseURL: nil)
                    
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupUI() {
        inputField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputField)
        inputField.placeholder = "URL"
        inputField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        inputField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        inputField.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)
        inputField.textContentType = .URL
        inputField.clearButtonMode = .whileEditing
        inputField.keyboardType = .URL
        inputField.autocapitalizationType = .none
        inputField.autocorrectionType = .no
        inputField.tintColor = .black
        inputField.borderStyle = .roundedRect
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 20).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        spinner.isHidden = true
        
    }
    
    @objc
    private func enterPressed() {
        guard let text = inputField.text,
              var components = URLComponents(string: text) else { return }
        if components.scheme == nil {
            components.scheme = "https"
        }
        if let url = components.url {
            manager.refresh(url)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
}


