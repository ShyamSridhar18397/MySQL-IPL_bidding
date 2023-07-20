use ipl;
select * from ipl_bidder_points;
select * from ipl_bidding_details;
select * from match_schedule;

#Question 1  Show the percentage of wins of each bidder in the order of highest to lowest percentage.
with subquery as
(select bp.bidder_id,
if(bd.bid_status!='won',no_of_bids-1,no_of_bids-0)as win_total,
no_of_bids
from IPL_BIDDER_POINTS bp join IPL_BIDDING_DETAILS bd
on bp.BIDDER_ID=bd.BIDDER_ID
)
select *,
(win_total/no_of_bids)*100 as percentage_of_wins
from subquery
group by bidder_id,no_of_bids,win_total
order by percentage_of_wins desc;

#Question 2 .Display the number of matches conducted at each stadium with the stadium name and city.

select  ms.stadium_id, stadium_name, count(match_id) No_of_matches
from ipl_match_schedule ms
join ipl_stadium s
on ms.stadium_id= s.stadium_id
group by stadium_id order by stadium_id ;

#Question 3 In a given stadium, what is the percentage of wins by a team which has won the toss?

select stadium_id,(matches_won/total_matches)*100 as percentage
from(
select stadium_id,total_matches,count(*)matches_won
from(
select stadium_id,count(m.match_id)total_matches,toss_winner,match_winner
from ipl_match m join IPL_MATCH_SCHEDULE ms
on m.match_id=ms.MATCH_ID
group by stadium_id,toss_winner,match_winner) as t
where t.toss_winner=t.match_winner
group by stadium_id,total_matches
)as t;

#Question 4 Show the total bids along with the bid team and team name.

select  bid_team, team_name, count(bidder_id) Total_bids
from ipl_bidding_details ibs
join ipl_team it
on ibs.BID_TEAM=it.TEAM_ID
group by bid_team;

#Question 5 Show the team id who won the match as per the win details.

select * from ipl_match;
select match_id,
(case when match_winner=1 then team_id1
when match_winner =2 then team_id2 end) Winner_team_id
from ipl_match; 

#Question 6 .Display total matches played, total matches won and total matches lost by the team along with its team name.

select Team_name, sum(MATCHES_PLAYED) Total_played, sum(MATCHES_WON) Total_won, sum(MATCHES_LOST) Total_lost 
from ipl_team_standings its
join ipl_team it
on its.TEAM_ID=it.TEAM_ID
group by it.team_id;

#Question 7 Display the bowlers for the Mumbai Indians team.

select player_name from ipl_player where player_id in 
(select player_id from ipl_team_players where player_role like '%bowler%' and team_id in 
(select team_id from ipl_team where team_name like '%mumbai%'));

#Question 8 How many all-rounders are there in each team, Display the teams with more than 4 
#all-rounders in descending order.

select * from ipl_team_players;
select Team_id,count(player_id) All_rounders 
from ipl_team_players 
where player_role like '%all%' 
group by team_id
having All_rounders>4
order by count(player_id) desc;

#Q9.Write a query to get the total bidders points for each bidding status of those bidders who bid on CSK when it won the match in M. Chinnaswamy Stadium bidding year-wise.
#Note the total bidders’ points in descending order and the year is bidding year.
#Display columns: bidding status, bid date as year, total bidder’s points
select ibd.bidder_id,year(BID_DATE) bidding_year,sum(total_points) over (partition by bidder_id)total_bidders_points
from IPL_BIDDER_POINTS ibp join IPL_BIDDING_DETAILS ibd
using(bidder_id) 
join IPL_MATCH_SCHEDULE ims
on ibd.SCHEDULE_ID=ims.SCHEDULE_ID
where BID_TEAM=
(select team_id from IPL_TEAM where remarks='csk')
and ims.MATCH_ID in
(select MATCH_ID from IPL_MATCH where TEAM_ID1 or TEAM_ID2 in 
(select team_id from IPL_TEAM where remarks='csk')
and win_details like '%csk%')
and STADIUM_ID=
(select stadium_id  from IPL_STADIUM  where STADIUM_NAME like '%chinnaswamy%');

#Q10.Extract the Bowlers and All Rounders those are in the 5 highest number of wickets.
#Note 
#1. use the performance_dtls column from ipl_player to get the total number of wickets
#2. Do not use the limit method because it might not give appropriate results when players have the same number of wickets
#3.	Do not use joins in any cases.
#4.	Display the following columns teamn_name, player_name, and player_role.
select player_name,player_role,team from 
(select *, 
dense_rank() over(order by cast(wickets as signed) desc) as rnk 
from 
(select player_name ,player_role,itl.remarks as team,
substring_index(substring_index(substring_index(PERFORMANCE_DTLS,' ',3),' ',-1),'-',-1) as wickets
from IPL_PLAYER ip 
join ipl_team_players itl
on ip.player_id=itl.player_id
where player_role in('bowler','all-rounder'))as t
)as t
where rnk<6;


#Q11.Show the percentage of toss wins of each bidder and display the results in descending order based on the percentage
select *,(toss_wins/NO_OF_BIDS)*100 as percentage_tosswins from 
(select bidder_id,NO_OF_BIDS,count(ims.MATCH_ID) over (partition by BIDDER_ID)as toss_wins
from IPL_BIDDING_DETAILS ibd join IPL_BIDDER_POINTS ibp
using(BIDDER_ID)
join IPL_MATCH_SCHEDULE ims
on ims.SCHEDULE_ID=ibd.SCHEDULE_ID
join IPL_MATCH im
on im.MATCH_ID= ims.MATCH_ID
where (BID_TEAM=TEAM_ID1 and TOSS_WINNER=1) or (BID_TEAM=TEAM_ID2 and TOSS_WINNER=2))as t
group by BIDDER_ID;

#Q12.Find the IPL season which has min duration and max duration.
#Output columns should be like the below:
#Tournment_ID, Tourment_name, Duration column, Duration

select *, dense_rank() over (order by duration desc)rnk from 
(select TOURNMT_ID,TOURNMT_NAME,(TO_DATE-FROM_DATE)duration
from IPL_TOURNAMENT) as t ;

#Q13.Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total points in descending order and month-wise in ascending order.
#Note: Display the following columns:
#1.	Bidder ID, 2. Bidder Name, 3. bid date as Year, 4. bid date as Month, 5. Total points
#Only use joins for the above query queries.

select ibd.BIDDER_ID,BIDDER_NAME,year(BID_DATE)as bid_year,month(BID_DATE)as bid_month,
sum(TOTAL_POINTS) over(partition by month(BID_DATE),BIDDER_NAME order by month(BID_DATE)) as total_point
from IPL_BIDDER_DETAILS ibd join IPL_BIDDER_POINTS
using(BIDDER_ID)
join IPL_BIDDING_DETAILS ipbd
using(BIDDER_ID)
where year(BID_DATE)=2017
order by total_point desc ;

#Q14.Write a query for the above question using sub queries by having the same constraints as the above question.

select * from(select ibd.BIDDER_ID,BIDDER_NAME,year(BID_DATE)as bid_year,month(BID_DATE)as bid_month,
sum(TOTAL_POINTS) over(partition by month(BID_DATE),BIDDER_NAME) as total_point
from IPL_BIDDER_DETAILS ibd join IPL_BIDDER_POINTS
using(BIDDER_ID)
join IPL_BIDDING_DETAILS ipbd
using(BIDDER_ID)
where year(BID_DATE)=2017)as t
group by bidder_id,bid_month
order by TOTAL_POINT desc;

#Q15.Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
#Output columns should be like:
#Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, Lowest_3_Bidders  --> columns contains name of bidder;

select BIDDER_ID,TOTAL_POINTS,
case
when t.top<=3 then 'top 3'
when t.bottom<=3 then 'bottom 3'
end as position
from(
select BIDDER_ID,TOTAL_POINTS,dense_rank() over (order by TOTAL_POINTS desc)top ,dense_rank() over (order by TOTAL_POINTS )bottom 
from IPL_BIDDER_POINTS
where BIDDER_ID in (select BIDDER_ID from IPL_BIDDING_DETAILS where year(BID_DATE)=2018))
as t
where t.top<=3 or t.bottom <=3 ;
