function rankTeams(rows) {
  const points = rows.map((r) => r.points).sort().reverse();
  return points.map((p) => rows.find((r) => r.points === p).team);
}
module.exports = { rankTeams };
