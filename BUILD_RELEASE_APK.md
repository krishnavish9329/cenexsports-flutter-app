# Building Optimized Release APK (30-50 MB)

## Optimizations Applied

1. **Code Shrinking (R8)**: Enabled `isMinifyEnabled = true` to remove unused code
2. **Resource Shrinking**: Enabled `isShrinkResources = true` to remove unused resources
3. **ProGuard Rules**: Added rules to keep necessary classes while obfuscating code
4. **Split APKs**: Optional - can be enabled for architecture-specific APKs (smaller but multiple files)

## Build Commands

### Option 1: Single Universal APK (Recommended for 30-50 MB target)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Option 2: Split APKs by Architecture (Smaller individual APKs)
1. Uncomment the `splits` section in `android/app/build.gradle.kts`
2. Build:
```bash
flutter build apk --release --split-per-abi
```
Output: Multiple APKs in `build/app/outputs/flutter-apk/`:
- `app-armeabi-v7a-release.apk` (~15-25 MB)
- `app-arm64-v8a-release.apk` (~15-25 MB)
- `app-x86_64-release.apk` (~15-25 MB)

### Option 3: App Bundle (For Play Store - Recommended)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`
- Google Play will generate optimized APKs automatically
- Usually 20-40% smaller than universal APK

## Additional Size Reduction Tips

1. **Remove unused assets**: Check `assets/images/` and remove unused images
2. **Optimize images**: Compress images before adding to assets
3. **Remove unused dependencies**: Check `pubspec.yaml` and remove unused packages
4. **Use WebP format**: Convert PNG/JPG to WebP for better compression
5. **Check APK size**: After building, check size with:
   ```bash
   ls -lh build/app/outputs/flutter-apk/app-release.apk
   ```

## Verify APK Size

After building, check the APK size:
```bash
# Windows PowerShell
(Get-Item build/app/outputs/flutter-apk/app-release.apk).Length / 1MB

# Linux/Mac
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

If APK is still too large:
1. Check for large assets: `du -sh assets/images/*`
2. Remove unused packages from `pubspec.yaml`
3. Enable split APKs (uncomment splits section)
4. Use App Bundle instead of APK for Play Store
