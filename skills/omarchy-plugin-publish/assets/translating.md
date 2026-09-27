# Translating <Plugin Name>

Every piece of text this plugin shows lives in `i18n/`. English (`i18n/en.json`) is the source and the fallback: any key missing from a translation shows in English.

## Add a language

1. Copy `i18n/en.json` to `i18n/<lang>.json` — a language code like `de`, `fr`, `ja`, or language plus region like `pt_BR` when it differs from the base language.
2. Translate the **values**. Leave every key exactly as it is.
3. Keep `{placeholders}` unchanged; move them wherever the sentence needs them.
4. Plural keys end in `.one` / `.other`. If your language has more plural forms (for example `.few`, `.many`), add them and extend `pluralCategory` in `I18n.qml`.
5. Check the file: `jq -e 'type=="object" and all(.[]; type=="string")' i18n/<lang>.json`
6. Test with your locale, e.g. `LANG=de_DE.UTF-8`, and look for text that overflows or truncates.

No code changes are needed to add a language.

## Translating with an AI assistant

Paste this into your assistant from the root of your fork:

> Translate this Omarchy plugin into <language>. Copy `i18n/en.json` to `i18n/<code>.json` and translate only the values. Keep every key and every `{placeholder}` exactly as they are. Provide the plural forms <language> needs as `.one` / `.few` / `.many` / `.other` keys, and if it needs forms beyond `one`/`other`, extend `pluralCategory` in `I18n.qml` for that language. Keep strings concise — they appear in a desktop bar and panel. Do not change any other file. Then validate the JSON with jq and list any strings you were unsure about.

Review the result before publishing it; a native speaker's pass is worth it for anything user-facing.

## Don't translate

Plugin id, manifest fields, settings keys, file names, command names and anything shown as a code in logs or errors.
