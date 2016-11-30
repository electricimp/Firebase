// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

const FIREBASE_ERROR_TOO_MANY_REQUESTS = "Too many requests";

class Firebase {
    // Library version
    static version = [2,0,1];
    static KEEP_ALIVE = 60;     // Timeout for streaming

    // General
    _db = null;                 // The name of your firebase instance
    _auth = null;               // _auth key (if auth is enabled)
    _baseUrl = null;            // base url (may change with 307 responses)
    _domain = null;

    // Debugging
    _debug = null;              // Debug flag, when true, class will log errors

    // REST
    _defaultHeaders = { "Content-Type": "application/json" };

    // Streaming
    _streamingHeaders = { "accept": "text/event-stream" };
    _streamingRequest = null;   // The request object of the streaming request
    _data = null;               // Current snapshot of what we're streaming
    _callbacks = null;          // List of _callbacks for streaming request
    _keepAliveTimer = null;     // Wakeup timer that watches for a dead Firebase socket
    _promiseIncluded = null ;   // indicate if Promise library is included
    _bufferedInput = null;      // Buffer used for reading streamed data
    /***************************************************************************
     * Constructor
     * Returns: FirebaseStream object
     * Parameters:
     *      _baseUrl - the base URL to your Firebase (https://username.firebaseio.com)
     *      _auth - the _auth token for your Firebase
     **************************************************************************/
    constructor(db, auth = null, domain = "firebaseio.com", debug = true) {
        _debug = debug;

        _db = db;
        _domain = domain;
        _baseUrl = "https://" + _db + "." + domain;
        _auth = auth;

        _data = {};

        _callbacks = {};

        _promiseIncluded = ("Promise" in getroottable());

        _bufferedInput = "";
    }

    /***************************************************************************
     * Attempts to open a stream
     * Returns:
     *      false - if a stream is already open
     *      true -  otherwise
     * Parameters:
     *      path - the path of the node we're listending to (without .json)
     *      uriParams - table of values to attach as URI parameters.  This can be used for queries, etc. - see https://www.firebase.com/docs/rest/guide/retrieving-data.html#section-rest-uri-params
     *      onError - custom error handler for streaming API
     **************************************************************************/
    function stream(path = "", uriParams = null, onError = null) {
        // if we already have a stream open, don't open a new one
        if (isStreaming()) return false;

        if (typeof uriParams == "function") {
            onError = uriParams;
            uriParams = null;
        }
        if (onError == null) onError = _defaultErrorHandler.bindenv(this);
        _streamingRequest = http.get(_buildUrl(path, uriParams), _streamingHeaders);
        _streamingRequest.setvalidation(VALIDATE_USING_SYSTEM_CA_CERTS);

        _streamingRequest.sendasync(
            _onStreamExitFactory(path, onError),
            _onStreamDataFactory(path, onError),
            NO_TIMEOUT
        );

        // Tickle the keepalive timer
        if (_keepAliveTimer) imp.cancelwakeup(_keepAliveTimer);
        _keepAliveTimer = imp.wakeup(KEEP_ALIVE, _onKeepAliveExpiredFactory(path, onError));

        // Return true if we opened the stream
        return true;
    }

    /***************************************************************************
     * Returns whether or not there is currently a stream open
     * Returns:
     *      true - streaming request is currently open
     *      false - otherwise
     **************************************************************************/
    function isStreaming() {
        return (_streamingRequest != null);
    }

    /***************************************************************************
     * Closes the stream (if there is one open)
     **************************************************************************/
    function closeStream() {
        // Close the stream if it's open
        if (_streamingRequest) {
            _streamingRequest.cancel();
            _streamingRequest = null;
        }

        // Kill the keepalive if it exists
        if (_keepAliveTimer) imp.cancelwakeup(_keepAliveTimer);
    }

    /***************************************************************************
     * Registers a callback for when data in a particular path is changed.
     * If a handler for a particular path is not defined, data will change,
     * but no handler will be called
     *
     * Returns:
     *      nothing
     * Parameters:
     *      path     - the path of the node we're listending to (without .json)
     *      callback - a callback function with two parameters (path, change) to be
     *                 executed when the data at path changes
     **************************************************************************/
    function on(path, callback) {
        if (path.len() > 0 && path.slice(0, 1) != "/") path = "/" + path;
        if (path.len() > 1 && path.slice(-1) == "/") path = path.slice(0, -1);
        _callbacks[path] <- callback;
    }

    /***************************************************************************
     * Reads a path from the internal cache. Really handy to use in an .on() handler
     **************************************************************************/
    function fromCache(path = "/") {
        local data = _data;
        foreach (step in split(path, "/")) {
            if (step == "") continue;
            if (step in data) data = data[step];
            else return null;
        }
        return data;
    }

    /***************************************************************************
     * Reads data from the specified path, and executes the callback handler
     * once complete.
     *
     * NOTE: This function does NOT update firebase._data
     *
     * Returns:
     *      nothing
     * Parameters:
     *      path     - the path of the node we're reading
     *      uriParams - table of values to attach as URI parameters.  This can be used for queries, etc. - see https://www.firebase.com/docs/rest/guide/retrieving-data.html#section-rest-uri-params
     *      callback - a callback function with one parameter (data) to be
     *                 executed once the data is read
     **************************************************************************/
     function read(path, uriParams = null, callback = null) {
        if (typeof uriParams == "function") {
            callback = uriParams;
            uriParams = null;
        }
        local request = http.get(_buildUrl(path, uriParams), _defaultHeaders)
        request.setvalidation(VALIDATE_USING_SYSTEM_CA_CERTS);
        if (callback) {
            _processResponse(request,callback);

        } else {
            return  _returnPromise(request);
        }

    }

    /***************************************************************************
     * Pushes data to a path (performs a POST)
     * This method should be used when you're adding an item to a list.
     *
     * NOTE: This function does NOT update firebase._data
     * Returns:
     *      nothing
     * Parameters:
     *      path     - the path of the node we're pushing to
     *      data     - the data we're pushing
     **************************************************************************/
    function push(path, data, priority = null, callback = null) {
        if (priority != null && typeof data == "table") data[".priority"] <- priority;
        local request = http.post(_buildUrl(path), _defaultHeaders, http.jsonencode(data))
        request.setvalidation(VALIDATE_USING_SYSTEM_CA_CERTS);
        if (callback) {
            _processResponse(request,callback);
        } else {
           return _returnPromise(request);
        }

    }

    /***************************************************************************
     * Writes data to a path (performs a PUT)
     * This is generally the function you want to use
     *
     * NOTE: This function does NOT update firebase._data
     *
     * Returns:
     *      nothing
     * Parameters:
     *      path     - the path of the node we're writing to
     *      data     - the data we're writing
     **************************************************************************/
    function write(path, data, callback = null) {
        local request = http.put(_buildUrl(path), _defaultHeaders, http.jsonencode(data))
        request.setvalidation(VALIDATE_USING_SYSTEM_CA_CERTS);
        if (callback) {
            _processResponse(request,callback);
        } else {
            return _returnPromise(request);
        }

    }

    /***************************************************************************
     * Updates a particular path (performs a PATCH)
     * This method should be used when you want to do a non-destructive write
     *
     * NOTE: This function does NOT update firebase._data
     *
     * Returns:
     *      nothing
     * Parameters:
     *      path     - the path of the node we're patching
     *      data     - the data we're patching
     **************************************************************************/
    function update(path, data, callback = null) {
        if (typeof(data) == "table" || typeof(data) == "array") data = http.jsonencode(data);
        local request = http.request("PATCH", _buildUrl(path), _defaultHeaders, data)
        request.setvalidation(VALIDATE_USING_SYSTEM_CA_CERTS);
        if (callback) {
            _processResponse(request,callback);
        } else {
            return _returnPromise(request);
        }

    }

    /***************************************************************************
     * Deletes the data at the specific node (performs a DELETE)
     *
     * NOTE: This function does NOT update firebase._data
     *
     * Returns:
     *      nothing
     * Parameters:
     *      path     - the path of the node we're deleting
     **************************************************************************/
    function remove(path, callback = null) {
        local request = http.httpdelete(_buildUrl(path), _defaultHeaders)
        request.setvalidation(VALIDATE_USING_SYSTEM_CA_CERTS);
        if (callback) {
            _processResponse(request,callback);
        } else {
            return _returnPromise(request);
        }

    }


    /************ Private Functions (DO NOT CALL FUNCTIONS BELOW) ************/
    // Builds a url to send a request to
    function _buildUrl(path, uriParams = null) {
        // Normalise the /'s
        // _baseUrl = <_baseUrl>
        // path = <path>
        if (_baseUrl.len() > 0 && _baseUrl[_baseUrl.len()-1] == '/') _baseUrl = _baseUrl.slice(0, -1);
        if (path.len() > 0 && path[0] == '/') path = path.slice(1);

        local url = _baseUrl + "/" + path + ".json";

        if(typeof(uriParams) != "table") uriParams = {}


        local quoteWrappedKeys = [
            "startAt",
            "endAt" ,
            "equalTo",
            "orderBy"
        ]

        foreach(key, value in uriParams){
            if(quoteWrappedKeys.find(key) != null && typeof(value) == "string") uriParams[key] = "\"" + value + "\""
        }

        //TODO: Right now we aren't doing any kind of checking on the uriParams - we are trusting that Firebase will throw errors as necessary

        // Use instance values if these keys aren't provided
        if(!("ns" in uriParams)) uriParams.ns <- _db;
        if(!("auth" in uriParams) && _auth !=null) uriParams.auth <- _auth ;

        url += "?" + http.urlencode(uriParams);
        return url;
    }

    // Default error handler
    function _defaultErrorHandler(errors) {
        foreach (error in errors) {
            _logError("ERROR " + error.code + ": " + error.message);
        }
    }

    // Stream Callback
    function _onStreamExitFactory(path, onError) {
        return function(resp) {
            _streamingRequest = null;
            if (resp.statuscode == 307 && "location" in resp.headers) {
                // set new location
                local location = resp.headers["location"];
                local p = location.find("." + _domain);
                p = location.find("/", p);
                _baseUrl = location.slice(0, p);
                return imp.wakeup(0, function() { stream(path, onError); }.bindenv(this));
            } else if (resp.statuscode == 28 || resp.statuscode == 429) {
                // if we timed out, just reconnect after a small delay
                imp.wakeup(0, function() { return stream(path, onError); }.bindenv(this));
            } else {
                // Otherwise log an error (if enabled)
                _logError("Stream closed with error " + resp.statuscode);

                // Invoke our error handler
                imp.wakeup(0, function() { onError(resp); });
            }
        }.bindenv(this);
    }

    // Stream Callback
    //TODO: We are not currently explicitly handling https://www.firebase.com/docs/rest/api/#section-streaming-cancel and https://www.firebase.com/docs/rest/api/#section-streaming-auth-revoked
    function _onStreamDataFactory(path, onError) {
        return function(messageString) {
            // Tickle the keep alive timer
            if (_keepAliveTimer) imp.cancelwakeup(_keepAliveTimer);
            _keepAliveTimer = imp.wakeup(KEEP_ALIVE, _onKeepAliveExpiredFactory(path, onError));

            local messages = _parseEventMessage(messageString);
            foreach (message in messages) {
                // Update the internal cache
                _updateCache(message);

                // Check out every callback for matching path
                foreach (path,callback in _callbacks) {

                    if (path == "/" || path == message.path || message.path.find(path + "/") == 0) {
                        // This is an exact match or a subbranch

                        // Create local instance of message for the callback
                        local thisMessage = message;
                        local thisCallback = callback;
                        imp.wakeup(0, function() { thisCallback(thisMessage.path, thisMessage.data); }.bindenv(this));
                    } else if (message.event == "patch") {
                        // This is a patch for a (potentially) parent node
                        foreach (head,body in message.data) {
                            local newmessagepath = ((message.path == "/") ? "" : message.path) + "/" + head;
                            if (newmessagepath == path) {
                                // We have found a superbranch that matches, rewrite this as a PUT
                                local subdata = _getDataFromPath(newmessagepath, message.path, _data);
                                local thisCallback = callback;
                                imp.wakeup(0, function() { thisCallback(newmessagepath, subdata); }.bindenv(this));
                            }
                        }
                    } else if (message.path == "/" || path.find(message.path + "/") == 0) {
                        // This is the root or a superbranch for a put or delete
                        local subdata = _getDataFromPath(path, message.path, _data);

                        // Create local instance of path and callback
                        local thisPath = path;
                        local thisCallback = callback;
                        imp.wakeup(0, function() { thisCallback(thisPath, subdata); }.bindenv(this));
                    }
                }
            }
        }.bindenv(this);
    }

    // No keep alive has been seen for a while, lets reconnect
    function _onKeepAliveExpiredFactory(path, onError) {
        return function() {
            _logError("Keep alive timer expired. Reconnecting stream.")
            closeStream();
            stream(path, onError);
        }.bindenv(this);
    }

    // parses event messages
    function _parseEventMessage(input) {
        // make sure we've read till the end of the "data" line
        local text = _bufferedInput + input;
        if (!text.find("}\n") && !text.find("null\n")) {
            // TODO:
            // Even though that's an indicator of the end of the "data" line, this might
            // not be sufficient in some cases that we haven't got into yet. We'll need
            // to implement a fair parser if we hit this issue again in the future.
            _bufferedInput = text;
            return [];
        }
        _bufferedInput = "";

        // split message into parts
        local alllines = split(text, "\n");
        if (alllines.len() < 2) return [];
        local returns = [];
        for (local i = 0; i < alllines.len(); ) {
            local lines = [];

            lines.push(alllines[i++]);
            lines.push(alllines[i++]);
            if (i < alllines.len() && alllines[i+1] == "}") {
                lines.push(alllines[i++]);
            }

            // Check for error conditions
            if (lines.len() == 3 && lines[0] == "{" && lines[2] == "}") {
                local error = http.jsondecode(text);
                _logError("Firebase error message: " + error.error);
                continue;   //The continue operator jumps to the next iteration of the loop skipping the execution of the following statements.
            }

            // get the event
            local eventLine = lines[0];
            local event = eventLine.slice(7);

            if(event.tolower() == "keep-alive") continue;

            // get the data
            local dataLine = lines[1];
            local dataString = dataLine.slice(6);

            // pull interesting bits out of the data
            local d;
            try {
                d = http.jsondecode(dataString);
            } catch (e) {
                _logError("Exception while decoding (" + dataString.len() + " bytes): " + dataString);
                throw e;
            }

            // return a useful object
            returns.push({ "event": event, "path": d.path, "data": d.data });
        }

        return returns;
    }

    // Updates the local cache
    function _updateCache(message) {

        // base case - refresh everything
        if (message.event == "put" && message.path == "/") {
            _data = (message.data == null) ? {} : message.data;
            return _data
        }

        local pathParts = split(message.path, "/");
        local key = pathParts.len() > 0 ? pathParts[pathParts.len()-1] : null;

        local currentData = _data;
        local parent = _data;
        local lastPart = "";

        // Walk down the tree following the path
        foreach (part in pathParts) {
            if (typeof currentData != "array" && typeof currentData != "table") {
                // We have orphaned a branch of the tree
                if (lastPart == "") {
                    _data = {};
                    parent = _data;
                    currentData = _data;
                } else {
                    parent[lastPart] <- {};
                    currentData = parent[lastPart];
                }
            }

            parent = currentData;

            // NOTE: This is a hack to deal with a quirk of Firebase
            // Firebase sends arrays when the indicies are integers and its more efficient to use an array.
            if (typeof currentData == "array") {
                part = part.tointeger();
            }

            if (!(part in currentData)) {
                // This is a new branch
                currentData[part] <- {};
            }
            currentData = currentData[part];
            lastPart = part;
        }

        // Make the changes to the found branch
        if (message.event == "put") {
            if (message.data == null) {
                // Delete the branch
                if (key == null) {
                    _data = {};
                } else {
                    if (typeof parent == "array") {
                        parent[key.tointeger()] = null;
                    } else {
                        delete parent[key];
                    }
                }
            } else {
                // Replace the branch
                if (key == null) {
                    _data = message.data;
                } else {
                    if (typeof parent == "array") {
                        parent[key.tointeger()] = message.data;
                    } else {
                        parent[key] <- message.data;
                    }
                }
            }
        } else if (message.event == "patch") {
            foreach(k,v in message.data) {
                if (key == null) {
                    // Patch the root branch
                    _data[k] <- v;
                } else {
                    // Patch the current branch
                    parent[key][k] <- v;
                }
            }
        }

        // Now clean up the tree, removing any orphans
        _cleanTree(_data);
    }

    // Cleans the tree by deleting any empty nodes
    function _cleanTree(branch) {
        foreach (k,subbranch in branch) {
            if (typeof subbranch == "array" || typeof subbranch == "table") {
                _cleanTree(subbranch)
                if (subbranch.len() == 0) delete branch[k];
            }
        }
    }

    // Steps through a path to get the contents of the table at that point
    function _getDataFromPath(c_path, m_path, m_data) {

        // Make sure we are on the right branch
        if (m_path.len() > c_path.len() && m_path.find(c_path) != 0) return null;

        // Walk to the base of the callback path
        local new_data = m_data;
        foreach (step in split(c_path, "/")) {
            if (step == "") continue;
            if (step in new_data) {
                new_data = new_data[step];
            } else {
                new_data = null;
                break;
            }
        }

        // Find the data at the modified branch but only one step deep at max
        local changed_data = new_data;
        if (m_path.len() > c_path.len()) {
            // Only a subbranch has changed, pick the subbranch that has changed
            local new_m_path = m_path.slice(c_path.len())
            foreach (step in split(new_m_path, "/")) {
                if (step == "") continue;
                if (step in changed_data) {
                    changed_data = changed_data[step];
                } else {
                    changed_data = null;
                }
                break;
            }
        }

        return changed_data;
    }

    function _logError(message) {
        if (_debug) server.error(message);
    }

    // return a Promise if the Promise library is included
    function _returnPromise (request){
        if (_promiseIncluded) {
            return Promise(function (resolve,reject){
                    request.sendasync(function(res){
                        local data = null ;
                        try {
                            data = http.jsondecode(res.body);
                            if ( 200 <= res.statuscode && res.statuscode < 300) {
                                resolve(data);
                            } else {
                                reject(data.error);
                            }
                        } catch (err){
                            reject (err);
                        }
                    }.bindenv(this));
            });
        }
        return;
    }

    // process the http response accordingly
    function _processResponse (request,callback) {
        request.sendasync(function(res) {
            local data = res.body;
            try {
                if (200 <= res.statuscode && res.statuscode < 300) {
                    data = http.jsondecode(data);
                    callback(null, data);
                } else if (res.statuscode == 429) {
                    callback(FIREBASE_ERROR_TOO_MANY_REQUESTS, res);
                } else {
                    data = http.jsondecode(data);
                    callback(data.error, res);
                }
            } catch (err) {
                callback(err, null);
            }
        }.bindenv(this))
    }

}
