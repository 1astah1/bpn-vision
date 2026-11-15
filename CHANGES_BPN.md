# BPN Vision: изменения относительно Veyra

Основа: Veyra `main` от 2026-11-15 (2.1.6, https://github.com/Likely7/Veyra-NRVideo), GPL-3.0.
Изменения внесены с 2026-11-15 и распространяются по GPL-3.0.

## Облачный Xbox (xCloud)
- `src/xbox/Account.cpp`, `include/veyra/xbox/Account.h`: вход в облачные предложения `xgpuweb` (Game Pass Ultimate) и `xgpuwebf2p` (бесплатные игры) по тому же входу Microsoft; ответ «недоступно в этой стране» отличается от ошибки сервиса.
- `src/xbox/StreamApi.cpp`, `include/veyra/xbox/StreamApi.h`: сеансы `cloud` наряду с `home`, список игр `/v2/titles`, оценка очереди `/v1/waittime`, названия и обложки из каталога Game Pass.
- `src/source/XboxSessionSource.cpp`, `include/veyra/source/XboxSessionSource.h`: запуск игры по `titleId`, ожидание в очереди облака до 30 минут с показом времени.
- `src/ui/XboxModel.cpp`, `include/veyra/ui/XboxModel.h`, `qml/Veyra/XboxSourceDialog.qml`: вкладка «Облако» со списком, поиском и запуском игр; «Продолжить» помнит облачную игру; язык игры = язык интерфейса.
- `tests/xbox/XboxTests.cpp`: офлайн-тесты облачного API и входа.

## Русский язык
- `i18n/catalog.json`: колонка `ru` для всех строк и новые строки облака на всех языках.
- `src/ui/UiLanguage.cpp`, `include/veyra/ui/UiLanguage.h`, `qml/Veyra/SettingsPage.qml`, `qml/Veyra/Theme.qml`: язык «Русский», автовыбор на русской Windows, шрифт Segoe UI для кириллицы.

## Бренд
- `include/veyra/Brand.h`, `qml/Veyra/Theme.qml`: название и адреса BPN Vision в одном месте.
- `src/ui/UpdateChecker.cpp`, `include/veyra/ui/UpdateChecker.h`, `tests/unit/UpdateCheckerTests.cpp`, `src/ui/bridge/Preferences.cpp`: обновления, ошибки и страница проекта ведут в репозиторий BPN Vision.
- `qml/Veyra/Main.qml`, `qml/Veyra/HomePage.qml`, `qml/Veyra/SettingsPage.qml`: название в интерфейсе, ссылка на BPN VPN и на оригинальный Veyra.
- `README.md`: новый; исходный перенесён в `docs/README_VEYRA_UPSTREAM.md`.

Внутренние имена (`veyra::`, файлы, папка `%LOCALAPPDATA%\Veyra`, устройство «Veyra Virtual Speaker») оставлены, чтобы настройки и пресеты Veyra подходили и правки автора сливались без конфликтов.
