import SwiftUI

struct LibraryBoardDetailView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    let boardID: String

    @State private var isSelectMode = false
    @State private var selectedItemIDs: Set<String> = []
    @State private var showActionSheet = false

    private var board: LibraryBoard? {
        appModel.boards.first(where: { $0.id == boardID })
    }

    var body: some View {
        Group {
            if let board {
                boardContent(board: board)
            } else {
                Color(hex: 0x111111)
                    .ignoresSafeArea()
                    .onAppear { dismiss() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func boardContent(board: LibraryBoard) -> some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
                let gap: CGFloat = 10
                let pad: CGFloat = 22
                let cW = geo.size.width - pad * 2
                let available = geo.size.height - 100 - pad * 2
                let rH = rowHeights(count: board.items.count, available: available, gap: gap)
                let wideW = (cW - gap) * 0.585
                let narrowW = cW - gap - wideW
                let halfW = (cW - gap) / 2
                let thirdW = (cW - gap * 2) / 3

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        boardHeader(board: board)

                        VStack(spacing: gap) {
                            selectableTile(board.items[safe: 0], w: cW, h: rH[0])

                            if board.items.count >= 3, rH.count > 1 {
                                HStack(spacing: gap) {
                                    selectableTile(board.items[safe: 1], w: wideW, h: rH[1])
                                    selectableTile(board.items[safe: 2], w: narrowW, h: rH[1])
                                }
                            }

                            if rH.count > 2 {
                                if board.items.count == 4 {
                                    selectableTile(board.items[safe: 3], w: cW, h: rH[2])
                                } else if board.items.count == 5 {
                                    HStack(spacing: gap) {
                                        selectableTile(board.items[safe: 3], w: halfW, h: rH[2])
                                        selectableTile(board.items[safe: 4], w: halfW, h: rH[2])
                                    }
                                } else if board.items.count >= 6 {
                                    HStack(spacing: gap) {
                                        selectableTile(board.items[safe: 3], w: thirdW, h: rH[2])
                                        selectableTile(board.items[safe: 4], w: thirdW, h: rH[2])
                                        selectableTile(board.items[safe: 5], w: thirdW, h: rH[2])
                                    }
                                }
                            }

                            if rH.count > 3 {
                                if board.items.count == 7 {
                                    selectableTile(board.items[safe: 6], w: cW, h: rH[3])
                                } else if board.items.count >= 8 {
                                    HStack(spacing: gap) {
                                        selectableTile(board.items[safe: 6], w: halfW, h: rH[3])
                                        selectableTile(board.items[safe: 7], w: halfW, h: rH[3])
                                    }
                                }
                            }
                        }

                        if isSelectMode {
                            Color.clear.frame(height: 80)
                        }
                    }
                    .padding(pad)
                }
                .scrollDisabled(board.items.count <= 8)
            }
            .background(Color(hex: 0x111111).ignoresSafeArea())

            if isSelectMode {
                selectionToolbar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isSelectMode)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showActionSheet) {
            BoardActionSheet(
                boardID: boardID,
                selectedItemIDs: selectedItemIDs,
                onComplete: {
                    showActionSheet = false
                    isSelectMode = false
                    selectedItemIDs = []
                }
            )
            .environmentObject(appModel)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(hex: 0x181818))
        }
    }

    @ViewBuilder
    private func boardHeader(board: LibraryBoard) -> some View {
        if isSelectMode {
            HStack {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        isSelectMode = false
                        selectedItemIDs = []
                    }
                }
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundStyle(.white)

                Spacer()

                Text(selectedItemIDs.isEmpty ? "Select Items" : "\(selectedItemIDs.count) Selected")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.default, value: selectedItemIDs.count)

                Spacer()

                Button(selectedItemIDs.count == board.items.count ? "Deselect All" : "Select All") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        if selectedItemIDs.count == board.items.count {
                            selectedItemIDs = []
                        } else {
                            selectedItemIDs = Set(board.items.map(\.id))
                        }
                    }
                }
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundStyle(.white.opacity(0.7))
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(board.promptTitle)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                    Text("\(board.itemCount) items • \(board.updatedAtLabel)")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    glassButton(systemName: "checkmark.circle") {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            isSelectMode = true
                        }
                    }
                    glassButton(systemName: "xmark") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func selectableTile(_ item: LibraryItem?, w: CGFloat, h: CGFloat) -> some View {
        let isSelected = item.map { selectedItemIDs.contains($0.id) } ?? false

        ZStack(alignment: .topTrailing) {
            LibraryTile(item: item, width: w, height: h, compactPreview: false)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: isSelectMode && isSelected ? 3 : 0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(isSelectMode && isSelected ? Color.accentColor.opacity(0.14) : .clear)
                )
                .scaleEffect(isSelectMode && isSelected ? 0.97 : 1.0)

            if isSelectMode {
                selectionBadge(isSelected: isSelected)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            if !isSelectMode, let item {
                NavigationLink(value: LibraryRoute.item(item.id)) { Color.clear }
            }
        }
        .onTapGesture {
            guard isSelectMode, let item else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                if selectedItemIDs.contains(item.id) {
                    selectedItemIDs.remove(item.id)
                } else {
                    selectedItemIDs.insert(item.id)
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isSelectMode)
    }

    private func selectionBadge(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.black.opacity(0.45))
                .frame(width: 26, height: 26)
                .overlay(
                    Circle().stroke(Color.white.opacity(isSelected ? 0 : 0.85), lineWidth: 1.5)
                )

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .transition(.scale.combined(with: .opacity))
    }

    private var selectionToolbar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)

            HStack {
                Text(
                    selectedItemIDs.isEmpty
                        ? "Tap items to select"
                        : "\(selectedItemIDs.count) item\(selectedItemIDs.count == 1 ? "" : "s") selected"
                )
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundStyle(selectedItemIDs.isEmpty ? .white.opacity(0.45) : .white)
                .contentTransition(.numericText())
                .animation(.default, value: selectedItemIDs.count)

                Spacer()

                Button {
                    showActionSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(selectedItemIDs.isEmpty ? .white.opacity(0.28) : .white)
                        .frame(width: 44, height: 44)
                }
                .disabled(selectedItemIDs.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
    }

    private func glassButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(LinearGradient(
                    colors: [.white.opacity(0.2), .white.opacity(0.06)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                )
        }
        .buttonStyle(.plain)
    }

    private func rowHeights(count: Int, available: CGFloat, gap: CGFloat) -> [CGFloat] {
        let (weights, numGaps): ([CGFloat], Int)
        switch count {
        case 4:  (weights, numGaps) = ([0.40, 0.32, 0.28], 2)
        case 5:  (weights, numGaps) = ([0.40, 0.32, 0.28], 2)
        case 6:  (weights, numGaps) = ([0.36, 0.30, 0.34], 2)
        case 7:  (weights, numGaps) = ([0.32, 0.26, 0.20, 0.22], 3)
        default: (weights, numGaps) = ([0.34, 0.26, 0.20, 0.20], 3)
        }
        let usable = available - CGFloat(numGaps) * gap
        return weights.map { max(60, usable * $0) }
    }
}

// MARK: - Board Action Sheet

private struct BoardActionSheet: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var sheetDismiss
    let boardID: String
    let selectedItemIDs: Set<String>
    let onComplete: () -> Void

    @State private var actionMode: ActionMode = .move
    @State private var showBoardPicker = false

    enum ActionMode { case move, copy }

    private var otherBoards: [LibraryBoard] {
        appModel.boards.filter { $0.id != boardID }
    }

    var body: some View {
        NavigationStack {
            choicesView
                .navigationDestination(isPresented: $showBoardPicker) {
                    boardPickerView
                }
        }
    }

    private var choicesView: some View {
        VStack(spacing: 0) {
            Text("\(selectedItemIDs.count) Item\(selectedItemIDs.count == 1 ? "" : "s") Selected")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundStyle(.white)
                .padding(.top, 32)
                .padding(.bottom, 6)

            Text("What would you like to do?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.bottom, 28)

            VStack(spacing: 10) {
                actionRow(
                    icon: "arrow.right.square.fill",
                    label: "Move to Board",
                    subtitle: "Remove from here and add to another board"
                ) {
                    actionMode = .move
                    showBoardPicker = true
                }

                actionRow(
                    icon: "plus.square.on.square.fill",
                    label: "Copy to Board",
                    subtitle: "Keep here and duplicate into another board"
                ) {
                    actionMode = .copy
                    showBoardPicker = true
                }

                actionRow(
                    icon: "trash.fill",
                    label: "Remove from Board",
                    subtitle: "Delete selected items from this board",
                    destructive: true
                ) {
                    appModel.removeItems(itemIDs: selectedItemIDs, from: boardID)
                    onComplete()
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            Button("Cancel") { sheetDismiss() }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.bottom, 24)
        }
        .background(Color(hex: 0x181818))
        .toolbar(.hidden, for: .navigationBar)
    }

    private var boardPickerView: some View {
        VStack(spacing: 0) {
            Text(actionMode == .move ? "Move to Board" : "Copy to Board")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundStyle(.white)
                .padding(.top, 8)
                .padding(.bottom, 4)

            Text(actionMode == .move ? "Items will be removed from this board" : "Items will remain in this board")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(otherBoards) { board in
                        Button {
                            if actionMode == .move {
                                appModel.moveItems(itemIDs: selectedItemIDs, from: boardID, to: board.id)
                            } else {
                                appModel.copyItems(itemIDs: selectedItemIDs, from: boardID, to: board.id)
                            }
                            onComplete()
                        } label: {
                            HStack(spacing: 14) {
                                PreviewGrid(items: board.previewItems, height: 60)
                                    .frame(width: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .allowsHitTesting(false)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(board.promptTitle)
                                        .font(.system(size: 15, weight: .semibold, design: .default))
                                        .foregroundStyle(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text("\(board.itemCount) item\(board.itemCount == 1 ? "" : "s")")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.5))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color(hex: 0x181818))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showBoardPicker = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    private func actionRow(icon: String, label: String, subtitle: String, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(destructive ? .red : .white)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundStyle(destructive ? .red : .white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if !destructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
