# Microsoft Entra B2C 設定メモ

Microsoft Entra 管理センターで本アプリを動かすための手順をまとめます。

## 1. テナント準備
1. Azure ポータルで **Azure AD B2C** テナントを作成（既存があれば利用）
2. テナントをサブスクリプションと関連付け、管理者としてサインイン

## 2. アプリ登録
1. Entra 管理センター → **アプリの登録** → **新規登録**
2. 名前を入力し、「この組織ディレクトリ内のアカウントのみに対応」を選択
3. **リダイレクト URI** に `msal<CLIENT_ID>://auth` を追加
4. 登録後、以下を控える
   - アプリケーション (クライアント) ID → `CLIENT_ID`
   - ディレクトリ (テナント) ID およびテナント名 (例: `contoso`)

## 3. ユーザーフロー (B2C ポリシー)
1. **ユーザーフロー** → **新しいユーザーフロー** → 「サインアップとサインイン」
2. 名前を `B2C_1_signupsignin1` 等に設定し、作成
3. **属性**で「表示名」「メールアドレス」を収集、**アプリケーションクレーム**でも同値を返却
4. 必要に応じて MFA などを有効化

## 4. API スコープ (任意)
1. 独自 API を呼びたい場合は **API の公開** で `api.read` 等のスコープを定義
2. 管理者同意を与え、`AuthenticationConfig.plist` の `SCOPES` に `https://<tenant>.onmicrosoft.com/api/read` を追加

## 5. iOS アプリ設定
1. `AuthenticationConfig.plist` を以下の値で更新
   - `CLIENT_ID`: 手順 2 で控えた ID
   - `TENANT_DOMAIN`: `contoso` のように `onmicrosoft.com` を除いた名前
   - `POLICY_NAME`: 例 `B2C_1_signupsignin1`
   - `REDIRECT_URI`: `msal<CLIENT_ID>://auth`
   - `SCOPES`: 必要な API スコープ配列
2. Xcode の Info → URL Types に `msal<CLIENT_ID>` を追加
3. Keychain Sharing を有効化すると MSAL キャッシュを複数ターゲットで共有可能

## 6. 動作確認
1. `xcodebuild` または Xcode からアプリを起動
2. 表示された「Sign In / Sign Up」ボタンをタップし、B2C フローが開くことを確認
3. サインイン成功後、ユーザー情報が `AuthView` に表示されることを確認
4. Entra ポータルの「サインインログ」でトレース可能

## 7. トラブルシューティング
- **AADB2C90118**: パスワードリセットフローが未設定。別ポリシーを追加
- **redirect_uri mismatch**: `AuthenticationConfig.plist` と Azure ポータルの URI が一致しているか確認
- **It looks like you have not set a URL scheme**: Xcode の URL Types 設定を再確認
