# NetworkSpectator Example App

This example app demonstrates how to integrate and use the NetworkSpectator library to observe, log, and inspect network activity across iOS and macOS. It includes a simple UI that triggers sample network calls and presents a built-in logging interface powered by NetworkSpectator.

## Features

- Simple SwiftUI interface to trigger mock/service calls
- Cross-platform logging UI
  - iOS: Presents NetworkSpectator logs in a sheet
  - macOS: Opens NetworkSpectator in a dedicated window
- Demonstrates how to:
  - Initialize and present the NetworkSpectator UI
  - Register mock network responses for testing
  - Skip logging for selected calls
  - Organize and view captured requests/responses

## How It Works

- The main view (ContentView) offers two primary actions:
  - “Call Services”: Triggers sample network calls using a ViewModel to demonstrate how requests and responses are captured by NetworkSpectator.
  - “Show Logs”: Presents NetworkSpectator’s UI so you can browse, filter, and inspect the logged calls.
- On appearance, the app configures the demo environment by optionally skipping certain logs and registering mock responses.

### Code Highlight

```swift
VStack {
    Text("Hello, Network Spectator!")
        .padding(10)

    Button("Call Services") {
        Task {
            await viewModel.callServices()
        }
    }
    .padding(10)

    Button("Show Logs") {
        #if os(macOS)
        openWindow(id: "NetworkSpectator")
        #else
        showLogs.toggle()
        #endif
    }
    .padding(10)
}
.onAppear {
    viewModel.skipLogging()
    viewModel.registerMock()
}
#if os(iOS)
.sheet(isPresented: $showLogs) {
    NetworkSpectator.rootView
}
#endif
