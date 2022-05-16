IF NOT EXISTS (select name from sysobjects where id=object_id(N'BT_col_CardManagement_FCCELL') AND NAME='BT_col_CardManagement_FCCELL') 
 begin
create table BT_col_CardManagement_FCCELL
(
    id int identity(1,1) primary key,
	cardid int,
	cellid int
)
  end

go
/*≥ı ºªØ*/
  --insert into BT_col_CardManagement_FCCELL(cardid,cellid)
  --select col_id,col_fccellid
  --from BT_col_CardManagement
  --where not exists(select 1 from BT_col_CardManagement_FCCELL where cardid = BT_col_CardManagement.col_id)

