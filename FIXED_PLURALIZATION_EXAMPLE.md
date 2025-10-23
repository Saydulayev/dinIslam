# Исправление проблемы с %d символами

## 🐛 **Проблема:**
В интерфейсе отображались символы `%d` вместо правильного текста.

## 🔍 **Причина:**
Использовались ключи локализации с `%d` (например, `"stats.questionsStudied"`) без передачи количества через `localized(count:)`.

## ✅ **Решение:**

### 1. Разделили ключи на два типа:

#### **Заголовки (без %d):**
```swift
// В Localizable.strings
"stats.questionsStudied.title" = "Questions Studied";
"stats.correctAnswers.title" = "Correct Answers";
```

#### **Pluralization (с %d):**
```swift
// В Localizable.strings
"stats.questionsStudied" = "%d question studied";
"stats.questionsStudied_other" = "%d questions studied";
```

### 2. Обновили код:

#### **Было (неправильно):**
```swift
Text("stats.questionsStudied".localized) // Показывало "%d вопрос изучен"
```

#### **Стало (правильно):**
```swift
// Для заголовков
Text("stats.questionsStudied.title".localized) // "Questions Studied"

// Для значений с pluralization
Text("stats.questionsStudied".localized(count: 5)) // "5 questions studied"
```

### 3. Результат:

| Количество | Русский | Английский |
|------------|---------|------------|
| 0 | 0 вопросов изучено | 0 questions studied |
| 1 | 1 вопрос изучен | 1 question studied |
| 2 | 2 вопроса изучено | 2 questions studied |
| 5 | 5 вопросов изучено | 5 questions studied |
| 21 | 21 вопрос изучен | 21 questions studied |

## 🧪 **Тестирование:**

### Проверьте, что:
1. ✅ Заголовки отображаются без `%d`
2. ✅ Значения используют правильную грамматику
3. ✅ Pluralization работает для всех языков
4. ✅ Accessibility labels корректны

### Пример кода для тестирования:
```swift
// Тест pluralization
let testValues = [0, 1, 2, 5, 11, 21, 101]
for value in testValues {
    let localized = "stats.questionsStudied".localized(count: value)
    print("\(value): \(localized)")
}
```

## 📱 **Использование в приложении:**

### EnhancedStatCard теперь:
1. **Показывает заголовок** без `%d`
2. **Показывает значение** с правильной грамматикой
3. **Поддерживает accessibility**
4. **Работает с Dynamic Type**

### Пример:
```swift
EnhancedStatCard(
    title: "stats.questionsStudied.title".localized, // "Questions Studied"
    value: 5,
    icon: "questionmark.circle.fill",
    color: .blue,
    isCompact: false
)
// Результат: Заголовок "Questions Studied", значение "5 questions studied"
```

## 🎯 **Ключевые изменения:**

1. **Добавлены `.title` ключи** для заголовков
2. **Обновлен EnhancedStatCard** для использования pluralization
3. **Исправлены все места** с `%d` символами
4. **Сохранена обратная совместимость**

Теперь приложение должно отображать правильный текст без символов `%d`! 🎉
