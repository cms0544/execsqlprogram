if(exists(select 1 from sysobjects where id = object_id('sp_SaveMember')))
  begin
     drop PROCEDURE [dbo].[sp_SaveMember]
  end
/****** Object:  StoredProcedure [dbo].[sp_SaveMember]    Script Date: 2021/7/26 17:45:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Mason>
-- Create date: <2019-10-17,,>
-- Description:	<Description,, sp_SaveMember '','1222','test1','男','業主','','test1','12312312','12312312','','',1,'2021-03-24 00:00:00','2121-03-24 00:00:00','',1,0,'1,2,3,4,5,6',27,1093,'00000000-0000-0000-0000-000000000000',0,99999,1,0,'',0,0,0,''>
-- =============================================
create PROCEDURE [dbo].[sp_SaveMember]
	-- Add the parameters for the stored procedure here
	@savemess     varchar(max),          --图片
	@code varchar(max),
	@name varchar(max),   --成员姓名
	@sex varchar(max),   --性别
	@jtsf varchar(max),  --成员身份
	@remark varchar(max),   -- 备注 
	@alias varchar(max),   --显示名

	@qrcodeno varchar(max), --二维码
	@mobile varchar(max),    --手机号码

	@is_master  int,                  --app账户类型
	@isDisabled int,                  --app是否禁用

	@PermissionType varchar(max),     --app账号权限
	@ownerid int,                      --业主id
	@id int,                          --成员id
	@app_bind_guid uniqueidentifier,   --appid
	@usercardid    int,                 --卡id

	@MaxMembeNum   int  = 9999,            --家庭成員限制
	@PMS_IsDoor int = 1,                   --是否具有門禁功能
	@PMS_IsPark int = 1,                    --是否具有停車場功能
	@whatapps varchar(max)='',                --whatapps
	@jjlxr varchar(max) = '',                   --紧急联系人
	@jjlxrmobile varchar(max) = '',              --緊急聯繫人電話
	@enname varchar(max) = '',                    --英文姓名
	@cardstr varchar(max) = '',
	@defaultcardstr varchar(max) ='',              --默認卡號
	@authorizer varchar(max) = '',
	@authorizedperson varchar(max)='',
	@authorizedfrom varchar(max) = '',
	@authorizedend varchar(max)=''
AS
BEGIN


   	begin transaction 
		begin try

		set @code = LTRIM(RTRIM(@code))

		declare @type int = 0;
		declare @message varchar(max);
		declare @ishasnoapp int = 0 ;
		declare @cellid int;
		declare @colcellid varchar(max);
		declare @maxfk int = 0;
		declare @begincellindex int = 0;
		declare @endcellindex int = 0;
		
		declare @isexistkmbm bit = 0;
		declare @updateoctopusno varchar(max);
		declare @cardno varchar(max);
		declare @insertcount int = 0;
		declare @col_id int = 0;
		declare @col_card_status int = 0;
		declare @col_card_fee decimal(18,2);
		declare @cardid varchar(max) = '',@cardStartDate datetime,@cardEndDate datetime,@cardkmbm varchar(max),@disabledreason varchar (max),@cardState int;
		declare @colcreateTime datetime;
		declare @cellname nvarchar(max);
		declare @errcellname nvarchar(max);
		declare @IsDeleteCodeCanUse nvarchar(max);
		
		
		select @IsDeleteCodeCanUse = ParamValue  from BT_SystemParam where  ParamName = 'PMS_IsDeleteCodeCanUse'

		select @ishasnoapp = isnull(ParamValue,0) from BT_SystemParam where  ParamName = 'PMS_HasNoAPP'




		declare @maxfkvalue  varchar(max)= '0';
		select @maxfkvalue = isnull(ParamValue,0) from BT_SystemParam where  ParamName = 'PMS_limitMaxFK'
			 

		if(isnull(@authorizedfrom,'') !='')
		   begin
		      set @authorizedfrom = convert(varchar(10),CONVERT(datetime,@authorizedfrom, 103),120)
		   end
		else 
		   begin
		      set @authorizedfrom = null
		   end
	

		if(isnull(@authorizedend,'') !='')
		   begin
		      set @authorizedend = convert(varchar(10),CONVERT(datetime,@authorizedend, 103),120)
		   end
		else 
		   begin
		      set @authorizedend = null;
		   end

	create table #tempmessage
	(
		tempmessage varchar(max)
	)



	--if(@PMS_IsDoor!=0  and isnull(@cardStartDate,'') = '')
	--   begin
	--     RaisError( '請選擇開始日期！',16,1)  with log;
	--	 return;
	--   end

	--if(@PMS_IsDoor!=0  and isnull(@cardEndDate,'') = '')
	--   begin
	--      RaisError( '請選擇結束日期！',16,1)  with log;
	--	 return;
	--   end


	--if(@PMS_IsDoor!=0  and isnull(@cardid,'')!='' and isnull(@cardkmbm,'')='')
	--  begin
	--      RaisError( '請输入卡面編碼！',16,1)  with log;
	--	 return;

	--  end

	 --if(@PMS_IsDoor!=0  and isnull(@cardstr,'')='' )
	 -- begin
	 --     RaisError( '請输入卡號！',16,1)  with log;
		-- return;
	 -- end


	  if(@name = '')
		begin
		      RaisError('請輸入成員姓名！',16,1)  with log;
					return;
		end

		if(@PMS_IsDoor!=0  and @alias = '')
		begin
		      RaisError('請輸入顯示名！',16,1)  with log;
					return;
		end


		if(@code = '')
		  begin
		      RaisError('請輸入編號！',16,1)  with log;
					return;
		  end


	   --if(@PMS_IsDoor!=0  and ISNUMERIC(@cardid)=0)
			 --     begin
				--      RaisError('請輸入正确的卡號！',16,1)  with log;
				--	return;
				--  end 
	

	
		select 
		dbo.[GetSplitOfIndex](col,'@@',1) as col_id,
		dbo.[GetSplitOfIndex](col,'@@',2) as col_cardid,
		dbo.[GetSplitOfIndex](col,'@@',3) as kmbm,
		dbo.[GetSplitOfIndex](col,'@@',4) as col_cardtype,
		dbo.[GetSplitOfIndex](col,'@@',5) as col_state,
		dbo.[GetSplitOfIndex](col,'@@',6) as col_leave_reason,
		convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',7), 103),120)  as  col_datestart,
		convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',8), 103),120)  as col_dateend,
		dbo.[GetSplitOfIndex](col,'@@',9) as col_card_status,
		dbo.[GetSplitOfIndex](col,'@@',10) as col_card_fee,
		dbo.[GetSplitOfIndex](col,'@@',11) as col_fccellid,
		convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',12), 103),120) as col_createtime
		into #tempcard
		from dbo.fn_split(@cardstr,'##')


		--select distinct col_fccellid into #cellid from #tempcard 
		

		select row_number() over (order by  zfid) as rowindex , CELLID into #tempcellid from ZH_Fc where OWNERID = @ownerid
		--select row_number() over (order by  col_fccellid) as rowindex , col_fccellid as cellid into #tempcellid from #cellid
		




		/*卡号的门禁全选默认用所属房号第一个门禁权限*/
		select @cellid = cellid from #tempcellid where rowindex = 1
				  

		--select col into #tempcaridid from 
		--dbo.fn_split_ToTable(@cardid,',')
		--where isnull(col,'') !=''


		--select col into #tempOctopusno from 
		--dbo.fn_split_ToTable(@octopusno,',')
		--where isnull(col,'') !=''


		
	  declare @count int ;

	  select @count = count(1) from ZH_Members where ownerid = @ownerid and deleted = 0


	 


	if(isnull(@id,0)=0)
	   begin
	     --新增
	      if(@count>=@MaxMembeNum)
		    begin
				
				set @message  =  '儲存失敗,最多只能添加'+convert(varchar(max),@MaxMembeNum)+'個成員！';
				 RaisError( @message,16,1)  with log;
				 return;
			end 
		  --if(exists(select 1 from BT_col_CardManagement where kmbm=@cardkmbm and kmbm!=''))
		  --    begin
			 --    DELETE FROM BT_sys_FreeCard where sys_CardNO=@cardid;
				--  RaisError( '儲存失敗,此卡號已存在,请重新输入！',16,1)  with log;
				-- return;
			 -- end

			

		   if(exists(select 1 from BT_APP_BindOwner where zh_owner_id = @ownerid  and isnull(deleted,0) = 0 and bt_app_user_mobile=@mobile ))
		      begin
			      RaisError('該手機號碼已經存在',16,1)  with log;
				  return;
			  end

			 if(@IsDeleteCodeCanUse = 0)
			    begin
					if(exists(select 1 from ZH_Members where code = @code  ) or exists ( select 1 from ZH_Owner where code = @code ))
					  begin
						  RaisError('該編碼已經存在',16,1)  with log;
						  return;
					  end
				end
			else
			     begin
						if(exists(select 1 from ZH_Members where code = @code and isnull(deleted,0) = 0 ) or exists ( select 1 from ZH_Owner where code = @code ))
					  begin
						  RaisError('該編碼已經存在',16,1)  with log;
						  return;
					  end

			    end


			if(isnull(@mobile,'')!='' and @ishasnoapp = 0 and exists(select 1 from jtsf where isnull(ismanage,0) = 1 and id = @jtsf))   --只有管理員才綁定APP
			   begin

			   
			   	set @app_bind_guid  = newid() ;

				 if(isnull(@is_master,0)=1)
				    begin
					     if(exists(select 1 from BT_APP_BindOwner where is_master =1 and zh_owner_id = @ownerid  and deleted = 0))
						    begin
							       RaisError('只能有1個主賬號！',16,1)  with log;
									 return;
							end
					end
				
			      insert into BT_APP_BindOwner(app_bind_guid,zh_owner_id,bt_app_user_uid,bt_app_user_name,app_alias,is_master,bt_app_user_mobile,app_permission_type,bind_created_by_appuser,remark)
				  values(@app_bind_guid,@ownerid,cast(cast(0 as binary) as uniqueidentifier),'',@alias,@is_master,@mobile,@PermissionType,0,@remark)
			   end
			else
			   begin

			      set @app_bind_guid = cast(cast(0 as binary) as uniqueidentifier)
			   end




			insert into ZH_MEMBERS(ownerid,name,sex,lxdh,memo,zpurl,jtsf,usercardid,app_bind_guid,alias,CODE,col_cardNo,col_QrcodeNo,kmbm,whatapps,jjlxr,jjlxrmobile,enname,pwd,authorizer,authorizedperson,authorizedfrom,authorizedend)
			values(@ownerid, @name, @sex, @mobile, @remark,iif(@savemess='no','',@savemess),@jtsf,@usercardid,@app_bind_guid,@alias,@code,@cardid,@qrcodeno,@cardkmbm,@whatapps,@jjlxr,@jjlxrmobile,@enname,'c4ca4238a0b923820dcc509a6f75849b',@authorizer,@authorizedperson,@authorizedfrom,@authorizedend)
		
			set @id = scope_identity();


			if(isnull(@cardstr,'')!='')
			   begin
							 
					while(exists(select 1 from #tempcard))
					 begin
						select top 1 @cardno = col_cardid,@cardStartDate = col_datestart,@cardState = col_state,@cardEndDate=col_dateend,@colcellid = col_fccellid,@cardkmbm=iif(kmbm='null','',kmbm),@type = col_cardtype,@disabledreason=col_leave_reason,@col_card_fee=col_card_fee,@col_card_status=col_card_status,@colcreateTime=col_createtime from #tempcard
						 if(exists(select 1 from BT_col_CardManagement where col_State = 1 and col_CardID=@cardno))
						   begin
							  DELETE FROM BT_sys_FreeCard where sys_CardNO=@cardno;

							  select @errcellname = a.simplecellname
							  from VI_col_CardManagement as a 
							  where a.col_CardID = @cardno and a.col_State = 1
							  set @message = '儲存失敗,此卡號'''+@cardno+'''已錄入在'''+@errcellname+''',請重新輸入！';
								  RaisError(@message ,16,1)  with log;
								 return;
						   end 

							  --if(@cardno = @qrcodeno )
							  --  begin
							  --     set @type = 11
							  --  end

						      insert into BT_col_CardManagement(col_CardID,col_DateStart,col_DateEnd,col_State,col_UserID,col_FCCellID,col_CardName,col_Remark,col_CreateTime,kmbm,col_CardType,col_Leave_Reason,col_card_fee,col_card_status,col_ownerid) 
							  values(@cardno,  @cardStartDate ,@cardEndDate, @cardState,@id,@cellid,@alias,@remark,@colcreateTime,@cardkmbm,@type,@disabledreason,@col_card_fee,@col_card_status,@ownerid)
							  set @usercardid = SCOPE_IDENTITY();


							  /*卡所屬住戶,給限制卡號數量和報表標記用*/
							  insert into BT_col_CardManagement_FCCELL(cardid,cellid)
							  select @usercardid,col
							 from dbo.fn_split_ToTable(@colcellid,',')
							 /**/
				  
							  DELETE FROM BT_sys_FreeCard where sys_CardNO=@cardno
				  
							
							   insert into #tempmessage
							  exec SaveUserCardInfoForReader @id,@cardno,0,1

							  if(@savemess !='' and @savemess !='no')
							     begin
								   insert into #tempmessage
								    exec SaveUserFacePath @code,@cardno,@savemess
								 end

								if(@savemess = 'no')
								   begin
								    insert into #tempmessage
								    exec SaveUserFacePath @code,@cardno,''

								   end

						if(@cardkmbm!='')
						   begin
							if(not exists(select 1 from bt_cardrelate where cardno = @cardno or kmbm = @cardkmbm))
								 begin
									   insert into bt_cardrelate(cardno,kmbm)
									   values(@cardno,@cardkmbm)
								 end
							  else if(exists(select 1 from bt_cardrelate where cardno = @cardno and kmbm!=@cardkmbm))
								begin
									 update bt_cardrelate set kmbm = @cardkmbm where cardno =@cardno
								end
							  else if(exists(select 1 from bt_cardrelate where cardno != @cardno and kmbm=@cardkmbm))
								 begin
									  update bt_cardrelate set cardno =@cardno where kmbm =@cardkmbm
								 end
							 end


						   delete from #tempcard where col_cardid=@cardno
			       
					 end
			   end
			 

			


			  
			 if(isnull(@cardstr,'') ='')
			   begin

							 delete from zh_member_carddefault where col_userid = @id
								 insert into zh_member_carddefault(col_userid,col_cardtype,col_state,col_leave_reason,col_datestart,col_dateend,col_card_status,col_card_fee,col_fccellid,col_createTime)
								select @id,dbo.[GetSplitOfIndex](col,'@@',1) as col_cardtype,
								dbo.[GetSplitOfIndex](col,'@@',2) as col_state,
								dbo.[GetSplitOfIndex](col,'@@',3) as col_leave_reason,
								convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',4), 103),120)  as  col_datestart,
								convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',5), 103),120)  as col_dateend,
								dbo.[GetSplitOfIndex](col,'@@',6) as col_card_status,
								dbo.[GetSplitOfIndex](col,'@@',7) as col_card_fee,
								dbo.[GetSplitOfIndex](col,'@@',8) as col_fccellid,
								convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',9), 103),120) as col_creattime
								from dbo.fn_split(@defaultcardstr,'##')
								where isnull(col,'')!=''


			   end

			  

			--insert into #tempmessage
		 --  exec SP_BindOwner_CopyReaderAccess4QRCodeScan @ownerid,@id

		 
			  	--insert into  #tempid
					--Exec SaveUserReaderAccessByCellID @id,@cellid,1;
	   end
	 else
	   begin
	  
		   --if(exists(select 1 from BT_col_CardManagement where col_CardID=@cardid and col_id<>@usercardid))
		   --   begin
			  --   DELETE FROM BT_sys_FreeCard where sys_CardNO=@cardid;
				 -- RaisError('儲存失敗,此卡號已存在,请重新输入！',16,1)  with log;
				 --return;
			  --end

			  declare @tempmess  varchar(max) ='';
			  select @tempmess = zpurl from ZH_Members where id = @id
			   
				
			  declare @tempbt_app_user_uid uniqueidentifier,@tempbindcreate_by_qrcode int,@tempbt_app_user_mobile varchar(max);

			  select @tempbt_app_user_uid = bt_app_user_uid,@tempbindcreate_by_qrcode = convert(int,isnull(bind_created_by_qrcode,0)) ,@tempbt_app_user_mobile = bt_app_user_mobile from BT_APP_BindOwner  where app_bind_guid=@app_bind_guid

			  if(@ishasnoapp = 0)
			     begin
					if(isnull(@app_bind_guid,cast(cast(0 as binary) as uniqueidentifier)) = cast(cast(0 as binary) as uniqueidentifier) and  exists(select 1 from jtsf where isnull(ismanage,0) = 1 and id = @jtsf))
					   begin

					    
						   --app绑定不存在 新增
							if(isnull(@mobile,'') != '')
							   begin

					      			if(isnull(@is_master,0)=1)
									begin
										 if(exists(select 1 from BT_APP_BindOwner where is_master =1 and zh_owner_id = @ownerid  and deleted = 0))
											begin
												   RaisError('只能有1個主賬號！',16,1)  with log;
													 return;
											end
									end

								   set @app_bind_guid  = newid() ;
								  insert into BT_APP_BindOwner(app_bind_guid,zh_owner_id,bt_app_user_uid,bt_app_user_name,app_alias,is_master,bt_app_user_mobile,app_permission_type,bind_created_by_appuser,remark)
								  values(@app_bind_guid,@ownerid,cast(cast(0 as binary) as uniqueidentifier),'',@alias,@is_master,@mobile,@PermissionType,0,@remark)
			  
							end
					   end

					else
						begin
					   if(isnull(@app_bind_guid,cast(cast(0 as binary) as uniqueidentifier)) != cast(cast(0 as binary) as uniqueidentifier))
					      begin
								 update BT_APP_BindOwner set deleted = 1 where app_bind_guid=@app_bind_guid
						  end
						if(isnull(@mobile,'') = '')
							begin
								  set @app_bind_guid = cast(cast(0 as binary) as uniqueidentifier)
								
							  end
							else if(exists(select 1 from jtsf where isnull(ismanage,0) = 1 and id = @jtsf))
							   begin 
					    --  			if(isnull(@is_master,0)=1)
									--begin
									--	 --if(exists(select 1 from BT_APP_BindOwner where is_master =1 and zh_owner_id = @ownerid  and deleted = 0))
									--		--begin
									--		--  set @message = '只能有1個主賬號！'+convert(varchar(max),@app_bind_guid);
									--		--	   RaisError(@message,16,1)  with log;
									--		--		 return;
									--		--end
									--end

							   	   set @app_bind_guid = newid();
					  
								   insert into BT_APP_BindOwner(app_bind_guid,zh_owner_id,bt_app_user_uid,bt_app_user_name,app_alias,is_master,bt_app_user_mobile,app_permission_type,bind_created_by_appuser,remark,[disabled])
								  values(@app_bind_guid,@ownerid,cast(cast(0 as binary) as uniqueidentifier),'',@alias,@is_master,@mobile,@PermissionType,0,@remark,@isdisabled)
							   end
							else
							  begin

							      set @app_bind_guid = cast(cast(0 as binary) as uniqueidentifier)
							  end


						end
				  end

			  else
				begin

					    set @app_bind_guid = cast(cast(0 as binary) as uniqueidentifier)
					end
				

				
			  if(@savemess = '')
			  begin

				 select @savemess = isnull(zpurl,'') from ZH_Members where id =@id
			  end

			  	  --or exists ( select 1 from ZH_Owner where code = @code)
			    if(exists(select 1 from ZH_Members where code = @code and isnull(deleted,0) = 0 and id !=@id  ))
		      begin
			      RaisError('該編碼已經存在',16,1)  with log;
				  return;
			  end

	

					  --if(isnull(@cardid,'') = '' or isnull(@octopusno,'')='')
					  --    begin
							-- while(exists(select 1 from #oldcard))
							--  begin 
							--	  select top 1 @deletecardid = col_id from #oldcard
							--	   insert into #tempmessage
							--	   Exec DeleteUserCard @deletecardid
							--		delete from #oldcard where	col_id = @deletecardid			      
							--  end

					  --  end

                declare @oldsavemess varchar(max) = '';

			  select @oldsavemess = zpurl from ZH_Members where id = @id;

			  

				update ZH_MEMBERS set name =@name,sex=@sex,lxdh=@mobile,memo=@remark,zpurl =iif(isnull(@savemess,'')='',@oldsavemess,iif(@savemess='no','',@savemess)),jtsf = @jtsf,alias=@alias,app_bind_guid = @app_bind_guid,col_cardNo = @cardid,col_QrcodeNo = @qrcodeNo,code=@code,kmbm=@cardkmbm
				,whatapps = @whatapps,jjlxr=@jjlxr,jjlxrmobile=@jjlxrmobile,enname=@enname,authorizer= @authorizer,authorizedperson=@authorizedperson,authorizedfrom=@authorizedfrom,authorizedend=@authorizedend
				 where id = @id
						 

				
								 
					  declare @deletecardid int = 0
					   select col_id into #oldcard from BT_col_CardManagement where col_userid = @id
					   and col_cardid not in (
							select col_cardid from #tempcard
					   ) and col_id not in ( 
					       select col_ID from #tempcard
					    )
		

					   /*删除卡號*/
						while(exists(select 1 from #oldcard))
						  begin 
							  select top 1 @deletecardid = col_id from #oldcard

							   insert into #tempmessage
							   Exec DeleteUserCard @deletecardid
								delete from #oldcard where	col_id = @deletecardid			      
						  end

			     
		
			 

				  select sys_ReaderID  into #BT_sys_UserReaderAccess_JTCY from BT_sys_UserReaderAccess_JTCY where sys_memberid = @id

				  if(exists (select 1 from #BT_sys_UserReaderAccess_JTCY))
				    begin
					      select @code as code,col_cardid,b.sys_ReaderID
						   into #tempupdatecard
						  from #tempcard
						  left join #BT_sys_UserReaderAccess_JTCY as b on 1=1
						  where isnull(b.sys_ReaderID,0)!=0 and not exists(select 1 from BT_sys_UserReaderAccess where sys_UserCode = @code and sys_cardno = col_cardid and sys_readerid = b.sys_ReaderID)


						  insert into BT_sys_UserReaderAccess(sys_UserCode,sys_CardNo,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange)
						  select code,col_cardid,sys_ReaderID,255,2,1
						  from #tempupdatecard


						  
						  declare @tempupdatecardid varchar(max) = '';
						  while(exists(select 1 from #tempupdatecard))
							begin
							   select top 1 @tempupdatecardid = col_cardid from #tempupdatecard
							   insert into #tempmessage
							   Exec SaveUserReaderAccessByUserCard @code,@tempupdatecardid

							   delete from #tempupdatecard where col_cardid = @tempupdatecardid
							end

					end
				 

				  --where sys_ReaderID is not null

				  --where not exists(select 1 from BT_sys_UserReaderAccess where sys_UserCode = @code and sys_cardno = col and sys_readerid = b.sys_ReaderID)

			

			   if(isnull(@cardstr,'')!='')
				    begin
					       while(exists(select 1 from #tempcard))
							   begin
									select top 1 @col_id = col_id,@cardno = col_cardid,@cardStartDate=col_datestart,@cardEndDate = col_dateend,@cardState=col_state,@colcellid = col_fccellid,@cardkmbm= iif(kmbm='null','',kmbm),@type= col_cardtype,@disabledreason =col_leave_reason,@col_card_fee=col_card_fee,@col_card_status=col_card_status,@colcreateTime = col_createtime from #tempcard
									

											 if(exists(select 1 from BT_col_CardManagement where col_state= 1 and col_CardID=@cardno and col_userid != @id))
											   begin
											 
												  DELETE FROM BT_sys_FreeCard where sys_CardNO=@cardno;
												 
												  select @errcellname = a.simplecellname
												  from VI_col_CardManagement as a 
												  where a.col_CardID = @cardno and a.col_State = 1
												  set @message = '儲存失敗,此卡號'''+@cardno+'''已錄入在'''+@errcellname+''',請重新輸入！';
													  RaisError(@message ,16,1)  with log;
													 return;
											   end 



												--if(@cardno = @qrcodeno )
												--  begin
												--     set @type = 11
												--  end
												if(@col_id!=0)
												   begin
												       update BT_col_CardManagement set col_cardid= @cardno,col_DateStart = @cardStartDate,col_DateEnd= @cardEndDate,col_State = isnull(@cardState,1),col_FCCellID=@cellid,col_CardName=@alias,col_Remark=@remark,kmbm =@cardkmbm ,col_CardType=@type,col_Leave_Reason=@disabledreason,col_card_fee=@col_card_fee,col_card_status=@col_card_status,col_OwnerID = @ownerid,col_CreateTime=@colcreateTime
													   where col_id = @col_id

													    select @usercardid = @col_id
												   end
												else 
												   begin
													  insert into BT_col_CardManagement(col_CardID,col_DateStart,col_DateEnd,col_State,col_UserID,col_FCCellID,col_CardName,col_Remark,col_CreateTime,kmbm,col_CardType,col_Leave_Reason,col_card_fee,col_card_status,col_OwnerID) 
													  values(@cardno,@cardStartDate ,@cardEndDate, isnull(@cardState,1), @id,@cellid,@alias,@remark,@colcreateTime,@cardkmbm,@type,@disabledreason,@col_card_fee,@col_card_status,@ownerid)

													  select @usercardid = scope_identity()
					                               end

												     delete from BT_col_CardManagement_FCCELL where cardid = @usercardid
												     /*卡所屬住戶,給限制卡號數量和報表標記用*/
							 						 insert into BT_col_CardManagement_FCCELL(cardid,cellid)
													 select @usercardid,col
													 from dbo.fn_split_ToTable(@colcellid,',')
													 /**/



												  DELETE FROM BT_sys_FreeCard where sys_CardNO=@cardno


												  if(@cardkmbm!='')
												    begin
														if(not exists(select 1 from bt_cardrelate where cardno = @cardno or kmbm = @cardkmbm))
														 begin
															   insert into bt_cardrelate(cardno,kmbm)
															   values(@cardno,@cardkmbm)
														 end
													  else if(exists(select 1 from bt_cardrelate where cardno = @cardno and kmbm!=@cardkmbm))
														begin
															 update bt_cardrelate set kmbm = @cardkmbm where cardno =@cardno
														end
													  else if(exists(select 1 from bt_cardrelate where cardno != @cardno and kmbm=@cardkmbm))
														 begin
															  update bt_cardrelate set cardno =@cardno where kmbm =@cardkmbm
														 end
													 end


												insert into #tempmessage
												  exec SaveUserCardInfoForReader @id,@cardno,0,1


												  if((@savemess !='' and @savemess !='no'  and @savemess != @oldsavemess ) or @col_id = 0)
													 begin
													   if(@savemess = 'no')
													     begin
															 set @savemess = ''
														 end
													   insert into #tempmessage
														exec SaveUserFacePath @code,@cardno,@savemess
													 end


													else if(@tempmess!='' and @tempmess != 'no' and @savemess = 'no')
													 begin
													   insert into #tempmessage
														exec SaveUserFacePath @code,@cardno,''
													 end

												
											   delete from #tempcard where col_cardid=@cardno
			       
							   end
						end


						if( exists(select * from tempdb..sysobjects where id=object_id('tempdb..#cardcellid')))
							begin
							      drop table #cardcellid
							end

				

							


				
				if(isnull(@cardstr,'') ='')
				   begin
								 delete from zh_member_carddefault where col_userid = @id
									 insert into zh_member_carddefault(col_userid,col_cardtype,col_state,col_leave_reason,col_datestart,col_dateend,col_card_status,col_card_fee,col_fccellid,col_createTime)
									select @id,dbo.[GetSplitOfIndex](col,'@@',1) as col_cardtype,
									dbo.[GetSplitOfIndex](col,'@@',2) as col_state,
									dbo.[GetSplitOfIndex](col,'@@',3) as col_leave_reason,
									convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',4), 103),120)  as  col_datestart,
									convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',5), 103),120)  as col_dateend,
									dbo.[GetSplitOfIndex](col,'@@',6) as col_card_status,
									dbo.[GetSplitOfIndex](col,'@@',7) as col_card_fee,
									dbo.[GetSplitOfIndex](col,'@@',8) as col_fccellid,
									convert(varchar(10),CONVERT(datetime,dbo.[GetSplitOfIndex](col,'@@',9), 103),120) as col_createtime
									from dbo.fn_split(@defaultcardstr,'##')
									where isnull(col,'')!=''


				   end


			
	   end

	   	select distinct a.cellid,c.name as cellname 
								into #cardcellid
								from BT_col_CardManagement_FCCELL as a
								left join BT_col_CardManagement as b on a.cardid = b.col_id
								left join FC_Cell as c on c.cellid = a.cellid
								where b.col_UserID = @id


				while(exists(select 1 from #cardcellid))
				   begin
				        select top 1  @cellid = cellid,@cellname = cellname from #cardcellid 
				        select @maxfk = isnull(maxfk,0) from fc_cell where cellid = @cellid


						 if(@maxfk !=0)
							  begin
					
								select  @insertcount =count(1) 
								from BT_col_CardManagement_FCCELL as a
								left join BT_col_CardManagement as b on a.cardid = b.col_id
								 where a.cellid  = @cellid and col_State = 1  


								if(@insertcount >@maxfk and @maxfkvalue !='0')
								   begin
									   select @message = ''''+@cellname+'''已超出發卡數量'+convert(varchar(max),@maxfk)+'！'; 
									   RaisError(@message,16,1)  with log;
										return;
								   end

							end

						 delete from #cardcellid where cellid = @cellid
				   end
	


	if(isnull(@id,0)>0)  --Jason 20210420 保存时如果之前没有加门禁权限则自动赋予楼宇门禁权限
		begin
			exec SP_UserReaderAccess_Save @id
		end


			
	end try

	begin catch
	     
		--if(@@TRANCOUNT >0) 
		--  begin
			  select '保存失敗,'+ERROR_MESSAGE(); 
			  rollback transaction;
			 
		  --end
	end catch
	 if(@@TRANCOUNT >0)  
	     begin
		  
			 select '保存成功';
			  commit transaction;
		end

			--select '保存成功';
END

