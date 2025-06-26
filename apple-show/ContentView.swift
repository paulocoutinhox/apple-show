import SwiftUI
import AVFoundation
import MediaPlayer

// MARK: - AVPlayer Remote Control Manager

class AVPlayerRemoteManager: ObservableObject {
    static let shared = AVPlayerRemoteManager()
    
    var onForward: (() -> Void)?
    var onRewind: (() -> Void)?
    
    private var player: AVPlayer?
    
    private init() {
        // Evita sleep/screensaver
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Use um áudio local válido chamado "blank.mp3" no projeto
        if let url = Bundle.main.url(forResource: "blank", withExtension: "mp3") {
            player = AVPlayer(url: url)
        }
        setupRemoteCommands()
    }
    
    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [5]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.onForward?()
            return .success
        }
        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [5]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.onRewind?()
            return .success
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
}

// MARK: - UIKit Play/Pause + Next/Prev Catcher

class PlayPauseCatcher: UIViewController {
    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onPrev: (() -> Void)?
    
    override var canBecomeFirstResponder: Bool { true }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            switch press.type {
            case .playPause:
                onPlayPause?()
            case .rightArrow:
                onNext?()
            case .leftArrow:
                onPrev?()
            case .select:
                // Opcional: se quiser que clique no touchpad avance slide
                onNext?()
            default:
                super.pressesBegan(presses, with: event)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
}

struct PlayPauseRepresentable: UIViewControllerRepresentable {
    var onPlayPause: () -> Void
    var onNext: () -> Void
    var onPrev: () -> Void
    
    func makeUIViewController(context: Context) -> PlayPauseCatcher {
        let c = PlayPauseCatcher()
        c.onPlayPause = onPlayPause
        c.onNext = onNext
        c.onPrev = onPrev
        return c
    }
    
    func updateUIViewController(_ uiViewController: PlayPauseCatcher, context: Context) {
        uiViewController.onPlayPause = onPlayPause
        uiViewController.onNext = onNext
        uiViewController.onPrev = onPrev
    }
}

// MARK: - Models

struct SlidesData: Decodable {
    struct Config: Decodable {
        let interval: Double
    }
    struct Slide: Decodable {
        let title: String?
        let image: String
        let interval: Double?
    }
    let config: Config
    let slides: [Slide]
}

struct LoadedSlide: Identifiable {
    let id = UUID()
    let title: String?
    let imageURL: String
    let interval: Double?
    let uiImage: UIImage
}

// MARK: - ViewModel

class SlidesViewModel: ObservableObject {
    @Published var slides: [LoadedSlide] = []
    @Published var configInterval: Double = 10
    @Published var currentIndex: Int = 0
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    
    private var timer: Timer?
    
    func loadSlides(from urlString: String) {
        self.isLoading = true
        self.errorMessage = nil
        guard let url = URL(string: urlString) else {
            self.errorMessage = "URL inválida."
            self.isLoading = false
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Erro ao baixar JSON: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            guard let data else {
                DispatchQueue.main.async {
                    self.errorMessage = "Nenhum dado recebido do JSON."
                    self.isLoading = false
                }
                return
            }
            do {
                let slidesData = try JSONDecoder().decode(SlidesData.self, from: data)
                DispatchQueue.main.async {
                    self.configInterval = slidesData.config.interval
                    self.downloadAllImages(for: slidesData.slides)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Erro ao decodificar JSON: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    private func downloadAllImages(for slides: [SlidesData.Slide]) {
        var loaded: [LoadedSlide] = []
        let group = DispatchGroup()
        var foundError: String?
        
        for slide in slides {
            guard let url = URL(string: slide.image) else {
                foundError = "URL de imagem inválida: \(slide.image)"
                break
            }
            group.enter()
            URLSession.shared.dataTask(with: url) { data, _, error in
                defer { group.leave() }
                if let error = error {
                    foundError = "Erro ao baixar imagem: \(error.localizedDescription) (\(slide.image))"
                    return
                }
                guard let data, let uiImage = UIImage(data: data) else {
                    foundError = "Imagem inválida: \(slide.image)"
                    return
                }
                let loadedSlide = LoadedSlide(
                    title: slide.title,
                    imageURL: slide.image,
                    interval: slide.interval,
                    uiImage: uiImage
                )
                DispatchQueue.main.async {
                    loaded.append(loadedSlide)
                }
            }.resume()
        }
        group.notify(queue: .main) {
            if let error = foundError {
                self.errorMessage = error
                self.isLoading = false
            } else if loaded.isEmpty {
                self.errorMessage = "Nenhuma imagem foi carregada."
                self.isLoading = false
            } else {
                self.slides = loaded
                self.currentIndex = 0
                self.isLoading = false
                self.startTimer()
            }
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        guard !slides.isEmpty else { return }
        let interval = slides[safe: currentIndex]?.interval ?? configInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.nextSlide()
        }
    }
    
    func nextSlide() {
        guard !slides.isEmpty else { return }
        withAnimation {
            currentIndex = (currentIndex + 1) % slides.count
        }
        startTimer()
    }
    
    func prevSlide() {
        guard !slides.isEmpty else { return }
        withAnimation {
            currentIndex = (currentIndex - 1 + slides.count) % slides.count
        }
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Array Safe Index

extension Array {
    subscript(safe idx: Int) -> Element? {
        indices.contains(idx) ? self[idx] : nil
    }
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var vm = SlidesViewModel()
    private let jsonURL = "https://bibleapp-data.s3.us-east-1.amazonaws.com/config/banners-app-show.json"
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if let error = vm.errorMessage {
                Color.black.ignoresSafeArea()
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .padding(.bottom, 24)
                    Text("Erro")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if vm.isLoading {
                Color.black.ignoresSafeArea()
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(2)
                        .padding(.bottom, 24)
                    Text("Carregando slides e imagens…")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            } else if let slide = vm.slides[safe: vm.currentIndex] {
                ZStack(alignment: .bottom) {
                    Image(uiImage: slide.uiImage)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                    
                    if let title = slide.title {
                        HStack {
                            Text(title)
                                .font(.title2)
                                .foregroundColor(.white)
                                .bold()
                                .shadow(radius: 6)
                                .padding(.leading, 40)
                            Spacer()
                        }
                        .frame(height: 150)
                        .background(Color.black.opacity(0.6))
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
            // UIKit catch de Play/Pause + Next/Prev
            PlayPauseRepresentable(
                onPlayPause: {
                    vm.loadSlides(from: jsonURL)
                },
                onNext: {
                    vm.nextSlide()
                },
                onPrev: {
                    vm.prevSlide()
                }
            )
            .frame(width: 0, height: 0)
        }
        .onAppear {
            vm.loadSlides(from: jsonURL)
            AVPlayerRemoteManager.shared.onForward = {
                vm.nextSlide()
            }
            AVPlayerRemoteManager.shared.onRewind = {
                vm.prevSlide()
            }
            AVPlayerRemoteManager.shared.play()
        }
        .onDisappear {
            AVPlayerRemoteManager.shared.pause()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
