# Firebase 3.2.0 #

The Firebase library allows you to easily integrate your agent code with Firebase’s realtime backend, which includes data storage, user authentication, static hosting and more.

**To include this library in your project, add** `#require "Firebase.agent.lib.nut:3.2.0"` **to the top of your agent code.**

[![Build Status](https://travis-ci.org/electricimp/Firebase.svg?branch=master)](https://travis-ci.org/electricimp/Firebase)

## Class Usage ##

### Authentication ###

Firebase supports three types of [authentication](https://firebase.google.com/docs/database/rest/auth):

- [Google OAuth2 access tokens](https://firebase.google.com/docs/database/rest/auth#google_oauth2_access_tokens)
- [Firebase ID tokens](https://firebase.google.com/docs/database/rest/auth#firebase_id_tokens)
- [Legacy tokens](https://firebase.google.com/docs/database/rest/auth#legacy_tokens)

By default, the library is configured to use legacy tokens for authentication. This mode may be initialized by using the *authKey* parameter in the library class’ constructor. Set this parameter to `null` if you plan to use another authentication type.

At any time, the current type of authentication may be changed by calling [*setAuthProvider()*](#setauthprovidertype-provider). Please see the method’s description for more details.

Full working examples for each type of authentication are provided in the [Examples](./Examples) directory.

### Optional Callbacks And Promises ###

The methods *read()*, *write()*, *remove()*, *update()* and *push()* all include an optional *callback* parameter. If a callback function is provided, it will be called when the response from Firebase is received. The callback function has two parameters: *error* and *data*. If no error was encountered, *error* will be `null`. If any error occurred, an error message will be passed to the callback’s *error* parameter. If Firebase returns a 429 error, the library will now prevent further requests from being processed for at least 60 seconds. 

As an alternative to passing in a callback, you can make use of Electric Imp’s Promise library [GitHub](https://github.com/electricimp/Promise/). If the Promise library is included and no callback is provided, the methods *read()*, *write()*, *remove()*, *update()* and *push()* will automatically return a promise.

**To include the Promise library in your project, add** `#require "Promise.lib.nut:4.0.0"` **to the top of your agent code.**

### Constructor: Firebase(*instanceName[, authKey][, domain][, debug]*) ###

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *instanceName* | String | Yes | The name of your firebase instance |
| *authKey* | String | No | An optional authentication key. Default: `null` (see [‘Authentication’](#authentication), above) |
| *domain* | String | No | A base domain name for the Firebase instance, used to build the base Firebase database URL, eg. `https://username.firebaseio.com`. Default: `"firebaseio.com"` |
| *debug* | Boolean | No | The debug flag. Set to `false` to suppress error logging within the Firebase class. Default: `true` |

The domain and instance are used to construct the URL that requests are made against in the following way: `https://{instance}.{domain}`.

If you do not plan to use legacy tokens for authentication, pass `null` as the *authKey* parameter and call the [*setAuthProvider()*](#setauthprovidertype-provider) method immediately after the constructor. That method’s description contains an example of this.

#### Example: Legacy Authentication ####

```squirrel
#require "Firebase.agent.lib.nut:3.2.0"

const FIREBASE_NAME = "YOUR_FIREBASE_NAME";
const FIREBASE_AUTH_KEY = "YOUR_FIREBASE_AUTH_KEY";

firebase <- Firebase(FIREBASE_NAME, FIREBASE_AUTH_KEY);
```

## Class Methods ##

### setAuthProvider(*type[, provider]*) ###

This method updates the type of authentication used by the library to communicate with Firebase. All subsequent calls to Firebase will use the set authentication method.

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *type* | Constant | Yes | The type of authentication. It must be one of the following values:<br />&bull; *FIREBASE_AUTH_TYPE.LEGACY_TOKEN* &mdash; [Legacy token authentication](https://firebase.google.com/docs/database/rest/auth#legacy_tokens). It is initialized by the *authKey* parameter in the library class’ constructor<br />&bull; *FIREBASE_AUTH_TYPE.OAUTH2_TOKEN* &mdash; [Google OAuth2 access tokens authentication](https://firebase.google.com/docs/database/rest/auth#google_oauth2_access_tokens). An external provider of access tokens must be used and passed to the library via the *provider* parameter. Electric Imp’s [OAuth2.JWTProfile.Client](https://github.com/electricimp/OAuth-2.0) library may be used as the provider<br />&bull; *FIREBASE_AUTH_TYPE.FIREBASE_ID_TOKEN* &mdash; [Firebase ID token authentication](https://firebase.google.com/docs/database/rest/auth#firebase_id_tokens). An external provider of access tokens must be used and passed to the library via the *provider* parameter |
| *provider* | String | No | An optional external provider of access tokens. The provider must contain an *acquireAccessToken()* method that takes one required parameter: a handler that is called when an access token is acquired or an error occurs. The handler itself has two required parameters: *token* &mdash; a string representation of the access token, and *error* &mdash; a string with error details (or `null` if no error occurred). |

If an unsupported value is passed into *type*, or `null` is passed into *provider* (irrespective of the *type* value), the authentication type is changed to *LEGACY_TOKEN*.

#### Return Value ####

Nothing.

#### Example: Firebase ID Authentication ####

```squirrel
#require "Firebase.agent.lib.nut:3.2.0"
#require "OAuth2.agent.lib.nut:2.0.1"

const FIREBASE_NAME = "YOUR_FIREBASE_NAME";
const FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL = "YOUR_FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL";
const FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY = "YOUR_FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY";

firebase <- Firebase(FIREBASE_NAME);
firebase.setAuthProvider(
    FIREBASE_AUTH_TYPE.OAUTH2_TOKEN,
    OAuth2.JWTProfile.Client(
        OAuth2.DeviceFlow.GOOGLE,
        {
            "iss"         : FIREBASE_SERVICE_ACCOUNT_CLIENT_EMAIL,
            "jwtSignKey"  : FIREBASE_SERVICE_ACCOUNT_PRIVATE_KEY,
            "scope"       : "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/firebase.database"
        }));
```

### on(*path, callback*) ###

This method listens for changes at a particular location.

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *path* | String | Yes | The path to a node |
| *callback* | Function | Yes | Called when changes to the node are detected |

The callback method takes two parameters of its own: *path* and *data*. The *path* parameter returns the full path of the node that was modified. This allows you to determine if the root of the path you’re tracking was changed, or if a node below it changed. The *data* parameter contains the modified data.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Register a callback handler
firebase.on("/settings", function(path, data) {
    server.log("Changes detected at: " + path);
    server.log("New Data: " + http.jsonencode(data));

    // Make sure the data we're looking for exists
    if ("color" in data) {
        // Send the new settings to the device
        device.send("newColor", data.color);
    }
});

// Register a callback handler
firebase.on("/current/state", function(path, state) {
    server.log("Changes detected at: " + path);
    server.log("New Data: " + http.jsonencode(state));

    // Send the new state to the device
    if (state) device.send("newState", state);
});

// Open the stream to begin listening
firebase.stream();
```

**Note** You must call the *stream()* method *(see below)* in order to open a realtime stream with Firebase and have the registered callbacks invoked.

### stream(*[path][, uriParams][, onErrorCallback]*) ###

This method creates a streaming request. 

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *path* | String | No | The path to a node. Default: the root of the instance (`"/"`) |
| *uriParams* | Function | No | An optional table of Firebase queries |
| *onErrorCallback* | Function | No | Called if errors occur while making the streaming request |

The Firebase class will attempt to silently and automatically reconnect when it encounters a 429 or 503 status code error. For all other errors, it is up to the developer to re-initiate the *stream()* request, typically in the function passed into *onErrorCallback*. This function has a single parameter which receives the [HTTP Response Table](https://developer.electricimp.com/api/httprequest/sendasync) from the request.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Setup onError handler
function onStreamError(response) {
    server.error("Firebase encountered and error:");
    server.error(response.statuscode + " - " + response.body);
    imp.wakeup(1.0, openStream });
}

// Wrap up the process of opening a stream
function openStream() {
    firebase.stream("/", onStreamError);
}

openStream();
```

### isStreaming() ###

Is a stream currently open?

#### Return Value ####

Boolean &mdash; `true` if the stream is currently open, otherwise `false`.

### closeStream() ###

This method closes the current stream if it is open, but takes no action otherwise.

#### Return Value ####

Nothing.

### fromCache(*[path]*) ###

This method reads the local/cached copy of the data at a specified path. This method is intended for use in a *.on()* handler to prevent unnecessary communication with Firebase through the *read()* method.

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *path* | String | No | The path to a node. Default: the root of the instance (`"/"`) |

#### Return Value ####

The cached data.

#### Example ####

```squirrel
firebase.on("/settings", function(path, data) {
    // Check if the location setting changed
    if ("location" in data) {
        // If it did, grab the location data from Firebase
        // use fromCache() instead of read to avoid an unnecessary Web request
        local location = firebase.fromCache("/location");

        // Send the new location information to the device
        device.send("updateLocation", location);
    }
});
```

### read(*path[, uriParams][, callback]*) ###

This method reads data from the specified path (ie. performs a GET request).

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *path* | String | Yes | The path to a node |
| *uriParams* | Function | No | An optional table of Firebase queries |
| *callback* | Function | No | Called when data is received from Firebase, or an error occurred |

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be the data received from Firebase. It will be `null` if an error occurred.

#### Return Value ####

This method returns a Promise when no callback is provided and the Promise library is included in your agent code.

#### Examples ####

##### Simple Asynchronous Read #####

```squirrel
// Read all the settings:
firebase.read("/settings", function(error, data) {
    if (error) {
        server.error(error);
    } else {
        foreach (setting, value in data) {
            server.log(setting + ": " + value);
        }
    }
});
```

##### Read With Query Parameters #####

Query Parameters can also be passed in as a table of arguments to *uriParams*:

```squirrel
fbDino <- Firebase("dinosaur-facts");

// Perform a shallow query to get the list of keys at this location
fbDino.read("/dinosaurs", {"shallow": true}, function(error, data){
    server.log(http.jsonencode(data));
    // Logs: { "lambeosaurus": true, "linhenykus": true, "triceratops": true,
    //         "stegosaurus": true, "bruhathkayosaurus": true, "pterodactyl": true }
})

// The \uf8ff character used in the query above is a very high code point in the Unicode range.
// Because it is after most regular characters in Unicode, the query matches all values that start with a b.
fbDino.read("/dinosaurs", {"orderBy": "$key", "startAt": "b", "endAt": @"b\uf8ff"},
    function(error,data){
        server.log(http.jsonencode(data));
        // Logs { "bruhathkayosaurus": { "appeared": -70000000, "vanished": -70000000,
        //        "order": "saurischia", "length": 44, "weight": 135000, "height": 25 } }
});
```

### write(*path, data[, callback]*) ###

This method updates data at the specified path (ie. performs a PUT request).

**Note** When you write to a specific path you replace all of the data at that path and all paths below it.

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *path* | String | Yes | The path to a node |
| *data* | Any | Yes | The data to write |
| *callback* | Function | No | Called when data is received from Firebase, or an error occurred |

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be the written data. It will be `null` if an error occurred.

#### Return Value ####

This method returns a Promise when the callback is not provided and the Promise library is included in your agent code.

#### Example ####

```squirrel
// When we get a new state
device.on("newState", function(state) {
    // Write the state to Firebase
    firebase.write("/current/state", state, function(error, data) {
        // If there was an error during the write, log it
        if (error) {
            server.error(error);
        } else {
            server.log(data);
        }
    });
});
```

### update(*path, data[, callback]*) ###

This method updates a subset of data at a particular path (ie. performs a PATCH request).

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *path* | String | Yes | The path to a node |
| *data* | Any | Yes | The data to write |
| *callback* | Function | No | Called when data is received from Firebase, or an error occurred |

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be the updated information. It will be `null` if an error occurred.

#### Return Value ####

This method returns a Promise when the callback is not provided and the Promise library is included in your agent code.

#### Example ####

```squirrel
device.on("newLocation", function(location) {
    // Update the location in the settings:
    firebase.update("/settings", { "location": location }, function(error, data) {
        if (error) {
            server.error(error);
        } else {
            server.log(data.location);
        }
    });
});
```

### push(*path, data[, priority][, callback]*) ###

This method pushes data to the specified path (ie. performs a POST request). It should be used when you’re adding an item to a list.

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *path* | String | Yes | The path to a node |
| *data* | Any | Yes | The data to write |
| *priority* | Integer or string | No | An optional value used to sort the children under a specific parent, or in a query if no other sort condition is specified |
| *callback* | Function | No | Called when data is received from Firebase, or an error occurred |

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be the pushed data. It will be `null` if an error occurred.

#### Return Value ####

This method returns a Promise when the callback is not provided and the Promise library is included in your agent code.

#### Example ####

```squirrel
// Example using a promise instead of callback function
local results = [];
local fbKeys = [];

device.on("temps", function(data) {
    foreach(reading in data) {
        local pushData = { "deviceId": reading.deviceId,
                           "timestamp": reading.ts,
                           "temp": reading.temp };

        results.push(firebase.push("/temperatures", pushData));
    }

    local promise = Promise.all(results);
    promise.then(function(responses) {
        foreach(response in responses) {
            fbKeys.push(response.name);
        }
    });
});
```

### remove(*path[, callback]*) ###

This method deletes data at the specified path (ie. performs a DELETE request).

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *path* | String | Yes | The path to a node |
| *callback* | Function | No | Called when Firebase responds, or an error occurred |

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *response*, will be an object representing the Firebase response. It will be `null` if an error occurred.

#### Return Value ####

This method returns a Promise when the callback is not provided and the Promise library is included in your agent code.

#### Example ####

```squirrel
// If the user opts out of tracking:
device.on("no-tracking", function(data) {
    // Delete the location information from Firebase
    firebase.remove("/settings/location", function(error, response) {
        // If there was an error
        if (error) server.error(error);
    });
});
```

## Examples ##

Full working examples are provided in the [Examples](./Examples) directory.

## Testing ##

Tests for the library are provided in the [tests](./tests) directory.

## License ##

This library is licensed under [MIT License](https://github.com/electricimp/Firebase/blob/master/LICENSE).
