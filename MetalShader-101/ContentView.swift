import SwiftUI

struct ContentView: View {
    @State private var pixellate: CGFloat = 1
    @State private var speed: CGFloat = 1
    @State private var amplitude: CGFloat = 5
    @State private var frequency: CGFloat = 15
    @State private var enableLayerEffect: Bool = false
    @State private var blur: CGFloat = 0
    @State private var radius: CGFloat = 0
    @State private var circleRadius: CGFloat = 2
    @State private var circleSize: CGFloat = 5
    @State private var chomaKeyColor: Color = .white
    
    // fopr wave used
    let startDate: Date = .init()
    // for passthrough
    @State private var start = Date.now
    @State private var tough = CGPoint.zero
    
    // gradient blur
    @State private var gradientBlur1Radius: CGFloat = 0
    @State private var gradientBlur2Radius: CGFloat = 0
    @State private var gradientBlur3Radius: CGFloat = 1
    @State private var gradientBlur3_2Radius: CGFloat = 1
    @State private var gradientBlur4Radius: CGFloat = 20
    @State private var gradientBlur5Radius: CGFloat = 1
    
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
                
                NavigationLink {
                    PassthroughView()
                } label: {
                    Text("Passthrough")
                }
                
                NavigationLink {
                    LoupeView()
                } label: {
                    Text("Loupe")
                }
                
                NavigationLink {
                    gradientBlurView1()
                } label: {
                    Text("Gradient Blur 1")
                }
                
                NavigationLink {
                    gradientBlurView2()
                } label: {
                    Text("Gradient Blur 2")
                }
                
                NavigationLink {
                    gradientBlurView3()
                } label: {
                    Text("Gradient Blur 3 (Horizontal)")
                }
                
                NavigationLink {
                    gradientBlurView3_2()
                } label: {
                    Text("Gradient Blur 3 (Vertical)")
                }
                
                NavigationLink {
                    gradientBlurView4()
                } label: {
                    Text("Gradient Blur 4")
                }
                
                NavigationLink {
                    gradientBlurView5()
                } label: {
                    Text("Motion Blur")
                }
                
            }
            .navigationTitle("Shaders Example")
        }
        
    }
}

extension ContentView {
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
    func CircleBlurView() -> some View {
        VStack {
            defaultImageView()
                .layerEffect(.init(function: .init(library: .default, name: "circleBlur"), arguments: [
                    .float2(CGSize(width: 400, height: 400)),
                    .float(circleRadius),
                    .float(circleSize)
                ]), maxSampleOffset: CGSize(width: radius, height: radius))
            Slider(value: $circleRadius, in: 2...10)
            Slider(value: $circleSize, in: 5...50)
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
    
    @ViewBuilder
    func PassthroughView() -> some View {
        TimelineView(.animation) { tl in
            let time = start.distance(to: tl.date)
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 300))
                .foregroundStyle(.blue)
                .padding(20)
                .background(.white)
                .drawingGroup()
//                    .colorEffect(ShaderLibrary.invertAlpha())
//                    .colorEffect(ShaderLibrary.recolor())
//                .colorEffect(ShaderLibrary.rainbow(.float(time)))
//                .distortionEffect(ShaderLibrary.wave2(.float(time)), maxSampleOffset: .zero)
                .visualEffect { content, geometryProxy in
                    content
                        .distortionEffect(ShaderLibrary.wave3(.float(time), .float2(geometryProxy.size)), maxSampleOffset: .zero)
                }
        }
    }
    
    @ViewBuilder
    func LoupeView() -> some View {
        defaultImageView()
            .visualEffect { content, geometryProxy in
                content
                    .layerEffect(ShaderLibrary.loupe(
                        .float2(geometryProxy.size),
                        .float2(CGSize.zero)
                    ),maxSampleOffset: .zero)
            }
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged({ val in
                    tough = val.location
                }))
    }
}

extension ContentView {
    func defaultImageView() -> some View {
        Image(.gundam)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 400)
    }
    
    func blurShader(blur: CGFloat) -> Shader {
        let f = ShaderFunction(library: .default, name: "gaussianBlurFragment")
        let image = Image(.gundam)
        let imageArg = Shader.Argument.image(image)
        let shader = Shader(function: f, arguments: [
            imageArg,
            .float(blur)
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

// Gradient Blur Views
extension ContentView {
    @ViewBuilder
    func gradientBlurView1() -> some View {
        VStack {
            Image(.snow)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 600)
                .visualEffect { content, geometryProxy in
                    content
                        .layerEffect(ShaderLibrary.gaussianBlur_1(
                            .float2(geometryProxy.size),
                            .float(gradientBlur1Radius)
                        ), maxSampleOffset: .zero)
                }
            Slider(value: $gradientBlur1Radius, in: 0...1)
        }
    }
    
    @ViewBuilder
    func gradientBlurView2() -> some View {
        HStack {
            Image(.snow)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 600)
                .visualEffect { content, geometryProxy in
                    content
                        .layerEffect(ShaderLibrary.gaussianBlur_2(
                            .float2(geometryProxy.size),
                            .float(gradientBlur2Radius)
                        ), maxSampleOffset: .zero)
                }
        }
    }
    
    @ViewBuilder
    func gradientBlurView3() -> some View {
        VStack {
            Image(.snow)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 600)
                .visualEffect { content, geometryProxy in
                    content
                        .layerEffect(ShaderLibrary.gaussianBlur_3(
                            .float2(geometryProxy.size),
                            .float(gradientBlur3Radius)
                        ), maxSampleOffset: .zero)
                }
            Slider(value: $gradientBlur3Radius, in: 1...30)
        }
    }
    
    @ViewBuilder
    func gradientBlurView3_2() -> some View {
        VStack {
            Image(.snow)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 600)
                .visualEffect { content, geometryProxy in
                    content
                        .layerEffect(ShaderLibrary.gaussianBlur_3_2(
                            .float2(geometryProxy.size),
                            .float(gradientBlur3_2Radius)
                        ), maxSampleOffset: .zero)
                }
            Slider(value: $gradientBlur3_2Radius, in: 1...30)
        }
    }
    
    
    @ViewBuilder
    func gradientBlurView4() -> some View {
        VStack {
            Image(.snow)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 600)
                .visualEffect { content, geometryProxy in
                    content
                        .layerEffect(ShaderLibrary.gaussianBlur_4(
                            .float2(geometryProxy.size),
                            .float(gradientBlur4Radius)
                        ), maxSampleOffset: .zero)
                }
        }
    }
    
    @ViewBuilder
    func gradientBlurView5() -> some View {
        VStack {
            Image(.snow)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 600)
                .visualEffect { content, geometryProxy in
                    content
                        .layerEffect(ShaderLibrary.gaussianBlur_5(
                            .float2(geometryProxy.size),
                            .float(gradientBlur5Radius)
                        ), maxSampleOffset: .zero)
                }
            Slider(value: $gradientBlur5Radius, in: 1...30)
        }
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
