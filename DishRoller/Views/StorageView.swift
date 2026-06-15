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
    @State private var showAddFoodSheet = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    searchPanel
                    categoryFilters

                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(appVM.storageVM.filteredIngredients) { ingredient in
                            IngredientCardView(
                                ingredient: ingredient,
                                onIncrease: { appVM.storageVM.increase(ingredient) },
                                onDecrease: { appVM.storageVM.decrease(ingredient) }
                            )
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
        .sheet(isPresented: $showAddFoodSheet) {
            AddFoodItemSheet(storageVM: appVM.storageVM)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Camera scan", isPresented: $showScannerPlaceholder) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Camera scanning will match purchased items to storage or create a new item card in a future version.")
        }
    }

    private var addFoodButton: some View {
        Button {
            showAddFoodSheet = true
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
        .padding(.bottom, 18)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Fresh Food Storage")
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
                    .frame(width: 48, height: 48)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                showScannerPlaceholder = true
            } label: {
                Image(systemName: "camera.viewfinder")
                    .font(.title3.weight(.black))
                    .foregroundColor(.black)
                    .frame(width: 54, height: 50)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Scan purchased items")
        }
    }

    private var categoryFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .fontWeight(.black)
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
        VStack(spacing: 10) {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var storageBackground: Color {
        Color(red: 0.96, green: 0.95, blue: 0.98)
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
    @State private var selectedIconName = "fork.knife"
    @State private var capturedImageData: Data?
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var validationMessage: String?

    private let defaultIcons = [
        "fork.knife",
        "leaf",
        "fish",
        "cup.and.saucer",
        "flame",
        "takeoutbag.and.cup.and.straw",
        "birthday.cake",
        "drop"
    ]

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
                                    selectedIconName = category.categoryIcon
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
                        Image(systemName: selectedIconName)
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundColor(.black)
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
                                    Image(systemName: iconName)
                                        .font(.headline.weight(.bold))
                                        .foregroundColor(selectedIconName == iconName && capturedImageData == nil ? .black : .gray)
                                        .frame(width: 42, height: 42)
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

        storageVM.addIngredient(
            name: cleanName,
            category: selectedCategory,
            amount: quantity,
            unit: selectedUnit,
            iconName: capturedImageData == nil ? selectedIconName : nil,
            imageData: capturedImageData
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
