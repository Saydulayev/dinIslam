# Tabiin Academy

<p align="center">
  <img src="https://github.com/Saydulayev/dinIslam/blob/main/dinIslam/Sreen./Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-02-05%20at%2013.09.13.png?raw=1" alt="Tabiin Academy Screenshot 1" width="240">
  <img src="https://github.com/Saydulayev/dinIslam/blob/main/dinIslam/Sreen./Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-02-05%20at%2013.11.07.png?raw=1" alt="Tabiin Academy Screenshot 2" width="240">
  <img src="https://github.com/Saydulayev/dinIslam/blob/main/dinIslam/Sreen./Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-02-05%20at%2013.12.00.png?raw=1" alt="Tabiin Academy Screenshot 3" width="240">
</p>

`Tabiin Academy` — iOS-приложение для изучения исламских знаний в формате квиза и экзамена.  
Проект написан на SwiftUI и организован по принципам Clean Architecture + MVVM.

## Ключевые возможности

- Режимы `Quiz` и `Exam`
- Повторение ошибок и отслеживание прогресса
- Статистика и достижения
- Профиль пользователя с синхронизацией через CloudKit
- Локализация: русский и английский
- Локальные уведомления (ежедневные напоминания и reminders для стрика)
- Загрузка вопросов из GitHub с кэшем и fallback на локальные ресурсы

## Технологии

- iOS `17.6+`
- Swift + SwiftUI
- Observation (`@Observable`)
- Swift Concurrency (`async/await`)
- URLSession + Network framework
- UserDefaults, файловый кэш, CloudKit

## Архитектура

- `Domain` — модели, use cases, репозитории, менеджеры
- `Presentation` — SwiftUI views и view models
- `Resources` — JSON-вопросы и локализационные файлы

Краткая структура:

```text
.
├── dinIslam.xcodeproj
├── dinIslam/
│   ├── Domain/
│   ├── Presentation/
│   └── Resources/
├── dinIslamTests/
├── docs/
├── update_local_questions.sh
└── update_questions_build_phase.sh
```

## Быстрый старт

### Требования

- macOS с установленным Xcode 15+
- iOS SDK 17.6+

### Запуск

1. Клонировать репозиторий:

   ```bash
   git clone <repository-url>
   cd dinIslam
   ```

2. Открыть проект:

   ```bash
   open dinIslam.xcodeproj
   ```

3. Выбрать симулятор/устройство и запустить (`Cmd + R`).

## Тесты

Запуск из Xcode: `Cmd + U`.

CLI-вариант:

```bash
xcodebuild test \
  -project dinIslam.xcodeproj \
  -scheme dinIslam \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Данные вопросов

Основные файлы:

- `dinIslam/Resources/questions.json` (RU)
- `dinIslam/Resources/questions_en.json` (EN)

Поддерживаемый компактный формат:

```json
{
  "id": "q1",
  "q": "Текст вопроса",
  "a": ["Ответ 1", "Ответ 2", "Ответ 3", "Ответ 4"],
  "c": 0
}
```

Также поддерживаются альтернативные поля (`text`/`question`) и разные форматы `answers`/`id` для обратной совместимости.

Удаленный источник вопросов:

- `https://raw.githubusercontent.com/Saydulayev/dinIslam-questions/main/questions.json`
- `https://raw.githubusercontent.com/Saydulayev/dinIslam-questions/main/questions_en.json`

## Обновление локальных вопросов

Ручное обновление:

```bash
./update_local_questions.sh
```

Автообновление в процессе сборки:

- используйте `update_questions_build_phase.sh` в `Build Phases` проекта.

## Документация и privacy pages

- `docs/index.html`
- `docs/privacy-ru.html`
- `docs/privacy-en.html`

Эти файлы можно публиковать через GitHub Pages и использовать URL в App Store Connect (`Privacy Policy URL`).

## Вклад

1. Создайте ветку: `git checkout -b feature/your-change`
2. Внесите изменения и закоммитьте
3. Откройте Pull Request

## Лицензия

Проект создан в образовательных целях.
