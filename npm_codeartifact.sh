export PROFILE_NAME="artifacttest"
export AWS_DOMAIN="cf-handson-domain" && echo $AWS_DOMAIN
export REPOSITORY_NAME="cfhandson"
export AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile $PROFILE_NAME --query 'Account' --output text` && echo $AWS_ACCOUNT_ID
export AWS_DEFAULT_REGION="ap-northeast-1" && echo $AWS_DEFAULT_REGION

aws sso login --profile $PROFILE_NAME

aws codeartifact create-domain --domain $AWS_DOMAIN --profile $PROFILE_NAME
aws codeartifact create-repository --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --repository $REPOSITORY_NAME --profile $PROFILE_NAME
aws codeartifact create-repository --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --repository npm-store --profile $PROFILE_NAME
aws codeartifact associate-external-connection --domain $AWS_DOMAIN  --domain-owner $AWS_ACCOUNT_ID --repository npm-store --external-connection "public:npmjs" --profile $PROFILE_NAME
aws codeartifact update-repository --repository cfhandson --domain $AWS_DOMAIN  --domain-owner $AWS_ACCOUNT_ID --upstreams repositoryName=npm-store --profile $PROFILE_NAME
aws codeartifact login --tool npm --domain $AWS_DOMAIN --region $AWS_DEFAULT_REGION --domain-owner $AWS_ACCOUNT_ID --repository $REPOSITORY_NAME --profile $PROFILE_NAME

export CODEARTIFACT_URL=`aws codeartifact get-repository-endpoint --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --repository $REPOSITORY_NAME --format npm --profile $PROFILE_NAME` && && echo $CODEARTIFACT_URL
export CODEARTIFACT_AUTH_TOKEN=`aws codeartifact get-authorization-token --domain $AWS_DOMAIN --region $AWS_DEFAULT_REGION --domain-owner $AWS_ACCOUNT_ID --query authorizationToken --output text --profile $PROFILE_NAME` && echo $CODEARTIFACT_AUTH_TOKEN

yarn config set npmRegistryServer "$CODEARTIFACT_URL"
yarn config set 'npmRegistries["$CODEARTIFACT_URL"].npmAuthToken' "${CODEARTIFACT_AUTH_TOKEN}"
yarn config set 'npmRegistries["$CODEARTIFACT_URL"].npmAlwaysAuth' "true"

aws codeartifact list-packages --domain $AWS_DOMAIN --repository $REPOSITORY_NAME --query 'packages' --output text --profile $PROFILE_NAME
aws codeartifact list-packages --domain $AWS_DOMAIN --repository $REPOSITORY_NAME --profile $PROFILE_NAME
npm install sample-package@1.0.0 && node index.js

aws codeartifact delete-repository --domain $AWS_DOMAIN --domain-owner $AWS_ACCOUNT_ID --output text --repository $REPOSITORY_NAME --profile $PROFILE_NAME

yarn config set npmRegistryServer ""
yarn config set 'npmRegistries["$CODEARTIFACT_URL"].npmAlwaysAuth' "false"
npm config set registry ""
