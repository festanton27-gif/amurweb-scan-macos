# AMURWEB Scan for macOS 0.1.0 Alpha

Первый macOS-прототип AMURWEB Scan.

## Что уже работает в Alpha

- нативный интерфейс SwiftUI для macOS 13+;
- верхнее системное меню macOS;
- русский и английский языки;
- запоминание языка, DPI, режима, формата, папки и выбранного устройства;
- выбор папки через штатный Finder (`NSOpenPanel`);
- JPG, PNG и одностраничный PDF;
- автоматические имена `Скан/Scan - YYYY-MM-DD - 001`;
- общая последовательность номера между JPG/PNG/PDF;
- предпросмотр;
- окно «О программе» с AMURWEB, `awc-dv.ru` и `info@awc-dv.ru`;
- техподдержка и правовая информация;
- Mock Scanner для тестирования без физического сканера;
- GitHub Actions: Apple Silicon + Intel → Universal app → DMG.

## Пока НЕ включено

Аппаратное сканирование. `ImageCaptureScannerBackend` специально оставлен отдельным слоем и будет реализован через ImageCaptureCore после того, как CI подтвердит сборку приложения на macOS.

## Почему Mock Scanner полезен

У разработчика сейчас нет физического Mac. Mock Scanner позволяет автоматически проверить почти всю продуктовую логику: интерфейс, Finder, настройки, форматы, PDF и нумерацию. Для подтверждения реальной совместимости со сканерами всё равно потребуется внешний тест на Mac со сканером.

## Локальная сборка на Mac

```bash
swift test
swift build -c release
```

## Автоматическая сборка без Mac

Файл `.github/workflows/macos-build.yml` запускает две реальные macOS-машины GitHub: Apple Silicon и Intel. После успешной компиляции создаётся Universal `.dmg`.

Текущий Alpha использует ad-hoc подпись. Перед публичным стабильным релизом нужен Developer ID и Apple notarization.
