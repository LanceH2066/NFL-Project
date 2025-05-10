-- NFL Player and Team Performance Queries
-- Focus: Which positional stats are most important for team wins

-- Summary of Findings:
-- After analyzing various statistical categories, quarterback (QB) performance and defensive strength
-- (particularly turnovers and points allowed) emerge as the most critical factors for team success.
-- Star receivers and strong rushing also show impact but are secondary to QB performance and defense.
-- Each query below includes a description of what it reveals and why it matters.

-- View Definition: LeadingReceivers
-- This view identifies the top receiver (by receiving yards at any position) for each team and season.
-- It simplifies queries where we need to focus on star receivers and their contribution to team success.
CREATE VIEW LeadingReceivers AS
SELECT
    ranked.team_id,
    ranked.season_year,
    ranked.player_id,
    p.name AS player_name,
    p.position,
    ranked.receiving_yards
FROM (
    SELECT
        pts.team_id,
        ps.season_year,
        ps.player_id,
        ps.receiving_yards,
        ROW_NUMBER() OVER (PARTITION BY pts.team_id, ps.season_year ORDER BY ps.receiving_yards DESC) AS rn
    FROM PlayerStats ps
    JOIN PlayerTeamSeason pts ON ps.player_id = pts.player_id AND ps.season_year = pts.season_year
) AS ranked
JOIN Player p ON ranked.player_id = p.player_id
WHERE ranked.rn = 1;

-- 1. Top 10 Highest Passing Yard QBs All Time with Team Wins (how impactful were these record seasons for their team wins)
SELECT 
    p.name AS player_name,
    ps.passing_yards,
    s.season_year,
    t.name AS team_name,
    ts.wins
FROM PlayerStats ps
JOIN Player p ON ps.player_id = p.player_id
JOIN PlayerTeamSeason pts ON ps.player_id = pts.player_id AND ps.season_year = pts.season_year
JOIN Team t ON pts.team_id = t.team_id
JOIN Season s ON ps.season_year = s.season_year
JOIN TeamStats ts ON ts.team_id = t.team_id AND ts.season_year = s.season_year
WHERE p.position = 'QB'
ORDER BY ps.passing_yards DESC
LIMIT 10;

/* 1. RESULTS
# player_name, passing_yards, season_year, team_name, wins
'Drew Brees', '6404', '2011', 'New Orleans Saints', '13'
'Peyton Manning', '6387', '2013', 'Denver Broncos', '13'
'Eli Manning', '6152', '2011', 'New York Giants', '9'
'Tom Brady ', '6113', '2011', 'New England Patriots', '13'
'Matt Ryan', '5958', '2016', 'Atlanta Falcons', '11'
'Kurt Warner', '5730', '2008', 'Arizona Cardinals', '9'
'Drew Brees', '5721', '2013', 'New Orleans Saints', '11'
'Tom Brady ', '5543', '2007', 'New England Patriots', '16'
'Andrew Luck ', '5528', '2014', 'Indianapolis Colts', '11'
'Tom Brady ', '5491', '2012', 'New England Patriots', '12'

What the Results Show:
The results list record-breaking QB seasons and the corresponding team win totals. 
While some of the top QB performances resulted in high win totals, a few did not lead to playoff-level success (e.g., Eli Manning's 6152 yards but only 9 wins).
Why It Matters:
This highlights that even elite QB yardage alone doesn’t always guarantee wins, suggesting that other factors like defense or turnovers also play a key role.
*/

-- 2. Average Wins for Teams With vs. Without a 3000-Yard Quarterback (how important is a star Quarterback)
SELECT
    CASE
        WHEN ps_max.max_passing_yards >= 3000 THEN '3000+ Yard QB'
        ELSE 'Under 3000 Yard QB'
    END AS qb_category,
    AVG(ts.wins) AS avg_wins
FROM TeamStats ts
JOIN Season s ON ts.season_year = s.season_year
JOIN Team t ON ts.team_id = t.team_id
JOIN (
    -- Subquery to find the leading QB for each team-season
    SELECT pts.team_id, ps.season_year, MAX(ps.passing_yards) AS max_passing_yards
    FROM PlayerStats ps
    JOIN PlayerTeamSeason pts ON ps.player_id = pts.player_id AND ps.season_year = pts.season_year
    JOIN Player p ON ps.player_id = p.player_id
    WHERE p.position = 'QB'
    GROUP BY pts.team_id, ps.season_year
) AS ps_max ON ps_max.team_id = ts.team_id AND ps_max.season_year = ts.season_year
GROUP BY qb_category;

/* 2. RESULTS
# qb_category, avg_wins
'Under 3000 Yard QB', '6.2563'
'3000+ Yard QB', '9.2135'

What the Results Show:
Teams with a QB throwing for over 3000 yards averaged about 9.2 wins, while those under 3000 averaged only about 6.3 wins.
Why It Matters:
This shows that having a productive quarterback is a strong predictor of team success.
*/


-- 3. Avg Passing TDs of QBs on Playoff vs. Non-Playoff Teams (how important is a qb's ability to throw touchdowns)
SELECT CASE WHEN ts.wins >= 10 THEN 'Playoff Team' ELSE 'Non-Playoff Team' END AS team_type,
       AVG(ps.touchdowns) AS avg_passing_tds
FROM TeamStats ts
JOIN PlayerTeamSeason pts ON ts.team_id = pts.team_id AND ts.season_year = pts.season_year
JOIN PlayerStats ps ON pts.player_id = ps.player_id AND pts.season_year = ps.season_year
JOIN Player p ON ps.player_id = p.player_id
WHERE p.position = 'QB'
GROUP BY team_type;

/* 3. RESULTS
# team_type, avg_passing_tds
'Non-Playoff Team', '8.7869'
'Playoff Team', '13.7466'

What the Results Show:
Playoff teams' QBs averaged nearly 14 passing touchdowns, compared to about 8.8 for non-playoff teams.
Why It Matters:
QB scoring ability (touchdowns) is a key driver of team victories and playoff appearances.
*/

-- 4. Average Wins of Teams Whose Leading Rusher Had Over 1000 Rushing Yards (how important is a star running back)
SELECT AVG(ts.wins) AS avg_wins_for_1000yd_rusher_teams
FROM TeamStats ts
JOIN Team t ON ts.team_id = t.team_id
JOIN Season s ON ts.season_year = s.season_year
WHERE EXISTS (
    SELECT 1
    FROM PlayerStats ps
    JOIN PlayerTeamSeason pts ON ps.player_id = pts.player_id AND ps.season_year = pts.season_year
    JOIN Player p ON ps.player_id = p.player_id
    WHERE p.position = 'RB'
      AND pts.team_id = ts.team_id
      AND ps.season_year = ts.season_year
      AND ps.rushing_yards > 1000
      AND ps.rushing_yards = (
          SELECT MAX(ps2.rushing_yards)
          FROM PlayerStats ps2
          JOIN PlayerTeamSeason pts2 ON ps2.player_id = pts2.player_id AND ps2.season_year = pts2.season_year
          JOIN Player p2 ON ps2.player_id = p2.player_id
          WHERE pts2.team_id = ts.team_id AND ps2.season_year = ts.season_year AND p2.position = 'RB'
      )
);

/* 4. RESULTS
# rusher_category, avg_wins
'Under 1000 Yard Rusher', '7.2205'
'1000+ Yard Rusher', '8.8496'

What the Results Show:
Teams with a 1000+ yard rusher averaged 8.85 wins, while those without averaged only 7.22 wins.
Why It Matters:
This suggests that while rushing success does correlate with wins, it may be slightly less impactful than QB performance.
*/

-- 5. Avg Rushing Yards of RBs on Playoff vs. Non-Playoff Teams (how important is a strong running game)
SELECT CASE WHEN ts.wins >= 10 THEN 'Playoff Team' ELSE 'Non-Playoff Team' END AS team_type,
       AVG(ps.rushing_yards) AS avg_rushing_yards
FROM TeamStats ts
JOIN PlayerTeamSeason pts ON ts.team_id = pts.team_id AND ts.season_year = pts.season_year
JOIN PlayerStats ps ON pts.player_id = ps.player_id AND pts.season_year = ps.season_year
JOIN Player p ON ps.player_id = p.player_id
WHERE p.position = 'RB'
GROUP BY team_type;
 
/* 5. RESULTS
# team_type, avg_rushing_yards
'Non-Playoff Team', '312.3435'
'Playoff Team', '405.0596'

What the Results Show:
Playoff teams' RBs averaged about 405 rushing yards, versus 312 for non-playoff teams.
Why It Matters:
A stronger running game can contribute to team success, though the effect size here appears moderate.
*/

-- 6. Average Wins for Teams With vs. Without a 1200+ Yard Wide Receiver (how important is a star wide receiver)
SELECT
    CASE
        WHEN lr.receiving_yards >= 1200 THEN '1200+ Yard WR'
        ELSE 'Under 1200 Yard WR'
    END AS receiver_category,
    AVG(ts.wins) AS avg_wins
FROM TeamStats ts
JOIN Season s ON ts.season_year = s.season_year
JOIN Team t ON ts.team_id = t.team_id
JOIN LeadingReceivers lr ON lr.team_id = ts.team_id AND lr.season_year = ts.season_year
WHERE lr.position = 'WR'
GROUP BY receiver_category;

/* 6. RESULTS
# receiver_category, avg_wins
'1200+ Yard WR', '9.3586'
'Under 1200 Yard WR', '7.3274'

What the Results Show:
Teams with a star wide receiver (1200+ yards) averaged 9.36 wins, while others averaged 7.33 wins.
Why It Matters:
Elite receiving performance positively impacts team success.
*/

-- 7. Average Wins for Teams With vs. Without 3000+ Total WR Receiving Yards (how important is a strong receiving corps)
SELECT
    CASE
        WHEN wr_yds.total_receiving_yards >= 3000 THEN '3000+ WR Receiving Yards'
        ELSE 'Under 3000 WR Receiving Yards'
    END AS receiving_category,
    AVG(ts.wins) AS avg_wins
FROM TeamStats ts
JOIN Season s ON ts.season_year = s.season_year
JOIN Team t ON ts.team_id = t.team_id
JOIN (
    -- Subquery to sum total WR receiving yards per team-season
    SELECT pts.team_id, ps.season_year, SUM(ps.receiving_yards) AS total_receiving_yards
    FROM PlayerStats ps
    JOIN PlayerTeamSeason pts ON ps.player_id = pts.player_id AND ps.season_year = pts.season_year
    JOIN Player p ON ps.player_id = p.player_id
    WHERE p.position = 'WR'
    GROUP BY pts.team_id, ps.season_year
) AS wr_yds ON wr_yds.team_id = ts.team_id AND wr_yds.season_year = ts.season_year
GROUP BY receiving_category;

/* 7. RESULTS
# receiving_category, avg_wins
'Under 3000 WR Receiving Yards', '7.4500'
'3000+ WR Receiving Yards', '10.0300'

What the Results Show:
Teams with a strong receiving corps (3000+ yards from all WRs) averaged 10 wins, while others averaged 7.45.
Why It Matters:
Depth at the WR position may be even more important than having just one star receiver.
*/

-- 8. Average Wins for Teams With vs. Without a 1000+ Recieving Yard Tight End (how important is a star TE)
SELECT
    CASE
        WHEN lr.receiving_yards >= 1000 THEN '1000+ Yard TE'
        ELSE 'Under 1000 Yard TE'
    END AS te_category,
    AVG(ts.wins) AS avg_wins
FROM TeamStats ts
JOIN Season s ON ts.season_year = s.season_year
JOIN Team t ON ts.team_id = t.team_id
JOIN LeadingReceivers lr ON lr.team_id = ts.team_id AND lr.season_year = ts.season_year
WHERE lr.position = 'TE'
GROUP BY te_category;

/* 8. RESULTS
# te_category, avg_wins
'Under 1000 Yard TE', '7.5938'
'1000+ Yard TE', '9.0588'

What the Results Show:
Teams with a 1000+ yard TE averaged about 9 wins, compared to 7.6 for those without.
Why It Matters:
While TE performance does show some correlation with success, it may be a secondary factor.
*/

-- 9. Average TE Receiving Yards for Teams With 10+ Wins vs. 10 or Fewer Wins (how important are recieving tight ends)
SELECT
    CASE WHEN ts.wins >= 10 THEN '10+ Wins' ELSE 'Under 10 Wins' END AS team_category,
    AVG(ps.receiving_yards) AS avg_te_receiving_yards
FROM TeamStats ts
JOIN PlayerTeamSeason pts ON ts.team_id = pts.team_id AND ts.season_year = pts.season_year
JOIN PlayerStats ps ON pts.player_id = ps.player_id AND pts.season_year = ps.season_year
JOIN Player p ON ps.player_id = p.player_id
WHERE p.position = 'TE'
GROUP BY team_category;

/* 9. RESULTS
# team_category, avg_te_receiving_yards
'10+ Wins', '241.7504'
'Under 10 Wins', '189.2723'

What the Results Show:
Winning teams averaged about 241 receiving yards from their TEs, versus 189 for others.
Why It Matters:
Contributions from the TE position can support a strong offense but are not typically the primary driver.
*/

-- 10. Average Wins for Teams Allowing Fewer Than 300 Points vs. 300+ Points Allowed (how important is a strong defense)
SELECT
    CASE
        WHEN ts.points_opp < 300 THEN 'Allowed Under 300 Points'
        ELSE 'Allowed 300+ Points'
    END AS defense_category,
    AVG(ts.wins) AS avg_wins
FROM TeamStats ts
GROUP BY defense_category;

/* 10. RESULTS
# defense_category, avg_wins
'Allowed Under 300 Points', '10.9706'
'Allowed 300+ Points', '7.5281'

What the Results Show:
Teams allowing fewer than 300 points averaged nearly 11 wins, while those allowing more averaged only 7.5.
Why It Matters:
This confirms that defense, especially limiting points allowed, is one of the strongest predictors of success.
*/

-- 11. Average Turnovers by Teams With 10+ Wins vs. Under 10 Wins (Do winning teams turn the ball over less?)
SELECT
    CASE WHEN ts.wins >= 10 THEN '10+ Wins' ELSE 'Under 10 Wins' END AS team_category,
    AVG(ts.turnovers) AS avg_turnovers_committed
FROM TeamStats ts
GROUP BY team_category;

/* 11. RESULTS
# team_category, avg_turnovers_committed
'10+ Wins', '21.0652'
'Under 10 Wins', '26.6041'

What the Results Show:
Winning teams averaged about 21 turnovers, compared to nearly 27 for losing teams.
Why It Matters:
Avoiding turnovers is strongly correlated with winning, reinforcing the importance of disciplined offense and defense.
*/

-- 12. Average Wins for Teams With a Player Recording 100+ Tackles (Does having a high-tackle defender correlate with more wins?)
SELECT
    CASE
        WHEN def_tackles.max_tackles >= 100 THEN '100+ Tackle Defender'
        ELSE 'Under 100 Tackle Defender'
    END AS defender_category,
    AVG(ts.wins) AS avg_wins
FROM TeamStats ts
JOIN Season s ON ts.season_year = s.season_year
JOIN Team t ON ts.team_id = t.team_id
JOIN (
    -- Leading tackler per team-season
    SELECT pts.team_id, ps.season_year, MAX(ps.tackles) AS max_tackles
    FROM PlayerStats ps
    JOIN PlayerTeamSeason pts ON ps.player_id = pts.player_id AND ps.season_year = pts.season_year
    GROUP BY pts.team_id, ps.season_year
) AS def_tackles ON def_tackles.team_id = ts.team_id AND def_tackles.season_year = ts.season_year
GROUP BY defender_category;

/* 12. RESULTS
# defender_category, avg_wins
'Under 100 Tackle Defender', '7.9713'
'100+ Tackle Defender', '8.0968'

What the Results Show:
Teams with a high-tackle defender averaged 8.1 wins, only slightly higher than those without (8 wins).
Why It Matters:
While tackling leaders may contribute defensively, raw tackle numbers alone may not directly translate to more wins.
*/

-- 13. Average Tackles per Player on Teams With 10+ Wins vs. Under 10 Wins (Do players on successful teams tend to rack up more tackles?)
SELECT
    CASE WHEN ts.wins >= 10 THEN '10+ Wins' ELSE 'Under 10 Wins' END AS team_category,
    AVG(ps.tackles) AS avg_tackles_per_player
FROM TeamStats ts
JOIN PlayerTeamSeason pts ON ts.team_id = pts.team_id AND ts.season_year = pts.season_year
JOIN PlayerStats ps ON pts.player_id = ps.player_id AND pts.season_year = ps.season_year
JOIN Player p ON ps.player_id = p.player_id
GROUP BY team_category;

/* 13. RESULTS
# team_category, avg_tackles_per_player
'Under 10 Wins', '7.5289'
'10+ Wins', '8.2532'

What the Results Show:
Players on winning teams averaged about 8.25 tackles, compared to 7.5 on losing teams.
Why It Matters:
Higher tackle rates could suggest better overall defensive involvement, but again, not the strongest success factor compared to points allowed or turnovers.
*/

-- 14. Average interceptions by QBs on Teams With 10+ Wins vs. Under 10 Wins (Do winning teams have QBs that throw fewer interceptions?) 
SELECT
    CASE WHEN ts.wins >= 10 THEN '10+ Wins' ELSE 'Under 10 Wins' END AS team_category,
    AVG(ps.interceptions) AS avg_qb_interceptions
FROM TeamStats ts
JOIN PlayerTeamSeason pts ON ts.team_id = pts.team_id AND ts.season_year = pts.season_year
JOIN PlayerStats ps ON pts.player_id = ps.player_id AND pts.season_year = ps.season_year
JOIN Player p ON ps.player_id = p.player_id
WHERE p.position = 'QB'
GROUP BY team_category;

/* 14. RESULTS
# team_category, avg_qb_interceptions
'Under 10 Wins', '6.5599'
'10+ Wins', '6.1526'

What the Results Show:
QBs on winning teams threw slightly fewer interceptions (6.15) than QBs on losing teams (6.56).
Why It Matters:
While the difference is small, limiting interceptions still appears to play a supportive role in achieving winning seasons.
*/