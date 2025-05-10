USE nfl_project;

-- Players and their basic info
CREATE TABLE Player (
    player_id INT PRIMARY KEY,
    name VARCHAR(100),
    position VARCHAR(20)
);

-- NFL Teams
CREATE TABLE Team (
    team_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE
);

-- Seasons (e.g., 2003, 2004, etc.)
CREATE TABLE Season (
    season_year INT PRIMARY KEY
);

-- Which player played for which team that season
CREATE TABLE PlayerTeamSeason (
    player_id INT,
    season_year INT,
    team_id INT,
    PRIMARY KEY (player_id, season_year),
    FOREIGN KEY (player_id) REFERENCES Player(player_id),
    FOREIGN KEY (season_year) REFERENCES Season(season_year),
    FOREIGN KEY (team_id) REFERENCES Team(team_id)
);

-- Aggregated player stats per season
CREATE TABLE PlayerStats (
    player_id INT,
    season_year INT,
    passing_yards INT,
    rushing_yards INT,
    receiving_yards INT,
    touchdowns INT,
    interceptions INT,
    tackles INT,
    field_goals INT,
    PRIMARY KEY (player_id, season_year),
    FOREIGN KEY (player_id) REFERENCES Player(player_id),
    FOREIGN KEY (season_year) REFERENCES Season(season_year)
);

-- Team performance per season
CREATE TABLE TeamStats (
    season_year INT,
    team_id INT,
    wins INT,
    losses INT,
    ties INT,
    win_loss_perc FLOAT,
    points INT,
    points_opp INT,
    points_diff INT,
    mov FLOAT,
    turnovers INT,
    total_yards INT,
    pass_yds INT,
    rush_yds INT,
    penalties INT,
    exp_pts_tot FLOAT,
    PRIMARY KEY (team_id, season_year),
    FOREIGN KEY (team_id) REFERENCES Team(team_id),
    FOREIGN KEY (season_year) REFERENCES Season(season_year)
);
