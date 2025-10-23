# Примеры использования Pluralization в Tabiin Academy

## 🎯 Основные методы

### 1. Обычная локализация (как раньше)
```swift
"stats.title".localized
// Результат: "Статистика" (RU) или "Statistics" (EN)
```

### 2. Pluralization с количеством
```swift
"stats.questionsStudied".localized(count: 1)
// Результат: "1 вопрос изучен" (RU) или "1 question studied" (EN)

"stats.questionsStudied".localized(count: 5)
// Результат: "5 вопросов изучено" (RU) или "5 questions studied" (EN)

"stats.questionsStudied".localized(count: 21)
// Результат: "21 вопрос изучен" (RU) или "21 questions studied" (EN)
```

### 3. Pluralization с аргументами
```swift
"stats.questionsStudied".localized(count: 5, arguments: 5)
// Результат: "5 вопросов изучено" (RU) или "5 questions studied" (EN)
```

## 📱 Примеры в коде

### StatsView с pluralization
```swift
struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(title.localized(count: value))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// Использование:
StatCard(
    title: "stats.questionsStudied",
    value: 5,
    icon: "questionmark.circle.fill",
    color: .blue
)
// Результат: "5 вопросов изучено"
```

### QuizView с accessibility
```swift
Text("\(viewModel.correctAnswers)")
    .font(.title2)
    .fontWeight(.bold)
    .foregroundStyle(.green)
    .accessibilityLabel("stats.correctAnswers".localized(count: viewModel.correctAnswers))
```

## 🌍 Поддержка языков

### Русский язык (сложная pluralization)
- 1 вопрос изучен
- 2-4 вопроса изучено  
- 5+ вопросов изучено
- 11-19 вопросов изучено

### Английский язык (простая pluralization)
- 1 question studied
- 2+ questions studied

## 🔧 Настройка в Localizable.strings

### Английский (en.lproj/Localizable.strings)
```
"stats.questionsStudied" = "%d question studied";
"stats.questionsStudied_other" = "%d questions studied";
```

### Русский (ru.lproj/Localizable.strings)
```
"stats.questionsStudied" = "%d вопрос изучен";
"stats.questionsStudied_2" = "%d вопроса изучено";
"stats.questionsStudied_5" = "%d вопросов изучено";
```

## 🧪 Тестирование

### Проверка pluralization
```swift
// Тест для разных количеств
let testCounts = [0, 1, 2, 5, 11, 21, 101]
for count in testCounts {
    let localized = "stats.questionsStudied".localized(count: count)
    print("\(count): \(localized)")
}
```

### Ожидаемые результаты:
- 0: 0 вопросов изучено (RU) / 0 questions studied (EN)
- 1: 1 вопрос изучен (RU) / 1 question studied (EN)
- 2: 2 вопроса изучено (RU) / 2 questions studied (EN)
- 5: 5 вопросов изучено (RU) / 5 questions studied (EN)
- 11: 11 вопросов изучено (RU) / 11 questions studied (EN)
- 21: 21 вопрос изучен (RU) / 21 questions studied (EN)
- 101: 101 вопрос изучен (RU) / 101 questions studied (EN)

## 🚀 Миграция существующего кода

### Было:
```swift
Text("\(statsManager.stats.correctAnswers) correct answers")
```

### Стало:
```swift
Text("stats.correctAnswers".localized(count: statsManager.stats.correctAnswers))
```

### Преимущества:
- ✅ Правильная грамматика для всех языков
- ✅ Автоматическая поддержка новых языков
- ✅ Лучшая доступность
- ✅ Соответствие стандартам локализации
