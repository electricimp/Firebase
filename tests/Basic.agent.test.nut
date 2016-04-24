
const FIREBASE_AUTH_KEY = "#{env:FIREBASE_AUTH_KEY}";
const FIREBASE_INSTANCE_NAME = "#{env:FIREBASE_INSTANCE_NAME}";

class BasicTestCase extends ImpTestCase {
    _firebase = null;
    _luckyNum = null;

    function setUp() {
        this._firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        this._luckyNum = math.rand() + "" + math.rand();
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    /**
     * Write test data
     */
    function test01_write() {
        return Promise(function (ok, err) {
            this._firebase.write(this.session, this._luckyNum, function (response) {
                response.body = http.jsondecode(response.body);
                if (response.statuscode >= 400) {
                    err(response.body.error);
                } else {
                    try {
                        this.assertEqual(this._luckyNum, response.body);
                        ok("Written test data at \"/"+ this.session + "\"");
                    } catch (e) {
                        err(e);
                    }
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    /**
     * Test *basic* reads
     */
    function test02_read() {
        return Promise(function (ok, err) {
            this._firebase.read(this.session, function (data) {
                try {
                    this.assertEqual(this._luckyNum, data);
                    ok("Read test data at \"/"+ this.session + "\"");
                } catch (e) {
                    err(e);
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    /**
     * Deletes test data
     */
    function tearDown() {
        return Promise(function (ok, err) {
            this._firebase.remove(this.session, function (response) {
                response.body = http.jsondecode(response.body);
                if (response.statuscode >= 400) {
                    err(response.body.error);
                } else {
                    ok("Removed test data at \"/"+ this.session + "\"");
                }
            }.bindenv(this));
        }.bindenv(this))
    }
}
