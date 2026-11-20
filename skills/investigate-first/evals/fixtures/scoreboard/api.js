// Pretend API client: returns raw scores as the backend sends them.
function fetchScores() {
  return [
    { team: "Owls", points: 9 },
    { team: "Foxes", points: 12 },
    { team: "Bears", points: 100 },
    { team: "Hares", points: 7 },
  ];
}
module.exports = { fetchScores };
