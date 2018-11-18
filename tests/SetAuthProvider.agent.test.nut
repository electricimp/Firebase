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

@include "./tests/AuthProviders.agent.nut"

const FIREBASE_AUTH_KEY = "@{FIREBASE_AUTH_KEY}";
const FIREBASE_INSTANCE_NAME = "@{FIREBASE_INSTANCE_NAME}";

class SetAuthProviderTestCase extends ImpTestCase {
    function testSetAuthProvider() {
        local firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        this.assertEqual(firebase._authType, FIREBASE_AUTH_TYPE.LEGACY_TOKEN);

        firebase.setAuthProvider(FIREBASE_AUTH_TYPE.OAUTH2_TOKEN, oAuth2TokenProvider);
        this.assertEqual(firebase._authType, FIREBASE_AUTH_TYPE.OAUTH2_TOKEN);

        firebase.setAuthProvider(FIREBASE_AUTH_TYPE.FIREBASE_ID_TOKEN, firebaseIdTokenProvider);
        this.assertEqual(firebase._authType, FIREBASE_AUTH_TYPE.FIREBASE_ID_TOKEN);

        firebase.setAuthProvider(FIREBASE_AUTH_TYPE.LEGACY_TOKEN, firebaseIdTokenProvider);
        this.assertEqual(firebase._authType, FIREBASE_AUTH_TYPE.LEGACY_TOKEN);
        this.assertEqual(firebase._authProvider, null);

        // If the provider parameter is null (irrespective of the type parameter value), 
        // the authentication type must be changed to the FIREBASE_AUTH_TYPE.LEGACY_TOKEN
        firebase.setAuthProvider(FIREBASE_AUTH_TYPE.FIREBASE_ID_TOKEN, firebaseIdTokenProvider);
        firebase.setAuthProvider(FIREBASE_AUTH_TYPE.OAUTH2_TOKEN, null);
        this.assertEqual(firebase._authType, FIREBASE_AUTH_TYPE.LEGACY_TOKEN);
        
        // If a not supported value is passed to the type parameter, the authentication type is changed to the 
        // FIREBASE_AUTH_TYPE.LEGACY_TOKEN
        firebase.setAuthProvider(FIREBASE_AUTH_TYPE.FIREBASE_ID_TOKEN, firebaseIdTokenProvider);
        firebase.setAuthProvider("wrong type", firebaseIdTokenProvider);
        this.assertEqual(firebase._authType, FIREBASE_AUTH_TYPE.LEGACY_TOKEN);
    }
}
