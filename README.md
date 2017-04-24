# Firebase v3.0.0

The Firebase library allows you to easily integrate your agent code with Firebase’s realtime backend, which includes data storage, user authentication, static hosting and more.

**To add this library to your project, add** `#require "Firebase.agent.lib.nut:3.0.0"` **to the top of your agent code.**

[![Build Status](https://travis-ci.org/electricimp/Firebase.svg?branch=master)](https://travis-ci.org/electricimp/JSONParser)

## Class Usage

### Optional Callbacks/Promises

The methods *read()*, *write()*, *remove()*, *update()* and *push()* contain an optional *callback* parameter. If a callback function is provided, it will be called when the response from Firebase is received. The callback takes two required parameters: *error* and *response*. If no error is encountered, the error parameter will be `null`.

As an alternative to passing in a callback, you can include the Electric Imp Promise library [GitHub](https://github.com/electricimp/Promise/). If the promise library is included, the methods *read()*, *write()*, *remove()*, *update()* and *push()* will return a promise if no callback is provided.

**To add Promise library to your project, add** `#require "promise.class.nut:3.0.0"` **to the top of your agent code.**

### Constructor: Firebase(*instance[, authKey][, domain][, debug]*)

The Firebase class must be instantiated with an instance name, and optionally an authorization Key, a custom Firebase domain and a debug flag.

| Parameter | Type   | Default            | Notes    |
| --------- | ------ | ------------------ | -------- |
| *instance*  | String | n/a                |          |
| *auth*      | String | `null` (no authorization) | Optional |
| *domain*    | String | `"firebaseio.com"`  | Optional |
| *debug*    | Boolean   | `true`             | Optional. Set to `false` to supress error logging within<br>the Firebase class |

The domain and instance are used to construct the url requests are made against in the following was: `https://{instance}.{domain}`.

```squirrel
const FIREBASE_NAME = "<YOUR_FIREBASE_NAME>";
const FIREBASE_AUTH_KEY = "<YOUR_FIREBASE_AUTH_KEY>";

firebase <- Firebase(FIREBASE_NAME, FIREBASE_AUTH_KEY);
```

## Class Methods

### on(*path, callback*)

Listens for changes at a particular location (*path*) or a node below *path*. When changes are detected, the callback method will be invoked.

The callback method takes two parameters: *path* and *data*. The *path* parameter returns the full path of the node that was modified (this allows you to determine if the root of the path you’re tracking changed, or if a node below it changed).

The *data* parameter contains the modified data.

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

### stream(*[path][, uriParams][, onErrorCallback]*)

Creates a streaming request using the *path* as the base address to track. If no *path* is supplied, the root of the instance (`"/"`) will be used.

An optional table of *uriParams* can be supplied in order to use Firebase queries.

An optional *onErrorCallback* parameter can be supplied that will be invoked if errors occur while making streaming requests. If no *onErrorCallback* is supplied, the Firebase class will attempt to silently and automatically reconnect when it encounters an error. If an *onErrorCallback* is supplied, it is up to the developer to re-initiate the *stream()* request in the callback.

The *onErrorCallback* takes a single parameter: the [HTTP Response Table](https://electricimp.com/docs/api/httprequest/sendasync/) from the request.

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

### isStreaming()

Returns `true` if the stream is currently open, and `false` otherwise.

### closeStream()

Closes the current stream if it is open, but takes no action otherwise.

### fromCache(*[path]*)

Reads the local/cached copy of the data at the specified path. This method is ntended for use in a *.on()* handler to prevent unnecessary communication with Firebase through the *read()* method.

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

### read(*path[, uriParams][, callback]*)

Reads data from the specified path (ie. performs a GET request). Returns a Promise when the callback is not provided and the Promise library is included in your agent code.

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
        //Logs { "bruhathkayosaurus": { "appeared": -70000000, "vanished": -70000000,
        //     "order": "saurischia", "length": 44, "weight": 135000, "height": 25 } }
});
```

### write(*path, data[, callback]*)

Updates data at the specified path (ie. performs a PUT request). Returns a Promise when the callback is not provided and the Promise library is included in your agent code.

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

### update(*path, data[, callback]*)

Updates a subset of data at a particular path (ie. performs a PATCH request). Returns a Promise when the callback is not provided and the Promise library is included in your agent code.

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

### push(*path, data[, priority][, callback]*)

Pushes data to the specified path (ie. performs a POST request). This function should be used when you’re adding an item to a list. Returns a Promise when the callback is not provided and the Promise library is included in your agent code.

```squirrel
// Example using a promise instead of callback function
local results = [];
local fbKeys = [];

device.on("temps", function(data) {
    foreach(reading in data) {
        local pushData = {
            "deviceId": reading.deviceId,
            "timestamp": reading.ts,
            "temp": reading.temp
        };

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

### remove(*path[, callback]*)

Deletes data at the specified path (ie. performs a DELETE request). Returns a Promise when the callback is not provided and the Promise library is included in your agent code.

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

## License
The Firebase class is licensed under [MIT License](https://github.com/electricimp/Firebase/tree/master/LICENSE).
