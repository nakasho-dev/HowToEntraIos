# SignIn シーケンス図

SignedOutView の SignIn ボタン押下から、MSAL ライブラリ経由で Microsoft Entra ID 認証を行い、
ユーザ情報を取得・表示するまでの流れを示す。
Azure Maps 認証設定（`setupMapAuthentication`）については別図を参照。

## Part 1: アプリ → MSAL SDK 呼び出し

SignIn ボタンタップからクリーンアーキテクチャの各層を経由し、
MSAL SDK の `acquireToken` を呼び出すまでの流れ。

```mermaid
sequenceDiagram
    actor User
    participant SignedOut as SignedOutView
    participant View as AuthView
    participant VM as AuthViewModel
    participant UC as DefaultAuthenticationUseCase
    participant Repo as MSALAuthenticationRepository
    participant Auth as MSALAuthenticator
    participant MSAL as MSALPublicClientApplication

    User->>SignedOut: SignIn ボタンタップ
    SignedOut->>View: onSignIn() コールバック
    View->>VM: Task { await signIn() }
    Note over VM: state.isProcessing = true<br/>state.alert = nil

    VM->>UC: signIn()
    UC->>Repo: signIn()

    Repo->>Repo: RootViewControllerProvider.current()<br/>→ UIViewController 取得
    Note over Repo: MSALWebviewParameters(<br/>  authPresentationViewController: vc<br/>)

    Repo->>Auth: acquireToken(with: scopes,<br/>webParameters: webParameters)
    Note over Auth: withCheckedThrowingContinuation で<br/>コールバックを async/await に変換

    Auth->>Auth: MSALInteractiveTokenParameters(<br/>  scopes: scopes,<br/>  webviewParameters: webParameters<br/>)
    Auth->>MSAL: application.acquireToken(with:)<br/>{ result, error in ... }
```

## Part 2: Entra ID 認証 → ユーザ情報取得

MSAL SDK が Entra ID と通信し、認証結果を受け取ってから
`AuthenticatedUser` を生成して UI に反映するまでの流れ。

```mermaid
sequenceDiagram
    actor User
    participant SignedIn as SignedInOverlayView
    participant View as AuthView
    participant VM as AuthViewModel
    participant Repo as MSALAuthenticationRepository
    participant Auth as MSALAuthenticator
    participant MSAL as MSALPublicClientApplication
    participant Entra as Microsoft Entra ID

    MSAL->>Entra: OAuth2 認可リクエスト
    Note over MSAL,Entra: ASWebAuthenticationSession で<br/>ログイン画面を表示
    Entra->>User: ログイン画面表示
    User->>Entra: 資格情報入力
    Entra->>MSAL: 認可コード発行
    MSAL->>Entra: 認可コード → トークンエンドポイント
    Entra->>MSAL: トークン応答<br/>(access_token, id_token, refresh_token)

    Note over MSAL: MSALResult 生成<br/>・accessToken: String<br/>・account.accountClaims<br/>・account.identifier
    MSAL->>Auth: callback(result, nil)
    Note over Auth: continuation.resume(returning: result)

    Auth->>Repo: MSALResult
    Note over Repo: makeUser(from: MSALResult)<br/>claims["name"] → displayName<br/>identifier → objectId
    Repo-->>VM: AuthenticatedUser

    Note over VM: state.phase = .signedIn(user)<br/>defer: state.isProcessing = false
    VM->>View: state 更新（Observation）
    Note over View: phase が .signedIn に変化<br/>→ SignedInOverlayView を表示
    View->>SignedIn: user, isProcessing,<br/>selectedMapStyle, onSignOut を渡す
    SignedIn->>User: ようこそ画面表示
```

## エラー系

認証失敗時（ユーザキャンセル・資格情報不正等）の流れ。

```mermaid
sequenceDiagram
    participant VM as AuthViewModel
    participant Auth as MSALAuthenticator
    participant MSAL as MSALPublicClientApplication
    participant Entra as Microsoft Entra ID
    participant View as AuthView
    participant SignedOut as SignedOutView
    actor User

    Note over MSAL,Entra: ※ Part 1〜2 と同様に進行後

    Entra->>MSAL: エラー応答
    MSAL->>Auth: callback(nil, error)
    Note over Auth: continuation.resume(throwing: error)
    Auth-->>VM: throw Error（各層を伝播）

    Note over VM: state.alert = AuthAlert(message:)<br/>state.phase = .signedOut<br/>defer: state.isProcessing = false
    VM->>View: state 更新（Observation）
    Note over View: phase が .signedOut に変化<br/>→ SignedOutView を表示
    View->>User: エラーダイアログ表示
```