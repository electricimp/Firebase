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

#require "Firebase.agent.lib.nut:3.2.0"

// Firebase library example.
// Periodically writes data to the specified path of the Firebase database.
//
// Legacy Firebase tokens is used for authentication.
// Data is written every 10 seconds using write() library method.
// Every data record contains:
//  - A "value" attribute. This is an integer value, which starts at 1 and increases by 1 with every record written.
//    It restarts from 1 every time the example is restarted.
//  - A "measureTime" attribute. This is an integer value, converted to string, and is the time in seconds since the epoch.

const FIREBASE_DATA_PATH = "/test_data";
const WRITE_DATA_PERIOD_SEC = 10.0;

class DataWriter {
    _counter = 0;
    _firebaseClient = null;

    constructor(name, authKey) {
        _firebaseClient = Firebase(name, authKey);
    }

    // Returns a data to be written
    function getData() {
        _counter++;
        return {
            "value" : _counter,
            "measureTime" : time().tostring()
        };
    }

    // Periodically writes data to the specified path of the Firebase database
    function writeData() {
        _firebaseClient.write(
            FIREBASE_DATA_PATH,
            getData(),
            onDataWritten.bindenv(this));

        imp.wakeup(WRITE_DATA_PERIOD_SEC, writeData.bindenv(this));
    }

    // Callback executed once the data is written
    function onDataWritten(error, data) {
        if (error) {
            server.error("Writing data failed: " + error);
        } else {
            server.log("Data written successfully:");
            server.log(http.jsonencode(data));
        }
    }
}

// ----------------------------------------------------------
// FIREBASE CONSTANTS
// ----------------------------------------------------------
const FIREBASE_PROJECT_ID = "<YOUR_FIREBASE_PROJECT_ID>";
const FIREBASE_SECRET = "<YOUR_FIREBASE_SECRET>";

// Start application
dataWriter <- DataWriter(FIREBASE_PROJECT_ID, FIREBASE_SECRET);
dataWriter.writeData();
