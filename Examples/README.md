# Firebase Examples #

This document describes the sample applications provided with the [Firebase library](../README.md).

The following example applications are provided:

- DataWriter &mdash; writes data to a Firebase database.
- DataReader &mdash; reads data from a Firebase database.
- StreamReader &mdash; subscribes to data-change notifications from a Firebase database.

We recommend that you:

- Run DataWriter as the agent of one device.
- Run DataReader as the agent of a second device.
- Run StreamReader as the agent of a third device.

To see data being received, you need to run the DataReader and/or StreamReader examples alongside the DataWriter example.

Each example is described below. If you wish to try one out, you'll find generic and example-specific setup instructions further down the page.

## DataWriter ##

This example periodically writes data to the specified path of the Firebase database.

- Legacy Firebase tokens are used for authentication.
- Data is written every ten seconds using the library's *write()* method.
- Every data record contains:
  - A *value* attribute. This is an integer value, which starts at 1 and increases by 1 with every record sent. It restarts from 1 every time the example is restarted.
  - A *measureTime* attribute. This is an integer value, converted to string, and is the time in seconds since the epoch.

![DataWriter example](../png/DataWriter.png)

## DataReader ##

This example periodically reads data from the specified path of the Firebase database.

- Google OAuth2 access tokens are used for authentication.
- Data is read every 15 seconds using the library's *read()* method.
- Every read data record is printed to the log.

![DataReader example](../png/DataReader.png)

## StreamReader ##

This example subscribes to notifications of changes to data at the specified path of the Firebase database.

- Firebase ID tokens for an anonymous user are used for authentication.
- The library's *on()* and *stream()* methods are used.
- Every received data record is printed to the log.

![StreamReader example](../png/StreamReader.png)

## Examples Setup ##

1. In [Electric Imp’s impCentral™](https://impcentral.electricimp.com/login) create a new Product and an accompanying Development Device Group.
1. Assign a device to the newly created Device Group.
1. Copy the code linked below for the example you wish to run and paste it into impCentral as the agent code.
    1. [DataWriter](./DataWriter.agent.nut)
    1. [DataReader](./DataReader.agent.nut)
    1. [StreamReader](./StreamReader.agent.nut)

Before running an example application you need to set the configuration constants in the application (agent) source code. The instructions below will walk you through the necessary steps.

### Setup For All Examples ### 

#### Configure A Firebase Account ###

1. Log in to the [Firebase Console](https://console.firebase.google.com) in your web browser.
1. If you have an existing project that you want to work with, skip to Step 3, otherwise click the **Add project** button.
In the opened window enter a project name, then check the **I accept the controller-controller** box and click **Create project**:
![Create project](../png/CreateProject.png)
    - Wait until your project is created and click **Continue**.
1. From your project’s **Project Overview** section, click the gearwheel icon and choose **Project settings** from the menu:
![Project settings](../png/ProjectSettings.png)
    - Copy your project’s ID &mdash; it will be used as the *FIREBASE_PROJECT_ID* constant in the agent code:<br />
    ![Project settings project ID](../png/ProjectSettingsProjectId.png)
1. In the left sidebar menu, click **Database**, scroll down to the **Realtime Database** section and click **Create database**:
![Realtime Database](../png/RealtimeDatabase.png)
1. Select **Start in test mode** and click **Enable**:
![Database Security Rules](../png/DatabaseSecurityRules.png)

### Additional Setup for the DataWriter Example ###

1. In the [Firebase Console](https://console.firebase.google.com) select the project you created in the previous steps.
1. From your project’s **Project Overview** section, click the gearwheel icon and choose **Project settings** from the menu:
![Project settings](../png/ProjectSettings.png)
1. Select the **Service accounts** tab.
1. Click **Database secrets**.
1. Click **Show** near your database secret and copy the secret &mdash; it will be used as the *FIREBASE_SECRET* constant in the agent code:
![Project settings](../png/DatabaseSecret.png)

### Additional Setup for the DataReader Example ###

1. In the [Firebase Console](https://console.firebase.google.com) select the project you created in the previous steps.
1. From your project’s **Project Overview** section, click the gearwheel icon and choose **Project settings** from the menu:
![Project settings](../png/ProjectSettings.png)
1. Select the **Service accounts** tab.
1. Click **Generate new private key**:
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
    - Copy the contents of the `client_email` and `private_key` fields from the downloaded JSON file &mdash; they will be used as the *FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL* and *FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY* constants in the agent code.

### Additional Setup for the StreamReader Example ###

1. In the [Firebase Console](https://console.firebase.google.com) select the project you created in the previous steps.
1. From your project’s **Project Overview** section, click the gearwheel icon and choose **Project settings** from the menu:
![Project settings](../png/ProjectSettings.png)
    - Copy your project’s Web API Key &mdash; it will be used as the *FIREBASE_WEB_API_KEY* constant in the agent code:
![Project settings web api key](../png/ProjectSettingsWebApiKey.png)
1. In the left sidebar menu click **Authentication**, choose the **Sign-in method** tab and click **Anonymous** for your **Sign-in provider**:
![Sign-in method](../png/SignInMethod.png)
1.Click the **Enable** switch to enable Anonymous and click **Save**:
![Sign-in method](../png/EnableAnonymousProvider.png)

#### Constants Setup ###

Set the example code configuration constants (*FIREBASE_PROJECT_ID*, *FIREBASE_SECRET*, *FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL*, *FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY*, *FIREBASE_WEB_API_KEY* depending on the example) with the values retrieved in the previous steps. Set the same value of *FIREBASE_PROJECT_ID* for all examples:
![Examples config](../png/ExampleConfig.png)
