# SwiftUI Guidelines (iOS 17+, Swift 5.9+)

## Цели
- Таргет: **iOS 17+**, Swift 5.9+, Xcode 15+.
- Приоритет: **современные API** и чистая архитектура (MVVM + сервисы).
- Используем:
  - Observation (`@Observable`, `@Bindable`, `@Environment(SomeType.self)`)
  - Swift Concurrency (`async/await`, `Task`, `actors`)
  - NavigationStack / NavigationSplitView
  - `#Preview`
  - SwiftData при необходимости

## Архитектура
- MVVM + Use Cases + сервисы
- View: только UI и привязка к стейту
- ViewModel: `@Observable`, бизнес-логика, DI
- Сервисы: выделены в протоколы, инжектируются через init

## Состояние
- `@State` — для локального состояния
- `@Environment(SomeType.self)` — для глобальных моделей
- `@Bindable` — для биндинга к `@Observable`-моделям

## Навигация
- Только `NavigationStack` и `navigationDestination`
- Маршруты описываются через enum

## Асинхронность
- Используем `async/await`, `Task`, `@MainActor`
- Избегаем completion handler'ов в новом коде

## Память
- Следить за `retain cycle` (особенно в `Task` и замыканиях)
- Избегать синглтонов для сервисов

## SOLID
- Single Responsibility
- Open/Closed (расширяем через новые типы, а не переписываем старые)
- Dependency Inversion через протоколы

## Стиль
- Говорящие имена
- System-палитра, адаптивный UI
- Модульность: UI-компоненты и модификаторы выносим

## Принципы для ИИ
- Не используй `NavigationView`, `ObservableObject`, `@EnvironmentObject`, если не требуется совместимость
- Следуй этим правилам при генерации и анализе кода
- При нарушении — сначала предложи рефакторинг, потом расширяй функционал

