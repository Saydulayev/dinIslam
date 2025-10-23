# Пример интеграции улучшенной сетевой архитектуры

## 🚀 Быстрая интеграция

### Шаг 1: Добавление файлов в проект

Добавьте следующие файлы в ваш Xcode проект:
1. `NetworkManager.swift`
2. `EnhancedRemoteQuestionsService.swift`
3. `EnhancedQuestionsRepository.swift`
4. `EnhancedDIContainer.swift`

### Шаг 2: Обновление StartView для предзагрузки

```swift
// В StartView.swift добавьте в .onAppear:
.onAppear {
    // Предзагрузка вопросов для улучшения UX
    Task {
        await EnhancedDIContainer.shared.enhancedQuizUseCase.preloadQuestions(
            for: ["ru", "en"]
        )
    }
}
```

### Шаг 3: Обновление QuizViewModel

```swift
// В QuizViewModel.swift замените инициализацию:
init(quizUseCase: EnhancedQuizUseCaseProtocol, statsManager: StatsManager, settingsManager: SettingsManager) {
    self.quizUseCase = quizUseCase
    // остальная инициализация...
}

// И обновите тип свойства:
private let quizUseCase: EnhancedQuizUseCaseProtocol
```

### Шаг 4: Обновление DIContainer в приложении

```swift
// В dinIslamApp.swift или где используется DIContainer:
let enhancedContainer = EnhancedDIContainer.shared

// Передайте enhancedContainer в ваши ViewModels
```

## 🔧 Конфигурация для разных окружений

### Development (быстрые таймауты)
```swift
EnhancedDIContainer.shared.configureNetwork(
    timeout: 10.0,
    maxRetries: 2,
    retryDelay: 0.5
)
```

### Production (надежные настройки)
```swift
EnhancedDIContainer.shared.configureNetwork(
    timeout: 30.0,
    maxRetries: 3,
    retryDelay: 1.0
)
```

### Screenshots
```swift
EnhancedDIContainer.shared.configureCache(
    ttl: 60 * 60, // 1 час для скриншотов
    maxCacheSize: 10 * 1024 * 1024, // 10MB
    compressionEnabled: true
)
```

## 📊 Мониторинг и отладка

### Добавление логов в StartView
```swift
.onAppear {
    Task {
        let cacheStatus = EnhancedDIContainer.shared.enhancedQuizUseCase.getCacheStatus()
        print("📊 Cache status: \(cacheStatus)")
        
        await EnhancedDIContainer.shared.enhancedQuizUseCase.preloadQuestions(
            for: ["ru", "en"]
        )
    }
}
```

### Отображение статуса сети
```swift
// В StartView добавьте индикатор сети:
@State private var networkStatus: NetworkStatus = .unknown

.onReceive(EnhancedDIContainer.shared.enhancedRemoteQuestionsService.$networkStatus) { status in
    networkStatus = status
}

// В UI:
if networkStatus == .disconnected {
    Text("📡 No internet connection")
        .foregroundColor(.orange)
        .font(.caption)
}
```

## 🧪 Тестирование

### Unit тест для NetworkManager
```swift
func testNetworkRetry() async throws {
    let networkManager = NetworkManager(configuration: .default)
    
    // Мокаем URLSession для тестирования retry
    // ...
}
```

### Integration тест для кэша
```swift
func testCacheExpiration() async {
    let cacheManager = CacheManager()
    
    // Тестируем TTL кэша
    // ...
}
```

## 🚨 Обработка ошибок в UI

### Обновление StartView для отображения ошибок
```swift
@State private var networkError: String?

.onAppear {
    Task {
        do {
            await EnhancedDIContainer.shared.enhancedQuizUseCase.preloadQuestions(
                for: ["ru", "en"]
            )
        } catch {
            networkError = error.localizedDescription
        }
    }
}

// В UI:
if let error = networkError {
    Text("⚠️ \(error)")
        .foregroundColor(.red)
        .font(.caption)
}
```

## 📱 Адаптация для разных размеров экрана

### Оптимизация кэша для iPhone vs iPad
```swift
#if os(iOS)
let maxCacheSize: Int
if UIDevice.current.userInterfaceIdiom == .pad {
    maxCacheSize = 200 * 1024 * 1024 // 200MB для iPad
} else {
    maxCacheSize = 100 * 1024 * 1024 // 100MB для iPhone
}
#endif
```

## 🔄 Постепенная миграция

### Этап 1: Добавить новые файлы (без изменений в существующем коде)
- Все новые файлы работают параллельно со старыми

### Этап 2: Обновить DIContainer
- Добавить новые зависимости
- Сохранить старые для обратной совместимости

### Этап 3: Обновить ViewModels
- Постепенно переходить на новые Use Cases
- Тестировать каждый компонент

### Этап 4: Удалить старые файлы
- После полной миграции и тестирования

## 📈 Метрики производительности

### Добавление аналитики
```swift
// В NetworkManager добавить отслеживание:
private func trackNetworkMetrics(duration: TimeInterval, success: Bool) {
    // Отправка метрик в аналитику
    Analytics.track("network_request", parameters: [
        "duration": duration,
        "success": success,
        "retry_count": retryCount
    ])
}
```

Этот подход обеспечивает плавную миграцию без нарушения существующего функционала.
