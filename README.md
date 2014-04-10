# Gust translation checker

```
canonical_language = Zephyr::TranslationChecker.new(:en)
foreign_language = Zephyr::TranslationChecker.new(:fr)
```

### Get any orphaned translations from the 'fr' language
```
comparison = foreign_language.compare_with(canonical_language)
comparison[:orphaned_interpolations]
```

### Get any keys missing from the 'fr' language
```
foreign_langauge.missing_keys(canonical_language)
```
