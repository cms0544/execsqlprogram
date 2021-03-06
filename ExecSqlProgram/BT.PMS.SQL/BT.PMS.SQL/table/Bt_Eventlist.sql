if( exists(select 1 from sysobjects where id = object_id('Bt_Eventlist')))
  begin
     drop table Bt_Eventlist

  end

create table Bt_Eventlist
(
    event_id int identity(1,1) primary key,
	event_keys nvarchar(max),
	event_name nvarchar(max),
	event_isapp_notice bit,
	event_isweb_notice bit,
	event_isemail_notice bit,
	event_issms_notice bit,
	event_url nvarchar(max),
	event_title nvarchar(max)
)

if(not exists(select 1 from Bt_Eventlist where event_keys = 'High_event'))
   begin
         insert into Bt_Eventlist
		 select 'High_event','高空拋物',0,0,0,0,'/highTossAct/EventLogList.aspx','高空拋物事件列表'
   end

if(not exists(select 1 from Bt_Eventlist where event_keys = 'OverTemp_event'))
   begin
         insert into Bt_Eventlist
		 select 'OverTemp_event','超溫提示',0,0,0,0,'/report/InOutRecordReport.aspx','進出記錄報表'
   end

if(not exists(select 1 from Bt_Eventlist where event_keys = 'Service_warranty'))
   begin
         insert into Bt_Eventlist
		 select 'Service_warranty','服務保修單',0,0,0,0,'/pms2/fwgl/fwdcx.aspx','服務單查詢'
   end


   if(not exists(select 1 from Bt_Eventlist where event_keys = 'Suggestions'))
   begin
         insert into Bt_Eventlist
		 select 'Suggestions','投訴建議反饋',0,0,0,0,'/pms2/yzgl/zhts.aspx','業主建議/反饋'
   end
