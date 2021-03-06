if(exists(select 1 from sysobjects where id = object_id('sp_tempimport_yzxx')))
   begin
      drop  PROCEDURE [dbo].[sp_tempimport_yzxx]
   end
/****** Object:  StoredProcedure [dbo].[sp_tempimport_yzxx]    Script Date: 2021/8/4 11:45:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Mason>
-- Create date: <2019-10-21,,>
-- Description:	<業主信息導入,,sp_tempimport_yzxx 1,0,9999>
-- =============================================
create PROCEDURE [dbo].[sp_tempimport_yzxx]
	-- Add the parameters for the stored procedure here
	@lpid int,
	@type int=0,
	@MaxMembeNum int =9999,
	@yzid int= 0
AS
BEGIN
   	begin transaction 
		begin try
	select ROW_NUMBER() over(Order by (select 1)  ASC) As [index],cellid,a.*,null as ownerid,null as app_buid_guid, null as usercardid,b.cellcode
	into #tempyzdr
	from bt_temp_yzdr a 
	left join View_CellDetailInfo b on (a.cellname = b.cellcode or a.code = b.cellcode) and lpid = @lpid
	--where nullif(ltrim(rtrim(yzname)),'')!=''
	order by cellid

	--where nullif(ltrim(rtrim(yzname)),'')!=''


	--select   ROW_NUMBER() over(Order by (select 1)  ASC) As [index],ROW_NUMBER() over(partition by cellid Order by (select 1)  ASC) As [orderid],* 
	--into #tempyzdr
	--from #temps 	
	--where nullif(ltrim(rtrim(code)),'')!='' order by cellid






	declare @insertcount int = 0,@updatecount int = 0;

		declare @id int = 0, @index varchar(max) = '',@orderid int,@code varchar(max),@cellname varchar(max),@cardno varchar(max),@enname varchar(max),@name varchar(max),@sex varchar(max),@identity varchar(max),@Authorizer varchar(max),
	@Authorized_Person varchar(max),@Authorized_from varchar(max),@Authorized_until varchar(max),@zjstatus  varchar(max) ,@inserttime  varchar(max),

	@feetype varchar(max),@starttime varchar(max),@endttime varchar(max),@col_leave_reason varchar(max),@mobile varchar(max),@whatsapps  varchar(max),@yzdzdy  varchar(max),
	@yzdzds  varchar(max),@yzdzjd  varchar(max),@yzdzdq  varchar(max),@jjlxr  varchar(max),@jjlxrmobile  varchar(max),@ownerid  varchar(max),@app_buid_guid  varchar(max),@usercardid varchar(max),@cellcode varchar(max),
	@cellid int=0,@message varchar(max);
	declare @mobileerror varchar(max),@carderror varchar(max),@app_bind_guid varchar(max),@cardid varchar(max),@memberid int;
	declare @yzcode varchar(max) = ''
	declare @cardtype varchar(max) = '';
	declare @memo varchar(max) ='' ; 
	declare @maxfkstr varchar(max) = '';
	declare @email varchar(max) = '';

	declare @IsDeleteCodeCanUse nvarchar(max);
		
		
		select @IsDeleteCodeCanUse = ParamValue  from BT_SystemParam where  ParamName = 'PMS_IsDeleteCodeCanUse'



	/**最大发卡数量系统参数**/
	declare @maxfkvalue nvarchar(max) = '1' ;
	
	select @maxfkvalue = paramValue from BT_SystemParam where ParamName='PMS_limitMaxFK'



	create table #tempid
	(
	   id int
	)

	create table #deleteowner
	(
	    id int
	)





	if(@type = 1)
	  begin

	  if(@yzid = 0)
	     begin
		     insert into #deleteowner
			 select id  from ZH_OWNER as a
			 left join View_ZHFCLPInfo as b on a.id = b.OWNERID  where lpid= @lpid
		 end
		else
		 begin
		    insert into #deleteowner
			 select id  from ZH_OWNER as a
			 left join View_ZHFCLPInfo as b on a.id = b.OWNERID  where lpid= @lpid and b.OWNERID = @yzid
		 end
	   

	     delete from ZH_OWNER where id in (
		   select id from #deleteowner
		 )
		 delete from ZH_FC where ownerid in (
		   select id from #deleteowner
		 )
		 delete from BT_APP_BindOwner where zh_owner_id in (
		     select id from #deleteowner
		 )
		 delete from BT_col_CardManagement where col_fccellid in (
		     select cellid from View_CellDetailInfo where lpid = @lpid
		 )



		 	 Delete from BT_col_AutoDownloadUserForReader where col_Status<9 and col_userid in (
			 
			     select id from zh_members where ownerid in (
				  select id from #deleteowner
				  )
			 )
		-- insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime,col_userid,col_UserName,col_usertype,col_useraddress,col_FCCellid,col_cardtype,col_MaxSwipeTime,col_Enabled)
		--select col_UserCode,col_CardID,sys_ReaderID,99,col_DateStart,col_DateEnd,0,GetDate(),col_userid,col_UserName,col_usertype,col_useraddress,col_FCCellid,col_cardtype,col_MaxSwipeTime,Enabled
		--from BT_col_UserInfoForReader as a 
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo



	        INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,col_DateStart,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where  a.col_CardType<>11 and a.col_userid in (   select id from zh_members where ownerid in (
				  select id from #deleteowner
				  ))
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,col_DateStart,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType=11 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true') and a.col_userid in (   select id from zh_members where ownerid in (
				  select id from #deleteowner
				  ))

		delete from BT_sys_UserReaderAccess where sys_usercode in (select code from zh_members where ownerid in (
				  select id from #deleteowner
				  ))
		
		delete from BT_col_UserInfoForReader  where col_UserID in (select id from zh_members where ownerid in (
				  select id from #deleteowner
				  ))

		delete from BT_sys_UserReaderAccess_JTCY where sys_memberid in (select id from zh_members where ownerid in (
				  select id from #deleteowner
				  ))

			
		
		delete from tb_DoorGroup_UserReaderAccess_JTCY  where sys_memberid in (select id from zh_members where ownerid in (
				  select id from #deleteowner
				  ))
	
		--delete from tb_LP_ReaderAccess_JTCY
		delete from ZH_MEMBERS where ownerid in (
		      select id from #deleteowner
		 )
	  end

	  	 select * into #tempyz from #tempyzdr where [Identity] like '業主%'

		select count(1) as counts,code 
		into #tempcount
		from #tempyz
		group by code


		select a.*,c.counts
		into #tempyz2
		 from #tempyz as a
		left join #tempcount  as c on a.code = c.code
		where exists(select 1 from #tempyz as b where b.cellid =a.cellid and b.code!=a.code )





		--delete from #tempyz where code not in (
		--   select code from #tempyz2 where exists (
		--	select 1 from #tempyz3 where #tempyz2.counts= maxcounts and #tempyz2.cellid = #tempyz3.cellid
		--	)

		--  )


		select row_number() over (order by cellid) as rowindex,*  into #tempinsertyz from #tempyz

		create table #yzcode
		(
		   yzcode varchar(max) collate Chinese_PRC_CI_AS
		)

		declare @beginindex int = 0,@maxindex int = 0 ;

		select @beginindex = 1;
		select @maxindex = max(rowindex) from #tempinsertyz
;
     

		while (@beginindex<=@maxindex)
		   begin
		        select @cellid = cellid,@cellname=cellname,@code = code,@cellcode = code,@name = name,@sex = sex,@mobile = mobile  ,@yzdzdy = yzdzdy,@yzdzds=yzdzds,@yzdzjd = yzdzjd ,@yzdzdq =yzdzdq ,@yzdzdy = yzdzdy ,@yzdzds =yzdzds ,@yzdzjd = yzdzjd,@yzdzdq = yzdzdq,@jjlxr =jjlxr ,@jjlxrmobile = jjlxrmobile ,@memo = memo,@email = email  from #tempinsertyz where rowindex = @beginindex

				if(@sex = 'M')
				  begin
					set @sex = '男';
				  end 

				 else if(@sex = 'F')
				  begin
					set @sex = '女';
				  end 

				if(not exists(select 1 from zh_fc where CELLID = @cellid ) and  not exists (select 1 from ZH_OWNER where code = @cellname) and @yzid =0)
				begin

		  			insert into ZH_OWNER(code,NAME,SEX,LXDH,PWD,yzzt,cjr,cjsj,yzlx,yn_yhdk,lxdz,yzdzdw,yzdzds,yzdzjd,yzdzdq,jjlxrxm,jjlxrdh,email,memo) 
					select @cellname,@name,@sex,'+852'+@mobile, 'c4ca4238a0b923820dcc509a6f75849b','正常','admin',getdate(),'正式業主','否',@yzdzdy+@yzdzds+@yzdzjd+@yzdzdq,@yzdzdy,@yzdzds,@yzdzjd,@yzdzdq,@jjlxr,'+852'+@jjlxrmobile,@email,@memo
				
			
					select @ownerid = SCOPE_IDENTITY();

					insert into #yzcode
					select  @code

					insert into ZH_FC(ownerid,ownername,cellid,syzt,ynwxj,orderid)
					select @ownerid,@name,@cellid,'空閑','否',1
				end
			 else 
				begin

				  if(exists(select 1 from zh_fc where CELLID = @cellid))
				     begin
					     	select @ownerid =  OWNERID from zh_fc where CELLID = @cellid
					 end
					else
					 begin
	   
							select @ownerid =  id from ZH_OWNER where code = @cellname
						  	
							select  @orderid = max(orderid) +1  from  ZH_FC where ownerid = @ownerid
							insert into ZH_FC(ownerid,ownername,cellid,syzt,ynwxj,orderid)
							select @ownerid,@name,@cellid,'空閑','否',@orderid


								

								
					 end
	               

				   if(@yzdzdy!='' or not exists(select 1 from #tempinsertyz where cellname = @cellname and yzdzdy != '' ))
				      begin
							 update ZH_OWNER set code = @cellname ,NAME = @name,sex=@sex,lxdh= @mobile,lxdz= @yzdzdy+@yzdzds+@yzdzjd+@yzdzdq, yzdzdw=@yzdzdy,yzdzds= @yzdzds,yzdzjd = @yzdzjd,yzdzdq = @yzdzdq,jjlxrxm =@jjlxr,jjlxrdh= @jjlxrmobile   where id = @ownerid
				

								if(@email is not null)
								   begin
								      update ZH_OWNER set email = @email  where id = @ownerid
								   end

								   if(@memo is not null)
								     begin
									   update ZH_OWNER set memo = @memo  where id = @ownerid
									 end
								insert into #yzcode
								select  @code
				      end
				

				end


				if(@yzid != @ownerid and @yzid !=0)
				  begin

						set @message = '儲存失敗,此用戶無'+@cellcode+'的權限,請重新輸入！';
						  RaisError(@message ,16,1)  with log;
						 return;
				  end


				 set @beginindex = @beginindex + 1;
		   end




	  create table #tempcaridid(
	    col varchar(max) COLLATE Chinese_PRC_CI_AS,
		col_type int
	  )


	
	
	create table  #oldcard
	(
	    col_id int
	)




	select @beginindex = min([index]) from #tempyzdr

	select @maxindex = max([index]) from #tempyzdr


	while(@beginindex < = @maxindex)
	   begin

	--      --cardno为卡面编码
	      select @code = code,@cellname = cellname,@cardno =cardno,@enname = enname,@name  =name ,@sex = sex,@identity  = [identity],@Authorizer =Authorizer ,@Authorized_Person =  Authorized_Person,
		  @Authorized_from = case when replace(Authorized_from,' ','') = '' then null else Authorized_from end,@Authorized_until =case when replace(Authorized_until,' ','') = '' then null else Authorized_until end,@zjstatus = zjstatus, @inserttime = isnull(inserttime,getdate()), @feetype = feetype,
		  @starttime = starttime,@endttime = endttime,@col_leave_reason = col_leave_reason,@mobile = iif(mobile='Nil','',mobile),@whatsapps = iif(whatsapps='Nil','',whatsapps),
		  @yzdzdy = yzdzdy,@yzdzds = yzdzds,@yzdzjd = yzdzjd,@yzdzdq = yzdzdq,@jjlxr = jjlxr,@jjlxrmobile = jjlxrmobile,@ownerid = ownerid,@app_buid_guid = app_buid_guid,
			@usercardid = usercardid,@cellcode = cellcode,@cellid = cellid,@cardtype = cardtype,@memo = memo,@maxfkstr = isnull(nullif(maxfk,''),'-1')
		  from #tempyzdr
		  where [index] = @beginindex

		  select @ownerid = 0 ;

		  select @ownerid = isnull(ownerid,0) from zh_fc where cellid = @cellid
		

		  if(@ownerid = 0)
		     begin
			    --   set @message = '第'+convert(varchar(max),@beginindex)+'行業主不存在';
						 --RaisError(@message,16,1)  with log;
						 --return;


					insert into ZH_OWNER(code,NAME,SEX,LXDH,PWD,yzzt,cjr,cjsj,yzlx,yn_yhdk,lxdz,yzdzdw,yzdzds,yzdzjd,yzdzdq,jjlxrxm,jjlxrdh,email,memo) 
					select @cellname,@name,@sex,'+852'+@mobile, 'c4ca4238a0b923820dcc509a6f75849b','正常','admin',getdate(),'正式業主','否',@yzdzdy+@yzdzds+@yzdzjd+@yzdzdq,@yzdzdy,@yzdzds,@yzdzjd,@yzdzdq,@jjlxr,'+852'+@jjlxrmobile,@email,@memo
				
			
					select @ownerid = SCOPE_IDENTITY();

					insert into #yzcode
					select  @code

					insert into ZH_FC(ownerid,ownername,cellid,syzt,ynwxj,orderid)
					select @ownerid,@name,@cellid,'空閑','否',1
			 end
	
	
		  set @code = LTRIM(RTRIM(@code))

		  if(isnull(replace(@code,' ',''),'') = '')
		    begin
			    exec  sp_getMemeberCode @code output 

			end


		  set @memberid = 0
		  	  select @memberid = isnull(id,0) from zh_members where code = @code

		  set @beginindex = @beginindex +1;
		  
		  	if(@name = '' or @name is null)
				   begin
				      set @message = '第'+convert(varchar(max),@beginindex)+'行姓名不能為空';
						 RaisError(@message,16,1)  with log;
						 return;
				   end



		  if(@sex ='')
		     begin
			    set @sex = '男';
			 end

			if(@sex = 'M')
			  begin
			    set @sex = '男';
			  end 

			 else if(@sex = 'F')
			  begin
			    set @sex = '女';
			  end 


			  if(replace(isnull(@identity,''),' ','') = '' )
			    begin
				  set @identity = '業主';
				end 



			


	--	   if(@jtsf not in ('業主','住戶','租戶','管理處','清潔'))
	--	     begin
	--		     set @jtsf = '業主';
	--		 end

		   if(isnull(@cellid,0) = 0 )
		     begin
				set @message = '第'+convert(varchar(max),@beginindex)+'行['+convert(varchar(max),@cellname)+']房產不存在';
			     RaisError(@message,16,1)  with log;
				 return;
			 end


			 if(isnull(replace(@code,' ',''),'') = '')
			   begin
			      set @message = '第'+convert(varchar(max),@beginindex)+'行['+convert(varchar(max),@cellname)+']請輸入編號';
			     RaisError(@message,16,1)  with log;
				 return;
			   end



			 if(@IsDeleteCodeCanUse = 0)
			 /*刪除的編號可以複用*/
			    begin
					if((@memberid = 0 and (exists(select 1 from ZH_Members where code = @code ) or exists(select 1 from ZH_Owner where code = @code))) or ( @memberid != 0 and ( exists (select 1 from ZH_Members where code = @code and id != @memberid) or exists(select 1 from ZH_Owner where code = @code)) ))
					  begin
						   set @message = '第'+convert(varchar(max),@beginindex)+'行['+convert(varchar(max),@code)+']編號已存在';
						    RaisError(@message,16,1)  with log;
						    return;
					  end
				end
			else
				 /*刪除的編號不可以複用*/
			     begin
				 if((@memberid = 0 and exists(select 1 from ZH_Members where code = @code and isnull(deleted,0) = 0 )) or ( @memberid != 0 and ( exists (select 1 from ZH_Members where code = @code and isnull(deleted,0) = 0  and id != @memberid) or exists(select 1 from ZH_Owner where code = @code)) ))
					  begin
						 set @message = '第'+convert(varchar(max),@beginindex)+'行['+convert(varchar(max),@code)+']編號已存在';
						 RaisError(@message,16,1)  with log;
						 return;
					  end

			    end





			   if(ISNUMERIC(@maxfkstr)=0 and @maxfkvalue!='0')
			      begin
				       set @message = '第'+convert(varchar(max),@beginindex)+'行['+convert(varchar(max),@code)+']請輸入正確的最大發卡數量';
						 RaisError(@message,16,1)  with log;
						 return;
				      
				  end


			

		if(isnull(@mobile,'')!='')
		   begin
			 set @mobile = '+852'+@mobile;
		  end

		if(isnull(@jjlxrmobile,'') !='')
		  begin
		     set @jjlxrmobile = '+852'+@jjlxrmobile;
		  end 

	
		


		
		  declare @temp_app_bind_guid uniqueidentifier= cast(cast(0 as binary) as uniqueidentifier);

			select @temp_app_bind_guid = app_bind_guid from ZH_Members where id = @memberid


		


			-- if(exists(select 1 from BT_APP_BindOwner where zh_owner_id = @ownerid and app_bind_guid != @temp_app_bind_guid  and isnull(deleted,0) = 0 and bt_app_user_mobile=@mobile and isnull(bt_app_user_mobile,'')!='' ))
			--			  begin
			--			   --   set @message = '第'+convert(varchar(max),@beginindex)+'行['+convert(varchar(max),@lxdh)+']該手機號碼已經存在';
			--				  --RaisError(@message,16,1)  with log;
			--				  --return;
			--				  set @mobileerror =  @mobileerror+','+convert(varchar(max),@id);
			--				  continue;
			--end
		
		

			 --if(exists(select 1 from BT_col_CardManagement where col_CardID=@cardno and col_userid !=@memberid and isnull(col_CardID,'')!='') or exists(select 1 from BT_col_CardManagement where col_userid != @memberid and  kmbm=@cardno and isnull(kmbm,'')!=''))
				--		  begin
				--			 DELETE FROM BT_sys_FreeCard where sys_CardNO=@cardno;
				--			   set @message = '第'+convert(varchar(max),@beginindex)+'行['+convert(varchar(max),@cardno)+']此卡面編號已存在,请重新输入！';
				--			  RaisError( @message,16,1)  with log;
				--			 return;

				--			  select @carderror =  @carderror+','+convert(varchar(max),@id);
				--			   continue;
				--		  end

		
			  
	----		----房产信息

				declare @PMS_HasNoAPP int = 0;
				select @PMS_HasNoAPP = isnull(ParamValue,0) from BT_SystemParam where paramName = 'PMS_HasNoAPP'
				  


				declare @PMS_ISCompany int = 0;
				select @PMS_ISCompany = isnull(ParamValue,0) from BT_SystemParam where paramName = 'PMS_ISCompany'

               	declare @identityname int = 0 ;
		
					select top 1 @identityname = id from jtsf where name like '%'+@identity +'%'

					if(not exists(select 1 from jtsf where name like '%'+@identity+'%'))
					   begin
					        insert into jtsf(name)
							select @identity



							select @identityname = SCOPE_IDENTITY()
					   end
				

	--			--app绑定
				if(nullif(@mobile,'')!='' and @PMS_HasNoAPP=0)
				    begin

			         

					
					  declare @mobilenochange int = 0 ;


					  select @mobilenochange = 1 from BT_APP_BindOwner where zh_owner_id = @ownerid  and bt_app_user_mobile = @mobile and app_bind_guid = @temp_app_bind_guid
		           
					
					if(@mobilenochange = 0 and exists (select 1 from jtsf where ismanage = 1 and id = @identityname) )
					   begin
					  
					    if(exists(select 1 from BT_APP_BindOwner where zh_owner_id = @ownerid   and isnull(deleted,0) = 0 and bt_app_user_mobile=@mobile and isnull(bt_app_user_mobile,'')!='' ))
					    	 begin
							
							      update BT_APP_BindOwner set deleted = 1 where  zh_owner_id = @ownerid   and bt_app_user_mobile=@mobile
							  end 
							set @app_bind_guid = newid();

							if(charindex('業主',@identity) !=0)
								 begin
									declare @is_master int = 0;
									if(exists(select 1 from BT_APP_BindOwner where zh_owner_id = @ownerid and isnull(is_master,0) =1  and deleted = 0))
									   begin
										   set @is_master = 0;
									   end
									else 
									  begin
										   set @is_master = 1;
									  end
									 insert into BT_APP_BindOwner(app_bind_guid,zh_owner_id,bt_app_user_uid,bt_app_user_name,app_alias,is_master,bt_app_user_mobile,app_permission_type,bind_created_by_appuser,remark)
									 values(@app_bind_guid,@ownerid,cast(cast(0 as binary) as uniqueidentifier),'',@name,@is_master,@mobile,'1,2,3,4,5',0,'')
								end
							else 
								begin
									 insert into BT_APP_BindOwner(app_bind_guid,zh_owner_id,bt_app_user_uid,bt_app_user_name,app_alias,is_master,bt_app_user_mobile,app_permission_type,bind_created_by_appuser,remark)
									 values(@app_bind_guid,@ownerid,cast(cast(0 as binary) as uniqueidentifier),'',@name,0,@mobile,'2,3,4,5',0,'')
								end
						end
					/*不是管理員*/
					else if(not exists (select 1 from jtsf where ismanage = 1 and id = @identityname))
					    begin
						        if(exists(select 1 from BT_APP_BindOwner where zh_owner_id = @ownerid   and isnull(deleted,0) = 0 and bt_app_user_mobile=@mobile and isnull(bt_app_user_mobile,'')!='' ))
					    		 begin
							
									  update BT_APP_BindOwner set deleted = 1 where  zh_owner_id = @ownerid   and bt_app_user_mobile=@mobile
								  end 
								set   @app_bind_guid = cast(cast(0 as binary) as uniqueidentifier);
						    
						end
					 else 
					    begin

						    set @app_bind_guid=@temp_app_bind_guid;
						end
					end
				  else 
				    begin
					
					   set @app_bind_guid=@temp_app_bind_guid;

					end


				
	

				
					declare @feestatus int = 0,@feevalue int = 0;
					if(charindex('免費',@feetype)!=0)
					  begin
					     set @feestatus = 0;
					  end
					else
					  begin
					    set @feestatus = 1;
						set @feevalue =dbo.GET_NUMBER( @feetype);
					  end 


					  declare @zjstatusid int = 1;

					  if(@zjstatus ='')
					    begin 
						   set @zjstatusid = 1
						end
						else
						 begin
						   select @zjstatusid = isnull(id,1) from zjstatus where name like '%'+@zjstatus+'%'
						 end
		

					 declare @alias  varchar(max) = '';

					 if(@PMS_ISCompany != 1)
						begin
						    set @alias = @name
						end
					else
					    begin

							select @alias = qy_qc from QY
						end

					 if(isnull(@memberid,0) = 0 )
					   begin
							insert into ZH_MEMBERS(ownerid,name,sex,lxdh,memo,jtsf,usercardid,app_bind_guid,alias,code,col_cardNo,whatapps,jjlxr,jjlxrmobile,enname,PWD,Authorizer,AuthorizedPerson,AuthorizedFrom,AuthorizedEnd)
							values(@ownerid, @name, @sex, @mobile, @memo,@identityname,0,@app_bind_guid,@alias,@code,@cardno,@whatsapps,@jjlxr,@jjlxrmobile,@enname, 'c4ca4238a0b923820dcc509a6f75849b',@Authorizer,@Authorized_Person,case when @Authorized_from is null then null else @Authorized_from end,case when @Authorized_until is null then null else @Authorized_until end)

							set @memberid = scope_identity();
							set @insertcount = @insertcount + 1;

					  end 
					  else
					   begin
					      update ZH_MEMBERS  set ownerid = @ownerid,
						                       name = @name,
											   sex = @sex,
											   lxdh = @mobile,
											    jtsf = @identityname,
												app_bind_guid = @app_bind_guid,
												alias = @alias,
												col_cardNo = @cardno,
												whatapps = @whatsapps,
												jjlxr = @jjlxr,
												jjlxrmobile = @jjlxrmobile,
												enname = @enname,
												memo = @memo,
												Authorizer = @Authorizer,
												AuthorizedPerson = @Authorized_Person,
												AuthorizedFrom = case when @Authorized_from is null then null else @Authorized_from end,
												AuthorizedEnd = case when @Authorized_until is null then null else @Authorized_until end,
												deleted = 0	

						  where id = @memberid


						  
							if(@memo !='')
							    begin
										 update ZH_MEMBERS   set memo = @memo   where id = @memberid
								end


						  set @updatecount = @updatecount + 1;

					   end 


					   if(exists(select 1 from 	 #yzcode where yzcode = @code))
					     begin

						          update ZH_MEMBERS  set nodeleted = 1 where  id = @memberid
						 end
		


					/*最大發卡數量*/
					if(@maxfkstr != -1)
					   begin
							update FC_Cell set maxfk = @maxfkstr where cellid = @cellid
					  end
					--declare @ismulti_card int = 0;
				 --  select @ismulti_card = paramvalue from BT_SystemParam where paramname = 'PMS_ZH_Members_multi-Card'

				  -- if(@ismulti_card = 1	)
				  --  begin
						--insert into #tempcaridid
						--select col  from 
						--	dbo.fn_split_ToTable(@cardno,',')
						--	where isnull(col,'') !=''
					 --end
					 --else
					 --begin

					 if(isnull(replace(@cardno,' ',''),'')!='')
					   begin
							insert into #tempcaridid
							select @cardno,case when @cardtype = '八達通' then 12 else 0 end

					   end
					 --end


					  --  declare @deletecardid int = 0
						 --  insert into #oldcard
						 --  select col_id from BT_col_CardManagement where col_userid = @memberid
						 --  and col_cardid not in (
							--		select col from  #tempcaridid
						
						 --  ) and col_cardtype = 0


				   --	   while(exists(select 1 from #oldcard))
							--begin 
							--  select top 1 @deletecardid = col_id from #oldcard

							--   insert into #tempid
							--   Exec DeleteUserCard @deletecardid
							--	delete from #oldcard where	col_id = @deletecardid			      
							--end


					 
		

					
				   
				     
						   declare @tempcardno varchar(max);

						   declare  @tempstarttime varchar(max) =isnull(iif(@starttime='',getdate(),@starttime),getdate()) ;
						   declare @tempendttime varchar(max) = isnull(iif(isnull(@endttime,'')='',dateadd(year,100,getdate()),@endttime),dateadd(year,100,getdate()));
						   declare @tempcolstate varchar(max) = isnull(iif(isnull(@endttime,'')='',1,iif(@endttime<=getdate(),0,1)),1)
						   declare @qrocdecardid varchar(max) = '';
						

							declare @col_cardtype int = 11;  --第一个为二維碼
							declare @tempcol_type int = 0;

							  while(exists(select 1 from #tempcaridid))
							   begin
							    
							    select top 1 @tempcardno = col,@tempcol_type = col_type from #tempcaridid
							    declare @isnotchange int = 0 ;
							
							     select @isnotchange = 1 from BT_col_CardManagement where col_cardid = @tempcardno and convert(varchar(max),col_DateStart,120) = @tempstarttime and convert(varchar(max),col_DateEnd,120) = @tempendttime and col_State = @tempcolstate and col_CardName = @name and col_userid = @memberid and convert(varchar(max),col_CreateTime,120) = iif(@inserttime='',getdate(),@inserttime)
					             if(@isnotchange =0)
								  begin
									
									 if(exists(select 1 from BT_col_CardManagement where col_CardID=@tempcardno and col_userid != @memberid))
									   begin
										  --DELETE FROM BT_sys_FreeCard where sys_CardNO=@tempcardno;
										  --set @message = '儲存失敗,此卡號'+@tempcardno+'已存在,請重新輸入！';
											 -- RaisError(@message ,16,1)  with log;
											 --return;
											 update BT_col_CardManagement set col_UserID = @memberid where col_CardID=@tempcardno
											 
									   end 
								


										if(@col_cardtype = 11)
										   begin
										      set @qrocdecardid = @tempcardno;
										   end

										   set @col_cardtype = @tempcol_type ;
								      

									    if(exists(select 1 from BT_col_CardManagement where col_CardID=@tempcardno and col_Userid = @memberid))
									      begin

										    update BT_col_CardManagement set col_DateStart = @tempstarttime,col_DateEnd = @tempendttime,col_State= @tempcolstate,col_FCCellID=@cellid,col_CardName=@alias,col_Leave_Reason=@col_leave_reason,col_cardtype=@col_cardtype,col_OwnerID = @ownerid,col_card_fee = iif(@feestatus=0,0,@feevalue),col_card_status = @zjstatusid,col_CreateTime=iif(@inserttime='',getdate(),@inserttime)
											where col_Userid = @memberid and   col_cardid = @tempcardno

											select @usercardid = col_id from BT_col_CardManagement where col_CardID=@tempcardno  and col_Userid = @memberid
										  end 
										  else
										   begin
											  insert into BT_col_CardManagement(col_cardid,col_DateStart,col_DateEnd,col_State,col_UserID,col_FCCellID,col_CardName,col_Remark,col_CreateTime,col_Leave_Reason,col_cardtype,col_OwnerID,col_card_fee,col_card_status) 
											   values(@tempcardno,@tempstarttime ,@tempendttime, @tempcolstate, @memberid,@cellid,@alias,'',iif(@inserttime='',getdate(),@inserttime),@col_leave_reason,@col_cardtype,@ownerid, iif(@feestatus=0,0,@feevalue),  @zjstatusid)

											   select @usercardid = SCOPE_IDENTITY();
										   end


										   if(not exists ( select 1 from BT_col_CardManagement_fccell where cardid = @usercardid and cellid = @cellid))
										     begin
											     insert into BT_col_CardManagement_fccell(cardid,cellid)
												 select @usercardid,@cellid
											 end
									

										  DELETE FROM BT_sys_FreeCard where sys_CardNO=@tempcardno
			  
										  insert into #tempid
										  exec SaveUserCardInfoForReader @memberid,@tempcardno,0,1

									  
		                        end
								 --select @tempcardno
								 delete from #tempcaridid where col=@tempcardno
							  end


                       if(exists(select 1 from zh_members where id= @memberid and col_qrcodeno is null ))
					      begin
							update zh_members set col_qrcodeno = @qrocdecardid   where  id= @memberid
						  end



					   declare @cardnum int = 0,@maxfk int = 0;
					   select @cardnum  = count(1) from BT_col_CardManagement where col_FCCellID = @cellid and col_state = 1 

					   select @maxfk = maxfk from fc_cell where cellid = @cellid

					   if(@cardnum > @maxfk and @maxfkvalue != '0')
					      begin
						       set @message = '儲存失敗已超出該戶'+@cellname+'的最大發卡數量'+convert(varchar(max),@maxfk);
							    RaisError( @message,16,1)  with log;
								return;
						  end

						  if(not exists(select 1 from #tempcaridid))
						     begin

							     --沒有插入默認值

								 delete from zh_member_carddefault where col_userid = @memberid
								 insert into zh_member_carddefault(col_userid,col_cardtype,col_datestart,col_dateend,col_state,col_leave_reason,col_card_status,col_card_fee,col_CreateTime)
								 select @memberid,case when @cardtype = '八達通' then 12 else 0 end,@tempstarttime,@tempendttime,@tempcolstate,@col_leave_reason,@zjstatusid,iif(@feestatus=0,0,@feevalue),iif(@inserttime='',getdate(),@inserttime)
							 end




						if(isnull(@memberid,0)>0)  --Jason 20210420 保存时如果之前没有加门禁权限则自动赋予楼宇门禁权限
							begin

							 --  delete from BT_IsExistsUserReaderAccess where sys_MemberID = @memberid

								--delete from tb_DoorGroup_UserReaderAccess_JTCY where  sys_MemberID = @memberid

							    insert into #tempid
								exec SP_UserReaderAccess_Save @memberid
							end

	--				--insert into  #tempid
	--				--  exec SP_BindOwner_CopyReaderAccess4QRCodeScan @ownerid,@memeberid
	       
	--				 set @insertcount= @insertcount +1;


               end
				
				--insert into  #tempid
				--	Exec SaveUserReaderAccessByCellID @memberid,@cellid,1;

	         	 declare @count int ;
	
			  select @count = count(1) from ZH_Members where ownerid = @ownerid and deleted = 0



			   if(@count>=@MaxMembeNum)
				begin
					declare @messages varchar(max);
					set @messages  =  ''+@cellname+'最多只能添加'+convert(varchar(max),@MaxMembeNum)+'個成員！';
					 RaisError( @messages,16,1)  with log;
					 return;
				end 




		end try

	begin catch
	 
		--if(@@TRANCOUNT >0) 
		--  begin
		     rollback transaction;
			  select '保存失敗,'+ERROR_MESSAGE(); 
			  
		  --end
	end catch
	 if(@@TRANCOUNT >0)  
	     begin
		  
		  declare @successmessage varchar(max)='保存成功,新增'+convert(varchar(max),@insertcount)+'條記錄,修改'+convert(varchar(max),@updatecount)+ '條記錄';
		  if(@mobileerror!='')
		    begin
			 set @successmessage = @successmessage +  ',第'+ SUBSTRING(@mobileerror,2,len(@mobileerror))+'行手機號碼已經存在';
			end

		 if(@carderror!='')
		    begin
			 set @successmessage = @successmessage +  ',第'+substring(@carderror,2,len(@carderror))+'行卡面編號已經存在';
			end

		select @successmessage;
			  commit transaction;
		end
END

