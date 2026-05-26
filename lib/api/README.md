# API Codegen Notes

Generated Retrofit clients and shared transport live in this folder.

Workflow:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Rules for this migration slice:
- keep generated transport and DTO code under `lib/api/`
- keep UI/domain fallback logic in service wrappers under `lib/services/`
- do not mix new generated parsing with legacy manual parsing in same migrated endpoint
