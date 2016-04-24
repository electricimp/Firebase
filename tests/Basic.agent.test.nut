
const FIREBASE_AUTH_KEY = "#{env:FIREBASE_AUTH_KEY}";
const FIREBASE_INSTANCE_NAME = "#{env:FIREBASE_INSTANCE_NAME}";

class BasicTestCase extends ImpTestCase {
    _firebase = null;

    function setUp() {
        this._firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    function test01_write() {
        return Promise(function (ok, err) {
            local data = math.rand() + "" + math.rand();

            this._firebase.write(this.session, data, function (response) {
                response.body = http.jsondecode(response.body);
                if (response.statuscode >= 400) {
                    err(response.body.error);
                } else {
                    try {
                        this.assertEqual(data, response.body);
                        ok("Written test data at \"/"+ this.session + "\"");
                    } catch (e) {
                        err(e);
                    }
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
