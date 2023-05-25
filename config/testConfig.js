
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function (accounts) {

	// These test addresses are useful when you need to add
	// multiple users in test scripts
	let testAddresses = [
		"0x765cF904f6EA818e67bCC9Fa3F4A56D3E7Cc969F",
		"0x3e1d69dCa52CC7EEb2dbbE05F7DE61FD7f2D9527",
		"0xd5926E75aA89BE7745F3d7816DBBF13F7A44E5A8",
		"0xD183582984C363Cc7545E9619a8987275D9acdb8",
		"0xe24776dAb2967f26f4F9707B668684b8dd48AA17",
		"0x157B023C89bfb7Ae1E2A8a92F6356329Bf0D0342",
		"0x39440B824AF4a9EA2Ca1625d062C35d5a3f8A14f",
		"0x3F29538Df9083ba4244C3e4720729B3476cB1D9b",
		"0x36F43926C878c7C370568389981743C1066f28Ae"
	];


	let owner = accounts[0];
	let firstAirline = accounts[1];

	let flightSuretyData = await FlightSuretyData.new();
	let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);


	return {
		owner: owner,
		firstAirline: firstAirline,
		weiMultiple: (new BigNumber(10)).pow(18),
		testAddresses: testAddresses,
		flightSuretyData: flightSuretyData,
		flightSuretyApp: flightSuretyApp
	}
}

module.exports = {
	Config: Config
};