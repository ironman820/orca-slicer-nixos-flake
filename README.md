# Orca Slicer NixOS Flake

Минимальный package-only flake для Orca Slicer под x86_64-linux.

Пакет основан на официальном пакете nixpkgs из ветки nixos-25.11, но версия и source hash вынесены в отдельный flake, чтобы их можно было обновлять локальным скриптом.

## Что даёт

- packages.x86_64-linux.orca-slicer — Orca Slicer
- packages.x86_64-linux.default — то же самое
- overlays.default — overlay, который добавляет orca-slicer в pkgs

## Обновление

Скрипт по умолчанию смотрит самый свежий версионный релиз в GitHub Releases, включая pre-release, пересчитывает source hash и обновляет flake.nix. Служебные теги вроде nightly-builds при этом игнорируются.

```bash
./update-orca-slicer.sh
```

Если нужен только последний стабильный релиз:

```bash
ORCA_RELEASE_CHANNEL=stable ./update-orca-slicer.sh
```

Полная сборка Orca Slicer может занимать заметное время. Если нужно только обновить версию и hash без проверки сборки:

```bash
ORCA_SKIP_BUILD=1 ./update-orca-slicer.sh
```
