# Test Instructions #

The tests in the current directory are intended to check the behavior of the Firebase library. The current set of tests check:
- writing and reading data (write() and read() library methods) with callbacks and Promises using all available authentication types
- deleting data (remove() library method) using all available authentication types
- tests for internal _parseEventMessage() library method
- tests for setAuthProvider() library method

The tests are written for and should be used with [impt](https://github.com/electricimp/imp-central-impt). See [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for the details of how to configure and run the tests.

The tests for Firebase library require pre-setup described below.

## Firebase Account Configuration ##

- Login at [Firebase Console](https://console.firebase.google.com) in your web browser.
- If you have an existing project that you want to work with, skip this step, otherwise click the ‘Add project’ button.
In the opened window enter a project name, select the checkbox ‘I accept the controller’ and click ‘Create project’.
![Create project](../png/CreateProject.png)
Wait until your project is created and click ‘Continue’.
- In your project ‘Settings’ menu choose ‘Project settings’.
![Project settings](../png/ProjectSettings.png)
Copy your project’s ID and Web API Key &mdash; they will be used as the *FIREBASE_INSTANCE_NAME* and *FIREBASE_WEB_API_KEY* environment variables.
![Project settings project ID](../png/ProjectSettingsProjectIdAndWebApiKey.png)
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
Copy `client_email` and `private_key` fields values from the downloaded JSON file &mdash; they will be used as the *FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL* and *FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY* environment variables.
- Click ‘Database secrets’.
- Click ‘Show’ near your database secret and copy the secret &mdash; it will be used as the *FIREBASE_AUTH_KEY* environment variable.
![Project settings](../png/DatabaseSecret.png)
- In the left menu click ‘Database’, scroll down to the ‘Realtime Database’ section and click ‘Create database’.
![Realtime Database](../png/RealtimeDatabase.png)
- Select ‘Start in test mode’ and click ‘Enable’.
![Database Security Rules](../png/DatabaseSecurityRules.png)
- In the left menu click ‘Authentication’, choose ‘Sign-in method’ tab and click ‘Anonymous’ provider.
![Sign-in method](../png/SignInMethod.png)
- Enable Anonymous provider and click ‘Save’.
![Sign-in method](../png/EnableAnonymousProvider.png)

## Set Environment Variables ##

- Set *FIREBASE_INSTANCE_NAME*, *FIREBASE_WEB_API_KEY*, *FIREBASE_AUTH_KEY*, *FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL*, *FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY* environment variables to the values you retrieved in the previous steps.
- For integration with [Travis](https://travis-ci.org) set *EI_LOGIN_KEY* environment variable to the valid impCentral login key.

## Run Tests ##

- See [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for the details of how to configure and run the tests.
- Run [impt](https://github.com/electricimp/imp-central-impt) commands from the root directory of the lib. It contains a [default test configuration file](../.impt.test) which should be updated by *impt* commands for your testing environment (at least the Device Group must be updated).
