
const FIREBASE_AUTH_KEY = "#{env:FIREBASE_AUTH_KEY}";
const FIREBASE_INSTANCE_NAME = "#{env:FIREBASE_INSTANCE_NAME}";

class BasicTestCase extends ImpTestCase {
    _path = null;
    _firebase = null;
    _luckyNum = null;

    function setUp() {
        this._firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        this._path = this.session + "-basic";
        this._luckyNum = math.rand() + "" + math.rand();
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    /**
     * Write test data
     */
    function test01_write() {
        return Promise(function (ok, err) {
            this._firebase.write(this._path, this._luckyNum, function (error, response) {
                if (error) {
                    err(error);
                } else {
                    try {
                        this.assertEqual(this._luckyNum, response);
                        ok("Written test data at \""+ this._path + "\"");
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
            this._firebase.read(this._path, function (error, data) {
                if (error) {
                    err(error);
                } else {
                    try {
                        this.assertEqual(this._luckyNum, data);
                        ok("Read test data at \""+ this._path + "\"");
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
            this._firebase.remove(this._path, function (error, response) {
                if (error) {
                    err(error);
                } else {
                    ok("Removed test data at \""+ this._path + "\"");
                }
            }.bindenv(this));
        }.bindenv(this))
    }
}
