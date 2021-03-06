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

class QueriesTestCase extends ImpTestCase {
    _path = null;
    _firebase = null;

    // @see http://dinosaurs.findthedata.com/
    _dinos = {

        "Acrocanthosaurus": {
            "height": 18,
            "length": 38,
            "weight": 13600,
            "predation": "Carnivorous",
            "region": "North America"
        },

        "Euoplocephalus": {
            "height": 10,
            "length": 32,
            "weight": 4000,
            "predation": "Omnivorous",
            "region": "Africa"
        },

        "Herrerasaurus": {
            "height": 7,
            "length": 10,
            "weight": 772,
            "predation": "Carnivorous",
            "region": "South America"
        },

        "Homalocephale": {
            "height": 2,
            "length": 5,
            "weight": 100,
            "predation": "Omnivorous",
            "region": "Asia"
        },

        "Velociraptor": {
            "height": 2,
            "length": 6,
            "weight": 33,
            "predation": "Carnivorous",
            "region": "Asia"
        }
    };

    function setUp() {
        _firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        _path = this.session + "-queries";
        // add indexes
        local rules = {"rules": {".write": true, ".read": true}};
        rules.rules[_path] <- {".write": true, ".read": true, ".indexOn": ["height", "weight", "length"]};

        return Promise(function (ok, err) {
            _firebase.write(".settings/rules",
                rules,
                function (error, res) {
                    if (error) {
                        err(error);
                    } else {
                        ok();
                    }
                }.bindenv(this));
        }.bindenv(this))
    }

    /**
     * Write test data
     */
    function test01_write() {
        return Promise(function (ok, err) {
            _firebase.write(_path, _dinos, function (error, response) {
                if (error) {
                    err(error);
                } else {
                    try {
                        this.assertDeepEqual(_dinos, response);
                        ok("Written test data at \""+ _path + "\"");
                    } catch (e) {
                        err(e);
                    }
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    /**
     * Read keys only
     */
    function test02_readKeys() {
        return Promise(function (ok, err) {
            _firebase.read(_path, {"shallow": true}, function (error, data) {
                if (error) {
                    err(error);
                } else {
                    try {
                        this.assertDeepEqual({"Velociraptor":true,"Homalocephale":true,"Herrerasaurus":true,"Acrocanthosaurus":true,"Euoplocephalus":true}, data);
                        ok();
                    } catch (e) {
                        err(e);
                    }
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    // todo: more test on queries

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

class QueriesOAuth2TestCase extends QueriesTestCase {
    function setUp() {
        base.setUp();
        _firebase = Firebase(FIREBASE_INSTANCE_NAME);
        _firebase.setAuthProvider(FIREBASE_AUTH_TYPE.OAUTH2_TOKEN, oAuth2TokenProvider);
    }
}

class QueriesFirebaseIdAuthTestCase extends QueriesTestCase {
    function setUp() {
        base.setUp();
        _firebase = Firebase(FIREBASE_INSTANCE_NAME);
        _firebase.setAuthProvider(FIREBASE_AUTH_TYPE.FIREBASE_ID_TOKEN, firebaseIdTokenProvider);
    }
}
