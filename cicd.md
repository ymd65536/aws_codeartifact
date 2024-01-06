# 【AWS】用語を整理しながら学ぶAWS - Codeシリーズ CI/CD編 Part1

## はじめに

この記事では用語を整理しながらAWSが提供するCodeシリーズを学習していく記事です。
主な内容としては実践したときのメモを中心に書きます。（忘れやすいことなど）
誤りなどがあれば書き直していく予定です。

なお、内容につきましては2023年3月12日時点の調査内容で記載しております。あらかじめご了承ください。

## アジェンダ

- 今回扱うサービス
- CI/CDとは
- CI/CDがなかったら？
- CI/CDをAWSで実現するには？

## 今回扱うサービス

今回は以下のサービスを扱います。

- AWS CodeCommit
- AWS CodeBuild
- AWS CodeDeploy
- AWS CodePipeline
- AWS CodeStar

※ここにはないAWS CodeGuruや昨年発表されたAmazon CodeCatalystは別の記事で紹介します。
また、AWS CodeArtifactについては文脈が変わってくるのでこれについても別の機会に解説します。

## CI/CDとは

### 概要

今回の記事を読む前の前提知識としてまずは`CI/CD`について見ていきましょう。
CI/CDは`Continuous Integration／Continuous Delivery or Continuous Deploy`の略称です。
一連の開発プロセスを自動化して継続的にデプロイを繰り返すという技術/概念とも言えます。

簡単にいえば、以下のような工程をすべてつなげて自動化することがCI/CDと言えます。
（だいたいこんな感じ。諸説ある。現場による）

1. 新しくブランチをチェックアウト
2. コードの変更をブランチにコミット
3. コードの変更をリモートリポジトリにプッシュ
4. テスト
5. レビュー
6. マージ
7. テスト
8. デプロイ

昨今ではコンテナによるデプロイプロセスが主流となっていることもあり、デプロイするものはソースコードだけではありません。
たとえば、Dockerfileによるコンテナイメージを作成(Build)して決められたコンテナ基盤にコンテナをデプロイすることもCI/CDの対象となりえます。
そもそもコンテナにはアプリケーションも含まれることがある為、コンテナのデプロイがアプリケーションをデプロイするのとほぼ同義となる場合があります。

コンテナの場合は以下のような工程をすべてつなげて自動化することが考えられます。(だいたいこんな感じ)

1. 新しくブランチをチェックアウト
2. Dockerfileの変更をコードリポジトリにコミット
3. Dockerfileの変更をコードリポジトリにプッシュ
4. レビュー
5. Lint
6. フォーマット
7. イメージのビルド
8. コンテナレジストリの作成
9. イメージをコンテナレジストリにプッシュ
10. コンテナレジストリからイメージをpull
11. コンテナ基盤にデプロイ

補足にはなりますが、DeliveryとDeliveryの違いについて言及しておくと

- Deliveryは人の手が残る開発プロセスの自動化
- Deployは人の手が介在しない開発プロセスの自動化を

ということになります。皆さんがイメージするいわゆる開発プロセスの完全自動化は`Continuous Deploy`になります。

### CI/CDがなかったら？

たとえば、AWSでコンテナをデプロイする場合を考えてみましょう。
先にも書いたとおり、以下のような工程が考えられます。

1. 新しくブランチをチェックアウト
2. Dockerfileの変更をコードリポジトリにコミット
3. Dockerfileの変更をコードリポジトリにプッシュ
4. レビュー
5. Lint
6. フォーマット
7. イメージのビルド
8. コンテナレジストリの作成
9. イメージをコンテナレジストリにプッシュ
10. コンテナレジストリからイメージをpull
11. コンテナ基盤にデプロイ

とくにAWSの場合はAmazon Elastic Container Registry(ECR)を利用する為、docker loginにAWS CLIの`get-login-password`の値をパイプで渡すなどの工程もあります。
複数のアカウントの場合はAWS CLIで`--profile`オプション用いてプロファイル名を渡す必要があります。
とくに、ECRは異なるアカウントで同じリポジトリ名を設定できる為、プロファイル名を間違えてpushしてしまうことも考えられます。

以上のようにデプロイには幾つもの工程があり、これらの工程を乗り越えながらソフトウェアの品質を担保する必要があります。
※「ソフトウェアの品質とはなんぞや」と疑問に思い、小一時間考えてしまう人もいるかとは思いますが、この記事では取り扱いません。

がしかし、人が作業するからにはミスはつきものです。ミスでデプロイ作業が遅れてしまうこともあるかもしれません。
この手の作業をトイルと言います。※トイレではありません。

そこでCI/CDを導入することによってトイルを除去できるように工程を自動化できます。

## CI/CDをAWSで実現するには？

ようやく本題となりますが、ここでざっくり各サービスの役割をみていきましょう。

|サービス名|役割|
|:---|:---|
|AWS CodeCommit|コードを保管しておくGitリポジトリサービスを提供する|
|AWS CodeBuild|コードをビルドする環境を提供する|
|AWS CodeDeploy|コードが実際に動作する環境にコードを自動デプロイする|
|AWS CodePipeline|Codeシリーズのサービスの統括と他のAWSサービスとの連携やサードパーティツールとの連携を提供する|
|AWS CodeStar|他のコードプロバイダとの連携、プロジェクト環境を提供する|

概ね、5つのサービスを組みわせることで実現が可能です。CodeCommit、CodeBuild、CodeDeployの三つを組み合わせれば、AWSでCI/CDが実現できます。

ただ、組み合わせを実行するには厳密にはCodePipelineが必要であり、外部のリポジトリサービスと連携する場合はCodeStarを使った連携も不可欠です。
AWSでCI/CDを実現する方法は他にもいろいろあり、よく言われているものがいくつかあります。

- Jenkinsを使ったCI/CD
  - 資格試験の対策でも問われる部分、AWSの認定トレーニングでも聞かれるあたり、ほぼ公式見解
- GitHub Actionsを使ったCI/CD
  - 同じくAWSの認定でも名前が出てきますが、推奨はされていません。ただ、GitHubの導入率は世界的に大きい為、合わせて使われるケースは十分にあります
- Circle CIを使ったCI/CD
  - ザ・サードパーティ製のCI/CDという感じです。多機能で導入しているクラウド環境に縛られることなく利用できます（ベンダーロックインを回避できる）

※ベンダーロックイン：特定のベンダーにサービスを固定されること、もしくは統一されること。今回の場合はCodeシリーズがAWSにおけるCI/CDのベンダーロックイン

などなど挙げ始めると数えきれないほどの組み合わせがあります。興味のある方はCI/CDツールを調べてみると良いでしょう。
ここではAWSサービスのみを使ったCI/CDを扱います。

## AWS CodeCommit

まずはリポジトリです。AWSでもコードをリポジトリで管理することが可能です。もちろん、AWSが開発したサービスの為
IAMによるRBAC（ロールベースアクセスコントロール）を導入しています。

中身は通常のGitリポジトリサーバーと変わりありません。特筆すべきはマネージドであり、サーバーの運用を必要としない部分でしょう。
また、Gitである為、ブランチを作成したりコードをコミットしたりプッシュしたりなどが可能です。
ただし、自身の端末で利用する場合はGitからAWSのクレデンシャル情報を一時的に保管する必要があります。

※設定方法

```bash
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
git config --global -l
```

IAM Identity Centerを利用している場合は上記の設定を実行した後、IAM Identity Centerにある`Option 1: Set AWS environment variables (Short-term credentials)`から以下の3つコピーして環境変数に代入することでセットアップができます。

```bash
export AWS_ACCESS_KEY_ID={}
export AWS_SECRET_ACCESS_KEY={}
export AWS_SESSION_TOKEN={}
```

なお、GitHub同様にcloneして自身の端末にデータをコピーできます。※東京リージョンの場合

```bash
git clone https://git-codecommit.ap-northeast-1.amazonaws.com/v1/repos/{repository_name}
```

さらに、AWS CodeCommitには承認ルールテンプレートを使うことで独自のレビュープロセスを入れることができます。

## AWS CodeBuild

Commitしたら次はBuildです。AWSではビルド環境を提供してくれるサービスがあります。それがAWS CodeBuildです。
AWS CodeBuildは`buildspec.yml`というAWS CodeBuild特有の設定ファイルからビルド設定を読み取り、ビルドを自動化します。
また、ビルドはビルドプロジェクトという単位で管理され、ブランチ単位とコミットID単位でビルドできます。

※buidspec.ymlの例

```yml
version: 0.2
phases:
  install:
    on-failure: ABORT
    commands:
      - echo "install phases"
  pre_build:
    on-failure: ABORT
    commands:
      - echo "pre_build phases"
  build:
    on-failure: ABORT
    commands:
      - echo "build phases"
  post_build:
    on-failure: ABORT
    commands:
      - echo "post_build phases"
artifacts:
  files:
    - "**/*"

```

なお、ビルド時に環境変数を呼び出すことが可能であり、環境変数はymlファイル内に埋め込むことができます。
環境変数におくデータは以下の3つの形式で保存できます。

- PlainText
- Systems Manager Parameter Store
- Secret Manager

```yml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...          
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG      
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
```

さらにビルド状況を監視する為にCloudWatchを利用してビルド時のログを参照することもできます。
※ビルドプロジェクトが非VPCの場合はそのまま利用できますが、VPCの場合は別途、設定が必要です。

ビルドのソースはAWS CodeCommitだけでなく他のリポジトリサービスも利用できます。

## AWS CodeDeploy

コミット、ビルドときたら最後にデプロイです。※テストは？と思われたかもしれませんが、それはCodeBuildで可能です。

AWS CodeDeployではビルドされた内容もしくはブランチにコミットされた内容を実際にデプロイします。
実はCodeBuildがなくてもAWS CodeDeployは動きます。とりわけ、ビルドする必要がないものなどが対象です。

AWS CodeDeployは`appspec.yml`を元にアプリケーションのデプロイを実行します。
AWS CodeDeployはアプリケーションという単位で管理され、デプロイグループという単位でデプロイされます。
デプロイの種類にはいくつか手段があり、ここで語ると1つの記事になってしまう為、別の機会に解説しようと思います。

なお、資格試験の対策ではElastic Beanstalkとともにデプロイの種類についてよく出題されます。

※appspec.ymlの例

```yml
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/html
permissions:
  - object: /var/www/html
    owner: apache
    group: apache
    mode: 755
    type:
      - file
      - directory
#hooks:
#      デプロイする際に動かすシェルスクリプトなどを設定するセクション

```

デプロイ先は`EC2/オンプレミス`、`Lambda`、`Amazon ECS`の3つから選択できます。

## AWS CodePipeline

コミット、ビルド、デプロイのサービスを解説してきましたが
これらを統括するサービスがあります。

それがAWS CodePipelineです。AWS CodePipelineを使うとAWS CodeCommitにコードがpushされたことを検知して自動でBuild & Deployを実行するということが可能になります。
※コードを検知する仕組みは厳密にはEventBridgeが内部で動いています。

そもそもパイプラインとはITにおいて処理と処理をつなげるような意味合いをもつ言葉としても知られています。
Linuxのコマンド同士を繋ぐ処理のことをパイプライン処理と言うのと同じであり、AWS CodePipelineはCodeシリーズを繋ぐ為のパイプラインとなります。

とくに大きな機能or目立った機能はありませんが、言うならばコミットビルドデプロイの3つの工程がWebブラウザ上で可視化されているという点です。
それぞれの工程にはPipeline実行IDというのが付与されて一意に管理されている為、それぞれの工程状況を瞬時に閲覧できます。

## AWS CodeStar

これでAWS上におけるCI/CDについてはほぼ終わりになりますが、実際にはAWSのCI/CDだけでなく他のCI/CDを使わざるをえないことがあるでしょう。
さらに、すぐに開発環境を構築したいといった状況もあると思います。
AWS CodeStarを使えば、そういった要件にも対応できます。

AWS CodeStarを使うことでAWSではない異なるリポジトリサービス、とりわけGitHubとの連携が可能です。この接続のことをAWS CodeStar Connectionと言います。
AWS CodeStarはこれだけではなく開発用のテンプレートを提供しています。まさに開発者には猫の手のような存在

## まとめ

今回の記事はとても長くなってしまいましたが、まだ解説が足りない部分が多いにあります。
次からは各サービスにフォーカスした内容で記事にしていこうと思います。

## リソース

- [CodeBuild のDocker サンプル](https://docs.aws.amazon.com/ja_jp/codebuild/latest/userguide/sample-docker.html)
- [AWS CI/CD for Amazon ECS](https://pages.awscloud.com/rs/112-TZM-766/images/AWS_CICD_ECS_Handson.pdf)
- [AWS で CI/CD パイプラインをセットアップする](https://aws.amazon.com/jp/getting-started/projects/set-up-ci-cd-pipeline/)
- [Code シリーズ入門ハンズオンを公開しました！- Monthly AWS Hands-on for Beginners 2020年8月号](https://aws.amazon.com/jp/blogs/news/aws-hands-on-for-beginners-10/)
- [CI/CD とは - RedHat](https://www.redhat.com/ja/topics/devops/what-is-ci-cd)

## おわり
