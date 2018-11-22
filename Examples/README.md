# Firebase Examples

This document describes the sample applications provided with the [Firebase library](../README.md).

The following example applications are provided:
- DataWriter &mdash; writes data to a Firebase database
- DataReader &mdash; reads data from a Firebase database
- StreamReader &mdash; subscribes to data changes of a Firebase database

We recommend that you:
- run DataWriter on the agent of one device
- run DataReader on the agent of a second device
- run StreamReader on the agent of a third device

To see data receiving you need to run the DataReader and/or StreamReader examples alongside the DataWriter example.

Each example is described below. If you wish to try one out, you'll find generic and example-specific setup instructions further down the page.

## DataWriter

This example periodically writes data to the specified path of the Firebase database.
- Legacy Firebase tokens is used for authentication.
- Data is written every 10 seconds using write() library method.
- Every data record contains:
  - A "value" attribute. This is an integer value, which starts at 1 and increases by 1 with every record sent. It restarts from 1 every time the example is restarted.
  - A "measureTime" attribute. This is an integer value, converted to string, and is the time in seconds since the epoch.

![DataWriter example](../png/DataWriter.png)

## DataReader

This example periodically reads data from the specified path of the Firebase database.
- Google OAuth2 access tokens is used for authentication.
- Data is read every 15 seconds using read() library method.
- Every read data record is printed to the log.

![DataReader example](../png/DataReader.png)

## StreamReader

This example subscribes to data changes at the specified path of the Firebase database.
- Firebase ID tokens for anonymous user is used for authentication.
- on() and stream() library methods are used.
- Every received data record is printed to the log.

![StreamReader example](../png/StreamReader.png)

## Examples Setup

- In the [Electric Imp’s IDE](https://ide.electricimp.com/) create new Product and Development Device Group.
- Assign device to the newly created Device Group.
- Copy the code linked below for the example you wish to run and paste it into the IDE as the agent code.
  - [DataWriter](./DataWriter.agent.nut)
  - [DataReader](./DataReader.agent.nut)
  - [StreamReader](./StreamReader.agent.nut)

Before running an example application you need to set the configuration constants in the application (agent) source code. The instructions below will walk you through the necessary steps.

### Setup For All Examples

#### Firebase Account Configuration

- Login at [Firebase Console](https://console.firebase.google.com) in your web browser.
- If you have an existing project that you want to work with, skip this step, otherwise click the ‘Add project’ button.
In the opened window enter a project name, select the checkbox ‘I accept the controller’ and click ‘Create project’.
![Create project](../png/CreateProject.png)
Wait until your project is created and click ‘Continue’.
- In your project ‘Settings’ menu choose ‘Project settings’.
![Project settings](../png/ProjectSettings.png)
Copy your project’s ID &mdash; it will be used as the *FIREBASE_PROJECT_ID* constant in the agent code.
![Project settings project ID](../png/ProjectSettingsProjectId.png)
- In the left menu click ‘Database’, scroll down to the ‘Realtime Database’ section and click ‘Create database’.
![Realtime Database](../png/RealtimeDatabase.png)
- Select ‘Start in test mode’ and click ‘Enable’.
![Database Security Rules](../png/DatabaseSecurityRules.png)

### Additional Setup for the DataWriter Example

- In the [Firebase Console](https://console.firebase.google.com) select the project you created in the previous steps.
- In your project ‘Settings’ menu choose ‘Project settings’.
![Project settings](../png/ProjectSettings.png)
- Click ‘Service accounts’ tab.
- Click ‘Database secrets’.
- Click ‘Show’ near your database secret and copy the secret &mdash; it will be used as the *FIREBASE_SECRET* constant in the agent code.
![Project settings](../png/DatabaseSecret.png)

### Additional Setup for the DataReader Example
- In the [Firebase Console](https://console.firebase.google.com) select the project you created in the previous steps.
- In your project ‘Settings’ menu choose ‘Project settings’.
![Project settings](../png/ProjectSettings.png)
- Click ‘Service accounts’ tab.
- Click ‘Generate new private key’.
![Generate private key](../png/GeneratePrivateKey.png)
- In the opened window click ‘Generate key’. The file `<project ID>-<random identifier>.json` will be downloaded to your computer.
It looks something like this:
```
{
  "type": "service_account",
  "project_id": "test-1dd6f",
  "private_key_id": "8d429015c3ce0e91e62f3af7578338f5b6b2f801",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...cARA==\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-mtv6g@test-1dd6f.iam.gserviceaccount.com",
  "client_id": "100254262646168050509",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-mtv6g%40test-1dd6f.iam.gserviceaccount.com"
}
```
Copy `client_email` and `private_key` fields values from the downloaded JSON file &mdash; they will be used as the *FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL* and *FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY* constants in the agent code.

### Additional Setup for the StreamReader Example
- In the [Firebase Console](https://console.firebase.google.com) select the project you created in the previous steps.
- In your project ‘Settings’ menu choose ‘Project settings’.
![Project settings](../png/ProjectSettings.png)
Copy your project’s Web API Key &mdash; it will be used as the *FIREBASE_WEB_API_KEY* constant in the agent code.
![Project settings web api key](../png/ProjectSettingsWebApiKey.png)
- In the left menu click ‘Authentication’, choose ‘Sign-in method’ tab and click ‘Anonymous’ provider.
![Sign-in method](../png/SignInMethod.png)
- Enable Anonymous provider and click ‘Save’.
![Sign-in method](../png/EnableAnonymousProvider.png)

#### Constants Setup

Set the example code configuration constants (*FIREBASE_PROJECT_ID*, *FIREBASE_SECRET*, *FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL*, *FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY*, *FIREBASE_WEB_API_KEY* depending on the example) with the values retrieved in the previous steps. Set the same value of *FIREBASE_PROJECT_ID* for all examples.
![Examples config](../png/ExampleConfig.png)
