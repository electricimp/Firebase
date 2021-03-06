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

class BasicTestCase extends ImpTestCase {
    _path = null;
    _firebase = null;
    _luckyNum = null;

    function setUp() {
        _firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        _path = this.session + "-basic";
        _luckyNum = math.rand() + "" + math.rand();
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    /**
     * Write, then read test data with callbacks
     */
    function test01_callbackWriteRead() {
        return Promise(function (ok, err) {
            _firebase.write(_path, _luckyNum, function (error, response) {
                if (error) {
                    err(error);
                } else {
                    try {
                        this.assertEqual(_luckyNum, response);
                        ok("Written test data at \""+ _path + "\"");
                    } catch (e) {
                        err(e);
                    }
                }
            }.bindenv(this));
        }.bindenv(this)).then(function (data) {
            return Promise(function (ok, err) {
                _firebase.read(_path, function (error, data) {
                    if (error) {
                        err(error);
                    } else {
                        try {
                            this.assertEqual(_luckyNum, data);
                            ok("Read test data at \""+ _path + "\"");
                        } catch (e) {
                            err(e);
                        }
                    }
                }.bindenv(this));
            }.bindenv(this));
        }.bindenv(this));
    }

    /**
     * Write, then read test data with promises
     */
    function test02_promiseWriteRead() {
        _luckyNum = _luckyNum + 1;
        return _firebase.write(_path, _luckyNum)
            .then(function (data) {
                      this.assertEqual(_luckyNum, data);
                  }.bindenv(this))
            .then(function (data) {
                      return _firebase.read(_path);
                  }.bindenv(this))
            .then(function (data) {
                      this.assertEqual(_luckyNum, data);
                  }.bindenv(this));
    }


    /**
     * Deletes test data
     */
    function tearDown() {
        return Promise(function (ok, err) {
            _firebase.remove(_path, function (error, response) {
                if (error) {
                    err(error);
                } else {
                    ok("Removed test data at \""+ _path + "\"");
                }
            }.bindenv(this));
        }.bindenv(this))
    }
}

class BasicOAuth2TestCase extends BasicTestCase {
    function setUp() {
        base.setUp();
        _firebase = Firebase(FIREBASE_INSTANCE_NAME);
        _firebase.setAuthProvider(FIREBASE_AUTH_TYPE.OAUTH2_TOKEN, oAuth2TokenProvider);
    }
}

class BasicFirebaseIdAuthTestCase extends BasicTestCase {
    function setUp() {
        base.setUp();
        _firebase = Firebase(FIREBASE_INSTANCE_NAME);
        _firebase.setAuthProvider(FIREBASE_AUTH_TYPE.FIREBASE_ID_TOKEN, firebaseIdTokenProvider);
    }
}
