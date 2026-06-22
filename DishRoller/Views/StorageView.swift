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
    @State private var selectedIngredientID: UUID?
    @State private var selectedIngredientCardFrame: CGRect?
    @State private var searchFieldFrame: CGRect?
    @FocusState private var isSearchFieldFocused: Bool

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                storageBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        searchPanel
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                    .background(storageBackground)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            categoryFilters

                            LazyVGrid(columns: gridColumns, spacing: 14) {
                                ForEach(appVM.storageVM.filteredIngredients) { ingredient in
                                    IngredientCardView(
                                        ingredient: ingredient,
                                        isSelected: selectedIngredientID == ingredient.id,
                                        onEdit: {
                                            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                                editorContext = IngredientEditorContext(ingredientID: ingredient.id)
                                            }
                                        }
                                    )
                                    .background {
                                        if selectedIngredientID == ingredient.id {
                                            GeometryReader { proxy in
                                                Color.clear.preference(
                                                    key: SelectedIngredientCardFrameKey.self,
                                                    value: proxy.frame(in: .named("storageScreenSpace"))
                                                )
                                            }
                                        }
                                    }
                                    .contentShape(RoundedRectangle(cornerRadius: 22))
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                            selectedIngredientID = ingredient.id
                                        }
                                    }
                                    .onLongPressGesture {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                            selectedIngredientID = ingredient.id
                                        }

                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            pendingDeleteIngredient = ingredient
                                        }
                                    }
                                }
                            }

                            if appVM.storageVM.filteredIngredients.isEmpty {
                                emptyState
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 6)
                        .padding(.bottom, 220)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }

                addFoodButton
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .coordinateSpace(name: "storageScreenSpace")
        .onPreferenceChange(SelectedIngredientCardFrameKey.self) {
            selectedIngredientCardFrame = $0
        }
        .onPreferenceChange(StorageSearchFieldFrameKey.self) {
            searchFieldFrame = $0
        }
        .simultaneousGesture(
            SpatialTapGesture().onEnded { value in
                if selectedIngredientID != nil,
                   let selectedIngredientCardFrame,
                   !selectedIngredientCardFrame.contains(value.location) {
                    clearCardSelection()
                }

                if isSearchFieldFocused,
                   let searchFieldFrame,
                   !searchFieldFrame.contains(value.location) {
                    isSearchFieldFocused = false
                    dismissKeyboard()
                }
            }
        )
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
                ZStack(alignment: .trailing) {
                    Image(systemName: "cart")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 23, height: 23)
                        .frame(width: 72, height: 48)

                    if shoppingCartItemCount > 0 {
                        HStack {
                            Text(shoppingCartCountText)
                                .font(.caption.weight(.black))
                                .foregroundStyle(.yellow)
                                .frame(width: 28, height: 28)
                                .background(Color.black)
                                .clipShape(Circle())
                                .transition(.scale.combined(with: .opacity))

                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 10)
                    }
                }
                .frame(width: shoppingCartItemCount > 0 ? 100 : 72, height: 48)
                .background(Color.yellow)
                .clipShape(Capsule())
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.82),
                    value: shoppingCartItemCount
                )
            }
            .accessibilityLabel("Shopping Cart")
            .accessibilityValue("\(shoppingCartItemCount) items")
        }
    }

    private var shoppingCartItemCount: Int {
        appVM.storageVM.shoppingListItems.count { !$0.isCompleted }
    }

    private var shoppingCartCountText: String {
        shoppingCartItemCount > 99 ? "99+" : "\(shoppingCartItemCount)"
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
                    .submitLabel(.done)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        isSearchFieldFocused = false
                        dismissKeyboard()
                    }

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
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: StorageSearchFieldFrameKey.self,
                        value: proxy.frame(in: .named("storageScreenSpace"))
                    )
                }
            }

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

    private func clearCardSelection() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            selectedIngredientID = nil
        }
    }

    private func openAddFoodSheet(initialName: String = "") {
        addFoodSheetContext = AddFoodSheetContext(initialName: initialName)
    }
}

private struct SelectedIngredientCardFrameKey: PreferenceKey {
    static var defaultValue: CGRect?

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

private struct StorageSearchFieldFrameKey: PreferenceKey {
    static var defaultValue: CGRect?

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
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
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .overlay {
                            GeometryReader { proxy in
                                if purchaseRecords.count > 1 {
                                    let cardHeight = min(proxy.size.height - 44, 626)
                                    let cardBottomInset = max(0, (proxy.size.height - cardHeight) / 2)

                                    VStack {
                                        Spacer()

                                        HStack(spacing: 6) {
                                            ForEach(purchaseRecords) { record in
                                                Capsule()
                                                    .fill(
                                                        selectedRecordID == record.id
                                                            ? Color.black
                                                            : Color.black.opacity(0.18)
                                                    )
                                                    .frame(
                                                        width: selectedRecordID == record.id ? 18 : 6,
                                                        height: 6
                                                    )
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .frame(height: 28)
                                        .background(Color.white.opacity(0.94))
                                        .clipShape(Capsule())
                                        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
                                        .padding(.bottom, cardBottomInset + 8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .allowsHitTesting(false)
                                    .animation(
                                        .spring(response: 0.28, dampingFraction: 0.82),
                                        value: selectedRecordID
                                    )
                                }
                            }
                        }
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
    @State private var selectedCategory: IngredientCategory
    @State private var selectedUnit: UnitType
    @State private var expiryDate: Date?
    @State private var quantityEditMode: QuantityEditMode?
    @State private var originalAmountBeforeQuantityEdit: Double
    @State private var showDeleteConfirmation = false
    @State private var validationMessage: String?
    @State private var activeControl: EditorControl?
    @State private var editedImageData: Data?
    @State private var showPhotoSourceOptions = false
    @State private var imagePickerSource: StorageImagePickerSource?
    @State private var showCameraUnavailable = false
    @State private var isEstimatingExpiry = false
    @FocusState private var focusedControl: EditorControl?
    private let expiryEstimator = GeminiRecipeService()

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
        _selectedCategory = State(initialValue: ingredient.category)
        _selectedUnit = State(initialValue: ingredient.unit)
        _expiryDate = State(initialValue: ingredient.expiryDate)
        _originalAmountBeforeQuantityEdit = State(initialValue: ingredient.amount)
        _editedImageData = State(initialValue: ingredient.imageData)
    }

    var body: some View {
        PurchaseEditorCard(onBackgroundTap: onCancel) {
            VStack(spacing: 10) {
                editorHeader(
                    category: selectedCategory,
                    expiryDate: expiryDate,
                    onCategoryChange: { category in
                        selectedCategory = category
                        focusedControl = nil
                    },
                    onDelete: { showDeleteConfirmation = true }
                )
                Button {
                    focusedControl = nil
                    showPhotoSourceOptions = true
                } label: {
                    editorImage(
                        for: ingredient,
                        category: selectedCategory,
                        imageData: editedImageData
                    )
                        .overlay {
                            Circle()
                                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
                                .frame(width: 158, height: 158)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change item photo")

                TextField("Food name", text: $itemNameText)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(false)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .focused($focusedControl, equals: .name)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedControl = nil
                    }
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
                        .submitLabel(.done)
                        .onSubmit {
                            focusedControl = nil
                        }
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

                HStack(alignment: .bottom, spacing: 10) {
                    expiryEditor(
                        title: "Expired Date:",
                        expiryDate: $expiryDate,
                        width: 170,
                        isActive: isControlActive(.expiryDate),
                        onSelect: {
                            activeControl = .expiryDate
                            focusedControl = nil
                        }
                    )

                    aiExpiryEstimateButton(
                        isLoading: isEstimatingExpiry,
                        action: estimateExpiryDate
                    )
                }
                .frame(width: 224)

                Button {
                    saveChanges()
                } label: {
                    Text("Save")
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
        .overlay(alignment: .top) {
            if isEstimatingExpiry {
                aiExpiryLoadingNotice
                    .padding(.top, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(30)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.84), value: isEstimatingExpiry)
        .fullScreenCover(item: $imagePickerSource) { source in
            StorageImagePicker(sourceType: source.uiSourceType) { image in
                editedImageData = image.jpegData(compressionQuality: 0.7)
            }
            .ignoresSafeArea()
        }
        .confirmationDialog(
            "Replace Item Photo",
            isPresented: $showPhotoSourceOptions,
            titleVisibility: .visible
        ) {
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    imagePickerSource = .camera
                } else {
                    showCameraUnavailable = true
                }
            }

            Button("Choose from Photo Library") {
                imagePickerSource = .photoLibrary
            }

            Button("Cancel", role: .cancel) {}
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
            category: selectedCategory,
            amount: amount,
            unit: selectedUnit,
            expiryDate: expiryDate,
            imageData: editedImageData
        )
        onFinished()
    }

    private func estimateExpiryDate() {
        let cleanName = itemNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            validationMessage = "Enter the food name before using AI estimation."
            return
        }

        focusedControl = nil
        isEstimatingExpiry = true
        Task {
            do {
                expiryDate = try await expiryEstimator.estimateExpiryDate(
                    itemName: cleanName,
                    purchaseDate: ingredient.createdAt ?? Date()
                )
                activeControl = .expiryDate
            } catch {
                validationMessage = error.localizedDescription
            }
            isEstimatingExpiry = false
        }
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
    @State private var expiryDate: Date?
    @State private var validationMessage: String?
    @State private var activeControl: EditorControl?
    @State private var isEstimatingExpiry = false
    @FocusState private var focusedControl: EditorControl?
    private let purchaseDate = Date()
    private let expiryEstimator = GeminiRecipeService()

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
                    .submitLabel(.done)
                    .onSubmit {
                        focusedControl = nil
                    }
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
                        .submitLabel(.done)
                        .onSubmit {
                            focusedControl = nil
                        }
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

                HStack(alignment: .bottom, spacing: 10) {
                    expiryEditor(
                        title: "Expired Date:",
                        expiryDate: $expiryDate,
                        width: 170,
                        isActive: isControlActive(.expiryDate),
                        onSelect: {
                            activeControl = .expiryDate
                            focusedControl = nil
                        }
                    )

                    aiExpiryEstimateButton(
                        isLoading: isEstimatingExpiry,
                        action: estimateExpiryDate
                    )
                }
                .frame(width: 224)

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
        .overlay(alignment: .top) {
            if isEstimatingExpiry {
                aiExpiryLoadingNotice
                    .padding(.top, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(30)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.84), value: isEstimatingExpiry)
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
            expiryDate: expiryDate,
            createdAt: purchaseDate
        ) else {
            validationMessage = "Please enter valid item details."
            return
        }
        onCreated(newRecord)
    }

    private func estimateExpiryDate() {
        let cleanName = itemNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            validationMessage = "Enter the food name before using AI estimation."
            return
        }

        focusedControl = nil
        isEstimatingExpiry = true
        Task {
            do {
                expiryDate = try await expiryEstimator.estimateExpiryDate(
                    itemName: cleanName,
                    purchaseDate: purchaseDate
                )
                activeControl = .expiryDate
            } catch {
                validationMessage = error.localizedDescription
            }
            isEstimatingExpiry = false
        }
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
    expiryDate: Date?,
    onCategoryChange: ((IngredientCategory) -> Void)? = nil,
    onDelete: (() -> Void)? = nil
) -> some View {
    HStack(alignment: .center) {
        if let onCategoryChange {
            Menu {
                ForEach(IngredientCategory.allCases) { option in
                    Button {
                        onCategoryChange(option)
                    } label: {
                        if option == category {
                            Label(option.rawValue, systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            } label: {
                editorCategoryTag(category: category, expiryDate: expiryDate, isEditable: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change item type")
            .accessibilityValue(category.rawValue)
        } else {
            editorCategoryTag(category: category, expiryDate: expiryDate)
        }

        Spacer()

        Text(expiryDate.map { expiryStatusText(for: $0) } ?? "No Date")
            .font(.system(size: 18, weight: .black))
            .foregroundColor(
                expiryDate.map { daysUntilExpiry(for: $0) <= 1 } == true
                    ? Color(red: 0.89, green: 0.22, blue: 0.2)
                    : .black
            )
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

private func editorCategoryTag(
    category: IngredientCategory,
    expiryDate: Date?,
    isEditable: Bool = false
) -> some View {
    HStack(spacing: 7) {
        Text(category.rawValue)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: .infinity)

        if isEditable {
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .black))
                .fixedSize()
        }
    }
    .font(.system(size: 19, weight: .black))
    .foregroundColor(.black)
    .padding(.horizontal, 14)
    .frame(width: 150, height: 40)
    .background(
        expiryDate.map { daysUntilExpiry(for: $0) < 0 } == true
            ? Color(.systemGray4)
            : Color.yellow
    )
    .clipShape(Capsule())
}

private func editorImage(
    for ingredient: Ingredient,
    category: IngredientCategory? = nil,
    imageData: Data? = nil
) -> some View {
    let displayedCategory = category ?? ingredient.category

    return ZStack {
        Circle()
            .fill(editorCategoryTint(for: displayedCategory).opacity(0.18))
            .frame(width: 152, height: 152)

        if let imageData = imageData ?? ingredient.imageData,
           let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 132, height: 132)
                .clipShape(Circle())
        } else {
            Image(
                category == nil
                    ? ingredient.iconName ?? displayedCategory.foodIconAssetName
                    : displayedCategory.foodIconAssetName
            )
                .resizable()
                .scaledToFit()
                .frame(width: 126, height: 126)
        }
    }
    .frame(maxWidth: .infinity)
}

private func editorCategoryTint(for category: IngredientCategory) -> Color {
    switch category {
    case .meat:
        Color(red: 0.89, green: 0.25, blue: 0.22)
    case .veg:
        Color(red: 0.16, green: 0.56, blue: 0.28)
    case .seafood:
        Color(red: 0.12, green: 0.45, blue: 0.82)
    case .drink:
        Color(red: 0.46, green: 0.36, blue: 0.88)
    case .condiment:
        Color(red: 0.86, green: 0.55, blue: 0.04)
    case .other:
        Color(red: 0.68, green: 0.68, blue: 0.7)
    }
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
    expiryDate: Binding<Date?>,
    width: CGFloat = 224,
    isActive: Bool = false,
    onSelect: (() -> Void)? = nil
) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(.system(size: 15, weight: .black))
            .foregroundColor(.gray)

        if expiryDate.wrappedValue == nil {
            Button {
                expiryDate.wrappedValue = Date()
                onSelect?()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add Date")
                }
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(.gray)
                .frame(width: width, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .editorInputStyle(width: width, height: 44, isActive: isActive)
        } else {
            DatePicker(
                "",
                selection: Binding(
                    get: { expiryDate.wrappedValue ?? Date() },
                    set: { expiryDate.wrappedValue = $0 }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .frame(height: 44)
            .editorInputStyle(width: width, height: 44, isActive: isActive)
            .simultaneousGesture(TapGesture().onEnded {
                onSelect?()
            })
        }
    }
    .frame(width: width, alignment: .leading)
}

private func aiExpiryEstimateButton(
    isLoading: Bool,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        Image(systemName: "sparkles")
            .font(.system(size: 16, weight: .black))
            .foregroundStyle(.black)
            .frame(width: 44, height: 44)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.62),
                        Color.yellow
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }
    .buttonStyle(.plain)
    .disabled(isLoading)
    .opacity(isLoading ? 0.68 : 1)
    .accessibilityLabel("AI estimated expiry date")
}

private var aiExpiryLoadingNotice: some View {
    HStack(spacing: 10) {
        ProgressView()
            .tint(.yellow)

        Text("DishRoller is estimating the expired date for you")
            .font(.subheadline.weight(.black))
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 16)
    .frame(minHeight: 48)
    .background(Color.black.opacity(0.94))
    .clipShape(Capsule())
    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    .padding(.horizontal, 22)
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
                    .stroke(
                        isActive ? Color.yellow : Color(.systemGray4),
                        lineWidth: isActive ? 3 : 1.5
                    )
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
        case .other:
            "Other"
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
    @State private var expiryDate: Date?
    @State private var capturedImageData: Data?
    @State private var showPhotoSourceOptions = false
    @State private var imagePickerSource: StorageImagePickerSource?
    @State private var showCameraUnavailable = false
    @State private var validationMessage: String?
    @State private var isEstimatingExpiry = false
    private let purchaseDate = Date()
    private let expiryEstimator = GeminiRecipeService()

    private let defaultIcons = [
        IngredientCategory.veg.foodIconAssetName,
        IngredientCategory.meat.foodIconAssetName,
        IngredientCategory.seafood.foodIconAssetName,
        IngredientCategory.condiment.foodIconAssetName,
        IngredientCategory.drink.foodIconAssetName,
        IngredientCategory.other.foodIconAssetName
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
                            .submitLabel(.done)
                            .onSubmit(dismissKeyboard)
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
                                .submitLabel(.done)
                                .onSubmit(dismissKeyboard)
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
                        HStack(spacing: 10) {
                            Group {
                                if expiryDate == nil {
                                    Button {
                                        expiryDate = Date()
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "calendar.badge.plus")
                                            Text("Add Date")
                                        }
                                        .font(.headline)
                                        .foregroundStyle(.gray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    DatePicker(
                                        "Expiry Date",
                                        selection: Binding(
                                            get: { expiryDate ?? Date() },
                                            set: { expiryDate = $0 }
                                        ),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(fieldStroke)

                            aiExpiryEstimateButton(
                                isLoading: isEstimatingExpiry,
                                action: estimateExpiryDate
                            )
                        }
                    }

                    actionButtons
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.white)
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $imagePickerSource) { source in
            StorageImagePicker(sourceType: source.uiSourceType) { image in
                capturedImageData = image.jpegData(compressionQuality: 0.7)
            }
            .ignoresSafeArea()
        }
        .confirmationDialog(
            "Add Item Photo",
            isPresented: $showPhotoSourceOptions,
            titleVisibility: .visible
        ) {
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    imagePickerSource = .camera
                } else {
                    showCameraUnavailable = true
                }
            }

            Button("Choose from Photo Library") {
                imagePickerSource = .photoLibrary
            }

            Button("Cancel", role: .cancel) {}
        }
        .alert("Camera unavailable", isPresented: $showCameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device cannot open the camera right now.")
        }
        .overlay(alignment: .top) {
            if isEstimatingExpiry {
                aiExpiryLoadingNotice
                    .padding(.top, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(30)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.84), value: isEstimatingExpiry)
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
                        showPhotoSourceOptions = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Add Photo")
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
            expiryDate: expiryDate,
            createdAt: purchaseDate
        )
        dismiss()
    }

    private func estimateExpiryDate() {
        let cleanName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            validationMessage = "Enter the food name before using AI estimation."
            return
        }

        dismissKeyboard()
        isEstimatingExpiry = true
        Task {
            do {
                expiryDate = try await expiryEstimator.estimateExpiryDate(
                    itemName: cleanName,
                    purchaseDate: purchaseDate
                )
            } catch {
                validationMessage = error.localizedDescription
            }
            isEstimatingExpiry = false
        }
    }
}

private enum StorageImagePickerSource: String, Identifiable {
    case camera
    case photoLibrary

    var id: String { rawValue }

    var uiSourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: .camera
        case .photoLibrary: .photoLibrary
        }
    }
}

private struct StorageImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: StorageImagePicker

        init(parent: StorageImagePicker) {
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
