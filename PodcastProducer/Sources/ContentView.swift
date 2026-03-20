import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("scriptPath") private var scriptPath = ""
    @State private var riversideWav = ""
    @State private var rodeMicWav = ""
    @State private var rodeStereoWav = ""
    @State private var outputDir = ""
    @State private var lumixVideos: [String] = []
    @State private var copied = false

    private var isValid: Bool {
        !riversideWav.isEmpty && !rodeMicWav.isEmpty &&
        !rodeStereoWav.isEmpty && !outputDir.isEmpty &&
        !lumixVideos.isEmpty && !scriptPath.isEmpty
    }

    private var cliCommand: String {
        guard isValid else { return "" }
        var parts = ["time", scriptPath]
        parts.append(contentsOf: ["\\\n  --riverside-speaker-1", "\"\(riversideWav)\""])
        parts.append(contentsOf: ["\\\n  --rode-mic-speaker-1", "\"\(rodeMicWav)\""])
        parts.append(contentsOf: ["\\\n  --rode-stereo-all-tracks", "\"\(rodeStereoWav)\""])
        parts.append(contentsOf: ["\\\n  --output-dir", "\"\(outputDir)\""])
        for video in lumixVideos {
            parts.append(contentsOf: ["\\\n  --lumix", "\"\(video)\""])
        }
        return parts.joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    audioSection
                    Divider()
                    videoSection
                    Divider()
                    outputSection
                    Divider()
                    cliSection
                }
                .padding(24)
            }

            Divider()
            actionBar
        }
        .frame(minWidth: 720, minHeight: 500)
        .onAppear(perform: autoDetectScript)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Podcast Producer")
                    .font(.title2.bold())
                Text("Domovina.tv — Audio/Video Sync")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Audio Section

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Audio Sources", systemImage: "waveform")
                .font(.headline)
            FileField(label: "Riverside Speaker 1", path: $riversideWav, types: [.wav])
            FileField(label: "Rode Mic Speaker 1", path: $rodeMicWav, types: [.wav])
            FileField(label: "Rode Stereo All Tracks", path: $rodeStereoWav, types: [.wav])
        }
    }

    // MARK: - Video Section

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("LUMIX Video Files", systemImage: "video")
                .font(.headline)

            if lumixVideos.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "film.stack")
                            .font(.title2)
                            .foregroundStyle(.quaternary)
                        Text("Drag & drop video files here or click Add")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(Array(lumixVideos.enumerated()), id: \.offset) { index, path in
                    HStack(spacing: 8) {
                        Image(systemName: "film")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .fontWeight(.medium)
                            Text(path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                        Spacer()
                        Button {
                            lumixVideos.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Button {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.quickTimeMovie, .mpeg4Movie]
                panel.allowsMultipleSelection = true
                panel.canChooseDirectories = false
                panel.message = "Select LUMIX video files"
                if panel.runModal() == .OK {
                    lumixVideos.append(contentsOf: panel.urls.map(\.path))
                }
            } label: {
                Label("Add Video Files", systemImage: "plus.circle")
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            let validExts = ["mov", "mp4", "m4v"]
            let valid = urls.filter { validExts.contains($0.pathExtension.lowercased()) }
            lumixVideos.append(contentsOf: valid.map(\.path))
            return !valid.isEmpty
        }
    }

    // MARK: - Output Section

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Output", systemImage: "folder")
                .font(.headline)
            HStack {
                Text("Directory")
                    .frame(width: 180, alignment: .trailing)
                    .font(.callout)
                TextField("Select output directory...", text: $outputDir)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout)
                Button("Browse") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK {
                        outputDir = panel.url?.path ?? ""
                    }
                }
            }
        }
    }

    // MARK: - CLI Command Section

    private var cliSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("CLI Command", systemImage: "terminal")
                    .font(.headline)
                Spacer()
                if isValid {
                    Button {
                        copyToClipboard()
                    } label: {
                        Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(copied ? .green : .secondary)
                }
            }

            if isValid {
                Text(cliCommand)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Text("Fill in all fields to generate the command.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: scriptPath.isEmpty ? "xmark.circle" : "checkmark.circle.fill")
                    .foregroundStyle(scriptPath.isEmpty ? .red : .green)
                    .font(.caption)
                Text(scriptPath.isEmpty ? "Script not found" : scriptPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if scriptPath.isEmpty {
                    Button("Locate") { locateScript() }
                        .font(.caption)
                }
            }

            Spacer()

            Button {
                copyToClipboard()
            } label: {
                Label(copied ? "Copied!" : "Copy to Clipboard", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            .disabled(!isValid)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Logic

    private func autoDetectScript() {
        if !scriptPath.isEmpty && FileManager.default.fileExists(atPath: scriptPath) { return }

        let cwd = FileManager.default.currentDirectoryPath
        let candidates = [
            cwd + "/podcast_sync.sh",
            cwd + "/../podcast_sync.sh",
            NSHomeDirectory() + "/git/domovinatv/producer.domovina.tv/podcast_sync.sh",
        ]

        for path in candidates {
            let resolved = (path as NSString).standardizingPath
            if FileManager.default.fileExists(atPath: resolved) {
                scriptPath = resolved
                return
            }
        }
    }

    private func locateScript() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.shellScript]
        panel.message = "Locate podcast_sync.sh"
        if panel.runModal() == .OK {
            scriptPath = panel.url?.path ?? ""
        }
    }

    private func copyToClipboard() {
        guard isValid else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cliCommand, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

// MARK: - Reusable Components

struct FileField: View {
    let label: String
    @Binding var path: String
    let types: [UTType]

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 180, alignment: .trailing)
                .font(.callout)
            TextField("Select file...", text: $path)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
            Button("Browse") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = types
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if panel.runModal() == .OK {
                    path = panel.url?.path ?? ""
                }
            }
        }
    }
}
