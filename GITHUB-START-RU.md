# Как получить первый macOS DMG без собственного Mac

1. Открыть вкладку **Actions** в репозитории.
2. Выбрать workflow **macOS Alpha Build**.
3. При необходимости нажать **Run workflow**.
4. Дождаться трёх задач: Apple Silicon, Intel, Universal DMG.
5. Внизу страницы успешного запуска скачать artifact `AMURWEB-Scan-macOS-0.1.0-Alpha-Universal`.

Внутри будут:

- `AMURWEB-Scan-macOS-0.1.0-Alpha-Universal.dmg`
- `SHA256SUMS.txt`

## Важно

Эта версия предназначена для проверки сборки и интерфейса. Она использует виртуальный Mock Scanner. Реальный ImageCaptureCore backend подключается следующим этапом.
