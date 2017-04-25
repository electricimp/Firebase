// MIT License
//
// Copyright 2017 Electric Imp
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

const FIREBASE_AUTH_KEY = "#{env:FIREBASE_AUTH_KEY}";
const FIREBASE_INSTANCE_NAME = "#{env:FIREBASE_INSTANCE_NAME}";

class NoPromiseTestCase extends ImpTestCase {
    _path = null;
    _firebase = null;
    _luckyNum = null;

    function setUp() {
        if (getroottable().Promise != null) {
            delete getroottable().Promise; 
        }
        this._firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        this._path = this.session + "-nopromise";
        this._luckyNum = math.rand() + "" + math.rand();
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    /**
     * Write test data, but no callback and no promise used
     * We don't know, when write will be ready, and we just wait.
     * We also wait before remove in tearDown(); 
     */
    function test01_write() { 
        this._firebase.write(this._path, this._luckyNum);
        imp.wakeup(1, function() {
            this._firebase.read(this._path, function (error, data) {
                if (error) {
                    server.error(error);
                } else {
                    try {
                        this.assertEqual(this._luckyNum, data);
                        server.log("Read test data at \""+ this._path + "\"");
                    } catch (e) {
                        server.error(e);
                    }
                }
            }.bindenv(this));
        }.bindenv(this));
    }   

    /**
     * Deletes test data
     */
    function tearDown() {
        imp.wakeup(2, function() { 
            this._firebase.remove(this._path, function (error, response) {
                if (error) {
                    server.error(error);
                } else {
                    server.log("Removed test data at \""+ this._path + "\"");
                }
            }.bindenv(this))
        }.bindenv(this));
    }
}
