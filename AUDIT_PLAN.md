# План исправлений по итогам аудита UI/UX

Исправления идут поэтапно, от самого важного к менее важному.

## Порядок работы на каждом этапе

1. Работа в отдельной локальной ветке, `main` не трогаем.
2. Только правки текущего этапа — ничего сверх.
3. Сборка и тесты (`xcodebuild build` / `test`).
4. Сводка: что изменено и почему, затронутые файлы, что проверить в симуляторе.
5. Коммит — только после одобрения.
6. **`push` — только по отдельной явной команде.**

Приоритеты: **C** — Critical, **H** — High, **M** — Medium, **L** — Low.

---

## Этап 1. Баги экзамена

- [ ] **C1** — «Пересдать» открывает пустой экран: `restartExam()` очищает вопросы, а новый экзамен не запускается (`onRestartExam` нигде не задан).
  `ExamView.swift:255`, `ExamViewModel.swift:331`
- [ ] **C2** — при выключенном «Автозавершении» после истечения таймера состояние остаётся `.timeUp`, и ответить на следующие вопросы нельзя.
  `ExamViewModel.swift:385–426`
- [ ] **C3** — `finishExam()` не отменяет `nextQuestionTask`: досрочное «Завершить» сразу после ответа дублирует статистику или запускает таймер за экраном результата.
  `ExamViewModel.swift:209`, `:272`
- [ ] **H3** — в экзамене показывается id категории («prophets») вместо локализованного названия.
  `ExamView.swift:79`
- [ ] **H4** — настройка «Показывать таймер» (`showTimer`) нигде не учитывается.
  `ExamView.swift` (`ExamHeaderView`)

## Этап 2. VoiceOver в викторине и экзамене

- [ ] **C4** — `accessibilityLabel("Answer option N")` заменяет текст ответа; строки accessibility на английском и не локализованы; результат ответа не озвучивается.
  `QuizView.swift:156,190–191,245`, `ExamView.swift:73,104–105,156,198,235`, `MistakesReviewView.swift:101,157–158,226`
- [ ] **M7** — правильный, но не выбранный ответ выделен только цветом, без иконки.
  `QuizView.swift:343–351`

## Этап 3. Честные тексты и состояния загрузки

- [ ] **H1** — досрочное «Завершить» в викторине обещает «Результаты будут сохранены», но статистика не записывается; процент считается от всех вопросов, включая неотвеченные.
  `QuizViewModel.swift:332`, `Localizable.strings` (`quiz.finish.confirm.message`)
- [ ] **H2** — у экрана экзамена нет состояний загрузки и ошибки (виден «1 / 0», ошибка не показывается).
  `ExamView.swift`, `ExamViewModel.swift:176`
- [ ] **M5** — загрузка викторины перекрывается шапкой «1 / 0», кнопка «Завершить» активна во время загрузки.
  `QuizView.swift:49–85`
- [ ] **H12** — жёстко прописанные «сек» и «s» в английской версии.
  `ExamSettingsView.swift:121,484`, `ResultView.swift:352`

## Этап 4. Единый поток повторения ошибок

- [ ] **H5** — «Повторить ещё раз» после повторения из профиля закрывает экран.
  `MistakesReviewNavigationView.swift:53–55,138–142`
- [ ] **H6** — повторение из профиля создаёт второй DI-граф (`DIContainer.createDependencies()`) и использует отдельные экраны. Перевести на `StartViewModel.startReview(scope:)`, удалить `MistakesReviewNavigationView`, `MistakesReviewView`, `MistakesResultView`.
  `UnifiedProfileView.swift:231–262`

## Этап 5. Подтверждения разрушительных действий

- [ ] **H11** — «Начать заново» на экране завершения банка сбрасывает прогресс без подтверждения.
  `BankCompletionView.swift:104`
- [ ] **M18** — «Выйти из аккаунта» без подтверждения.
  `ProfileCardView.swift:145`

## Этап 6. Базовая доступность

- [ ] **H7** — Dynamic Type: токены `DesignTokens.Typography` перевести на текстовые стили; убрать `.dynamicTypeSize(.large)`; снять `maxHeight: 110` в `ProgressCardView`.
  `DesignTokens.swift:141–158`, `QuizView.swift:158`, `ExamView.swift:75`, `MistakesReviewView.swift:103`, `ProgressCardView.swift:64`
- [ ] **H8** — `Toggle("")` без подписи; строки настроек, выбор языка и карточки достижений на `onTapGesture` вместо `Button`.
  `SettingsView.swift:69,94,387,431`, `ExamSettingsView.swift:169,185,201`, `NotificationSettingsView.swift:154`, `AchievementsView.swift:236`
- [ ] **H9** — кнопки только с иконкой и зоны нажатия меньше 44 pt: меню «…», карандаш аватара, редактирование имени, свой шеврон «назад».
  `StartView.swift:210`, `ProfileCardView.swift:61,109–121`, `MistakesReviewNavigationView.swift:145`

## Этап 7. Обновление UI уведомлений и синхронизации

- [ ] **H10** — `NotificationManager` и `EnhancedRemoteQuestionsService` (`ObservableObject`) читаются через кастомный `@Environment`, поэтому SwiftUI не отслеживает изменения. Сначала подтвердить в симуляторе, затем перевести на `@Observable`.
  `NotificationSettingsView.swift:12`, `ProfileSyncSectionView.swift:12`

## Этап 8. Удаление аккаунта и политика конфиденциальности (блокер App Store)

- [ ] **C5** — добавить «Удалить аккаунт» (запись CloudKit + локальные данные + выход); привести политику конфиденциальности (in-app и `docs/`) и App Privacy labels в соответствие с фактическими данными: имя, email, фото, синхронизация через iCloud, загрузка вопросов с GitHub.
  `ProfileAuthService.swift:18`, `CloudKitProfileService.swift:82`, `Localizable.strings` (`privacy.*`), `docs/privacy-*.html`

Этап требует решений (см. ниже) и может быть перенесён раньше.

## Этап 9. Medium-пункты

- [ ] **M1** — переключатель «Автозавершение» не меняет поведения.
- [ ] **M2** — таймер экзамена отстаёт (шаг 0.1 с в цикле) и отображается рывками. `DefaultExamTimerManager.swift:49–67`
- [ ] **M3** — пороги цвета таймера 10/20 с не зависят от лимита. `ExamView.swift:337`
- [ ] **M4** — пауза и истечение времени никак не отображаются в UI экзамена.
- [ ] **M6** — при VoiceOver 1,5 с на правильный ответ недостаточно; показывать «Далее». `QuizViewModel.swift:239`
- [ ] **M8** — двойной звук и вибрация при выборе ответа. `QuizViewModel.swift:222`
- [ ] **M9** — из нескольких новых достижений показывается только первое; оверлей не модальный для VoiceOver. `ResultView.swift:356`
- [ ] **M10** — `.toolbarBackground(.clear)` + `.visible` на 19 экранах: контент уходит под заголовок без размытия.
- [ ] **M11** — «Готово» на экране настроек, открытом через push. `SettingsView.swift:318`
- [ ] **M12** — `SettingsViewModel` создаётся заново в `body`. `SettingsView.swift:490–498`
- [ ] **M13** — `mailto:` молча не срабатывает без настроенной почты. `SettingsView.swift:155–175`
- [ ] **M14** — кнопка «Оценить» через `SKStoreReviewController` может ничего не показать. `SettingsViewModel.swift:94`
- [ ] **M15** — после отказа в уведомлениях нет пути в системные настройки. `NotificationSettingsView.swift:255`
- [ ] **M16** — кнопка Sign in with Apple чёрная на чёрном фоне. `ProfileCardView.swift:149`
- [ ] **M17** — красные «Сбросить» в правом верхнем углу; разная семантика сброса. `UnifiedProfileView.swift:102–117`, `AchievementsView.swift:89`
- [ ] **M19** — аватар читается с диска синхронно в `body`. `ProfileViewHelpers.swift:71`
- [ ] **M20** — картинка для шаринга достижения ~75 МБ (`scale = UIScreen.main.scale`). `AchievementsView.swift:372`
- [ ] **M21** — «0 / 0» на профиле, пока загружается количество вопросов. `ProfileStatsSectionView.swift:34`
- [ ] **M22** — ландшафт на iPhone включён, но экраны викторины и экзамена не адаптированы.
- [ ] **M23** — низкий контраст у заблокированных достижений (`opacity(0.6)`). `AchievementsView.swift:234`
- [ ] **M24** — «Играть снова» после ежедневной практики или повторения запускает обычную викторину. `StartView.swift:134`

## Этап 10. Дизайн-система и чистка (без визуальных изменений)

- [ ] Одна реализация свечения (`glowBorder`) вместо 50 копий.
- [ ] `AppBackground` вместо 20 копий градиента фона.
- [ ] `DSButtonStyle` с ролями primary / secondary / destructive.
- [ ] Семантические цвета, `displayScore`, токены радиусов и иконок; убрать литералы `Color(hex:)` и `.font(.system(size:))` вне токенов.
- [ ] Удалить мёртвый код: `ProfileView.swift`, `StatsView.swift`, `LiquidGlassModifier`, частицы в `StartViewModel`, `showingStopConfirm` в `QuizView`, неиспользуемые `resolved*` в `ProgressCardView`.
- [ ] Одна функция определения языка вместо четырёх.
- [ ] Не создавать `DefaultQuestionPoolProgressManager()` во View — внедрять зависимость.

## Этап 11. Low-полировка

- [ ] `.navigationBarLeading/Trailing` → `.topBarLeading/Trailing`; `foregroundColor` → `foregroundStyle`; `.cornerRadius` → `clipShape`.
- [ ] Мёртвые ветки `#available(iOS 17)`.
- [ ] `Divider().background(...)` → `.overlay(...)`.
- [ ] Reduce Motion для свечения логотипа и spring-анимаций.
- [ ] Иконка «Отвечено» в результате экзамена, лишний `interactiveDismissDisabled`.
- [ ] «+-N» в статусе синхронизации вопросов.
- [ ] Время напоминания отображается дважды.
- [ ] Шевроны у навигационных строк настроек.
- [ ] `NSLocalizedString` в шаринге → `.localized`.
- [ ] Цвет фона экрана запуска (белая вспышка).
- [ ] Заголовки файлов, номер сборки в «О приложении».
- [ ] Общий `PressableButtonStyle` для кнопок с `.plain`.

---

## Открытые решения

| # | Вопрос | Этап |
|---|---|---|
| 1 | При досрочном завершении викторины только исправить текст или засчитывать отвеченные вопросы? | 3 |
| 2 | Переключатель «Автозавершение»: убрать или оставить? | 1 / 9 |
| 3 | Удаление аккаунта: iCloud-запись + локальные данные без сервера — достаточно? Нужен ли email из Sign in with Apple? | 8 |
| 4 | Фиксировать портретную ориентацию на iPhone? | 9 |
| 5 | Перенести кнопки «Сбросить» из верхней панели вниз экрана? | 9 |

## Ручной прогон перед релизом

- [ ] iPhone SE (3rd gen) и iPhone Pro Max
- [ ] Dynamic Type на размере AX5
- [ ] Полный сценарий под VoiceOver: старт → викторина → результат → профиль
- [ ] Reduce Motion и Increase Contrast
- [ ] Авиарежим: первый запуск без кэша, викторина, экзамен, синхронизация
- [ ] Английский язык: нет русских строк и сырых id
- [ ] Вход через Apple и анонимный режим: сброс, выход, удаление аккаунта
