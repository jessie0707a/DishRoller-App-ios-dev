//
//  StorageView.swift
//  DishRoller
//
//  Created by Jess Su on 5/5/2026.
//

import SwiftUI
import UIKit

struct StorageView: View {
    @EnvironmentObject private var appVM: AppViewModel

    @State private var showScannerPlaceholder = false
    @State private var addFoodSheetContext: AddFoodSheetContext?
    @State private var editorContext: IngredientEditorContext?
    @State private var pendingDeleteIngredient: Ingredient?

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    searchPanel
                    categoryFilters

                    LazyVGrid(columns: gridColumns, spacing: 14) {
                        ForEach(appVM.storageVM.filteredIngredients) { ingredient in
                            IngredientCardView(
                                ingredient: ingredient,
                                onEdit: {
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                        editorContext = IngredientEditorContext(ingredientID: ingredient.id)
                                    }
                                }
                            )
                            .onLongPressGesture {
                                pendingDeleteIngredient = ingredient
                            }
                        }
                    }

                    if appVM.storageVM.filteredIngredients.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 92)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(storageBackground)
            .overlay(alignment: .bottomTrailing) {
                addFoodButton
            }
        }
        .sheet(item: $addFoodSheetContext) { context in
            AddFoodItemSheet(storageVM: appVM.storageVM, initialFoodName: context.initialName)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .overlay {
            if let editorContext {
                IngredientPurchaseEditorOverlay(
                    storageVM: appVM.storageVM,
                    initialIngredientID: editorContext.ingredientID,
                    onClose: closeEditor
                )
                .transition(.scale(scale: 0.78, anchor: .bottomTrailing).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: editorContext?.id)
        .confirmationDialog(
            "Delete this storage card?",
            isPresented: Binding(
                get: { pendingDeleteIngredient != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeleteIngredient = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let ingredient = pendingDeleteIngredient {
                Button("Delete \(ingredient.name)", role: .destructive) {
                    appVM.storageVM.delete(ingredient)
                    pendingDeleteIngredient = nil
                }
            }
            Button("Cancel") {
                pendingDeleteIngredient = nil
            }
        } message: {
            if let ingredient = pendingDeleteIngredient {
                Text("This will remove the \(ingredient.name) record with \(formattedAmount(for: ingredient)).")
            }
        }
        .alert("Camera scan", isPresented: $showScannerPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Camera scanning will match purchased items to storage or create a new item card in a future version.")
        }
    }

    private var addFoodButton: some View {
        Button {
            openAddFoodSheet()
        } label: {
            Image(systemName: "plus")
                .font(.title.weight(.black))
                .foregroundColor(.black)
                .frame(width: 62, height: 62)
                .background(Color.yellow)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add food item")
        .padding(.trailing, 22)
        .padding(.bottom, 104)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Food Storage")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer()

            NavigationLink {
                OnlineShoppingView(storageVM: appVM.storageVM)
            } label: {
                Image(systemName: "cart")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)
                    .frame(width: 72, height: 48)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
        }
    }

    private var searchPanel: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.gray.opacity(0.85))

                TextField("Search", text: $appVM.storageVM.searchText)
                    .font(.subheadline.weight(.semibold))
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(false)

                if !appVM.storageVM.searchText.isEmpty {
                    Button {
                        appVM.storageVM.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .clipShape(Capsule())

            Button {
                showScannerPlaceholder = true
            } label: {
                Image(systemName: "camera.viewfinder")
                    .font(.title3.weight(.black))
                    .foregroundColor(.black)
                    .frame(width: 54, height: 54)
                    .background(Color.yellow)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Scan purchased items")
        }
    }

    private var categoryFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.black)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    filterChip(title: "All", icon: "square.grid.2x2.fill", category: nil)

                    ForEach(IngredientCategory.allCases) { category in
                        filterChip(
                            title: category.displayTitle,
                            icon: category.categoryIcon,
                            category: category
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func filterChip(title: String, icon: String, category: IngredientCategory?) -> some View {
        let isSelected = appVM.storageVM.selectedFilter == category

        return Button {
            appVM.storageVM.selectedFilter = category
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.black))
                Text(title)
                    .font(.caption)
                    .fontWeight(.black)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .black : .gray)
            .padding(.horizontal, 13)
            .frame(height: 34)
            .background(isSelected ? Color.yellow : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.yellow : Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        let searchName = searchedFoodName

        return VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.gray)

            Text("No items found")
                .font(.headline)
                .fontWeight(.black)

            Text("Try another search or category.")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            if let searchName {
                Button {
                    openAddFoodSheet(initialName: searchName)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.black))
                        Text("Add Item")
                            .font(.subheadline.weight(.black))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 18)
                    .frame(height: 42)
                    .background(Color.yellow)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add \(searchName)")
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var searchedFoodName: String? {
        let cleanSearch = appVM.storageVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanSearch.isEmpty ? nil : cleanSearch
    }

    private var storageBackground: Color {
        Color(red: 0.96, green: 0.95, blue: 0.98)
    }

    private func formattedAmount(for ingredient: Ingredient) -> String {
        let value = ingredient.amount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(ingredient.amount))
            : String(format: "%.1f", ingredient.amount)
        return "\(value) \(ingredient.unit.rawValue)"
    }

    private func closeEditor() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            editorContext = nil
        }
    }

    private func openAddFoodSheet(initialName: String = "") {
        addFoodSheetContext = AddFoodSheetContext(initialName: initialName)
    }
}

private struct AddFoodSheetContext: Identifiable {
    let id = UUID()
    let initialName: String
}

private struct IngredientEditorContext: Identifiable {
    let ingredientID: UUID

    var id: UUID { ingredientID }
}

private struct IngredientPurchaseEditorOverlay: View {
    @ObservedObject var storageVM: StorageViewModel
    let initialIngredientID: UUID
    let onClose: () -> Void

    @State private var isCreatingRecord = false
    @State private var selectedRecordID: UUID?

    private var initialIngredient: Ingredient? {
        storageVM.ingredients.first { $0.id == initialIngredientID }
    }

    private var purchaseRecords: [Ingredient] {
        guard let initialIngredient else { return [] }
        return storageVM.matchingPurchaseRecords(for: initialIngredient)
    }

    private var activeTemplateIngredient: Ingredient? {
        if let selectedRecordID,
           let selectedRecord = purchaseRecords.first(where: { $0.id == selectedRecordID }) {
            return selectedRecord
        }
        return initialIngredient
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.18))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }

            if let initialIngredient {
                Group {
                    if isCreatingRecord, let activeTemplateIngredient {
                        NewPurchaseRecordPage(
                            templateIngredient: activeTemplateIngredient,
                            storageVM: storageVM,
                            onCancel: onClose,
                            onCreated: { newRecord in
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                    selectedRecordID = newRecord.id
                                    isCreatingRecord = false
                                }
                            }
                        )
                    } else if purchaseRecords.isEmpty {
                        Text("This item is no longer available.")
                            .font(.headline.weight(.black))
                            .foregroundColor(.black)
                            .padding(24)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
                    } else {
                        TabView(selection: $selectedRecordID) {
                            ForEach(purchaseRecords) { record in
                                PurchaseRecordEditorPage(
                                    ingredient: record,
                                    storageVM: storageVM,
                                    onAddNew: {
                                        showNewRecordPage()
                                    },
                                    onCancel: onClose,
                                    onFinished: onClose
                                )
                                .tag(Optional(record.id))
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: purchaseRecords.count > 1 ? .automatic : .never))
                        .onAppear {
                            if selectedRecordID == nil {
                                selectedRecordID = initialIngredient.id
                            }
                        }
                    }
                }
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            } else {
                Text("This item is no longer available.")
                    .font(.headline.weight(.black))
                    .foregroundColor(.black)
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
            }
        }
    }

    private func showNewRecordPage() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            isCreatingRecord = true
        }
    }
}

private enum QuantityEditMode {
    case addition
    case subtraction
}

private enum EditorControl: Hashable {
    case name
    case amount
    case unit
    case expiryDate
}

private struct PurchaseRecordEditorPage: View {
    let ingredient: Ingredient
    @ObservedObject var storageVM: StorageViewModel
    let onAddNew: () -> Void
    let onCancel: () -> Void
    let onFinished: () -> Void

    @State private var amountText: String
    @State private var itemNameText: String
    @State private var selectedUnit: UnitType
    @State private var expiryDate: Date
    @State private var quantityEditMode: QuantityEditMode?
    @State private var originalAmountBeforeQuantityEdit: Double
    @State private var showDeleteConfirmation = false
    @State private var validationMessage: String?
    @State private var activeControl: EditorControl?
    @FocusState private var focusedControl: EditorControl?

    init(
        ingredient: Ingredient,
        storageVM: StorageViewModel,
        onAddNew: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onFinished: @escaping () -> Void
    ) {
        self.ingredient = ingredient
        self.storageVM = storageVM
        self.onAddNew = onAddNew
        self.onCancel = onCancel
        self.onFinished = onFinished
        _amountText = State(initialValue: Self.formattedAmount(ingredient.amount))
        _itemNameText = State(initialValue: ingredient.name)
        _selectedUnit = State(initialValue: ingredient.unit)
        _expiryDate = State(initialValue: ingredient.expiryDate ?? Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date())
        _originalAmountBeforeQuantityEdit = State(initialValue: ingredient.amount)
    }

    var body: some View {
        PurchaseEditorCard(onBackgroundTap: onCancel) {
            VStack(spacing: 10) {
                editorHeader(
                    category: ingredient.category,
                    expiryDate: expiryDate,
                    onDelete: { showDeleteConfirmation = true }
                )
                editorImage(for: ingredient)

                TextField("Food name", text: $itemNameText)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(false)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .focused($focusedControl, equals: .name)
                    .editorInputStyle(maxWidth: 220, height: 42, isActive: isControlActive(.name))
                    .tint(.black)

                HStack(spacing: 12) {
                    quantityButton(
                        systemName: leadingQuantityButtonIcon,
                        background: quantityEditMode == .subtraction ? Color.black : Color(.systemGray4),
                        foreground: quantityEditMode == .subtraction ? Color.yellow : Color.black
                    ) {
                        handleLeadingQuantityButton()
                    }

                    TextField(quantityPlaceholder, text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 20, weight: .black))
                        .focused($focusedControl, equals: .amount)
                        .editorInputStyle(width: 96, height: 44, isActive: isControlActive(.amount))
                        .tint(.black)

                    unitMenu

                    quantityButton(
                        systemName: trailingQuantityButtonIcon,
                        background: quantityEditMode == .addition ? Color.black : Color(.systemGray4),
                        foreground: quantityEditMode == .addition ? Color.yellow : Color.black
                    ) {
                        handleTrailingQuantityButton()
                    }
                }

                expiryEditor(
                    title: "Expired Date:",
                    expiryDate: $expiryDate,
                    isActive: isControlActive(.expiryDate),
                    onSelect: {
                        activeControl = .expiryDate
                        focusedControl = nil
                    }
                )

                Button {
                    saveChanges()
                } label: {
                    Text("Finished")
                        .primaryPillStyle(background: .yellow, foreground: .black)
                }
                .buttonStyle(.plain)

                Button {
                    onAddNew()
                } label: {
                    Text("Add New")
                        .primaryPillStyle(background: .black, foreground: .yellow)
                }
                .buttonStyle(.plain)

                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .outlinePillStyle()
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: focusedControl) { _, newValue in
            if let newValue {
                activeControl = newValue
            }
        }
        .alert("Check item details", isPresented: Binding(
            get: { validationMessage != nil },
            set: { _ in validationMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage ?? "")
        }
        .confirmationDialog(
            "Delete this card?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(ingredient.name)", role: .destructive) {
                storageVM.delete(ingredient)
                onFinished()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete this storage card.")
        }
    }

    private var unitMenu: some View {
        Menu {
            ForEach(UnitType.allCases) { unit in
                Button(unit.rawValue) {
                    selectedUnit = unit
                    activeControl = .unit
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedUnit.rawValue)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.black)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.black))
                    .foregroundColor(.black)
            }
            .editorInputStyle(width: 74, height: 44, isActive: isControlActive(.unit))
        }
        .simultaneousGesture(TapGesture().onEnded {
            activeControl = .unit
            focusedControl = nil
        })
    }

    private func isControlActive(_ control: EditorControl) -> Bool {
        focusedControl == control || activeControl == control
    }

    private var leadingQuantityButtonIcon: String {
        switch quantityEditMode {
        case .addition:
            "xmark"
        case .subtraction:
            "checkmark"
        case nil:
            "minus"
        }
    }

    private var trailingQuantityButtonIcon: String {
        switch quantityEditMode {
        case .addition:
            "checkmark"
        case .subtraction:
            "xmark"
        case nil:
            "plus"
        }
    }

    private var quantityPlaceholder: String {
        switch quantityEditMode {
        case .addition:
            "Add"
        case .subtraction:
            "Reduce"
        case nil:
            "150"
        }
    }

    private func handleLeadingQuantityButton() {
        switch quantityEditMode {
        case .addition:
            cancelQuantityEdit()
        case .subtraction:
            finishQuantityEdit()
        case nil:
            startQuantityEdit(.subtraction)
        }
    }

    private func handleTrailingQuantityButton() {
        switch quantityEditMode {
        case .addition:
            finishQuantityEdit()
        case .subtraction:
            cancelQuantityEdit()
        case nil:
            startQuantityEdit(.addition)
        }
    }

    private func adjustAmount(by delta: Double) {
        let currentValue = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let nextValue = max(step(for: selectedUnit), currentValue + delta)
        amountText = Self.formattedAmount(nextValue)
    }

    private func startQuantityEdit(_ mode: QuantityEditMode) {
        originalAmountBeforeQuantityEdit = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        amountText = ""
        quantityEditMode = mode
    }

    private func finishQuantityEdit() {
        guard let quantityEditMode else { return }
        let enteredAmount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard enteredAmount > 0 else {
            validationMessage = quantityEditMode == .addition
            ? "Please enter an amount to add."
            : "Please enter an amount to reduce."
            return
        }

        let nextValue: Double
        switch quantityEditMode {
        case .addition:
            nextValue = originalAmountBeforeQuantityEdit + enteredAmount
        case .subtraction:
            nextValue = originalAmountBeforeQuantityEdit - enteredAmount
        }

        guard nextValue >= 0 else {
            validationMessage = "Please reduce by no more than the current quantity."
            return
        }

        amountText = Self.formattedAmount(nextValue)
        originalAmountBeforeQuantityEdit = nextValue
        self.quantityEditMode = nil
    }

    private func cancelQuantityEdit() {
        amountText = Self.formattedAmount(originalAmountBeforeQuantityEdit)
        quantityEditMode = nil
    }

    private func saveChanges() {
        if quantityEditMode != nil {
            finishQuantityEdit()
            guard quantityEditMode == nil else { return }
        }

        let cleanName = itemNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard !cleanName.isEmpty else {
            validationMessage = "Please enter a food name."
            return
        }

        guard amount >= 0 else {
            validationMessage = "Please enter a valid quantity."
            return
        }

        storageVM.updateIngredientRecord(
            id: ingredient.id,
            name: cleanName,
            amount: amount,
            unit: selectedUnit,
            expiryDate: expiryDate
        )
        onFinished()
    }

    private static func formattedAmount(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(value))
        : String(format: "%.1f", value)
    }
}

private struct NewPurchaseRecordPage: View {
    let templateIngredient: Ingredient
    @ObservedObject var storageVM: StorageViewModel
    let onCancel: () -> Void
    let onCreated: (Ingredient) -> Void

    @State private var amountText = ""
    @State private var itemNameText: String
    @State private var selectedUnit: UnitType
    @State private var expiryDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var validationMessage: String?
    @State private var activeControl: EditorControl?
    @FocusState private var focusedControl: EditorControl?

    init(
        templateIngredient: Ingredient,
        storageVM: StorageViewModel,
        onCancel: @escaping () -> Void,
        onCreated: @escaping (Ingredient) -> Void
    ) {
        self.templateIngredient = templateIngredient
        self.storageVM = storageVM
        self.onCancel = onCancel
        self.onCreated = onCreated
        _itemNameText = State(initialValue: templateIngredient.name)
        _selectedUnit = State(initialValue: templateIngredient.unit)
    }

    var body: some View {
        PurchaseEditorCard(onBackgroundTap: onCancel) {
            VStack(spacing: 10) {
                editorHeader(category: templateIngredient.category, expiryDate: expiryDate)
                editorImage(for: templateIngredient)

                TextField("Food name", text: $itemNameText)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(false)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .focused($focusedControl, equals: .name)
                    .editorInputStyle(maxWidth: 220, height: 42, isActive: isControlActive(.name))
                    .tint(.black)

                HStack(spacing: 12) {
                    quantityButton(systemName: "minus", background: Color(.systemGray4)) {
                        adjustAmount(by: -step(for: selectedUnit))
                    }

                    TextField("New quantity", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 20, weight: .black))
                        .focused($focusedControl, equals: .amount)
                        .editorInputStyle(width: 96, height: 44, isActive: isControlActive(.amount))
                        .tint(.black)

                    Menu {
                        ForEach(UnitType.allCases) { unit in
                            Button(unit.rawValue) {
                                selectedUnit = unit
                                activeControl = .unit
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(selectedUnit.rawValue)
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(.black)

                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.black))
                                .foregroundColor(.black)
                        }
                        .editorInputStyle(width: 74, height: 44, isActive: isControlActive(.unit))
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        activeControl = .unit
                        focusedControl = nil
                    })

                    quantityButton(systemName: "plus", background: Color(.systemGray4)) {
                        adjustAmount(by: step(for: selectedUnit))
                    }
                }

                expiryEditor(
                    title: "Expired Date:",
                    expiryDate: $expiryDate,
                    isActive: isControlActive(.expiryDate),
                    onSelect: {
                        activeControl = .expiryDate
                        focusedControl = nil
                    }
                )

                Button {
                    createRecord()
                } label: {
                    Text("Create New Card")
                        .primaryPillStyle(background: .yellow, foreground: .black)
                }
                .buttonStyle(.plain)

                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .outlinePillStyle()
                }
                .buttonStyle(.plain)
            }
        }
        .onChange(of: focusedControl) { _, newValue in
            if let newValue {
                activeControl = newValue
            }
        }
        .alert("Check item details", isPresented: Binding(
            get: { validationMessage != nil },
            set: { _ in validationMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage ?? "")
        }
    }

    private func isControlActive(_ control: EditorControl) -> Bool {
        focusedControl == control || activeControl == control
    }

    private func adjustAmount(by delta: Double) {
        let currentValue = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let nextValue = max(step(for: selectedUnit), currentValue + delta)
        amountText = nextValue.truncatingRemainder(dividingBy: 1) == 0
        ? String(Int(nextValue))
        : String(format: "%.1f", nextValue)
    }

    private func createRecord() {
        let cleanName = itemNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard !cleanName.isEmpty else {
            validationMessage = "Please enter a food name."
            return
        }

        guard amount > 0 else {
            validationMessage = "Please enter a quantity greater than 0."
            return
        }

        guard let newRecord = storageVM.addIngredientRecord(
            name: cleanName,
            category: templateIngredient.category,
            amount: amount,
            unit: selectedUnit,
            iconName: templateIngredient.iconName ?? templateIngredient.category.foodIconAssetName,
            imageData: templateIngredient.imageData,
            expiryDate: expiryDate
        ) else {
            validationMessage = "Please enter valid item details."
            return
        }
        onCreated(newRecord)
    }
}

private struct PurchaseEditorCard<Content: View>: View {
    let onBackgroundTap: (() -> Void)?
    @ViewBuilder let content: () -> Content

    init(
        onBackgroundTap: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onBackgroundTap = onBackgroundTap
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(proxy.size.width - 32, 390)
            let cardHeight = min(proxy.size.height - 44, 626)

            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onBackgroundTap?()
                    }

                content()
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .frame(width: cardWidth, height: cardHeight)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.2), radius: 24, y: 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private func editorHeader(
    category: IngredientCategory,
    expiryDate: Date,
    onDelete: (() -> Void)? = nil
) -> some View {
    HStack(alignment: .center) {
        Text(category.rawValue)
            .font(.system(size: 19, weight: .black))
            .foregroundColor(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .padding(.horizontal, 14)
            .frame(minWidth: 104)
            .frame(height: 40)
            .background(daysUntilExpiry(for: expiryDate) < 0 ? Color(.systemGray4) : Color.yellow)
            .clipShape(Capsule())

        Spacer()

        Text(expiryStatusText(for: expiryDate))
            .font(.system(size: 18, weight: .black))
            .foregroundColor(daysUntilExpiry(for: expiryDate) <= 1 ? Color(red: 0.89, green: 0.22, blue: 0.2) : .black)
            .lineLimit(1)
            .minimumScaleFactor(0.65)

        if let onDelete {
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color(red: 0.89, green: 0.22, blue: 0.2))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete storage card")
        }
    }
}

private func editorImage(for ingredient: Ingredient) -> some View {
    ZStack {
        Circle()
            .fill(Color(red: 0.95, green: 0.72, blue: 0.72).opacity(0.45))
            .frame(width: 152, height: 152)

        if let imageData = ingredient.imageData,
           let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 132, height: 132)
                .clipShape(Circle())
        } else {
            Image(ingredient.iconName ?? ingredient.category.foodIconAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 126, height: 126)
        }
    }
    .frame(maxWidth: .infinity)
}

private func quantityButton(
    systemName: String,
    background: Color,
    foreground: Color = .black,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        Image(systemName: systemName)
            .font(.system(size: 19, weight: .black))
            .foregroundColor(foreground)
            .frame(width: 44, height: 44)
            .background(background)
            .clipShape(Circle())
    }
    .buttonStyle(.plain)
}

private func expiryEditor(
    title: String,
    expiryDate: Binding<Date>,
    isActive: Bool = false,
    onSelect: (() -> Void)? = nil
) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(.system(size: 15, weight: .black))
            .foregroundColor(.gray)

        DatePicker("", selection: expiryDate, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
            .frame(height: 44)
            .editorInputStyle(maxWidth: 224, height: 44, isActive: isActive)
            .simultaneousGesture(TapGesture().onEnded {
                onSelect?()
            })
    }
    .frame(maxWidth: 224, alignment: .leading)
}

private func step(for unit: UnitType) -> Double {
    switch unit {
    case .kg: return 0.1
    case .g: return 50
    case .liter: return 0.1
    case .ml: return 50
    case .pcs: return 1
    }
}

private func daysUntilExpiry(for expiryDate: Date) -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let expiryDay = calendar.startOfDay(for: expiryDate)
    return calendar.dateComponents([.day], from: today, to: expiryDay).day ?? 0
}

private func expiryStatusText(for expiryDate: Date) -> String {
    let days = daysUntilExpiry(for: expiryDate)
    if days < 0 { return "Expired" }
    if days == 0 { return "Today" }
    if days == 1 { return "1 Day" }
    return "\(days) Days"
}

private extension Text {
    func primaryPillStyle(background: Color, foreground: Color) -> some View {
        self
            .font(.system(size: 17, weight: .black))
            .foregroundColor(foreground)
            .frame(maxWidth: 224)
            .frame(height: 44)
            .background(background)
            .clipShape(Capsule())
    }

    func outlinePillStyle() -> some View {
        self
            .font(.system(size: 17, weight: .black))
            .foregroundColor(.black)
            .frame(maxWidth: 224)
            .frame(height: 44)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black, lineWidth: 2))
    }
}

private extension View {
    func editorInputStyle(
        width: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        height: CGFloat,
        isActive: Bool
    ) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(width: width, height: height)
            .background(isActive ? Color.yellow.opacity(0.08) : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.yellow : Color.black, lineWidth: isActive ? 4 : 2)
            )
            .shadow(color: isActive ? Color.yellow.opacity(0.34) : Color.clear, radius: 8, y: 2)
            .animation(.easeInOut(duration: 0.16), value: isActive)
    }
}

private extension IngredientCategory {
    var displayTitle: String {
        switch self {
        case .meat:
            "Meat"
        case .veg:
            "Veg"
        case .seafood:
            "Seafood"
        case .drink:
            "Drink"
        case .condiment:
            "Condiment"
        }
    }
}

#Preview {
    StorageView()
        .environmentObject(AppViewModel())
}

private struct AddFoodItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storageVM: StorageViewModel

    @State private var foodName = ""
    @State private var selectedCategory: IngredientCategory = .meat
    @State private var quantityText = ""
    @State private var selectedUnit: UnitType = .g
    @State private var selectedIconName = IngredientCategory.meat.foodIconAssetName
    @State private var expiryDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var capturedImageData: Data?
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var validationMessage: String?

    private let defaultIcons = [
        IngredientCategory.veg.foodIconAssetName,
        IngredientCategory.meat.foodIconAssetName,
        IngredientCategory.seafood.foodIconAssetName,
        IngredientCategory.condiment.foodIconAssetName,
        IngredientCategory.drink.foodIconAssetName
    ]

    init(storageVM: StorageViewModel, initialFoodName: String = "") {
        self.storageVM = storageVM
        _foodName = State(initialValue: initialFoodName)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Add Food Item")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.black)

                    imageSelector

                    labeledField("Food Name") {
                        TextField("e.g. Chicken, Broccoli...", text: $foodName)
                            .font(.headline)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(false)
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(fieldStroke)
                    }

                    labeledField("Category") {
                        Menu {
                            ForEach(IngredientCategory.allCases) { category in
                                Button(category.rawValue) {
                                    selectedCategory = category
                                    selectedIconName = category.foodIconAssetName
                                    capturedImageData = nil
                                }
                            }
                        } label: {
                            pickerRow(title: selectedCategory.rawValue)
                        }
                    }

                    HStack(spacing: 14) {
                        labeledField("Quantity") {
                            TextField("300", text: $quantityText)
                                .font(.headline)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 16)
                                .frame(height: 54)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(fieldStroke)
                        }

                        labeledField("Unit") {
                            Menu {
                                ForEach(UnitType.allCases) { unit in
                                    Button(unit.rawValue) {
                                        selectedUnit = unit
                                    }
                                }
                            } label: {
                                pickerRow(title: selectedUnit.rawValue)
                            }
                        }
                        .frame(width: 116)
                    }

                    labeledField("Expiry Date") {
                        DatePicker(
                            "Expiry Date",
                            selection: $expiryDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 54)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(fieldStroke)
                    }

                    actionButtons
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(Color.white)
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker { image in
                capturedImageData = image.jpegData(compressionQuality: 0.7)
            }
            .ignoresSafeArea()
        }
        .alert("Camera unavailable", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device cannot open the camera right now.")
        }
        .alert("Check item details", isPresented: Binding(
            get: { validationMessage != nil },
            set: { _ in validationMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage ?? "")
        }
    }

    private var imageSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Item Picture")
                .font(.headline)
                .fontWeight(.black)
                .foregroundColor(.gray)

            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.22))
                        .frame(width: 96, height: 96)

                    if let capturedImageData,
                       let image = UIImage(data: capturedImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                    } else {
                        Image(selectedIconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(defaultIcons, id: \.self) { iconName in
                                Button {
                                    selectedIconName = iconName
                                    capturedImageData = nil
                                } label: {
                                    Image(iconName)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(6)
                                        .frame(width: 46, height: 46)
                                        .background(selectedIconName == iconName && capturedImageData == nil ? Color.yellow : Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        } else {
                            showCameraUnavailable = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                        .font(.subheadline)
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button {
                addItem()
            } label: {
                Text("Add")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.black, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private func labeledField<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.black)
                .foregroundColor(.gray)

            content()
        }
    }

    private func pickerRow(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Spacer()

            Image(systemName: "chevron.down")
                .font(.caption.weight(.black))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(fieldStroke)
    }

    private var fieldStroke: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(Color.black.opacity(0.08), lineWidth: 1.5)
    }

    private func addItem() {
        let cleanName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedQuantity = quantityText.replacingOccurrences(of: ",", with: ".")
        let quantity = Double(normalizedQuantity) ?? 0

        guard !cleanName.isEmpty else {
            validationMessage = "Please enter a food name."
            return
        }

        guard quantity > 0 else {
            validationMessage = "Please enter a quantity greater than 0."
            return
        }

        storageVM.addIngredientRecord(
            name: cleanName,
            category: selectedCategory,
            amount: quantity,
            unit: selectedUnit,
            iconName: capturedImageData == nil ? selectedIconName : nil,
            imageData: capturedImageData,
            expiryDate: expiryDate
        )
        dismiss()
    }
}

private struct CameraImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraImagePicker

        init(parent: CameraImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            if let image {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
