# HowToEntraIos

Microsoft Entra (CIAM/B2C) のサインアップ/サインイン ユーザーフローを MSAL と SwiftUI で実装した学習用アプリです。MVVM+Observation で単一の `AuthState` を View に渡し、ViewInspector で UI テストを行います。

## 主な構成
- **Presentation**: `AuthView` + `AuthViewModel` (Observation)
- **Domain**: `AuthenticationUseCase` とユースケース実装
- **Data**: `MSALAuthenticationRepository` と `MSALAuthenticator`
- **Config**: `AuthenticationConfig.plist` で Entra 情報を管理

## セットアップ手順
1. `HowToEntraIos/Resources/AuthenticationConfig.plist.example` を `AuthenticationConfig.plist` としてコピー
2. `CLIENT_ID`, `TENANT_DOMAIN`, `POLICY_NAME`, `REDIRECT_URI`, `SCOPES` を実テナント値で更新
3. Xcode 16 以降で `HowToEntraIos.xcodeproj` を開き、カスタム URL Scheme `msal<CLIENT_ID>` をターゲットに追加
4. iOS 17 以降のシミュレータまたは実機でビルド/実行

### Microsoft Entra B2C ポータル設定
1. B2C テナントを作成/選択し、アプリ登録を新規作成
2. リダイレクト URI に `msal<CLIENT_ID>://auth` を追加
3. User Flow (例: `B2C_1_signupsignin1`) を作成し、表示名/メールを返すよう設定
4. 必要に応じて API のスコープを公開し、`AuthenticationConfig.plist` の `SCOPES` に追加
5. 取得した `CLIENT_ID`, テナント名 (例: `contoso`), ポリシー名を PLIST に反映

## テスト
ViewInspector を使った SwiftUI UI テストを `HowToEntraIosTests` に追加済みです。以下で実行できます。

```bash
cd /Users/nakasho/Works.iOS/HowToEntraIos
xcodebuild test -scheme HowToEntraIos -destination 'platform=iOS Simulator,name=iPhone 16'
```

> ※ シミュレータ名は `xcrun simctl list` で確認できる実在デバイスに変更してください。

## TODO
- [ ] エラーロギング/テレメトリ連携
- [ ] パスワードリセット等の別ポリシー対応
