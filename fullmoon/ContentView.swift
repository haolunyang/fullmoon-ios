//
//  ContentView.swift
//  fullmoon
//
//  Created by Jordan Singer on 10/4/24.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    @EnvironmentObject var appManager: AppManager
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var llm: LLMEvaluator
    @State var showOnboarding = false
    @State var showSettings = false
    @State var showChats = false
    @State var showModelPicker = false
    @State var prompt = ""
    @FocusState var isPromptFocused: Bool
    @State var currentThread: Thread?
    @Namespace var bottomID
    
    @State private var counter: Int = 0
    @State private var origin: CGPoint = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    VStack(spacing: 0) {
                        MeshGradientView()
                            .ignoresSafeArea()
                        Rectangle()
                            .frame(height: 50)
                            .foregroundStyle(.black)
                    }
                    .background(.black)
                    .overlay {
                        Image("Grain")
                            .scaleEffect(0.5)
                            .ignoresSafeArea()
                            .blendMode(.overlay)
                            .opacity(0.6)
                    }
                    .keyframeAnimator(
                        initialValue: 0,
                        trigger: counter
                    ) { view, elapsedTime in
                        view.visualEffect { view, _ in
                            view.layerEffect(
                                ShaderLibrary.Ripple(
                                    .float2(origin),
                                    .float(elapsedTime),
                                    .float(12), // amplitude
                                    .float(15), // frequency
                                    .float(8),  // decay
                                    .float(1200) // speed
                                ),
                                maxSampleOffset: CGSize(width: 12, height: 12),
                                isEnabled: 0 < elapsedTime && elapsedTime < 3
                            )
                        }
                    } keyframes: { _ in
                        MoveKeyframe(0)
                        LinearKeyframe(3, duration: 3)
                    }
                    
                    VStack(spacing: 0) {
                        if let currentThread = currentThread {
                            ScrollViewReader { scrollView in
                                ScrollView(.vertical) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(currentThread.sortedMessages) { message in
                                            HStack {
                                                if message.role == .user {
                                                    Spacer()
                                                }
                                                
                                                Text(try! AttributedString(markdown: message.content.trimmingCharacters(in: .whitespacesAndNewlines),
                                                                           options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                                                .textSelection(.enabled)
                                                .if(message.role == .user) { view in
                                                    view
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 12)
                                                        .background(
                                                            .ultraThinMaterial
                                                        )
                                                        .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                                        .overlay {
                                                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                                .strokeBorder(.white.opacity(0.1), lineWidth: 1.5)
                                                        }
                                                }
                                                .padding(message.role == .user ? .leading : .trailing, 48)
                                                
                                                if message.role == .assistant {
                                                    Spacer()
                                                }
                                            }
                                            .padding()
                                        }
                                        
                                        if llm.running && !llm.output.isEmpty {
                                            HStack {
                                                Text(try! AttributedString(markdown: llm.output.trimmingCharacters(in: .whitespacesAndNewlines) + " ◐",
                                                                           options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                                                .textSelection(.enabled)
                                                .multilineTextAlignment(.leading)
                                                .padding(.trailing, 48)
                                                
                                                Spacer()
                                            }
                                            .padding()
                                        }
                                    }
                                    
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(height: 1)
                                        .id(bottomID)
                                }
                                .onChange(of: llm.output) { _, _ in
                                    scrollView.scrollTo(bottomID)
                                }
                            }
                            .defaultScrollAnchor(.bottom)
                            #if !os(visionOS)
                            .scrollDismissesKeyboard(.interactively)
                            #endif
                        } else {
                            Spacer()
                            Image(systemName: appManager.getMoonPhaseIcon())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                                .foregroundStyle(.quaternary)
                            Spacer()
                        }
                        
                        HStack {
                            Button {
                                playHaptic()
                                showModelPicker.toggle()
                            } label: {
                                Group {
                                    Image(systemName: "chevron.up")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 16)
                                        .tint(.primary)
                                }
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .foregroundStyle(.ultraThinMaterial)
                                        .overlay {
                                            Circle()
                                                .strokeBorder(.white.opacity(0.1), lineWidth: 1.5)
                                        }
                                )
                            }
                            
                            HStack(spacing: 0) {
                                TextField("message", text: $prompt)
                                    .focused($isPromptFocused)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal)
                                    .if(idiom == .pad || idiom == .mac) { view in
                                        view
                                            .onSubmit {
                                                generate()
                                            }
                                            .submitLabel(.send)
                                    }
                                
                                Button {
                                    origin = CGPoint(x: geometry.size.width, y: geometry.size.height)
                                    counter += 1
                                    generate()
                                } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                        .offset(x: 2.5) // make the symbol concentric with the text field
                                }
                                .disabled(llm.running || prompt.isEmpty)
                                .padding(.trailing)
                            }
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .foregroundStyle(.ultraThinMaterial)
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(.white.opacity(0.1), lineWidth: 1.5)
                                    }
                            )
                        }
                        .padding()
                    }
                    .navigationTitle(chatTitle)
                    .toolbarRole(.editor)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
                                playHaptic()
                                showChats.toggle()
                            }) {
                                Image(systemName: "list.bullet")
                            }
                        }
                        
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                playHaptic()
                                showSettings.toggle()
                            }) {
                                Image(systemName: "gear")
                            }
                        }
                    }
                }
            }
        }
        .task {
            if appManager.installedModels.count == 0 {
                showOnboarding.toggle()
            } else {
                isPromptFocused = true
                // load the model
                if let modelName = appManager.currentModelName {
                    _ = try? await llm.load(modelName: modelName)
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if !showChats && gesture.startLocation.x < 20 && gesture.translation.width > 100 {
                        playHaptic()
                        showChats = true
                    }
                }
        )
        .sheet(isPresented: $showChats) {
            ChatsView(currentThread: $currentThread, isPromptFocused: $isPromptFocused)
                .environmentObject(appManager)
                .presentationDragIndicator(.hidden)
                .if(idiom == .phone) { view in
                    view.presentationDetents([.medium, .large])
                }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(currentThread: $currentThread)
                .environmentObject(appManager)
                .environment(llm)
                .presentationDragIndicator(.hidden)
                .if(idiom == .phone) { view in
                    view.presentationDetents([.medium])
                }
        }
        .sheet(isPresented: $showModelPicker) {
            NavigationStack {
                ModelsSettingsView()
                    .environment(llm)
            }
            .presentationDragIndicator(.visible)
            .if(idiom == .phone) { view in
                view.presentationDetents([.fraction(0.4)])
            }
        }
        .sheet(isPresented: $showOnboarding, onDismiss: dismissOnboarding) {
            OnboardingView(showOnboarding: $showOnboarding)
                .environment(llm)
                .interactiveDismissDisabled(appManager.installedModels.count == 0)
            
        }
        .tint(appManager.appTintColor.getColor())
        .fontDesign(appManager.appFontDesign.getFontDesign())
        .environment(\.dynamicTypeSize, appManager.appFontSize.getFontSize())
        .fontWidth(appManager.appFontWidth.getFontWidth())
    }
    
    var chatTitle: String {
        if let currentThread = currentThread {
            if let firstMessage = currentThread.sortedMessages.first {
                return firstMessage.content
            }
        }
        
        return "fullmoon"
    }

    private func generate() {
        if !prompt.isEmpty {
            if currentThread == nil {
                let newThread = Thread()
                currentThread = newThread
                modelContext.insert(newThread)
                try? modelContext.save()
            }
            
            if let currentThread = currentThread {
                Task {
                    let message = prompt
                    prompt = ""
                    playHaptic()
                    sendMessage(Message(role: .user, content: message, thread: currentThread))
                    isPromptFocused = true
                    if let modelName = appManager.currentModelName {
                        let output = await llm.generate(modelName: modelName, thread: currentThread, systemPrompt: appManager.systemPrompt)
                        sendMessage(Message(role: .assistant, content: output, thread: currentThread))
                    }
                }
            }
        }
    }
    
    private func sendMessage(_ message: Message) {
        playHaptic()
        modelContext.insert(message)
        try? modelContext.save()
    }
    
    func playHaptic() {
        #if !os(visionOS)
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()
        #endif
    }
    
    private func copyToClipboard(_ string: String) {
        UIPasteboard.general.string = string
    }
    
    func dismissOnboarding() {
        isPromptFocused = true
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
}
