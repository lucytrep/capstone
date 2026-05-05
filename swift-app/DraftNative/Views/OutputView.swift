import SwiftUI
import WebKit

struct OutputView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WebArtifactView(html: appModel.artifactHTML)
                    .ignoresSafeArea(edges: .bottom)

                HStack(spacing: 12) {
                    Button("Start Over") {
                        appModel.resetSession()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Done") {
                        appModel.dismissFlow()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
                .background(Color.black)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Artifact")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct WebArtifactView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
