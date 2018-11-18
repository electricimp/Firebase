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

@include "https://raw.githubusercontent.com/electricimp/OAuth-2.0/master/OAuth2.agent.lib.nut"

const FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL = "@{FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL}";
const FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY = "@{FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY}";
const FIREBASE_WEB_API_KEY = "@{FIREBASE_WEB_API_KEY}";

// Example of Firebase ID tokens provider for anonymous user.
// Uses Firebase Auth REST API requests:
// - anonymous sign in (https://firebase.google.com/docs/reference/rest/auth/#section-sign-in-anonymously)
// - exchange a refresh token for an ID token (https://firebase.google.com/docs/reference/rest/auth/#section-refresh-token)

const FIREBASE_ANONYMOUS_SIGN_IN_URL = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser";
const FIREBASE_REFRESH_TOKEN_URL = "https://securetoken.googleapis.com/v1/token";

class FirebaseIdTokenProvider {
    _webApiKey = null;
    _accessToken = null;
    _expiresAt = 0;
    _refreshToken = null;
    _headers = null;

    constructor(webApiKey) {
        _webApiKey = webApiKey;
        _headers = { "Content-Type" : "application/json" };
    }

    // Checks if access token is valid
    function isTokenValid() {
        return _accessToken && time() < _expiresAt;
    }

    // Acquires access token:
    // - if the current access token is valid, returns it immediately
    // - otherwise refreshes expired access token
    function acquireAccessToken(tokenReadyCallback) {
        if (isTokenValid()) {
            tokenReadyCallback(_accessToken, null);
            return;
        }
        if (_refreshToken) {
            _exchangeRefreshToken(tokenReadyCallback);
        } else {
            _anonymousSignIn(tokenReadyCallback);
        }
    }

    function _anonymousSignIn(callback) {
        local url = format("%s?key=%s", FIREBASE_ANONYMOUS_SIGN_IN_URL, _webApiKey);
        local body = { "returnSecureToken" : true };
        http.post(url, _headers, http.jsonencode(body)).sendasync(function (response) {
            _processResponse(response, "idToken", "refreshToken", "expiresIn", callback);
        }.bindenv(this));
    }

    function _exchangeRefreshToken(callback) {
        local url = format("%s?key=%s", FIREBASE_REFRESH_TOKEN_URL, _webApiKey);
        local body = {
            "grant_type" : "refresh_token",
            "refresh_token" : _refreshToken
        };
        http.post(url, _headers, http.jsonencode(body)).sendasync(function (response) {
            _processResponse(response, "access_token", "refresh_token", "expires_in", callback);
        }.bindenv(this));
    }

    function _processResponse(response, accessTokenKey, refreshTokenKey, expiresInKey, callback) {
        _accessToken = null;
        local httpStatus = response.statuscode;
        local error = null;
        local body = null;
        if (httpStatus < 200 || httpStatus >= 300) {
            error = "Firebase Auth error: " + httpStatus;
        }
        try {
            body = http.jsondecode(response.body);
            if (error) {
                if ("error" in body && "message" in body.error) {
                    error = format("%s: %s", error, body.error.message);
                }
            } else if (accessTokenKey in body && refreshTokenKey in body && expiresInKey in body) {
                _accessToken = body[accessTokenKey];
                _refreshToken = body[refreshTokenKey];
                _expiresAt = time() + body[expiresInKey].tointeger();
            } else {
                error = "Unexpected response from Firebase Auth";
            }
        } catch (e) {
            error = e;
        }
        callback(_accessToken, error);
    }
}

firebaseIdTokenProvider <- FirebaseIdTokenProvider(FIREBASE_WEB_API_KEY);

oAuth2TokenProvider <- OAuth2.JWTProfile.Client(
    OAuth2.DeviceFlow.GOOGLE,
    {
        "iss"         : FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL,
        "jwtSignKey"  : FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY,
        "scope"       : "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/firebase.database"
    });
