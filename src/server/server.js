import express from 'express';


const app = express();

function initREST() {
	app.get('/api', (req, res) => {
		res.send({
			message: 'An API for use with your Dapp!'
		})
	})

	app.get('/flights', (req, res) => {
		res.json({
			result: flights
		})
	})

	app.get('/eventIndex', (req, res) => {
		res.json({
			result: eventIndex
		})
	})
	console.log("App.get defined");

}

export default app;


