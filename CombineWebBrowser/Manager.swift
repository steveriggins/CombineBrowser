import Foundation
import Combine
import SwiftUI

public enum LoadingStatus {
    case loading
    case idle
}

public class Manager: ObservableObject {
    
    /// Reflects the loading status of the HTML
    @Published var loadingStatus: LoadingStatus

    /// The currently loaded HTML and the URL it was loaded from
    @Published var currentHTML: Result<(String, URL?), Error>
    
    public func refresh(_ url: URL) {
        loadingStatus = .loading
        
        let cancellableKey = UUID()
        
        let cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .map { String(data: $0, encoding: .utf8) }
            .sink (receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    break;
                case .failure(let error):
                    self.finished(cancellableKey)
                    self.currentHTML = .failure(error)
                }
                
            }, receiveValue: { [weak self] string in
                guard let self = self,
                      let html = string else { return }
                self.currentHTML = .success((html, url))
                self.finished(cancellableKey)
            })
        
        cancellables[cancellableKey] = cancellable
    }
    
    public init() {
        loadingStatus = .idle
        currentHTML = .success(("", nil))
    }
    
    private func finished(_ key: UUID) {
        loadingStatus = .idle
        cancellables[key] = nil
    }
    
    private var cancellables: [UUID: AnyCancellable] = [:]
}

