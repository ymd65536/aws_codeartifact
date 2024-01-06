# aws_codeartifact

AWS CodeArtifactのハンズオン

## はじめに

この記事では 手を動かしながらAWSが提供するAWS CodeArtifact(以下、CodeArtifact)を学習していく記事です。主な内容としては実践したときのメモを中心に書きます。
（忘れやすいことなど）誤りなどがあれば書き直していく予定です。

## AWS CodeArtifactとは

AWS CodeArtifactはパッケージマネージャツール(Maven、Gradle、npm、Yarn、Twine、pip、NuGetなど)でダウンロードするパッケージを管理するサービスです。

AWSのドキュメントでは以下のように説明されています。

> ソフトウェア開発のためのセキュアかつスケーラブルでコスト効率性に優れたパッケージ管理

> CodeArtifact を使用すると、一般的なパッケージマネージャーを使用してアーティファクトを格納し、Maven、Gradle、npm、Yarn、Twine、pip、NuGet などのツールを構築できます。CodeArtifact は、パブリックパッケージリポジトリからオンデマンドでソフトウェアパッケージを自動的にフェッチできるため、アプリケーションの依存関係の最新バージョンにアクセスできます。

[参考](https://aws.amazon.com/jp/codeartifact/)

ソフトウェアパッケージはアップストリームとダウンストリームを作成して配信が可能です。

アーティファクト？パブリックパッケージリポジトリ？ソフトウェアパッケージ？アップストリーム？ダウンストリーム？パッケージマネージャー？
何が何だかわかりませんね。まとめて解説していきます。

## 前提知識

### そもそもCodeArtifactのArtifact(アーティファクト)ってなんですか

簡単に言えば、人工的な成果物です。※ITでは自然発生するものはないので単に成果物と言っても差し支えないでしょう。

　IT以外の分野では人工物という意味があります。

>人工物。人の手によって作られたもの。信号処理や画像処理の過程で発生するデータの誤りや信号の歪ゆがみ。人為的な作業によって意図せず生じるノイズを指す。

[コトバンクより](https://kotobank.jp/word/%E3%82%A2%E3%83%BC%E3%83%86%E3%82%A3%E3%83%95%E3%82%A1%E3%82%AF%E3%83%88-676397#:~:text=%E3%82%A2%E3%83%BC%E3%83%86%E3%82%A3%E3%83%95%E3%82%A1%E3%82%AF%E3%83%88%EF%BC%88artifact%EF%BC%89,%E3%81%9A%E7%94%9F%E3%81%98%E3%82%8B%E3%83%8E%E3%82%A4%E3%82%BA%E3%82%92%E6%8C%87%E3%81%99%E3%80%82)

要するに人の手で作られたものという意味ですね。
まだQiitaで解説はしていませんが、CodeBuildを使ったことがあるならば、ビルドアーティファクトという言葉に聞き覚えがあると思います。

CodeBuildのアーティファクトはビルドされた成果物、つまりはこれも一種のアーティファクトです。ストレージにS3を利用すると思いますが、実際に保存されたものの中身を開けてみると `buildspec.yml`で指定されたファイル(成果物)が格納されています。

### パブリックパッケージリポジトリとは

アーティファクトは成果物ということがわかりました。ではその成果物はどこに保存するのでしょうか。
ここで登場するのがリポジトリです。アーティファクトはリポジトリに保存されて管理されます。

リポジトリにはパブリックとプライベートの2種類があり、`パブリックパッケージリポジトリ`はパブリックリポジトリの一つです。

### パブリックパッケージリポジトリのパッケージってなんですか

パッケージは直訳するといろんなものを組み合わせて作成した製品ですが、我々の業界ではSDKやFW、ライブラリがパッケージと表現される場合があります。そしてこれをソフトウェアパッケージと呼びます。

ソフトウェアパッケージはパッケージを管理するパッケージマネージャーで管理されます。管理ツールのことを総称してパッケージマネージャーと呼びます。

### パッケージマネージャには何があるの

プログラミング言語で言えば、言語毎に複数存在します。

|名前|言語|
|:---|:---|
|Maven、Gradle|Java|
|npm、Yarn|Node.js|
|Twine、pip|Python|
|NuGet|C#|

様々な種類がありますが、共通していれることとして全て外部にあるパッケージリポジトリを参照することです。
※説明する資料によってはパッケージリポジトリを `パブリックレジストリ`と表現することもあります。

なお、今回のハンズオンではNode.jsの`npm`と`yarn`を利用します。

### ダウンストリームやアップストリームとは何か

ここまででなんとなくパッケージマネージャやリポジトリについて理解できたと思います。
パッケージマネージャーを使ってそのパブリックリポジトリからパッケージを持ってくれば、それでもソフトウェアは動きます。

しかし、これではいくつかの問題があります。例えば、開発元が配信をやめたらどうなるでしょうか。
また、意図するしないに関係なく最新バージョンのパッケージに脆弱性が内在していたり
破壊的アップデートがあったらどうでしょうか。

もちろん、ソフトウェアは動きませんし、脆弱性を利用されて危険な状態になるかもしれません。
OSSについてここでは詳しく説明しませんが、その多くは無償の成果物で成り立っています。開発元の意思でどうにでもなるものです。

そこで開発元が許す範囲でパッケージをダウンロードした人がパッケージを配布するという方法、再配布が生まれました。※仮に再配布する人を`再配布者`と呼ぶことにします。

そうすると開発元と再配布者、実際にパッケージを利用する人　(エンドユーザー)の3人に分かれます。

この3人のうち開発元と再配布者に成り立つ関係をアップストリーム
再配布者とエンドユーザーに成り立つ関係をダウンストリームと呼びます。

[参考](https://www.miraclelinux.com/tech-blog/what_is_upstream_and_downstream)

## AWS CodeArtifactで登場する用語

### ドメイン

概ねここまででパッケージが配布される仕組みについて説明しました。AWSで「パッケージを配布する仕組み」を実現するサービスとしてCodeArtifactが存在します。

CodeArtifactでパッケージを配布する場合はパッケージを保存する区画となる`ドメイン`を作る必要があります。このドメインはリポジトリの場所を示すドメイン名(DNSで利用されるドメイン名と同一)の一部になります。

## ハンズオン

今回はNode.jsのnpmを使ってオレオレパッケージを配布する方法を紹介します。

### 前提

- Node.js
    - v16.17.0
    - volta でインストールしてます
        - [getting started](https://docs.volta.sh/guide/getting-started)
- npm
    - 9.7.1
- yarn
    - 3.6.0
- AWS CLI
    - aws-cli/2.12.1 Python/3.11.4 Darwin/22.5.0 source/arm64 prompt/off

### GitHubからコードを持ってくる

デスクトップに今回利用するリポジトリをクローンします。

```sh
git clone https://github.com/ymd65536/aws_codeartifact.git ~/Desktop/aws_codeartifact && cd ~/Desktop/aws_codeartifact/
```

### 環境変数のセット

```sh
export PROFILE_NAME="artifacttest"
export AWS_DOMAIN="cf-handson-domain" && echo $AWS_DOMAIN
export REPOSITORY_NAME="cfhandson"

export AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile $PROFILE_NAME --query 'Account' --output text` && echo $AWS_ACCOUNT_ID
export AWS_DEFAULT_REGION="ap-northeast-1" && echo $AWS_DEFAULT_REGION
```

### 補足：IAM Identity Centerを利用している場合

環境変数をセットした後にログインを忘れないようにしてください。
以下のコマンドでログインできます。

```sh
aws sso login --profile $PROFILE_NAME
```

### ドメインを作成する

AWS CLIでドメインを作成します。

```sh
aws codeartifact create-domain --domain cf-handson-domain --profile codeartifact
```

### リポジトリを作成する

```sh
aws codeartifact create-repository --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --repository $REPOSITORY_NAME --profile $PROFILE_NAME
```

### npm-storeを作成する

```sh
aws codeartifact create-repository --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --repository npm-store --profile $PROFILE_NAME
```

### リポジトリとnpm-store を接続する

```sh
aws codeartifact associate-external-connection --domain $AWS_DOMAIN  --domain-owner $AWS_ACCOUNT_ID --repository npm-store --external-connection "public:npmjs" --profile $PROFILE_NAME
```

### リポジトリを更新する

```sh
aws codeartifact update-repository --repository cfhandson --domain $AWS_DOMAIN  --domain-owner $AWS_ACCOUNT_ID --upstreams repositoryName=npm-store --profile $PROFILE_NAME
```

### CodeArtifactにログイン

エンドポイントの取得やトークンの取得が必要となる為、CodeArtifactににログインします。

```sh
aws codeartifact login --tool npm --domain $AWS_DOMAIN --region $AWS_DEFAULT_REGION --domain-owner $AWS_ACCOUNT_ID --repository $REPOSITORY_NAME --profile $PROFILE_NAME
```

### エンドポイントURLの取得とCODEARTIFACT_AUTH_TOKENの発行

```sh
export CODEARTIFACT_URL=`aws codeartifact get-repository-endpoint --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --repository $REPOSITORY_NAME --format npm --profile $PROFILE_NAME` && && echo $CODEARTIFACT_URL
export CODEARTIFACT_AUTH_TOKEN=`aws codeartifact get-authorization-token --domain $AWS_DOMAIN --region $AWS_DEFAULT_REGION --domain-owner $AWS_ACCOUNT_ID --query authorizationToken --output text --profile $PROFILE_NAME` && echo $CODEARTIFACT_AUTH_TOKEN
```

## npmの設定

CodeArtifactとパッケージマネージャを接続する為にnpmの設定を変更します。
※このハンズオンの最後に設定を削除します。

```sh
yarn config set npmRegistryServer "$CODEARTIFACT_URL"
yarn config set 'npmRegistries["$CODEARTIFACT_URL"].npmAuthToken' "${CODEARTIFACT_AUTH_TOKEN}"
yarn config set 'npmRegistries["$CODEARTIFACT_URL"].npmAlwaysAuth' "true"
```

## パッケージを登録

CodeArtifactにパッケージが登録されていないことを確認します。

```sh
aws codeartifact list-packages --domain $AWS_DOMAIN --repository $REPOSITORY_NAME --query 'packages' --output text --profile $PROFILE_NAME
```

```sh
cd ./sample-package
```

CodeArtifactにパッケージを登録します。

```sh
npm publish
```

登録されたパッケージの一覧を表示します。

```sh
aws codeartifact list-packages --domain $AWS_DOMAIN --repository $REPOSITORY_NAME --profile $PROFILE_NAME

```

## CodeArtifactに登録したパッケージをsample-appに読み込む

サンプルアプリケーションの`sample-app`に作成したパッケージを読み込みます。

```sh
cd ../sample-app
```

`npm install`を実行して`index.js`を実行します。

```sh
npm install sample-package@1.0.0 && node index.js
```

## 片付け

### リポジトリを削除する

```sh
aws codeartifact delete-repository --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --output text --repository cfhandson --profile codeartifact
```

### ドメインを削除する

```sh
aws codeartifact delete-repository --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --output text --repository $REPOSITORY_NAME --profile $PROFILE_NAME
```

```sh
yarn config set npmRegistryServer ""
yarn config set 'npmRegistries["$CODEARTIFACT_URL"].npmAlwaysAuth' "false"
npm config set registry ""
```

## まとめ

CodeArtifactを使うことで自身の利用するパッケージをAWS上に置いておくことができます。
ハンズオンでは自分の作成したパッケージを置くだけに留まりましたが、既に配布されているOSSを保管することも可能ですので興味がある人は試してみると良いでしょう。

