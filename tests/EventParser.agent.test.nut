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

class EventParserTestCase extends ImpTestCase {
    _firebase = null;

    function setUp() {
        _firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    function test01_parseEvent() {
        local events = _firebase._parseEventMessage("event: put\ndata: ");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("{\"path\":\"/\",\"data\":{\"data\":214}}\n");
        assertEqual(1, events.len());
        assertEqual(214, events[0].data.data);
        assertEqual("", _firebase._bufferedInput);
    }


    function test02_parseEvent() {
        local events = _firebase._parseEventMessage("event: put");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("\ndata: {\"path\":\"/\",\"data\":{\"data\":215}}\n");
        assertEqual(1, events.len());
        assertEqual(215, events[0].data.data);
        assertEqual("", _firebase._bufferedInput);
    }

    function test03_parseEvent() {
        local events = _firebase._parseEventMessage("event: put");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("\ndata: {\"path\":\"/\",");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("\"data\":{\"data\":216}}\n\n\n");
        assertEqual(1, events.len());
        assertEqual(216, events[0].data.data);
        assertEqual("", _firebase._bufferedInput);
    }

    function test04_parseEvent() {
        local events = _firebase._parseEventMessage("event: put");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("\ndata: {\"path\":\"/\",");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("\"data\":{\"data\":216}}");
        assertEqual(1, events.len());
        assertEqual("", _firebase._bufferedInput);
    }

    function test05_parseEvent() {
        local events = _firebase._parseEventMessage("event: put");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("\ndata: null \n");
        assertEqual(1, events.len());
        assertEqual("", _firebase._bufferedInput);
    }

     function test06_parseEvent() {
        local events = _firebase._parseEventMessage("event: put \ndata: {\"path\":\"/\",\"data\":{\"data\":217}}\n");
        assertEqual(1, events.len());
        assertEqual(217, events[0].data.data);
        assertEqual("", _firebase._bufferedInput);
    }

    function test07_parseEvent() {
         local events = _firebase._parseEventMessage("ev");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("ent: put\ndata: null \n");
        assertEqual(1, events.len())
        assertEqual("", _firebase._bufferedInput);
    }

    function test08_parseEvent() {
        local events = _firebase._parseEventMessage("event: put \ndata: {\"path\":\"/\",\"data\":{\"data\":219}}\nevent: put \ndata: {\"path\":\"/\",\"data\":{\"data\":220}}\n");
        assertEqual(2, events.len());
        assertEqual(219, events[0].data.data);
        assertEqual(220, events[1].data.data);
        assertEqual("", _firebase._bufferedInput);
    }

     function test09_parseEvent() {
        local events = _firebase._parseEventMessage("event: put \ndata: {\"path\":\"/\",\"data\":{\"data\":217}");
        assertEqual(0, events.len());
        events = _firebase._parseEventMessage("}");
        assertEqual(1, events.len());
        assertEqual(217, events[0].data.data);
        assertEqual("", _firebase._bufferedInput);
    }
}