// MIT License
//
// Copyright 2018 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#require "Promise.lib.nut:4.0.0"
#require "OAuth2.agent.lib.nut:2.0.1"
#require "Firebase.agent.lib.nut:3.2.0"

// Firebase library example.
// Periodically reads data from the specified path of the Firebase database.
//
// Google OAuth2 access tokens is used for authentication.
// Data is read every 15 seconds using read() library method.
// Every read data record is printed to the log.

const FIREBASE_DATA_PATH = "/test_data";
const READ_DATA_PERIOD_SEC = 15.0;

class DataReader {
    _firebaseClient = null;

    constructor(name, authProviderType, authProvider) {
        _firebaseClient = Firebase(name);
        _firebaseClient.setAuthProvider(authProviderType, authProvider);
    }

    // Periodically reads data from from the specified path of the Firebase database
    function readData() {
        _firebaseClient.read(FIREBASE_DATA_PATH)
            .then(onDataRead.bindenv(this))
            .fail(onError.bindenv(this));
        imp.wakeup(READ_DATA_PERIOD_SEC, readData.bindenv(this));
    }

    // Function executed once the data is read
    function onDataRead(data) {
        server.log("Data read successfully:");
        server.log(http.jsonencode(data));
    }

    // Function executed when reading data is failed
    function onError(error) {
        server.error("Reading data failed: " + error);
    }
}

// ----------------------------------------------------------
// FIREBASE CONSTANTS
// ----------------------------------------------------------
const FIREBASE_PROJECT_ID = "<YOUR_FIREBASE_PROJECT_ID>";
const FIREBASE_SERIVCE_ACCOUNT_CLIENT_EMAIL = "<YOUR_FIREBASE_SERIVCE_ACCOUNT_CLIENT_EMAIL>";
const FIREBASE_SERIVCE_ACCOUNT_PRIVATE_KEY = "<YOUR_FIREBASE_SERIVCE_ACCOUNT_PRIVATE_KEY>";

// obtaining Google OAuth2 access tokens provider
local oAuth2TokenProvider = OAuth2.JWTProfile.Client(
    OAuth2.DeviceFlow.GOOGLE,
    {
        "iss"         : FIREBASE_SERIVCE_ACCOUNT_CLIENT_EMAIL,
        "jwtSignKey"  : FIREBASE_SERIVCE_ACCOUNT_PRIVATE_KEY,
        "scope"       : "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/firebase.database"
    });

// Start application
dataReader <- DataReader(FIREBASE_PROJECT_ID, FIREBASE_AUTH_TYPE.OAUTH2_TOKEN, oAuth2TokenProvider);
dataReader.readData();
