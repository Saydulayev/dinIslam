# Правила написания чистого кода для dinIslam

Четкие правила, которым нужно следовать при написании кода в проекте dinIslam.

## 🏗️ Архитектура

### Структура проекта
```
Domain/           # Бизнес-логика
├── Models/       # Модели данных
├── UseCases/     # Бизнес-сценарии  
├── Repositories/ # Протоколы репозиториев
└── Managers/     # Сервисы

Presentation/    # UI слой
├── ViewModels/   # ViewModels с @Observable
└── Views/        # SwiftUI Views
```

### Принципы
- **Domain** не зависит от внешних фреймворков
- **Presentation** зависит только от Domain
- Используй **протоколы** для абстракции
- **Dependency Injection** через DIContainer

## 📝 Стандарты кода

### Структура файла
```swift
//
//  FileName.swift
//  dinIslam
//
//  Created by [Author] on [Date].
//

import Foundation
import SwiftUI

// MARK: - Properties
// MARK: - Initialization  
// MARK: - Public Methods
// MARK: - Private Methods
```

### Именование
- **Классы**: PascalCase (`QuizViewModel`, `Question`)
- **Переменные**: camelCase (`currentQuestion`, `loadQuestions`)
- **Константы**: camelCase (`maxQuestions`, `defaultLanguage`)
- **Протоколы**: PascalCase + Protocol (`QuizUseCaseProtocol`)
- **Enums**: PascalCase (`QuizState`, `Difficulty`)

### Доступность
- `private` - для внутренних методов и свойств
- `internal` (по умолчанию) - для API модуля
- `public` - только для публичного API
- Избегай `fileprivate`

## 🔧 Технологии

### SwiftUI
- Используй `@Observable` вместо `ObservableObject`
- Применяй `NavigationStack` вместо `NavigationView`
- Используй `@AppStorage` для простых настроек

### Асинхронность
- Предпочитай `async/await` над completion handlers
- Используй `Task` для запуска асинхронных операций
- Применяй `@MainActor` для UI операций

### Обработка ошибок
- Используй `Result` тип для операций с ошибками
- Обрабатывай ошибки явно с `do-catch`
- Создавай кастомные типы ошибок

## 📋 Правила написания

### 1. Функции
- Максимум 50 строк (warning), 100 строк (error)
- Одна функция = одна ответственность
- Используй понятные имена параметров

### 2. Классы
- Максимум 300 строк (warning), 500 строк (error)
- Один класс = одна ответственность
- Используй MARK комментарии для организации

### 3. Файлы
- Максимум 500 строк (warning), 1000 строк (error)
- Один файл = один основной класс/структура

### 4. Сложность
- Цикломатическая сложность: максимум 10 (warning), 20 (error)
- Уровень вложенности: максимум 3 (warning), 6 (error)

## 🎯 Паттерны

### MVVM
```swift
// View
struct QuizView: View {
    @State private var viewModel = QuizViewModel()
}

// ViewModel
@Observable
class QuizViewModel {
    var state: QuizState = .idle
}
```

### Repository Pattern
```swift
protocol QuestionsRepositoryProtocol {
    func loadQuestions(language: String) async throws -> [Question]
}

class QuestionsRepository: QuestionsRepositoryProtocol {
    // Implementation
}
```

### Use Case Pattern
```swift
protocol QuizUseCaseProtocol {
    func startQuiz(language: String) async throws -> [Question]
}

class QuizUseCase: QuizUseCaseProtocol {
    private let repository: QuestionsRepositoryProtocol
}
```

## 🚫 Что НЕ делать

- Не используй `force unwrapping` (!)
- Не используй `force casting` (as!)
- Не используй `force try` (try!)
- Не создавай длинные функции (>100 строк)
- Не смешивай ответственности в одном классе
- Не дублируй код - выноси в отдельные функции
- Не игнорируй ошибки
- Не используй completion handlers вместо async/await

## ✅ Что делать

- Используй `guard` для раннего выхода
- Используй `lazy` для дорогих вычислений
- Используй `weak self` в closures
- Валидируй все входящие данные
- Документируй публичные API
- Пиши тесты для бизнес-логики
- Используй локализацию для всех строк
- Поддерживай accessibility

## 🔍 SwiftLint правила

Проект использует SwiftLint с настроенными правилами:
- Длина строки: 120 символов (warning), 150 (error)
- Длина файла: 500 строк (warning), 1000 (error)
- Длина функции: 50 строк (warning), 100 (error)
- Цикломатическая сложность: 10 (warning), 20 (error)

## 📋 Чек-лист

Перед отправкой кода проверь:
- [ ] Код следует архитектурным принципам
- [ ] Все публичные методы документированы
- [ ] Нет нарушений SwiftLint правил
- [ ] Обработка ошибок реализована
- [ ] Локализация добавлена для новых строк
- [ ] Accessibility поддержка сохранена
- [ ] Нет дублирования кода
- [ ] Функции короткие и понятные
