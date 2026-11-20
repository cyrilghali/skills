const { fetchScores } = require("./api");
const { rankTeams } = require("./rank");
rankTeams(fetchScores()).forEach((team, i) => console.log(`${i + 1}. ${team}`));
