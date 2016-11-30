const FIREBASE_AUTH_KEY = "#{env:FIREBASE_AUTH_KEY}";
const FIREBASE_INSTANCE_NAME = "#{env:FIREBASE_INSTANCE_NAME}";

class EventParserTestCase extends ImpTestCase {
    _firebase = null;

    function setUp() {
        _firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    function test01_parseEvent() {
        local events = _firebase._parseEventMessage("event: put\ndata: ")
        assertEqual(0, events.len())
        events = _firebase._parseEventMessage("{\"path\":\"/\",\"data\":{\"data\":214}}")
        assertEqual(0, events.len())
        events = _firebase._parseEventMessage("\n\n")
        assertEqual(1, events.len())
        assertEqual(214, events[0].data.data)
    }


    function test02_parseEvent() {
        local events = _firebase._parseEventMessage("event: put")
        assertEqual(0, events.len())
        events = _firebase._parseEventMessage("\ndata: {\"path\":\"/\",\"data\":{\"data\":215}}")
        assertEqual(0, events.len())
        events = _firebase._parseEventMessage("\n\n")
        assertEqual(1, events.len())
        assertEqual(215, events[0].data.data)
    }

    function test03_parseEvent() {
        local events = _firebase._parseEventMessage("event: put")
        assertEqual(0, events.len())
        events = _firebase._parseEventMessage("\ndata: {\"path\":\"/\",")
        assertEqual(0, events.len())
        events = _firebase._parseEventMessage("\"data\":{\"data\":216}}\n\n\n")
        assertEqual(1, events.len())
        assertEqual(216, events[0].data.data)
    }

    function test04_parseEvent() {
        local events = _firebase._parseEventMessage("event: put")
        assertEqual(0, events.len())
        events = _firebase._parseEventMessage("\ndata: {\"path\":\"/\",")
        assertEqual(0, events.len())
        events = _firebase._parseEventMessage("\"data\":{\"data\":217}}\n\n\nevent: put\ndata: {\"path\":\"/\",\"data\":{\"data\":218}}\n\n\n")
        assertEqual(2, events.len())
        assertEqual(217, events[0].data.data)
        assertEqual(218, events[1].data.data)
    }
}