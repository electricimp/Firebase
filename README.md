# Firebase 3.2.0 #

The Firebase library allows you to easily integrate your agent code with Firebase’s realtime backend, which includes data storage, user authentication, static hosting and more.

**To add this library to your project, add** `#require "Firebase.agent.lib.nut:3.2.0"` **to the top of your agent code.**

[![Build Status](https://travis-ci.org/electricimp/Firebase.svg?branch=master)](https://travis-ci.org/electricimp/Firebase)

## Class Usage ##

### Authentication ###

Firebase supports three types of [authentication](https://firebase.google.com/docs/database/rest/auth):
- [Google OAuth2 access tokens](https://firebase.google.com/docs/database/rest/auth#google_oauth2_access_tokens),
- [Firebase ID tokens](https://firebase.google.com/docs/database/rest/auth#firebase_id_tokens),
- [Legacy tokens](https://firebase.google.com/docs/database/rest/auth#legacy_tokens).

By default, the library is setup for the *Legacy tokens* authentication which may be initialized by the *authKey* parameter in the library class's constructor. Set this parameter to `null` if you plan to use another authentication type.

At any time, the current type of authentication may be changed by calling the *setAuthProvider()* method. See the method's description for more details.

Full working examples for each type of authentication are provided in the [examples](./examples) directory.

### Optional Callbacks And Promises ###

The methods *read()*, *write()*, *remove()*, *update()* and *push()* contain an optional *callback* parameter. If a callback function is provided, it will be called when the response from Firebase is received. The callback takes two required parameters: *error* and *response*. If no error is encountered, *error* will be `null`. If Firebase returns a 429 error the library will now prevent further requests from being processed for at least 60 seconds, and an error will be passed to the callback’s *error* parameter.

As an alternative to passing in a callback, you can include the Electric Imp Promise library [GitHub](https://github.com/electricimp/Promise/). If the promise library is included, the methods *read()*, *write()*, *remove()*, *update()* and *push()* will return a promise if no callback is provided.

**To add Promise library to your project, add** `#require "Promise.lib.nut:4.0.0"` **to the top of your agent code.**

### Constructor: Firebase(*instanceName[, authKey][, domain][, debug]*) ###

The Firebase class must be instantiated with an instance name, and optionally an authorization Key, a custom Firebase domain and a debug flag.

#### Parameters ####

| Parameter | Type | Required | Notes |
| --- | --- | --- | --- |
| *instanceName* | String | Yes | The name of your firebase instance |
| *authKey* | String | No | An optional authentication key. Default: `null` (no authorization) |
| *domain* | String | No | A base domain name for the Firebase instance, used to build the base Firebase database URL, eg. `https://username.firebaseio.com`. Default: `"firebaseio.com"` |
| *debug* | Boolean | No | The debug flag. Set to `false` to supress error logging within the Firebase class. Default: `true` |

The domain and instance are used to construct the URL that requests are made against in the following way: `https://{instance}.{domain}`.

The constructor setups the *Legacy tokens* authentication. If you plan to use another type of authentication, pass `null` as the *authKey* parameter and call the *setAuthProvider()* method after the constructor.

#### Example ####

```squirrel
#require "Firebase.agent.lib.nut:3.2.0"

const FIREBASE_NAME = "YOUR_FIREBASE_NAME";
const FIREBASE_AUTH_KEY = "YOUR_FIREBASE_AUTH_KEY";

firebase <- Firebase(FIREBASE_NAME, FIREBASE_AUTH_KEY);
```

## Class Methods ##

### setAuthProvider(*type[, provider]*) ###

This method changes a type of authentication used by the library to work with the Firebase backend. The method has two parameters.

The mandatory *type* parameter &mdash; a type of authentication. It must be one of the following values of the *FIREBASE_AUTH_TYPE* enum:
- *LEGACY_TOKEN* &mdash; [Legacy tokens authentication](https://firebase.google.com/docs/database/rest/auth#legacy_tokens). It is initialized by the *authKey* parameter in the library class's constructor.
- *OAUTH2_TOKEN* &mdash; [Google OAuth2 access tokens authentication](https://firebase.google.com/docs/database/rest/auth#google_oauth2_access_tokens). An external provider of access tokens must be used and passed to the library via the *provider* parameter. Electric Imp’s [OAuth2.JWTProfile.Client library](https://github.com/electricimp/OAuth-2.0) may be used as the provider.
- *FIREBASE_ID_TOKEN* &mdash; [Firebase ID tokens authentication](https://firebase.google.com/docs/database/rest/auth#firebase_id_tokens). An external provider of access tokens must be used and passed to the library via the *provider* parameter.

The optional *provider* parameter &mdash; an external provider of access tokens. The provider must contain an *acquireAccessToken()* method that takes one required parameter: a handler that is called when an access token is acquired or an error occurs. The handler itself has two required parameters: *token* &mdash; a string representation of the access token, and *error* &mdash; a string with error details (or `null` if no error occurred).

If a not supported value is passed to the *type* parameter or the *provider* parameter is `null` (irrespective of the *type* parameter value), the authentication type is changed to the *LEGACY_TOKEN*.

#### Example ####

```squirrel
#require "Firebase.agent.lib.nut:3.2.0"
#require "OAuth2.agent.lib.nut:2.0.1"

const FIREBASE_NAME = "YOUR_FIREBASE_NAME";
const FIREBASE_SERIVCE_ACCOUNT_CLIENT_EMAIL = "YOUR_FIREBASE_SERIVCE_ACCOUNT_CLIENT_EMAIL";
const FIREBASE_SERIVCE_ACCOUNT_PRIVATE_KEY = "YOUR_FIREBASE_SERIVCE_ACCOUNT_PRIVATE_KEY";

firebase <- Firebase(FIREBASE_NAME);
firebase.setAuthProvider(
    FIREBASE_AUTH_TYPE.OAUTH2_TOKEN,
    OAuth2.JWTProfile.Client(
        OAuth2.DeviceFlow.GOOGLE,
        {
            "iss"         : FIREBASE_SERIVCE_ACCOUNT_CLIENT_EMAIL,
            "jwtSignKey"  : FIREBASE_SERIVCE_ACCOUNT_PRIVATE_KEY,
            "scope"       : "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/firebase.database"
        }));
```

### on(*path, callback*) ##

This method listens for changes at a particular location: *path* or a node below *path*. When changes are detected, the callback method will be invoked.

The callback method takes two parameters: *path* and *data*. The *path* parameter returns the full path of the node that was modified (this allows you to determine if the root of the path you’re tracking changed, or if a node below it changed).

The *data* parameter contains the modified data.

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

This method creates a streaming request using the *path* as the base address to track. If no *path* is supplied, the root of the instance (`"/"`) will be used.

An optional table (key-value pairs) can be passed into *uriParams* in order to use Firebase queries.

Optionally, you may pass a function into the *onErrorCallback* parameter. This function will be invoked if errors occur while making streaming requests. The Firebase class will attempt to silently and automatically reconnect when it encounters a 429 or 503 status code error. For all other errors, if an *onErrorCallback* is supplied, it is up to the developer to re-initiate the *stream()* request in the callback.

The *onErrorCallback* takes a single parameter: the [HTTP Response Table](https://developer.electricimp.com/api/httprequest/sendasync) from the request.

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

This method returns `true` if the stream is currently open, and `false` otherwise.

### closeStream() ###

This method closes the current stream if it is open, but takes no action otherwise.

### fromCache(*[path]*) ###

This method reads the local/cached copy of the data at the specified path. This method is ntended for use in a *.on()* handler to prevent unnecessary communication with Firebase through the *read()* method.

#### Example ####

```squirrel
firebase.on("/settings", function(path, data) {
  // Check if the location setting changed
  if ("location" in data) {
    // If it did, grab the location data from Firebase
    // use fromCache instead of read to avoid an unnecessary Web request
    local location = firebase.fromCache("/location");

    // Send the new location information to the device
    device.send("updateLocation", location);
  }
});
```

### read(*path[, uriParams][, callback]*) ###

This method reads data from the specified path (ie. performs a GET request).

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be an object represending the Firebase resosponse. It will be `null` if an error occurred.

This method returns a Promise when the callback is not provided and the Promise library is included in your agent code.

#### Examples ####

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

Query Parameters can also be passed in as a table of arguments to *uriParams*:

```squirrel
fbDino <- Firebase("dinosaur-facts");

// Perform a shallow query to get the list of keys at this location
fbDino.read("/dinosaurs", {"shallow": true}, function(error, data){
  server.log(http.jsonencode(data));
  // Logs: { "lambeosaurus": true, "linhenykus": true, "triceratops": true,
  //       "stegosaurus": true, "bruhathkayosaurus": true, "pterodactyl": true }
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

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be an object represending the Firebase resosponse. It will be `null` if an error occurred.

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

**Note** When you write to a specific path you replace all of the data at that path (and all paths below it).

### update(*path, data[, callback]*) ###

This method updates a subset of data at a particular path (ie. performs a PATCH request).

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be an object represending the Firebase resosponse. It will be `null` if an error occurred.

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

The parameter *priority* is an optional (numeric or alphanumeric) value of each node. It is used to sort the children under a specific parent, or in a query if no other sort condition is specified.

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be an object represending the Firebase resosponse. It will be `null` if an error occurred.

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

Any function passed into *callback* should have two parameters of its own. The first, *error*, receives a string which will describe an error if one occurred. If the call succeeded, *error* is `null`. The second parameter, *data*, will be an object represending the Firebase resosponse. It will be `null` if an error occurred.

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

Full working examples are provided in the [examples](./examples) directory.

## Testing ##

Tests for the library are provided in the [tests](./tests) directory.

## License ##

The Firebase class is licensed under [MIT License](https://github.com/electricimp/Firebase/tree/master/LICENSE).
