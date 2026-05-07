import SwiftUI

public struct VocabularySheetView: View {
    @StateObject var viewModel: VocabularySheetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingWord = false
    @State private var editText = ""
    @FocusState private var wordFieldFocused: Bool

    public var body: some View {
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    if viewModel.canGoBack {
                        Button {
                            viewModel.goBack()
                            isEditingWord = false
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.trailing, 4)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    if isEditingWord {
                        TextField("Look up word…", text: $editText)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                            .focused($wordFieldFocused)
                            .submitLabel(.search)
                            .onSubmit { commitEdit() }
                            .transition(.opacity)

                        Button { commitEdit() } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.leading, 6)

                        Button { cancelEdit() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 4)
                    } else {
                        Text(viewModel.word)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                            .contentTransition(.opacity)

                        Button {
                            viewModel.playPronunciation()
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.leading, 8)

                        Button { startEdit() } label: {
                            Image(systemName: "pencil")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 6)
                    }

                    Spacer()

                    if !isEditingWord {
                        Button {
                            Task { await viewModel.toggleSave() }
                        } label: {
                            Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                                .font(.title3)
                                .foregroundColor(viewModel.isSaved ? .accentColor : .secondary)
                        }
                        .disabled(viewModel.entry == nil && !viewModel.isSaved)
                        .padding(.leading, 8)
                    }
                }
                .padding()
                .padding(.top, 12)
                .animation(.easeInOut(duration: 0.2), value: isEditingWord)
                .animation(.easeInOut(duration: 0.22), value: viewModel.canGoBack)

                Divider()

                // Root word suggestion banner
                if let root = viewModel.suggestedRootWord {
                    Button {
                        Task { await viewModel.lookUp(root) }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.turn.up.left")
                                .font(.caption)
                            Text("Inflected form of")
                                .font(.caption)
                            Text(root)
                                .font(.caption.bold())
                                .underline()
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.06))
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Divider()
                        .transition(.opacity)
                }

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.top, 40)
                                Spacer()
                            }
                            .transition(.opacity)
                        } else if let error = viewModel.error {
                            Text(error)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        } else if let entry = viewModel.entry {
                            ForEach(entry.entries, id: \.partOfSpeech) { dictEntry in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Text(dictEntry.partOfSpeech.uppercased())
                                            .font(.caption.bold())
                                            .foregroundColor(.accentColor)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.accentColor.opacity(0.1))
                                            .cornerRadius(8)

                                        if let phonetics = dictEntry.pronunciations?.compactMap({
                                            $0.text
                                        }).first {
                                            Text(phonetics)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    ForEach(Array(dictEntry.senses.enumerated()), id: \.offset) {
                                        index, sense in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(alignment: .top) {
                                                Text("\(index + 1).")
                                                    .font(.subheadline.bold())
                                                    .foregroundColor(.secondary)

                                                Text(sense.definition)
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                            }

                                            if let examples = sense.examples, !examples.isEmpty {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    ForEach(examples, id: \.self) { example in
                                                        Text("\"\(example)\"")
                                                            .font(.subheadline)
                                                            .foregroundColor(.secondary)
                                                            .italic()
                                                            .padding(.leading, 20)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)

                                if dictEntry.partOfSpeech != entry.entries.last?.partOfSpeech {
                                    Divider()
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.25), value: viewModel.isLoading)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.word)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: viewModel.suggestedRootWord)
        }
        .edgesIgnoringSafeArea(.bottom)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    private func startEdit() {
        editText = viewModel.word
        isEditingWord = true
        wordFieldFocused = true
    }

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditingWord = false
        wordFieldFocused = false
        guard !trimmed.isEmpty else { return }
        Task { await viewModel.lookUp(trimmed) }
    }

    private func cancelEdit() {
        isEditingWord = false
        wordFieldFocused = false
        editText = ""
    }
}
