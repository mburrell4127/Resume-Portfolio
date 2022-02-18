/*This project stemmed from a discussion my brother and I had surrounding
what is considered an "exciting season" for a soccer fan; I downloaded some
high level data to explore this idea a bit more (Source: Statbunker Football Statistics, 
please see the link in this project's description). I hope to enhance my 
work over the next few months, both to search for an answer to our question
and to improve my SQL capabilities.*/


use soccer_schema;


/*First I'd like to glance at the data, getting a feel for what I'm working with.
I use some select statements and then went to the table inspectors to determine 
if the numbers of rows are as expected and whether appropriate
values are present.*/



SELECT * FROM home_attendance LIMIT 5; 
SELECT * FROM penalties_and_capacity LIMIT 5; 
SELECT * FROM team_defense LIMIT 5; 
SELECT * FROM team_offense LIMIT 5; 
SELECT * FROM team_tables LIMIT 5; 



/*I noticed that only one of the tables appears to be properly formatted with a
single row for each team: "penalties_and_capacity". The tables "team_offense,"
"team_defense," and "team_tables" all have more than 20 rows of data and 
the table "home_attendance" has headers listed as a record. 

I have the luxury of knowing that the first 20 data records of each table are what 
I am looking to use, and so I will remove the unecessary or invalid rows. I've 
created table copies so as to not alter raw data.*/



/*Top row was header values*/

CREATE TABLE home_attendance_clean 
	LIKE home_attendance;

INSERT INTO home_attendance_clean
	SELECT * FROM home_attendance;

DELETE FROM home_attendance_clean
	LIMIT 1;



/*Irrelevant leagues were removed*/

CREATE TABLE team_defense_clean
	LIKE team_defense;
    
INSERT INTO team_defense_clean
	SELECT * FROM team_defense
		WHERE league = 'Premier League';



CREATE TABLE team_offense_clean
	LIKE team_offense;
    
INSERT INTO team_offense_clean
	SELECT * FROM team_offense
		WHERE league = 'Premier League';



/*Irrelevant season records were removed*/

CREATE TABLE team_tables_clean
	LIKE team_tables;

INSERT INTO team_tables_clean
	SELECT * FROM team_tables;

ALTER TABLE team_tables_clean
	ADD id int NOT NULL AUTO_INCREMENT PRIMARY KEY;
    
DELETE FROM team_tables_clean
	WHERE id > '20';



/*Now that the tables have been updated to only contain relevant data, we
will combine them. Given the simplicity of these datasets, each team can be
represented by a single record without any redundant data*/

CREATE TABLE aggregated_table (

	league VARCHAR(25),
    team VARCHAR(25) NOT NULL PRIMARY KEY,
    pos int,
    played int,
    won int,
    drawn int,
    lost int,
    goals_for int,
    gf_home int,
    gf_last_10_mins int,
    goals_against int, 
    ga_home int,
    ga_last_10_mins int,
    penalties_scored int,
    stadium_capacity int,
    home_attendance VARCHAR(25)
    
);



/*Add primary keys and attendance data into the table*/

INSERT INTO aggregated_table (team, league, home_attendance)
	SELECT team, league, total_home_attendance FROM home_attendance_clean;



/*Use joins to populate the rest of the table*/

/*Defense data*/

UPDATE aggregated_table AS a
	INNER JOIN team_defense_clean AS d
		ON a.team = d.team
        SET a.goals_against = d.goals_against, a.ga_home = d.ga_home, a.ga_last_10_mins = d.ga_last_10_mins;
        

/* Offense data*/

UPDATE aggregated_table AS a
	INNER JOIN team_offense_clean AS o
		ON a.team = o.team
        SET a.goals_for = o.goals_for, a.gf_home = o.gf_home, a.gf_last_10_mins = o.gf_last_10_mins;
        

/* Table data*/

UPDATE aggregated_table AS a
	INNER JOIN team_tables_clean AS t
		ON a.team = t.team
        SET a.pos = t.pos, a.played = t.played, a.won = t.won, a.drawn = t.drawn, a.lost = t.lost;
        

/* Penalty and Capacity Data*/

UPDATE aggregated_table AS a
	INNER JOIN penalties_and_capacity AS pc
		ON a.team = pc.team
        SET a.penalties_scored = pc.penalties_scored, a.stadium_capacity = pc.stadium_capacity;




/*Now that we have all of the appropriate data consolidated, we can do a little exploratory analysis 
and get a sense of what might be an "exciting team."*/



/*First I'd like to rename our table to something more relevant*/

ALTER TABLE aggregated_table RENAME TO epl_season_stats_2017;



/*Getting a sense of what teams defended and attacked well*/ 

SELECT * FROM epl_season_stats_2017
	ORDER BY goals_for DESC;
    
SELECT * FROM epl_season_stats_2017
	ORDER BY goals_against ASC;


/*In both instances, we see Tottenham Hotspur leading the pack, with Chelsea
and Man City close behind. Noticeably, while Man United allowed very few goals,
their offense was relatively lacking. This aligns with the play-style of their coach,
Jose Mourinho, who is famous for his defensive tactics and conservative style
of play.*/



/*Let's also take a look at the teams sorted by penalties scored, as that
is one of the most nail-biting events that can happen in a game*/

SELECT * FROM epl_season_stats_2017
	ORDER BY penalties_scored DESC
    LIMIT 10;



/*Finally, my favorite team is Tottenham Hotspur; before I apply fairly 
arbitrary weights on what I deem "exciting," I'll look at their stats for fun.*/

SELECT * FROM epl_season_stats_2017
	WHERE team = 'Tottenham Hotspur';



/*Let's apply an arbitrary weighting system that I devised with my brother
to create a composite score on what we find "exciting." I have detailed our
scoring below:

Win: 1 point
Finishing Position: (20 - pos) * 1.5 point(s)
Goal Scored: 0.5 points
Goal Allowed: -0.4 points
Goal in Final 10 MInutes: 0.2 points
Goal Allowed in Final 10 Minutes: -0.3 points
Penalty Scored: 0.2 points*/



ALTER TABLE epl_season_stats_2017
	ADD score int;
    
UPDATE epl_season_stats_2017
	SET score = ((won*1) + (20 - pos)*1.5 + (goals_for*0.5) - 
    (goals_against*0.4) + (gf_last_10_mins*0.2) - (ga_last_10_mins*0.3) +
    (penalties_scored*0.2));
    
SELECT * FROM epl_season_stats_2017
	ORDER BY score DESC;



/*While this analysis does not significantly deviate from the actual finishing positions of each team, 
it did provide insight into what makes an enjoyable season as well as opened the door to more questions.

If I were to expand this analysis, I would like to acquire more data surrounding each goal's timing
(minute of the game), location (home or away), and point in the season (early, mid, or late). 
I'd like to contextualize each match played by weighting a win against a 
favored side as being more "exciting" - this may be attainable by pulling betting odds to
determine how favorited each side is. Additionally, I think I made a flawed assumption in my
scoring of finishing position, as a season can be "exciting" for a fan if their team over-achieves
their expected finish (a newly promoted side finishing in 10th is certainly exciting, while the last season's
champions finishing fifth would be considered a failure).*/
