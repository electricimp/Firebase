// MIT License
//
// Copyright 2017-2018 Electric Imp
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

@include "./tests/AuthProviders.agent.nut"

const FIREBASE_AUTH_KEY = "@{FIREBASE_AUTH_KEY}";
const FIREBASE_INSTANCE_NAME = "@{FIREBASE_INSTANCE_NAME}";

class NoPromiseTestCase extends ImpTestCase {
    _path = null;
    _firebase = null;
    _luckyNum = null;
    _myPromise = null;

    /**
     * Delete Promise lib for test no promise and no callback functionality
     * Use _myPromise to check async code
     */
    function setUp() {
        local rt = getroottable();
        if ("Promise" in rt) {
            _myPromise = delete rt.Promise; 
        }
        this._firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        this._path = this.session + "-nopromise";
        this._luckyNum = math.rand() + "" + math.rand();
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    /**
     * Write test data, but no callback and no promise used
     */
    function test01_write() {

        return _myPromise(function (ok, err) { 
            this._firebase.write(this._path, this._luckyNum);
            getroottable()["Promise"] <- _myPromise;
            imp.wakeup(3, // let the writing go through
                function () {
                    this._firebase.read(this._path, function (error, data) {
                        if (error) {
                            err(error);
                        } else {
                            try {
                                this.assertEqual(this._luckyNum, data);
                                ok("Read test data at \""+ this._path + "\"");
                            } catch (e) {
                                err(e);
                            }
                        }
                    }.bindenv(this));
                }.bindenv(this));
        }.bindenv(this));
    }

    /**
     * Deletes test data
     */
    function tearDown() {
        return _myPromise(function (ok, err) { 
            this._firebase.remove(this._path, function (error, response) {
                if (error) {
                    err(error);
                } else {
                    ok("Removed test data at \""+ this._path + "\"");
                }
            }.bindenv(this));
        }.bindenv(this));
    }
}

class NoPromiseOAuth2TestCase extends NoPromiseTestCase {
    function setUp() {
        base.setUp();
        this._firebase = Firebase(FIREBASE_INSTANCE_NAME);
        this._firebase.setAuthProvider(FIREBASE_AUTH_TYPE.OAUTH2_TOKEN, oAuth2TokenProvider);
    }
}

class NoPromiseFirebaseIdAuthTestCase extends NoPromiseTestCase {
    function setUp() {
        base.setUp();
        this._firebase = Firebase(FIREBASE_INSTANCE_NAME);
        this._firebase.setAuthProvider(FIREBASE_AUTH_TYPE.FIREBASE_ID_TOKEN, firebaseIdTokenProvider);
    }
}
