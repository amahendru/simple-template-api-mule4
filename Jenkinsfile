//returns the deployment env name according to branch name
//otherwise it raises an exception if the branch name is not recognized
def getDeployEnv(git_branch) {
  if(!git_branch){
    throw new Error("branch ${git_branch} is not valid.")
  }
  String bname = parseBranchName(git_branch) 
  String name;
  switch(bname) {
    case ~/dev/ : name = "DEV"; break;
    case ~/uat/: name = "UAT"; break;
    case ~/pprod/: name = "PPROD"; break;
    default: throw new Exception ("branch ${git_branch} not recognized.");
  }
  return name
}

//returns the type of the environment according to the branch name e.g sandbox or production
def getEnvType (git_branch) {
  if(!git_branch){
    throw new Error("branch ${git_branch} is not valid.")
  }
  String bname = parseBranchName(git_branch) 
  switch(bname) {
    case ~/(dev)|(uat)|(pprod)/: return 'sandbox';
    default: throw new Exception ("branch ${git_branch} not recognized.");
  }
}

//returns environment name mapped to the git branch
def getMappedEnv (git_branch) {
  if(!git_branch){
    throw new Error("branch ${git_branch} is not valid.")
  }
  String bname = parseBranchName(git_branch) 
  String name;
  switch(bname) {
    case ~/dev/ : name = "DEV"; break;
    case ~/uat/: name = "UAT"; break;
    case ~/pprod/: name = "PPROD"; break;
    default: throw new Exception ("branch ${git_branch} not recognized.");
  }
  return name
}

//removes the origin/ from the branch name
def parseBranchName (git_branch) {
  if(!git_branch){
    throw new Error("branch ${git_branch} is not valid.")
  }
  def (_,name) = (git_branch =~ /^origin\/(.+)$/)[0]
  return name
}

//parses the git url to extract repo name 
def parseRepoName (git_url) {
  if(!git_url){
    throw new Error("git url ${git_url} is not valid.")
  }
  def (_,head,name) = (git_url =~ /^(git@|https:\/\/).*\/(.*)(\.git)?$/)[0]
  return name
}

//returns the appropriate number of workers depending on the environment
def getNbWorkers (env_name) {
	def workers;
	if(env_name == "PROD"){ 
    workers = "2" 
  } else	{
 		workers = "1"
 	}
 return workers
}

/* 
  PIPELINE 
  *** CREDENTIALS REQUIREMENTS ***
  following is a list of nomenclature for credentials used in this pipeline.
    ** anypoint platform environment credentials. should be provided for each environment as "Secret text". 
      The name is generated from the git branch:
          - anypoint.{env}.client_id 
          - anypoint.{env}.secret_id 
    ** anypoint connected app credentials. should be provided for each environment as "Secret text".
      All environments below production use a single user and production has its own user.
      The cred key is generated from the git branch. see the "getEnvType" for the implementation of env descrimination:
          - anypoint.app.{sandbox/production}.client_id
          - anypoint.app.{sandbox/production}.client_secret
    ** mule vault key credential. should be provided for each project as "Secret text".
      the project name is extracted from the git url. See "parseRepoName" for project name extraction:  
          - anypoint.vault.{project_name}.{env}.key
  ********************************************************
  
 */
pipeline {
  agent any
  tools { 
    maven 'M3' 
    jdk 'JDK8' 
  }
  environment {
    PROJECT_NAME = parseRepoName(GIT_URL)
    ENV_TYPE = getEnvType(GIT_BRANCH)

    ENV = getMappedEnv(GIT_BRANCH)
    ANYPOINT_ENV = getDeployEnv(GIT_BRANCH)
    ANYPOINT_REGION = "{{REGION}}"
    ANYPOINT_BUSINESS_GROUP = "{{GROUP_NAME}}"
    ANYPOINT_BUSINESS_GROUP_ID = readMavenPom().getGroupId()
    ANYPOINT_WORKER_TYPE = "MICRO"
    ANYPOINT_WORKERS = getNbWorkers("$ANYPOINT_ENV")
    ANYPOINT_HOST = "https://{{ANYPOINT_HOST}}"
    ANYPOINT_ANALYTICS_HOST = "https://analytics-ingest.{{ANYPOINT_HOST}}"

    ANYPOINT_VAULT_CRED_KEY = "anypoint.vault.${ENV}.key"
    
    ANYPOINT_ENV_CLIENT_ID_KEY = "anypoint.${ANYPOINT_BUSINESS_GROUP_ID}.${ENV}.client_id"
    ANYPOINT_ENV_CLIENT_SECRET_KEY = "anypoint.${ANYPOINT_BUSINESS_GROUP_ID}.${ENV}.client_secret"
    
    ANYPOINT_APP_CLIENT_ID_KEY = "anypoint.app.${ENV_TYPE}.client_id"
    ANYPOINT_APP_CLIENT_SECRET_KEY = "anypoint.app.${ENV_TYPE}.client_secret"

    ANYPOINT_RTF_NAME_KEY = "anypoint.rtf.${ENV_TYPE}.name"
    ANYPOINT_RTF_PUBLIC_DOMAINS_KEY = "anypoint.rtf.${ENV}.domains.public"
    ANYPOINT_RTF_PUBLIC_DOMAINS_KEY = "anypoint.rtf.${ENV}.domains.private" 

    MVN_SETTING_FILE_ID = "global-mvn-settings"

    VERSION = readMavenPom().getVersion()
    APP_NAME = readMavenPom().getArtifactId()

    IS_PUBLIC = {{IS_PUBLIC}}
  } 
  stages {

    stage ('Initialization') {
      steps {
        script{
            def ENV_LOWER_CASE = ENV.toLowerCase(); 
            APP_NAME_SUFFIX = "-${ENV_LOWER_CASE}"
        }
        echo "PROJECT_NAME = $PROJECT_NAME"
        echo "APP_NAME = $APP_NAME"
        echo "VERSION = $VERSION"
        echo "IS_PUBLIC = $IS_PUBLIC"
        echo "ENV_TYPE = $ENV_TYPE"
        echo "ENV = $ENV"
        echo "ANYPOINT_ENV = $ANYPOINT_ENV"
        echo "ANYPOINT_ENV_CLIENT_ID_KEY = $ANYPOINT_ENV_CLIENT_ID_KEY"
        echo "ANYPOINT_ENV_CLIENT_SECRET_KEY = $ANYPOINT_ENV_CLIENT_SECRET_KEY"
        echo "ANYPOINT_APP_CLIENT_ID_KEY = $ANYPOINT_APP_CLIENT_ID_KEY"
        echo "ANYPOINT_APP_CLIENT_SECRET_KEY = $ANYPOINT_APP_CLIENT_SECRET_KEY"
      }
    }

    stage('MULE TEST') { 
      environment{
        ANYPOINT_VAULT_KEY = credentials("${ANYPOINT_VAULT_CRED_KEY}")
        
        ANYPOINT_APP_CLIENT_ID = credentials("${ANYPOINT_APP_CLIENT_ID_KEY}")
        ANYPOINT_APP_CLIENT_SECRET = credentials("${ANYPOINT_APP_CLIENT_SECRET_KEY}")
        
        ACCESS_TOKEN = sh (script: "curl -s '${ANYPOINT_HOST}/accounts/api/v2/oauth2/token' \
          -X POST -H 'Content-Type: application/json' \
          -d '{\"grant_type\": \"client_credentials\", \"client_id\": \"${ANYPOINT_APP_CLIENT_ID}\", \"client_secret\": \"${ANYPOINT_APP_CLIENT_SECRET}\"}' \
          | sed -n 's|.*\"access_token\":\"\\([^\"]*\\)\".*|\\1|p'", returnStdout: true).trim()
      }
      steps {
        echo 'Testing ...'
        configFileProvider([configFile(fileId: "${MVN_SETTING_FILE_ID}", variable: 'MAVEN_SETTINGS_XML')]) {
          sh '''
            mvn -s $MAVEN_SETTINGS_XML clean test \
              -Denv=${ENV} \
              -Dmule.env=${ENV} \
              -Danypoint.base_uri=${ANYPOINT_HOST} \
              -DauthToken=${ACCESS_TOKEN} \
              -Dmule.vault.key=${ANYPOINT_VAULT_KEY} \
          '''
        }
      }
    }

    stage ('MULE DEPLOY') {
      environment {
        ANYPOINT_VAULT_KEY = credentials("${ANYPOINT_VAULT_CRED_KEY}")

        ANYPOINT_ENV_CLIENT_ID = credentials("${ANYPOINT_ENV_CLIENT_ID_KEY}")
        ANYPOINT_ENV_CLIENT_SECRET = credentials("${ANYPOINT_ENV_CLIENT_SECRET_KEY}")
        
        ANYPOINT_APP_CLIENT_ID = credentials("${ANYPOINT_APP_CLIENT_ID_KEY}")
        ANYPOINT_APP_CLIENT_SECRET = credentials("${ANYPOINT_APP_CLIENT_SECRET_KEY}")

        ANYPOINT_RTF_NAME = credentials("${ANYPOINT_RTF_NAME_KEY}")
        ANYPOINT_RTF_PUBLIC_DOMAIN_VAL = credentials("${ANYPOINT_RTF_PUBLIC_DOMAINS_KEY}")
        ANYPOINT_RTF_PUBLIC_DOMAIN = "${ANYPOINT_RTF_PUBLIC_DOMAIN_VAL}/${APP_NAME}${APP_NAME_SUFFIX}"
        ANYPOINT_RTF_PRIVATE_DOMAIN_VAL = credentials("${ANYPOINT_RTF_PRIVATE_DOMAINS_KEY}")
        ANYPOINT_RTF_PRIVATE_DOMAIN = "${ANYPOINT_RTF_PRIVATE_DOMAIN_VAL}/${APP_NAME}${APP_NAME_SUFFIX}"

        ANYPOINT_RTF_DOMAINS = "${ANYPOINT_RTF_PRIVATE_DOMAIN}"

        ACCESS_TOKEN = sh (script: "curl -s '${ANYPOINT_HOST}/accounts/api/v2/oauth2/token' \
          -X POST -H 'Content-Type: application/json' \
          -d '{\"grant_type\": \"client_credentials\", \"client_id\": \"${ANYPOINT_APP_CLIENT_ID}\", \"client_secret\": \"${ANYPOINT_APP_CLIENT_SECRET}\"}' \
          | sed -n 's|.*\"access_token\":\"\\([^\"]*\\)\".*|\\1|p'", returnStdout: true).trim()
      }
      steps {
        script {
          if (env.IS_PUBLIC) {
            ANYPOINT_RTF_DOMAINS = "${ANYPOINT_RTF_PUBLIC_DOMAIN},${ANYPOINT_RTF_PRIVATE_DOMAIN}"
          }
        }
        configFileProvider([configFile(fileId: "${MVN_SETTING_FILE_ID}", variable: 'MAVEN_SETTINGS_XML')]) {
          sh '''
            echo 'Delete jar from jar ...'
            curl -X DELETE "https://eu1.anypoint.mulesoft.com/exchange/api/v2/assets/$ANYPOINT_BUSINESS_GROUP_ID/$APP_NAME/$VERSION" \
              -H "authorization: bearer $ACCESS_TOKEN" \
              -H "Content-Type: application/json" \
              -H "X-Delete-Type: hard-delete"

            echo 'Deploying jar to exchange...'
            mvn -s $MAVEN_SETTINGS_XML clean  deploy
            
            echo Deploying applications to RTF ...
            mvn clean -DmuleDeploy deploy \
              -Dplatform.client_id=${ANYPOINT_ENV_CLIENT_ID} \
              -Dplatform.client_secret=${ANYPOINT_ENV_CLIENT_SECRET} \
              -Dsecure.key=${ANYPOINT_VAULT_KEY} \
              -Dmule.env=${ENV} \
              -Danypoint.environment=${ANYPOINT_ENV} \
              -Ddeploy.rtf_platform_name=${ANYPOINT_RTF_NAME} \
              -Ddeploy.application_domain=${ANYPOINT_RTF_PUBLIC_DOMAINS} \
              -Danypoint.analytics_base_uri=${ANYPOINT_ANALYTICS_HOST} \
              -Danypoint.base_uri=${ANYPOINT_HOST} \
              -Dapp.runtime="4.3.0"
          '''
        }
      }
    }
  }
}
