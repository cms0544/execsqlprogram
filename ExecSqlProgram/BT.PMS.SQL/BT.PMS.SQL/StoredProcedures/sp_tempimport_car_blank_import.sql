if(exists(select 1 from sysobjects where id = object_id('sp_tempimport_car_blank_import')))
drop PROCEDURE [dbo].[sp_tempimport_car_blank_import] 
--USE [BT_PMS]
GO
/****** Object:  StoredProcedure [dbo].[sp_tempimport_car_blank_import]    Script Date: 6/16/2021 6:29:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Mason>
-- Create date: <2021-01-05,,>
-- Description:	<白名单導入,, sp_tempimport_car_blank_import  'admin',1>
-- =============================================
create PROCEDURE [dbo].[sp_tempimport_car_blank_import] 
  @user varchar(max),
  @importtype int = 0
AS
BEGIN

   	--begin transaction 
		begin try
		  
		     declare @importtypename varchar(max) = '';

			     declare @invailcarcount int = 0,@updatecount int = 0,@insertcount int = 0,@deletecount int = 0,@originalcount int = 0;

			 select @importtypename = name from bt_car_Parking_type where  id =  @importtype
			 create table #bt_temp_car_blank_import
			 (
				rownum int identity(1,1),
			    code varchar(max)  COLLATE Chinese_PRC_CI_AS,
				car_code varchar(max)  COLLATE Chinese_PRC_CI_AS,
				parktypename varchar(max)  COLLATE Chinese_PRC_CI_AS,
				lastname varchar(max)  COLLATE Chinese_PRC_CI_AS,
				firstname  varchar(max)  COLLATE Chinese_PRC_CI_AS,
				card_no  varchar(max)  COLLATE Chinese_PRC_CI_AS,
				mobile varchar(max)  COLLATE Chinese_PRC_CI_AS
			 )


			 create table #vi_car
			 (
			     id int,
				 code varchar(max)  COLLATE Chinese_PRC_CI_AS,
				 car_code varchar(max)  COLLATE Chinese_PRC_CI_AS,
				 car_Parking_type int,
				 parktypename  varchar(max)  COLLATE Chinese_PRC_CI_AS,
				 lastname  varchar(max)  COLLATE Chinese_PRC_CI_AS,
				 firstname  varchar(max)  COLLATE Chinese_PRC_CI_AS,
				 card_no   varchar(max)  COLLATE Chinese_PRC_CI_AS,
				 mobile varchar(max)  COLLATE Chinese_PRC_CI_AS,
				 carotherid int
			 )

			 if(@importtype!= 0 )
			    begin
					 if(@importtypename = '員工 Employee')
						begin
						   insert into #bt_temp_car_blank_import
						   select code,  replace(replace(replace(replace(isnull(nullif(upper(car_code),''),''),'O','0'),'I','1'),'Q','0'),' ',''),case when parktypename ='Staff' then '員工 Employee' when parktypename ='員工 Employee' then '員工 Employee' else '會員 Member' end,lastname,firstname,card_no,mobile  from bt_temp_car_blank_import where parktypename = 'Staff'
						
						 
						end 
					 else 
						begin
						   insert into #bt_temp_car_blank_import
						   select code, replace(replace(replace(replace(isnull(nullif(upper(car_code),''),''),'O','0'),'I','1'),'Q','0'),' ',''),case when parktypename ='Staff' then '員工 Employee'  when parktypename ='員工 Employee' then '員工 Employee' else '會員 Member' end,lastname,firstname,card_no,mobile  from bt_temp_car_blank_import where parktypename != 'Staff'
					
					       
						end 

						insert into #vi_car
						   select id,isnull(code,''),upper(isnull(car_code,'')),isnull(car_Parking_type,0),isnull(parktypename,''),isnull(lastname,''),isnull(firstname,''),isnull(card_no,''),isnull(mobile,''),isnull(carotherid,0)
						   from VI_Car
						   where car_Parking_type =  @importtype and isnull(card_status,0) = 0
				end
				else
				 begin
				        insert into #bt_temp_car_blank_import
						select isnull(code,''),  replace(replace(replace(replace(isnull(nullif(upper(car_code),''),''),'O','0'),'I','1'),'Q','0'),' ',''),case when parktypename ='Staff' then '員工 Employee' when parktypename ='員工 Employee' then '員工 Employee' else '會員 Member' end,lastname,firstname,card_no,mobile from bt_temp_car_blank_import
				      

					      insert into #vi_car
						   select id,isnull(code,''),isnull(car_code,''),isnull(car_Parking_type,0),isnull(parktypename,''),isnull(lastname,''),isnull(firstname,''),isnull(card_no,''),isnull(mobile,''),isnull(carotherid,0)
						   from VI_Car
						   where isnull(card_status,0) = 0
				 end 

				    /*已經更新過的id*/
			    create table #updatedid 
			    (
			    	id int 
			    )
    
  

				 /*若參數值為Deep Water Bay或有括號，請當無效紀錄*/
			
				 delete from #bt_temp_car_blank_import where lower(isnull(replace(car_code,' ',''),'')) = 'deepwaterbay' or charindex('(', isnull(car_code,'')) !=0 or charindex(')', isnull(car_code,'')) !=0 
				 select @invailcarcount = @@ROWCOUNT
		
		          /*原有車輛*/
				 select c.id,#bt_temp_car_blank_import.rownum   into #orignal_temp_car_blank_import from #bt_temp_car_blank_import
				 inner join #vi_car as c on isnull(c.code,'') = isnull(#bt_temp_car_blank_import.code,'') and c.car_code = #bt_temp_car_blank_import.car_code and   isnull(c.parktypename,'') =  isnull(#bt_temp_car_blank_import.parktypename,'') and isnull(c.lastname,'') = isnull(#bt_temp_car_blank_import.lastname,'')  and isnull(c.firstname,'') =  isnull(#bt_temp_car_blank_import.firstname,'') and  isnull(c.card_no,'') = isnull(#bt_temp_car_blank_import.card_no,'') and  isnull(c.mobile,'') = isnull(#bt_temp_car_blank_import.mobile,'') 
			

			   
		
				  
				  delete from #bt_temp_car_blank_import where rownum in (select rownum from #orignal_temp_car_blank_import)
				 
				   select @originalcount = @@ROWCOUNT

				   insert into #updatedid
				   select id from #orignal_temp_car_blank_import




			 declare @errorcarcode varchar(max) ='',@errorrownum int = 0;

			
				--所有出入口权限
		   declare @carpermisson varchar(max) = '';

		   	 declare @maxnum int =0,@beginnum int= 1;
			declare @code varchar(max),@car_code varchar(max),@lastname varchar(max),@firstname varchar(max),@card_no varchar(max),@mobile varchar(max),@blanktype varchar(max),@blanktypeid int,@username varchar(max),@starttime varchar(max),@endtime varchar(max),@message varchar(max);


		    if(exists (select 1 from #bt_temp_car_blank_import where isnull(car_code,'')!=''  group by car_code having count(1)>1)
			)
			    begin
			            select top 1 @errorcarcode =  car_code,@errorrownum= min(rownum) from #bt_temp_car_blank_import where isnull(car_code,'')!=''  group by car_code having count(1)>1
				
						          set @message ='第'+convert(varchar(max),@errorrownum)+'行車牌'+@errorcarcode+'已存在,請重新輸入'
								   RaisError(@message,16,1)  with log;

				end

				if(@importtype!= 0)
				   begin
				        if(exists(select 1 from #bt_temp_car_blank_import  as a
						inner join VI_Car as b on a.car_code = b.car_code and isnull(b.card_status,0) = 0
						  where car_Parking_type ! = @importtype  and isnull(a.car_code,'') !='' ))
						   begin
						      
			                   select top 1 @errorcarcode =  a.car_code,@errorrownum= rownum 
							   from #bt_temp_car_blank_import as a
							   inner join VI_Car as b on a.car_code = b.car_code and isnull(b.card_status,0) = 0
							    where car_Parking_type ! = @importtype and isnull(a.car_code,'')!='' 
				

				                   set @message ='第'+convert(varchar(max),@errorrownum)+'行車牌'+@errorcarcode+'其它类型已存在,請重新輸入'
								   RaisError(@message,16,1)  with log;
						       
						   end
				      
				   end

				if(exists (select 1 from #bt_temp_car_blank_import where  isnull(car_code,'')=''))
				    begin
				             select top 1 @errorrownum= rownum from #bt_temp_car_blank_import where isnull(car_code,'')='' 
				
						          set @message ='第'+convert(varchar(max),@errorrownum)+'行車牌不能為空,請重新輸入'
								   RaisError(@message,16,1)  with log;
				    end


					
				    if(exists (select 1 from #bt_temp_car_blank_import where  isnull(code,'')=''))
				    begin
				             select top 1 @errorrownum= rownum from #bt_temp_car_blank_import where isnull(code,'')='' 
				
						          set @message ='第'+convert(varchar(max),@errorrownum)+'行編號不能為空,請重新輸入'
								   RaisError(@message,16,1)  with log;
				    end

					if(exists (select 1 from #bt_temp_car_blank_import where  isnull(parktypename,'')=''))
				    begin
				             select top 1 @errorrownum= rownum from #bt_temp_car_blank_import where isnull(parktypename,'')='' 
				
						          set @message ='第'+convert(varchar(max),@errorrownum)+'行車主類型不能為空,請重新輸入'
								   RaisError(@message,16,1)  with log;
				    end


					select @carpermisson = stuff((select ','+convert(varchar(max),id) from tb_LotPass for xml path('')),1,1,'') 


				  --insert into BT_Car(car_code,car_Parking_type,username,card_endtime,card_starttime,card_registertime,mobile,card_no,updatetime,card_createuser,card_status,Parking_permission)
				  select rownum,car_code,b.id as car_Parking_type,isnull(a.lastname,'')+isnull(a.firstname,'') as username,getdate() as startdate,dateadd(year,100,getdate()) as [expiredate],mobile,card_no,a.lastname,a.firstname,code
				  into #tempinsert
				  from #bt_temp_car_blank_import as a
				  left join BT_car_parking_type as b on b.name = a.parktypename
				  where  not exists ( select 1 from #vi_car where   isnull(code,'') = isnull(a.code,'') or car_code = a.car_code or (isnull(lastname,'')+isnull(firstname,'') = isnull(a.lastname,'')+isnull(firstname,'') and ( isnull(a.lastname,'')+isnull(firstname,'')!='')) or isnull(mobile,'') = isnull(a.mobile,'') and isnull(a.mobile,'')!='' or isnull(card_no,'') = isnull(a.card_no,'') and isnull(a.card_no,'')!='') 
			
 
              insert into BT_Car(car_code,car_Parking_type,username,card_endtime,card_starttime,card_registertime,mobile,card_no,updatetime,card_createuser,card_status,Parking_permission)
				  select car_code,car_Parking_type,username,[expiredate],getdate(), getdate(),mobile,card_no,getdate(),@user,0,@carpermisson
				  from #tempinsert

				    select @insertcount = @insertcount + @@ROWCOUNT

				   insert into bt_car_other(carid,firstname,lastname,code)
				  select b.id,a.firstname,a.lastname,a.code 
				  from  #tempinsert as a
				  left join BT_Car as b on a.car_code = b.car_code
				  --where b.card_status =0 and not exists ( select 1 from #vi_car where isnull(code,'') = isnull(a.code,'') or isnull(car_code,'') = isnull(a.car_code,'') or (isnull(lastname,'')+isnull(firstname,'') = isnull(a.lastname,'')+isnull(firstname,'') and ( isnull(a.lastname,'')+isnull(firstname,'')!='')) or isnull(mobile,'') = isnull(a.mobile,'') and isnull(a.mobile,'')!='' or isnull(card_no,'') = isnull(a.card_no,'') and isnull(a.card_no,'')!='') 

			
			

					  insert into #updatedid
					  select id from #tempinsert as a
					   left join BT_Car as b on a.car_code = b.car_code




				  delete from #bt_temp_car_blank_import  where rownum in (select rownum from #tempinsert)


				  /*车牌号相同的先一起更 ,*/
				   select b.id,a.rownum,b.carotherid,a.firstname,a.lastname,a.code
				   into #tempupdate
				   from  #bt_temp_car_blank_import  as a
				  inner join #vi_car as b  on a.car_code = b.car_code
				  --where   not exists ( select 1 from #vi_car where  isnull(car_code,'') = isnull(a.car_code,'') and (isnull(lastname,'')+isnull(firstname,'') = isnull(a.lastname,'')+isnull(firstname,'') ) and isnull(mobile,'') = isnull(a.mobile,'')  and isnull(card_no,'') = isnull(a.card_no,'') ) 

				   if(@importtype!=0)
				    begin



						  update BT_Car set  car_Parking_type = b.id,mobile = a.mobile ,card_no = a.card_no,updatetime = getdate(),card_status = 0,Parking_permission = @carpermisson,username=isnull(a.lastname,'')+isnull(a.firstname,'')
						  from #bt_temp_car_blank_import as a  
						  left join bt_car_Parking_type as b on b.name = a.parktypename
						  where isnull(card_status,0) = 0 and BT_Car.car_code = a.car_code and car_Parking_type =  @importtype
						  --and not exists ( select 1 from #vi_car where  isnull(car_code,'') = isnull(a.car_code,'') and (isnull(lastname,'')+isnull(firstname,'') = isnull(a.lastname,'')+isnull(firstname,'') ) and isnull(mobile,'') = isnull(a.mobile,'')  and isnull(card_no,'') = isnull(a.card_no,'') ) 
					
				    end
				  else
				   begin
				         update BT_Car set car_Parking_type = b.id,mobile = a.mobile ,card_no = a.card_no,updatetime = getdate(),card_status = 0,Parking_permission = @carpermisson,username=isnull(a.lastname,'')+isnull(a.firstname,'')
						  from #bt_temp_car_blank_import as a  
						  left join bt_car_Parking_type as b on b.name = a.parktypename
						  where isnull(card_status,0) = 0 and BT_Car.car_code = a.car_code
						  --and not exists ( select 1 from #vi_car where  isnull(car_code,'') = isnull(a.car_code,'') and (isnull(lastname,'')+isnull(firstname,'') = isnull(a.lastname,'')+isnull(firstname,'') ) and isnull(mobile,'') = isnull(a.mobile,'')  and isnull(card_no,'') = isnull(a.card_no,'') ) 


				   end
		
		        set @updatecount  = @updatecount +  @@ROWCOUNT


					update bt_car_other  set lastname = isnull( a.lastname,''),firstname = isnull( a.firstname,''),code = isnull(a.code,'')
					from #tempupdate as a  
					where a.carotherid = bt_car_other.id


				insert into #updatedid
				select id
				from #tempupdate
				
				
				delete from   #bt_temp_car_blank_import where rownum in (select rownum from #tempupdate)


		      select row_number() over (order by (select 1)) as [index],* into #real_temp_car_blank_import from #bt_temp_car_blank_import


			  	

			 select @maxnum = count(1) from #real_temp_car_blank_import

			 --select @maxnum

			 -- return

			 declare @id int = 0;
			 while(@beginnum < = @maxnum)
				begin
		          set @id = 0;

			
				  select @code = code,@car_code=car_code,@blanktype =isnull(nullif(parktypename,''),''),@lastname =isnull(nullif(lastname,''),''),@firstname =isnull(nullif( firstname,''),''),@mobile = isnull( nullif(mobile,''),''),@card_no = isnull( nullif(card_no,''),'')   from #real_temp_car_blank_import where [index]=@beginnum
				 
				 
				 set @beginnum = @beginnum + 1;
				  

					/*參數值為Staff即員工，其他即會員*/
					--if(isnull(@blanktype,'') = 'Staff')

					--   begin
					--      set @blanktype = '員工'
					--   end 

					--else 
					--   begin
					--      set @blanktype = '會員';
					--   end 
		
			
				
					set @starttime = getdate();


				 
						set @endtime = dateadd(year,100,getdate())

					select @blanktypeid = isnull(id,0) from bt_car_Parking_type where name  = @blanktype
					
	
				  select top 1 @id = isnull(id,0) from #vi_car where (isnull(code,'') = @code or isnull(car_code,'') =@car_code  or   isnull(car_Parking_type,0)=@blanktypeid or (isnull(lastname,'')+isnull(firstname,'') = isnull(@lastname,'')+isnull(@firstname,'') and  isnull(@lastname,'')+isnull(@firstname,'')!='')  or isnull(card_no,'')!='' and card_no = @card_no  or isnull(mobile,'')!='' and mobile = @mobile )
				  
				   and id not in (select id from #updatedid) 
				    order by id 

				  --select @id
				  --select @id
				  if(@id!= 0)
					 begin
					  --if(exists(select 1 from BT_Car where car_code = @car_code and id != @id))
						 --  begin
						 --         set @message = '第' + convert(varchar(max),@beginnum) + '行請車牌'+@car_code+'已有,請重新輸入'
							--	   RaisError(@message,16,1)  with log;
						 --  end



						 update BT_Car set car_code = @car_code,car_Parking_type = @blanktypeid,username = @lastname +@firstname,card_endtime = @endtime,card_starttime = @starttime,mobile = @mobile ,card_no = @card_no,updatetime = getdate(),card_status = 0,Parking_permission = @carpermisson
						 where id = @id

						 if(exists (select 1 from bt_car_other where carid = @id))
						    begin
							    update  bt_car_other set firstname = @firstname,lastname = @lastname,code = @code where carid = @id
							end
						else 
						    begin
							   insert into bt_car_other(carid,firstname,lastname,code)
							   select @id,@firstname,@lastname,@code
							end 


							set @updatecount = @updatecount + 1;
					 end
					else 
					  begin
	
					    -- if(exists(select 1 from BT_Car where car_code = @car_code))
						   --begin
						   --       set @message = '第' + convert(varchar(max),@beginnum) + '行請車牌'+@car_code+'已有11,請重新輸入'
								 --  RaisError(@message,16,1)  with log;
						   --end

						  insert into BT_Car(car_code,car_Parking_type,username,card_endtime,card_starttime,card_registertime,mobile,card_no,updatetime,card_createuser,card_status,Parking_permission)
						  select @car_code,@blanktypeid,@lastname + @firstname,@endtime,@starttime,getdate(),@mobile,@card_no,getdate(),@username,0,@carpermisson


						   set @id = SCOPE_IDENTITY()


						   if(exists (select 1 from bt_car_other where carid = @id))
						    begin
							    update  bt_car_other set firstname = @firstname,lastname = @lastname,code = @code where carid = @id
							end
						else 
						    begin
							   insert into bt_car_other(carid,firstname,lastname,code)
							   select @id,@firstname,@lastname,@code
							end 

						    


							   set @insertcount = @insertcount + 1;

						   --select @id
					  end

					  --select @id

					  insert into #updatedid
					  select @id
				end




	      if(@importtype!=0)
		     begin
				select @deletecount =  count(1) from BT_Car where  id not in (
				 select id from #updatedid
				) and ( isnull(card_status,0)=0) and car_Parking_type = @importtype

				 


				update  BT_Car set card_endtime = getdate(),card_status=2 where id not in (
				 select id from #updatedid
				) and ( isnull(card_status,0)=0)  and car_Parking_type = @importtype

			  end
			else
			 begin
			    	select @deletecount =  count(1) from BT_Car where  id not in (
				 select id from #updatedid
				) and ( card_status=0) 

				 


				update  BT_Car set card_endtime = getdate(),card_status=2 where id not in (
				 select id from #updatedid
				) and ( card_status=0) 

			 end


	
	 
	   end try
	 begin catch
			if(@@TRANCOUNT >0) 
		  begin
			  select '保存失敗,'+ERROR_MESSAGE(); 
			    --rollback transaction;
		  end

	end catch

		    --commit transaction;
			 select '保存成功,原來車輛:'+convert(varchar(max),@originalcount)+',無效車輛:'+convert(varchar(max),@invailcarcount) +',新增車輛:'+convert(varchar(max),@insertcount)+',修改車輛:'+convert(varchar(max),@updatecount)+',刪除車輛:'+convert(varchar(max),@deletecount) ;
	
END

