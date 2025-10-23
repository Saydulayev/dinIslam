# Улучшения доступности и UX для Tabiin Academy

## 🚨 Критические проблемы и решения

### 1. Pluralization (Множественные формы)

**Проблема:** Жестко закодированные строки без учета грамматики
```swift
// ❌ Плохо
Text("\(count) questions studied")
```

**Решение:** Добавить поддержку pluralization
```swift
// ✅ Хорошо
Text(NSLocalizedString("stats.questionsStudied", comment: ""), count: count)
```

**Файлы для изменения:**
- `Resources/en.lproj/Localizable.strings`
- `Resources/ru.lproj/Localizable.strings`
- `Presentation/Views/StatsView.swift`
- `Presentation/Views/ResultView.swift`

### 2. Dynamic Type Support

**Проблема:** Ограниченная поддержка масштабирования текста
```swift
// ❌ Только один пример
.dynamicTypeSize(.large)
```

**Решение:** Добавить поддержку для всех текстовых элементов
```swift
// ✅ Для всех текстов
Text("Title")
    .font(.title)
    .dynamicTypeSize(.accessibility1) // Максимальная поддержка
```

### 3. Reduce Motion Support

**Проблема:** Анимации без учета пользовательских настроек
```swift
// ❌ Игнорирует настройки
.animation(.easeInOut(duration: 0.3), value: isAnswerSelected)
```

**Решение:** Проверка настроек анимации
```swift
// ✅ Уважает настройки пользователя
@Environment(\.accessibilityReduceMotion) private var reduceMotion

.animation(
    reduceMotion ? nil : .easeInOut(duration: 0.3), 
    value: isAnswerSelected
)
```

### 4. RTL (Right-to-Left) Support

**Проблема:** Отсутствие поддержки арабского/иврита

**Решение:** Добавить RTL поддержку
```swift
// ✅ Проверка направления текста
@Environment(\.layoutDirection) private var layoutDirection

HStack {
    if layoutDirection == .rightToLeft {
        // RTL layout
    } else {
        // LTR layout
    }
}
```

### 5. Контрастность и цветовая схема

**Проблема:** Отсутствие проверки контраста

**Решение:** Использовать семантические цвета
```swift
// ✅ Семантические цвета
.foregroundColor(.primary) // Автоматически адаптируется
.background(.ultraThinMaterial) // Поддерживает темную тему
```

## 📋 План реализации

### Этап 1: Pluralization
1. Обновить `Localizable.strings` файлы с pluralization
2. Заменить жестко закодированные строки на локализованные
3. Протестировать на разных языках

### Этап 2: Dynamic Type
1. Добавить `.dynamicTypeSize(.accessibility1)` ко всем текстам
2. Протестировать с максимальным размером шрифта
3. Убедиться в читаемости на всех экранах

### Этап 3: Reduce Motion
1. Добавить проверку `@Environment(\.accessibilityReduceMotion)`
2. Условно применять анимации
3. Протестировать с включенной настройкой

### Этап 4: RTL Support
1. Добавить проверку `@Environment(\.layoutDirection)`
2. Адаптировать layout для RTL языков
3. Протестировать с арабским языком

### Этап 5: Контрастность
1. Обновить AccentColor для темной темы
2. Использовать семантические цвета
3. Протестировать контрастность

## 🧪 Тестирование

### Accessibility Inspector
1. Запустить Accessibility Inspector
2. Проверить все элементы на доступность
3. Убедиться в корректности VoiceOver

### Dynamic Type Testing
1. Настройки → Дисплей и яркость → Размер текста
2. Протестировать все экраны с максимальным размером
3. Проверить читаемость и layout

### Reduce Motion Testing
1. Настройки → Универсальный доступ → Уменьшить движение
2. Протестировать все анимации
3. Убедиться в отсутствии анимаций

### RTL Testing
1. Изменить язык на арабский
2. Проверить layout всех экранов
3. Убедиться в правильном направлении текста

## 📊 Метрики успеха

- ✅ 100% элементов поддерживают VoiceOver
- ✅ Все тексты масштабируются до accessibility1
- ✅ Анимации отключаются при Reduce Motion
- ✅ Layout корректно работает в RTL
- ✅ Контрастность соответствует WCAG AA
- ✅ Pluralization работает для всех языков

## 📚 Дополнительные ресурсы

- [Apple Accessibility Guidelines](https://developer.apple.com/accessibility/)
- [SwiftUI Accessibility](https://developer.apple.com/documentation/swiftui/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [iOS Accessibility Testing](https://developer.apple.com/accessibility/ios/)
