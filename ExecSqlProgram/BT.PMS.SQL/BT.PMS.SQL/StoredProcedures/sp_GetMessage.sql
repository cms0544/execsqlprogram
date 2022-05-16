 
	 IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'sp_GetMessage') and xtype='P')  DROP PROCEDURE [dbo].sp_GetMessage
GO

-- Author:		<Colin>
-- Create date: <2021-04-21>
-- Description:	<10秒查詢是否超溫> 

	 
	   --sp_GetMessage 'admin'
	   create Proc  sp_GetMessage(
	   @UserID nvarchar(200)

	   )
	   as begin
	   
	   if(isnull(@UserID,'')!='' and  exists(select 1  from  YH where  ismessage=1 and  ui_id=@UserID))
	   begin

	  
	   	insert into  tb_TempMessage(UserID,UserName,companyname,temperature,place,TypeID ,Status ,InTime ,SendTime,sys_EventTime,picurl)
		select @UserID,  员工名称,公司名,体温,devicename ,sys_IsTAData,0,getdate(),null,sys_EventTime,照片 From  (
	    select  sys_EventTime, a.sys_UserName as '员工名称',isnull(c.alias,'') as '公司名',a.sys_IsOverTemp '是否超温',a.sys_UserTemp as '体温',
		
		--isnull(b.zpurl,'') 
		isnull(sys_PicDataUrl,'')
		as '照片',sys_DeviceName as devicename,case when isnull(sys_IsTAData,0) = 0 then '访客' else '業主租戶' end as  类型,sys_IsTAData
        from BT_sys_RawDataLogForReader as a with (nolock)
        left join ZH_Members as b on a.sys_UserID = b.id
        left join ZH_Owner as c on c.ID = b.ownerid
        left join V_HostDevice as v on a.sys_ReaderID = v.HostDeviceID  
		where  sys_IsOverTemp=1 and convert(varchar(10),sys_EventTime,20)>='2021-03-29'

		and  sys_EventTime>=dateadd(MINUTE,-5,getdate())
		
        and not exists( select  1 from  tb_TempMessage where  UserName=a.sys_UserName and  sys_EventTime=a.sys_EventTime and  UserID=@UserID )
		) as h
		order by  sys_EventTime asc
	   
	   --if(not exists(select 1 f from tb_TempMessage where Status=0 ))
	   --begin  
	   
	   --update tb_TempMessage set Status=0
	   --end
	   
									
		select  top 1 *from  tb_TempMessage where  isnull(Status,0)=0 and userid=@UserID  order by id asc
		update  tb_TempMessage set  Status=1,SendTime=getdate()
		from (select  top 1 id  from  tb_TempMessage where  userid=@UserID and isnull(Status,0)=0  order by id asc ) as h
		where h.id=tb_TempMessage.id

			end
			else  begin  
			
			select  '' as UserID
			end
		end
