
const FIREBASE_AUTH_KEY = "#{env:FIREBASE_AUTH_KEY}";
const FIREBASE_INSTANCE_NAME = "#{env:FIREBASE_INSTANCE_NAME}";

class BasicTestCase extends ImpTestCase {
    _path = null;
    _firebase = null;

    // @see http://dinosaurs.findthedata.com/
    _dinos = {

        "Acrocanthosaurus": {
            "height": 18,
            "length": 38,
            "weight": 13600,
            "predation": "Carnivorous",
            "region": "North America"
        },

        "Euoplocephalus": {
            "height": 10,
            "length": 32,
            "weight": 4000,
            "predation": "Omnivorous",
            "region": "Africa"
        },

        "Herrerasaurus": {
            "height": 7,
            "length": 10,
            "weight": 772,
            "predation": "Carnivorous",
            "region": "South America"
        },

        "Homalocephale": {
            "height": 2,
            "length": 5,
            "weight": 100,
            "predation": "Omnivorous",
            "region": "Asia"
        },

        "Velociraptor": {
            "height": 2,
            "length": 6,
            "weight": 33,
            "predation": "Carnivorous",
            "region": "Asia"
        }
    };

    function setUp() {
        this._firebase = Firebase(FIREBASE_INSTANCE_NAME, FIREBASE_AUTH_KEY);
        this._path = this.session + "-queries";
        return "Firebase instance \"" + FIREBASE_INSTANCE_NAME + "\" created";
    }

    /**
     * Add indexes
     */
    function test01_addIndex() {
        local rules = {"rules": {}};
        rules.rules[this._path] <- {".write": true, ".read": true, ".indexOn": ["height", "weight", "length"]};

        return Promise(function (ok, err) {
            this._firebase.write(".settings/rules",
                rules,
                function (res) {
                    ok();
                }.bindenv(this));
        }.bindenv(this))
    }

    /**
     * Write test data
     */
    function test02_write() {
        return Promise(function (ok, err) {
            this._firebase.write(this._path, this._dinos, function (response) {
                response.body = http.jsondecode(response.body);
                if (response.statuscode >= 400) {
                    err(response.body.error);
                } else {
                    try {
                        this.assertDeepEqual(this._dinos, response.body);
                        ok("Written test data at \""+ this._path + "\"");
                    } catch (e) {
                        err(e);
                    }
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    /**
     * Read keys only
     */
    function test03_readKeys() {
        return Promise(function (ok, err) {
            this._firebase.read(this._path, {"shallow": true}, function (data) {
                try {
                    this.assertDeepEqual({"Velociraptor":true,"Homalocephale":true,"Herrerasaurus":true,"Acrocanthosaurus":true,"Euoplocephalus":true}, data);
                    ok();
                } catch (e) {
                    err(e);
                }
            }.bindenv(this));
        }.bindenv(this))
    }

    // todo: more test on queries

    /**
     * Deletes test data
     */
    function tearDown() {
        return;
        return Promise(function (ok, err) {
            this._firebase.remove(this._path, function (response) {
                response.body = http.jsondecode(response.body);
                if (response.statuscode >= 400) {
                    err(response.body.error);
                } else {
                    ok("Removed test data at \""+ this._path + "\"");
                }
            }.bindenv(this));
        }.bindenv(this))
    }
}
