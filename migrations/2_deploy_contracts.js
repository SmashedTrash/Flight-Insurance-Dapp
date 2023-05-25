const FlightInsuranceApp = artifacts.require("FlightInsuranceApp");
const FlightData = artifacts.require("FlightData");
const fs = require('fs');

module.exports = function (deployer) {

	let firstAirline = '0x49856BBf9bd3864BAC5c99602Cd35DD88dE654eB';
	deployer.deploy(FlightSuretyData)
		.then(() => {
			return deployer.deploy(FlightInsuranceApp, FlightData.address)
					fs.writeFileSync(__dirname + '/../src/server/config.json', JSON.stringify(config, null, '\t'), 'utf-8');
				});
		};
