# harel-template-api-mule4

## TEMPLATE

### DESCRIPTION

This project is a simple template that integrates some of MuleSoft best practices. It provides a set of standard minimalistic tools that should help you start your project quickly/efficiently.

- **Plugins**
    - mule-maven-plugin: enriched with a configuration that goes along with the Jenkinsfile (pipeline).
    - maven-release-plugin: maven release management tool
- **Structure**
    - Separation between interface and implementation
    - Global configuration file
    - Logging and Error Handling framework
    - Resources
        - property files: 
            - common property file containing environment variable common to all environments (sandbox to production) like http port, basePath etc ...
            - a property file for each environment DEV/QA/UAT. You can add as many as you want
- **Profiles**
	- It contains 2 profiles; one for RTF deployment and other for ARM (standalone)
	- RTF is set as default profile

### USAGE

1. In Anypoint Studio, create a new project as File -> New -> Project from Template. In the following screen, select this template from exchange and click Open
2. The template will be downloaded to your local machine and this can now be used for creating new Implementation project
3. Rename the Project to correct name as per the naming conventions e.g 'harel-sys-mapa-client-api'
4. Open the pom.xml file and adjust the project artifactId, version and name as per new name
5. In the opened project, right click on project name -> Manage Dependencies -> Manage APIs
6. Here select the API from exchange and click apply. The scaffolding for the API resources will happen automatically in interface.xml
7. In the APIKist Router Configuration under main.xml, select the correct 'API Definition' from drop down menu and click OK
8. Make sure to change the Path variable in HTTP Listener to required path. 
9. Now you can start with the implementation of your API.

## ERROR HANDLING
The template contains a pre-built error handler under common -> error-global.xml. It contains most of the common error types but you can add more error types like database related etc. based on your requirements here. It is already added as Global Error Handler in global.xml
The error handler contains flow named 'global-error-response' which create error payload and log message with required error details. You can customize this flow as per your needs.

## LOGGING
The template defines a logging framework using standard mule logger to capture log messages. It is defined under common -> common.xml -> log-management (flow). In order to log a message, you simply need to set the required variables and reference this flow.
Following are the 2 variables that are needed at minimum:
1. logLevel - This defines what log level you want to maintain for your message and it can have one of the following values:
      - DEBUG
      - ERROR
      - INFO
      - TRACE
      - WARN
2. logMessage - You can specify here multiple fields in JSON format that you would like to log like message, tracepoint etc.

The framework by default populates following fields automatically for every log:
1. correlationId
2. applicationName
3. applicationVersion
4. environment
5. priority
6. category
7. timestamp
8. rootContainer (Flow Name)
9. content (payload) - Logged only in case logLevel is DEBUG or ERROR

In case of error, the global error handler uses the above framework to create log message with logLevel = ERROR and logMessage with following additional fields:
1. description - error.description
2. code - vars.errorCode if defined otherwise error.errorType.identifier

## DEPLOYMENT

Once the application is developed, you need to deploy it to the following repositories depending on your target environment:

1. Artifact Repository
2. Anypoint Exchange (Only for RTF Target)
3. RTF or Standalone Mule

Before deploying your application, you need to prepare your application's POM file by configuring following variables:

1. Make sure your project.artifactId and project.version are set correctly
2. If deployment target is RTF then perform following changes to pom.xml

    - Change deploy.rtf.replication_factor to reflect the number of replicas that you want to host for the application in RTF
    - Update deploy.rtf.cpu_reserved, deploy.rtf.cpu_max, deploy.rtf.memory_reserved based on your application's requirements
    - Make sure that project -> build -> plugins -> plugin -> configuration -> runtimeFabricDeployment is configured correctly
3. If deployment target is Standalone then perform following changes to pom.xml

    - Make sure that project -> build -> plugins -> plugin -> configuration -> armDeployment is configured correctly

### MAVEN CONFIGURATION

First you need to configure settings.xml file in your Maven Setup (local/jenkins) with Anypoint Exchange Server Information as follows:

```xml
<server>
   <id>anypoint-exchange</id>
   <username>~~~Client~~~</username>
   <password>{Connected App Client ID}~?~{Connected App Client Secret}</password>
</server>
```

You can get Connected App Client ID and Secret as follows:

1. Log onto Anypoint Platform
2. Go to Access Management
3. Click on Connected Apps
4. Copy the Client ID and Secret for App named 'DeployToExchange'

#### Sample Configuration

```xml
<server>
   <id>anypoint-exchange</id>
   <username>~~~Client~~~</username>
   <password>d70e5506a7f044af9e9abe68b5795bef~?~6bd8Gh2b00724a048E54436aF15b4bBg</password>
</server>
```

### DEPLOY TO STANDALONE (DEVELOPMENT)

For standalone deployment in Development environment, run the following maven command:

```bash
mvn clean deploy -DmuleDeploy -Parm -Dmule.env=<Mule Runtime Environment> -Danypoint.connected.app.id=<Connected App Client ID> -Danypoint.connected.app.secret=<Connected App Client Secret> -Ddeploy.standalone_platform_name=<Standalone Server Name> -Danypoint.environment=<Anypoint Environment for Deployment>
```

-Dmule.env can be dev, test, preprod, prod

-Ddeploy.standalone_platform_name can be apig-dev for Development

-Danypoint.environment can be Development, Test, Pre-Production, Production

-Danypoint.connected.app.id & -Danypoint.connected.app.secret can be extracted as follows:

1. Log onto Anypoint Platform
2. Go to Access Management
3. Click on Connected Apps
4. Copy the Client ID and Secret for App named 'DeployMuleAppsToNonProd' for Non-Production and 'DeployMuleAppsToProd' for Production

Example

```bash
mvn clean deploy -DmuleDeploy -Parm -Dmule.env=dev -Danypoint.connected.app.id=159b6596ba0c4936953d04cb3fbb5bac -Danypoint.connected.app.secret=xxxxxxxxxxxxxxxxxxxxxxx -Ddeploy.rtf_platform_name=apig-dev -Danypoint.environment=Development
```

### DEPLOY TO Standalone (TEST, PREPROD, PROD)

In development environment normally the deployment follows the standard procedure of build -> package -> deploy. However in further environments it is best practice to use the already built artifact from Nexus/Artifact repository.

First download the application jar file you want to deploy from Nexus Artifact repository to your local file system.

From the directory where this jar file is downloaded call the following Maven Command to deploy the prebuilt application to Standalone:

```bash
mvn mule:deploy -Dmule.artifact="/path to jar file" -Parm -Dmule.env=<Mule Runtime Environment> -Danypoint.connected.app.id=<Connected App Client ID> -Danypoint.connected.app.secret=<Connected App Client Secret> -Ddeploy.standalone_platform_name=<Standalone Server Name> -Danypoint.environment=<Anypoint Environment for Deployment>
```

-Dmule.artifact points to location/path of the application jar file downloaded

Rest of the parameters are same as used in previous deployment to Standalone development section.

#### DEPLOY TO EXCHANGE

For deployment to RTF, you need to first deploy the application to Exchange. This is not required for deployment to Standalone.

```bash
mvn clean deploy
```

This should deploy the application to Anypoint Exchange. You need to perform this step only when deploying the application to Development environment. For deployment to subsequent environments like Test, PreProd and Production, the already deployed version of the application to Exchange will be used for RTF deployment.

In case you want to overwrite an existing application in Exchange then following of the 2 options are available:

1. Upgrade the project.version to higher number in case new functionality is also being added
2. If no upgrade to version is required then delete the application first and redeploy to exchange with same project.version

#### DELETE APPLICATION FROM EXCHANGE

You can delete an existing application version from Exchange by using the following CURL command:

```
curl -X DELETE "https://anypoint.mulesoft.com/exchange/api/v2/assets/dfb0f634-ac3d-4cf6-8063-f34f24fd090f/<project.artifactId>/<project.version>" \
-H "authorization: bearer <authorization token>" \
-H "Content-Type: application/json" \
-H "X-Delete-Type: hard-delete"
```

Please refer to section 'AUTHORIZATION TOKEN FROM CONNECTED APP' on how to obtain authorization token for the above CURL command.

Example

```
curl -X DELETE "https://anypoint.mulesoft.com/exchange/api/v2/assets/dfb0f634-ac3d-4cf6-8063-f34f24fd090f/sys-template-client-api/1.0.0" \
-H "authorization: bearer xxxxxxxxxxxxxxxxxxxx" \
-H "Content-Type: application/json" \
-H "X-Delete-Type: hard-delete"
```

### DEPLOY TO RTF (DEVELOPMENT)

For RTF deployment in Development environment, run the following maven command:

```bash
mvn clean deploy -DmuleDeploy -Dmule.env=<Mule Runtime Environment> -Danypoint.connected.app.id=<Connected App Client ID> -Danypoint.connected.app.secret=<Connected App Client Secret> -Ddeploy.rtf_platform_name=<RTF Platform Name> -Danypoint.environment=<Anypoint Environment for Deployment> -Durl.domain=<RTF Inbound URL Domain>
```

-Dmule.env can be dev, test, preprod, prod

-Ddeploy.rtf_platform_name can be non-prod-rtf-01 for Pre-Prod and prod-rtf-01 for Production

-Danypoint.environment can be Development, Test, Pre-Production, Production

-Danypoint.connected.app.id & -Danypoint.connected.app.secret can be extracted as follows:

1. Log onto Anypoint Platform
2. Go to Access Management
3. Click on Connected Apps
4. Copy the Client ID and Secret for App named 'DeployMuleAppsToNonProd' for Non-Production and 'DeployMuleAppsToProd' for Production

-Durl.domain can be dev-api.office.com, test-api.office.com, preprod-api.office.com, api.office.com depending on environment

Example

```bash
mvn clean deploy -DmuleDeploy -Dmule.env=dev -Danypoint.connected.app.id=159b6596ba0c4936953d04cb3fbb5bac -Danypoint.connected.app.secret=xxxxxxxxxxxxxxxxxxxxxxx -Ddeploy.rtf_platform_name=non-prod-rtf-01 -Danypoint.environment=Development -Durl.domain=dev-api.office.com
```

### DEPLOY TO RTF (TEST, PREPROD, PROD)

In development environment normally the deployment follows the standard procedure of build -> package -> deploy. However in further environments it is best practice to use the already deployed artifact from Exchange.

First download the POM (pom.xml) file for the application you want to deploy from Exchange to your local file system by calling following CURL command:

```
curl -o ./pom.xml -L "https://anypoint.mulesoft.com/exchange/files/api/v1/organizations/dfb0f634-ac3d-4cf6-8063-f34f24fd090f/assets/dfb0f634-ac3d-4cf6-8063-f34f24fd090f/<project.artifactId>/<project.version>/pom?source=Exchange%20API" \
-H "authorization: bearer xxxxxxxxxxxxxxxxxxxxxxxxx"
```

Please refer to section 'AUTHORIZATION TOKEN FROM CONNECTED APP' on how to obtain authorization token for the above CURL command.

From the directory where this pom.xml file is downloaded call the following Maven Command to deploy the application from Exchange to RTF:

```bash
mvn mule:deploy -Dmule.artifact="/path" -Dmule.env=<Mule Runtime Environment> -Danypoint.connected.app.id=<Connected App Client ID> -Danypoint.connected.app.secret=<Connected App Client Secret> -Ddeploy.rtf_platform_name=<RTF Platform Name> -Danypoint.environment=<Anypoint Environment for Deployment> -Durl.domain=<RTF Inbound URL Domain>
```

-Dmule.artifact can be any random value and needs not to be an actual path

Rest of the parameters are same as used in previous deployment to RTF development section.

### AUTHORIZATION TOKEN FROM CONNECTED APP

You can issue following CURL command to obtain Authorization Token against a Connected App. Make sure that you have all required permissions assigned to your Connected App for the final purpose.

```
curl -L -X POST https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token \
-H "Content-Type: application/x-www-form-urlencoded" \
--data-urlencode "client_id=<Connected App Client ID>" \
--data-urlencode "client_secret=<Connected App Client Secret>" \
--data-urlencode "grant_type=client_credentials"
```
