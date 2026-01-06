use hospital;

#total revenue
select concat(left(round(sum(revenue_realized), -6),4), "M") as "Total Revenue" from fact_bookings ;

#toatal bookings
select concat(left(round(count(booking_id), -3),3), "K") as "Total Bookings" from fact_bookings ;

#total capacity
select concat(left(round(sum(capacity), -3), 3), "K") as "Total Capacity" from fact_aggregated_bookings;

#occupancy%
select concat(round(sum(successful_bookings) / sum(capacity) *100, 2), "%") as "Occupancy %" from fact_aggregated_bookings;

#cancellation rate
select concat(round((select count(booking_status) from fact_bookings as cancel_count where booking_status = "Cancelled") / 
count(booking_id) *100, 2), "%") as "Cancellation %" from fact_bookings;

#avg rating on 100% booking id's
select round(avg(ratings_given), 1)  as "Avg Rating" from fact_bookings;

#avg rating on 42% response rate
select round(avg(ratings_given), 1) as "Avg Rating" from fact_bookings  where not ratings_given =0;

#response rate
select concat(floor((select count(ratings_given) from fact_bookings where not ratings_given =0) / 
count(ratings_given) *100), "%") as "Response Rate" from fact_bookings;

#revenue by hotel & city
select B.property_name as Hotel, B.city as City,
case when length(sum(A.revenue_realized))=8 then concat(left(round(sum(A.revenue_realized), -6),2), "M")
     else concat(left(round(sum(A.revenue_realized), -6),3), "M") end as "Total Revenue"
from fact_bookings as A
left join (select property_id, property_name, city from dim_hotels) as B
on A.property_id = B.property_id
group by B.property_name, B.city
order by B.property_name;

#class wise Revenue
select D.room_class as "Class", 
if(length(sum(C.revenue_realized))=9, concat(left(round(sum(C.revenue_realized), -6),3), "M"), sum(C.revenue_realized)) 
as "Total Revenue" from
(select room_category, revenue_realized from fact_bookings) as C
left join dim_rooms as D
on C.room_category = D.room_id
group by D.room_class
order by  D.room_class;

#weekday & weekend revenue & booking
select F.day_type as "Day Type",
if(length(sum(E.revenue_realized))=10, concat(left(round(sum(E.revenue_realized), -6),4), "M"),
concat(left(round(sum(E.revenue_realized), -6),3), "M")) as "Total Revenue", 
concat(left(count(E.booking_id),2), "K") as "Bookings" from 
(select str_to_date(check_in_date, '%Y-%m-%d') as date1 , booking_id, revenue_realized from fact_bookings) as E
left join
(select date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') as date2 , day_type from dim_date) as F
on E.date1 = F.date2
group by F.day_type;

#weekly trend - revenue & bookings
select G.week_no as "Week no.", if(length(sum(H.revenue_realized))=9, concat(left(round(sum(H.revenue_realized), -6),3), "M"),
concat(left(round(sum(H.revenue_realized), -6),2), "M")) as "Total Revenue",
if(length(count(H.booking_id)) = 5, concat(left(round(count(H.booking_id), -3), 2), "K"), 
concat(left(round(count(H.booking_id), -3), 1), "K")) as "Bookings" from 
(select str_to_date(check_in_date, '%Y-%m-%d') as date1 , booking_id, revenue_realized, room_category from fact_bookings)
as H 
left join
(select date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') as date2 , 
concat("W ", week( date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') ) +1) as week_no from dim_date) as G
on H.date1= G.date2
group by G.week_no;

#weekly trend - occupancy%
select K.week_no as "Week No.", concat(round(sum(successful_bookings) / sum(J.capacity) *100,2), "%") as "Occupancy %" from 
(select successful_bookings, capacity ,
date_format(str_to_date(check_in_date, '%d-%b-%y'), '%Y-%m-%d') as date3 from fact_aggregated_bookings) as J
left join
(select date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') as date2 , 
concat("W ", week( date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') ) +1) as week_no from dim_date) as K
on J.date3 = K.date2
group by K.week_no;

#checked out, cancel, no show
select "Checked Out" as "Booking Status", concat(round((select count(booking_id) from fact_bookings 
where booking_status = "Checked Out") / count(booking_id) * 100,1), "%") as "%" from fact_bookings
union
select "Cancelled" as "Booking Status", concat(round((select count(booking_id) from fact_bookings 
where booking_status = "Cancelled") / count(booking_id) * 100,1), "%") as "%" from fact_bookings
union
select "No Show" as "Booking Status", concat(round((select count(booking_id) from fact_bookings 
where booking_status = "No Show") / count(booking_id) * 100,1), "%") as "%" from fact_bookings;

#trend analysis
select str_to_date(booking_date, '%Y-%m-%d') as "Booking Date", concat(round(sum(if(booking_status= "Cancelled",1,0)) / count(booking_id) *100, 0), "%")
as "Cancellation %"
from fact_bookings group by booking_date
order by booking_date;

#revenue & bookings by booking platform
select booking_platform as "Booking Platform", if(length(count(booking_id))=5, concat(left(round(count(booking_id),-3),2), "K"), 
concat(left(count(booking_id),1), "K")) as "Bookings", if(length(sum(revenue_realized)) = 9, 
concat(left(round(sum(revenue_realized), -6),3), "M"), concat(left(round(sum(revenue_realized), -6),2), "M")) as "Total Revenue"
from fact_bookings
group by booking_platform
order by sum(revenue_realized) desc;

#weekday & weekend revenue & booking
select F.day_type as "Day Type",
if(length(sum(E.revenue_realized))=10, concat(left(round(sum(E.revenue_realized), -6),4), "M"),
concat(left(round(sum(E.revenue_realized), -6),3), "M")) as "Total Revenue", 
concat(left(count(E.booking_id),2), "K") as "Bookings" from 
(select str_to_date(check_in_date, '%Y-%m-%d') as date1 , booking_id, revenue_realized from fact_bookings) as E
left join
(select date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') as date2 , day_type from dim_date) as F
on E.date1 = F.date2
group by F.day_type;

#weekly trend - revenue & bookings
select G.week_no as "Week no.", if(length(sum(H.revenue_realized))=9, concat(left(round(sum(H.revenue_realized), -6),3), "M"),
concat(left(round(sum(H.revenue_realized), -6),2), "M")) as "Total Revenue",
if(length(count(H.booking_id)) = 5, concat(left(round(count(H.booking_id), -3), 2), "K"), 
concat(left(round(count(H.booking_id), -3), 1), "K")) as "Bookings" from 
(select str_to_date(check_in_date, '%Y-%m-%d') as date1 , booking_id, revenue_realized, room_category from fact_bookings)
as H 
left join
(select date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') as date2 , 
concat("W ", week( date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') ) +1) as week_no from dim_date) as G
on H.date1= G.date2
group by G.week_no;

#weekly trend - occupancy%
select K.week_no as "Week No.", concat(round(sum(successful_bookings) / sum(J.capacity) *100,2), "%") as "Occupancy %" from 
(select successful_bookings, capacity ,
date_format(str_to_date(check_in_date, '%d-%b-%y'), '%Y-%m-%d') as date3 from fact_aggregated_bookings) as J
left join
(select date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') as date2 , 
concat("W ", week( date_format(str_to_date(date, '%d-%m-%Y'), '%Y-%m-%d') ) +1) as week_no from dim_date) as K
on J.date3 = K.date2
group by K.week_no;

#checked out, cancel, no show
select "Checked Out" as "Booking Status", concat(round((select count(booking_id) from fact_bookings 
where booking_status = "Checked Out") / count(booking_id) * 100,1), "%") as "%" from fact_bookings
union
select "Cancelled" as "Booking Status", concat(round((select count(booking_id) from fact_bookings 
where booking_status = "Cancelled") / count(booking_id) * 100,1), "%") as "%" from fact_bookings
union
select "No Show" as "Booking Status", concat(round((select count(booking_id) from fact_bookings 
where booking_status = "No Show") / count(booking_id) * 100,1), "%") as "%" from fact_bookings;

#trend analysis
select str_to_date(booking_date, '%Y-%m-%d') as "Booking Date", concat(round(sum(if(booking_status= "Cancelled",1,0)) / count(booking_id) *100, 0), "%")
as "Cancellation %"
from fact_bookings group by booking_date
order by booking_date;

#revenue & bookings by booking platform
select booking_platform as "Booking Platform", if(length(count(booking_id))=5, concat(left(round(count(booking_id),-3),2), "K"), 
concat(left(count(booking_id),1), "K")) as "Bookings", if(length(sum(revenue_realized)) = 9, 
concat(left(round(sum(revenue_realized), -6),3), "M"), concat(left(round(sum(revenue_realized), -6),2), "M")) as "Total Revenue"
from fact_bookings
group by booking_platform
order by sum(revenue_realized) desc;

