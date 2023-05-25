var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "depart quit survey faint message service talk spider urge dynamic jewel fancy";

module.exports = {
	networks: {
		development: {
			provider: function () {
				return new HDWalletProvider(mnemonic, "http://127.0.0.1:9545/", 0, 50);
			},
			network_id: '*',
			gas: 9999999
		}
	},
	compilers: {
		solc: {
			version: "^0.4.24"
		}
	}
};