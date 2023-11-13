import SwiftUI

struct ContentView: View {
    @State private var pixellate: CGFloat = 1
    @State private var speed: CGFloat = 1
    @State private var amplitude: CGFloat = 5
    @State private var frequency: CGFloat = 15
    @State private var enableLayerEffect: Bool = false
    @State private var blur: CGFloat = 0
    @State private var radius: CGFloat = 0
    @State private var chomaKeyColor: Color = .white
    let startDate: Date = .init()
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    PixellateView()
                } label: {
                    Text("Pixellate")
                }
                
                NavigationLink {
                    WavesView()
                } label: {
                    Text("Waves")
                }
                
                NavigationLink {
                    GrayscaleView()
                } label: {
                    Text("Gray scale")
                }
                
                NavigationLink {
                    GaussianBlurView()
                } label: {
                    Text("Gaussian Blur")
                }
                
                NavigationLink {
                    CircleBlurView()
                } label: {
                    Text("Circle Blur")
                }
                
                NavigationLink {
                    DefaultBlurView()
                } label: {
                    Text("Default Blur")
                }
                
                NavigationLink {
                    ChomaKeyView()
                } label: {
                    Text("Choma Key")
                }
                
            }
            .navigationTitle("Shaders Example")
        }
        
    }
    
    @ViewBuilder
    func PixellateView() -> some View {
        VStack {
            defaultImageView()
                .distortionEffect(.init(function: .init(library: .default, name: "pixellate"), arguments: [.float(pixellate)]), maxSampleOffset: .zero)
            
            Slider(value: $pixellate, in: 1...20)
        }
    }
    
    @ViewBuilder
    func WavesView() -> some View {
        List {
            TimelineView(.animation) {
                let time = $0.date.timeIntervalSince1970 - startDate.timeIntervalSince1970
                
                defaultImageView()
                    .distortionEffect(.init(function: .init(library: .default, name: "wave"), arguments: [
                            .float(time),
                            .float(speed),
                            .float(frequency),
                            .float(amplitude)]
                    ), maxSampleOffset: .zero)
            }
            
            Section("Speed") {
                Slider(value: $speed, in: 1...15)
            }
            Section("Frequency") {
                Slider(value: $frequency, in: 1...50)
            }
            Section("Amplitude") {
                Slider(value: $amplitude, in: 1...35)
            }
            
        }
    }
    
    @ViewBuilder
    func GrayscaleView() -> some View {
        VStack {
            defaultImageView()
                .layerEffect(
                    .init(
                        function: .init(library: .default, name: "grayscale"),
                        arguments: []
                    ),
                    maxSampleOffset: .zero,
                    isEnabled: enableLayerEffect)
            
            Toggle("Enable Grayscale Layer Effect", isOn: $enableLayerEffect)
            Spacer()
        }
    }
    
    @ViewBuilder
    func GaussianBlurView() -> some View {
        VStack {
            ZStack(alignment: .center) {
                defaultImageView()
//                Text("Hello world")z
//                    .background(.thickMaterial)
            }
//            .distortionEffect(blurShader(), maxSampleOffset: .init(width: 100, height: 100))
            .colorEffect(blurShader())
//            .layerEffect(blurShader(), maxSampleOffset: .init(width: 100, height: 100))
            
            Slider(value: $blur, in: 0...10)
        }
    }
    
    @ViewBuilder
    func CircleBlurView() -> some View {
        VStack {
            defaultImageView()
                .layerEffect(.init(function: .init(library: .default, name: "circleBlur"), arguments: [
                    .float2(CGSize(width: 200, height: 200)),
                    .float(radius),
                    .float(100)
                ]), maxSampleOffset: CGSize(width: radius, height: radius))
            Slider(value: $radius, in: 0...10)
        }
    }
    
    @ViewBuilder
    func DefaultBlurView() -> some View {
        VStack {
            defaultImageView()
                .blur(radius: blur)
            Slider(value: $blur, in: 0...10)
        }
    }
    
    @ViewBuilder
    func ChomaKeyView() -> some View {
        VStack {
            defaultImageView()
                .colorEffect(chomaKeyShader(color: chomaKeyColor))
            
            Form {
                Picker(selection: $chomaKeyColor) {
                    ForEach(Color.allColors(), id: \.self) { color in
                        Text("\(color.description)")
                    }
                } label: {
                    Text("Select Color")
                }
            }

        }
    }
    func blurShader() -> Shader {
        let f = ShaderFunction(library: .default, name: "gaussianBlurFragment")
        let image = Image(.gundam)
        let imageArg = Shader.Argument.image(image)
        let shader = Shader(function: f, arguments: [
            imageArg
        ])
        
        return shader
    }
    
    func chomaKeyShader(color: Color, settings: ChromaKeySettings = .init()) -> Shader {
        let f = ShaderFunction(library: .default, name: "chromaKey")
    
        let shader = Shader(function: f, arguments: [
            .color(color),
            .float(settings.range),
            .float(settings.softness),
            .float(settings.edgeDesaturation),
            .float(settings.alphaCrop)
        ])
        
        return shader
    }
}

extension ContentView {
    func defaultImageView() -> some View {
        Image(.gundam)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 200)
    }
}


extension Color {
    static func allColors() -> [Color] {
        return [.white, .red, .yellow, .blue, .green]
    }
}

#Preview {
    ContentView()
}
