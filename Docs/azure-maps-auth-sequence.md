# Azure Maps 認証設定 シーケンス図

SignIn 成功後に `setupMapAuthentication` が呼ばれ、
MSAL でアクセストークンを取得し MapLibre の HTTP ヘッダに設定するまでの流れを示す。

## Part 1: トークン取得

サイレント認証でアクセストークンを取得する流れ。
サイレント認証失敗時はインタラクティブ認証にフォールバックする。

```mermaid
sequenceDiagram
    participant VM as AuthViewModel
    participant Config as AuthenticationConfig
    participant UC as DefaultAuthenticationUseCase
    participant Repo as MSALAuthenticationRepository
    participant Auth as MSALAuthenticator
    participant MSAL as MSALPublicClientApplication
    participant Entra as Microsoft Entra ID

    Note over VM: signIn() 成功後に呼び出し

    VM->>Config: AuthenticationConfig.load()
    Config-->>VM: config（plist から読み込み）
    Note over VM: guard azureMapsClientId が存在

    VM->>UC: getAccessToken(for: scopes)
    UC->>Repo: getAccessToken(for: scopes)

    Note over Repo: まずサイレント認証を試行
    Repo->>Auth: acquireTokenSilently(with: scopes)
    Auth->>Auth: MSALSilentTokenParameters(<br/>  scopes: scopes, account: account<br/>)
    Auth->>MSAL: acquireTokenSilent(with:)<br/>{ result, error in ... }
    MSAL->>Entra: キャッシュ/リフレッシュトークンで取得

    alt サイレント認証成功
        Entra->>MSAL: トークン応答
        MSAL->>Auth: callback(result, nil)
        Note over Auth: continuation.resume(returning: result)
        Auth->>Repo: MSALResult
        Note over Repo: result.accessToken を返却
    else サイレント認証失敗（フォールバック）
        MSAL->>Auth: callback(nil, error)
        Note over Auth: continuation.resume(throwing: error)
        Note over Repo: catch → インタラクティブ認証へ
        Repo->>Auth: acquireToken(with: scopes,<br/>webParameters: webParameters)
        Auth->>MSAL: acquireToken(with:)<br/>{ result, error in ... }
        Note over MSAL,Entra: SignIn シーケンスと同様の<br/>OAuth2 フローを実行
        Entra->>MSAL: トークン応答
        MSAL->>Auth: callback(result, nil)
        Auth->>Repo: MSALResult
    end

    Repo->>UC: accessToken (String)
    UC->>VM: accessToken (String)
```

## Part 2: URLProtocol による認証ヘッダ付与

`AzureMapsAuthProtocol`（カスタム URLProtocol）を使い、
`atlas.microsoft.com` へのリクエストのみに認証ヘッダを付与する流れ。

```mermaid
sequenceDiagram
    participant VM as AuthViewModel
    participant Proto as AzureMapsAuthProtocol
    participant MLN as MLNNetworkConfiguration
    participant MapView as MapView（MapLibre）
    participant AzureMaps as Azure Maps Tile API

    Note over VM: accessToken 取得済み

    VM->>Proto: configure(token:, clientId:)<br/>静的プロパティにクレデンシャル保持
    VM->>Proto: makeSessionConfiguration()
    Note over Proto: URLSessionConfiguration.default 生成<br/>protocolClasses に自身を登録
    Proto-->>VM: URLSessionConfiguration
    VM->>MLN: sharedManager.sessionConfiguration<br/>= config

    Note over MapView: タイル取得リクエスト発生

    MapView->>Proto: canInit(with: request)<br/>host が atlas.microsoft.com か判定

    alt atlas.microsoft.com の場合
        Note over Proto: startLoading()<br/>Authorization: Bearer {token}<br/>x-ms-client-id: {clientId}<br/>をヘッダに付与
        Proto->>AzureMaps: リクエスト転送<br/>+ 認証ヘッダ
        AzureMaps->>Proto: タイルデータ
        Proto->>MapView: レスポンス中継
    else その他のホストの場合
        Note over Proto: canInit → false<br/>ヘッダ付与なしで通常処理
    end
```

