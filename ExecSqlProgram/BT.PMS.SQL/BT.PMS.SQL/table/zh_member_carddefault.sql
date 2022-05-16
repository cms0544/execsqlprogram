if(exists(select 1 from sysobjects where id = OBJECT_ID('zh_member_carddefault'))) drop table zh_member_carddefault
create table zh_member_carddefault
(
    col_userid int primary key,
	col_cardtype int,
	col_datestart datetime,
	col_dateend datetime,
	col_state int,
	col_leave_reason varchar(max),
	col_card_status int,
	col_card_fee decimal(18,2),
	col_fccellid varchar(max),
	col_CreateTime datetime
)
