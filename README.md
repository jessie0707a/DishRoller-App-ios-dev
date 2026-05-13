# DishRoller

DishRoller is a SwiftUI iOS app that helps users turn available ingredients into recipe ideas. Users can manage ingredients in storage, randomly select ingredients, generate a recipe with preferred cooking time, dish type, and flavour style, then save recipes for later.

## Features

- Ingredient storage with category, amount, and unit tracking
- Random ingredient selection for recipe inspiration
- Recipe generation using the Gemini API
- Demo recipe fallback when no Gemini API key is configured
- Saved recipes list
- Avoidance preferences for ingredients or food restrictions
- SwiftUI tab-based interface

## Tech Stack

- Swift
- SwiftUI
- Combine for view model bindings
- UserDefaults-based local persistence
- Gemini Generative Language API

## Setup

1. Open the project in Xcode.
2. Copy `DishRoller/DishRoller/Config.example.plist` to `DishRoller/DishRoller/Config.plist`.
3. Replace `YOUR_GEMINI_API_KEY` with your Gemini API key.
4. Keep `GEMINI_MODEL` as `gemini-2.5-flash-lite`, or change it to another supported Gemini model.
5. Build and run the app from Xcode.

If `Config.plist` is missing or the API key is left blank, the app still runs using demo recipes.

## Project Structure

```text
DishRoller/DishRoller
├── Components      Reusable SwiftUI views
├── Models          App data models and enums
├── Services        Gemini API and local storage logic
├── ViewModels      Screen and app state management
├── Views           Main app screens
├── Assets.xcassets App images and colors
└── Config.plist    Local API configuration
```

## Main Screens

- `StorageView`: manage available ingredients
- `DishRollerView`: select ingredients and generate recipes
- `MenuView`: view the generated recipe
- `SavedRecipesViews`: browse saved recipes
- `AvoidancePreferencesView`: manage food avoidance preferences

## Notes

`Config.plist` should contain local secrets and should not be committed with a real API key.
