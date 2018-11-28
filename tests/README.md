# Test Instructions #

The tests in the current directory are intended to check the behavior of the Firebase library. The current set of tests check:

- Writing and reading data (the *write()* and *read()* library methods) with callbacks and promises using all available authentication types.
- Deleting data (the *remove()* library method) using all available authentication types.
- Tests for private *_parseEventMessage()* library method.
- Tests for the new (version 3.2.0 and up) *setAuthProvider()* library method.

The tests are written for and should be used with [impt](https://github.com/electricimp/imp-central-impt). Please see the [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) to learn how to configure and run the tests.

The tests require the following actions to be performed.

## Configure A Firebase Account ##

1. Log in to the [Firebase Console](https://console.firebase.google.com) in your web browser.
1. If you have an existing project that you want to work with, skip to Step 4, otherwise click the **Add project** button.
In the opened window enter a project name, then check the **I accept the controller-controller** box and click **Create project**:
![Create project](../png/CreateProject.png)
1. Wait until your project is created and click **Continue**.
1. From your project’s **Project Overview** section, click the gearwheel icon and choose **Project settings** from the menu:
![Project settings](../png/ProjectSettings.png)
1. Copy your project’s ID and Web API Key &mdash; they will be used as the *FIREBASE_INSTANCE_NAME* and *FIREBASE_WEB_API_KEY* environment variables.
![Project settings project ID](../png/ProjectSettingsProjectIdAndWebApiKey.png)
1. Click the **Service accounts** tab, then click **Generate new private key**:
![Generate private key](../png/GeneratePrivateKey.png)
1. In the opened window, click **Generate key**. The file `<project ID>-<random identifier>.json` will be downloaded to your computer.
It looks something like this:<br /><pre><code>{ "type": "service_account",
      "project_id": "test-1dd6f",
      "private_key_id": "8d429015c3ce0e91e62f3af7578338f5b6b2f801",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...cARA==\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-mtv6g@test-1dd6f.iam.gserviceaccount.com",
      "client_id": "100254262646168050509",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-mtv6g%40test-1dd6f.iam.gserviceaccount.com" }</code></pre>
    - Copy the contents of the `client_email` and `private_key` fields from the downloaded JSON file &mdash; they will be used as the *FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL* and *FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY* environment variables.
1. Click **Database secrets**.
1. Click **Show** near your database secret and copy the secret &mdash; it will be used as the *FIREBASE_AUTH_KEY* environment variable.:
![Project settings](../png/DatabaseSecret.png)
1. In the left sidebar menu, click **Database**, scroll down to the **Realtime Database** section and click **Create database**:
![Realtime Database](../png/RealtimeDatabase.png)
1. Select **Start in test mode** and click **Enable**:
![Database Security Rules](../png/DatabaseSecurityRules.png)
1. In the left sidebar menu click **Authentication**, choose the **Sign-in method** tab and click **Anonymous** for your **Sign-in provider**:
![Sign-in method](../png/SignInMethod.png)
1. Click the **Enable** switch to enable Anonymous and click **Save**:
![Sign-in method](../png/EnableAnonymousProvider.png)

## Set Environment Variables ##

1. Set *FIREBASE_INSTANCE_NAME*, *FIREBASE_WEB_API_KEY*, *FIREBASE_AUTH_KEY*, *FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL*, *FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY* environment variables to the values you retrieved in the previous steps.
1. For integration with [Travis](https://travis-ci.org), set *EI_LOGIN_KEY* environment variable to the valid [impCentral login key](https://developer.electricimp.com/tools/impcentral/impcentralintroduction#login-keys).

## Run The Tests ##

- See the [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) to learn how to configure and run the tests.
- Run [impt](https://github.com/electricimp/imp-central-impt) commands from the root directory of the library. It contains a [default test configuration file](../.impt.test) which should be updated by *impt* commands for your testing environment (at the very least you must change the Device Group).
