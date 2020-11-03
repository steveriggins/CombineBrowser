import Foundation
import Combine

public enum LoadingStatus {
    case loading
    case idle
}

public class Manager {
    
    public var loadingStatus: AnyPublisher<LoadingStatus, Never> {
        return _loadingStatus
            .eraseToAnyPublisher()
    }
    
    public var currentHTML = PassthroughSubject<Result<String, Error>, Never>()
    
    public func refresh(_ url: URL) {
        _loadingStatus.send(.loading)
                
        let cancellableKey = UUID()
        
        let cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .map { String(data: $0, encoding: .utf8) }
            .sink (receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break;
                case .failure(let error):
                    self?.finished(cancellableKey)
                    self?.currentHTML.send(.failure(error))
                }
                
            }, receiveValue: { [weak self] string in
                guard let self = self,
                      let html = string else { return }
                self.currentHTML.send(.success(html))
                self.finished(cancellableKey)
            })
        
        cancellables[cancellableKey] = cancellable
            

    }
    
    public init() {
        
    }
    
    private func finished(_ key: UUID) {
        _loadingStatus.send(.idle)
        cancellables[key] = nil
    }
    
    private var cancellables: [UUID: AnyCancellable] = [:]
    private var _loadingStatus = CurrentValueSubject<LoadingStatus, Never>(.idle)
}

