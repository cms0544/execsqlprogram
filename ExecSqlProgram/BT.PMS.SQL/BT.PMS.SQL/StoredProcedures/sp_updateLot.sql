if(exists(select 1 from sysobjects where id = object_id('sp_updateLot')))
  begin
     drop PROCEDURE [dbo].[sp_updateLot]
  end
--USE [BT_PMS]
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-02-08,,>
-- Description:	<保存分配数量,, truncate table bt_lotcount_distribution go  sp_updateLot 1,'2021-02-25 04:33:28.383'  select * from bt_lotcount_distribution 



-- =============================================
create PROCEDURE [dbo].[sp_updateLot]
	-- Add the parameters for the stored procedure here
	@LotID int,
	@oldLastAmendTime datetime null
	
AS
BEGIN
	
	declare @lastAmendTime datetime = getdate(),@lotcount int = 0;

	
	select @lotcount = lotcount,@LastAmendTime= LastAmendTime  from tb_lot where LotID = @lotid
	if(@oldLastAmendTime is null)
	  begin
	     set @oldLastAmendTime = '2021-01-01';

	  end

	  declare @comparecount int = 0;

	select @comparecount = totalincurrent from bt_lotcount_distribution where lotid = @LotID

	if(@lotcount =@comparecount )
	   begin
	       return;
	   end
   -- if(@lotcount !=0)
	  --begin

	         select * into #tb_DeviceUserEventInfo_top　from　V_DeviceUserEventInfo_top_Golf  
			 where autoadd !=1


	        select  distinct platenumber,time,[Type],enter as PassType
				into #temptotalcurrent
				from #tb_DeviceUserEventInfo_top 
				where   LotID = @LotID  
				and time>@oldLastAmendTime and time <@LastAmendTime




				select  distinct platenumber,time,[Type],PassType
				into #temptotalcurrentIn
				from #temptotalcurrent as a
				 where  PassType = 1 


				select  distinct platenumber,time,[Type],PassType
				into #temptotalcurrentOut
				from #temptotalcurrent as a
				 where  PassType != 1 

				 --select * from #temptotalcurrent

				 
				   declare @incurrentNum int,@outcurrentNum int = 0,@totalincurrenMember int = 0,@totalincurrenEmployee int= 0,@totalincurrenGuest int = 0,
				   @totalincurrenCars int = 0,@totalincurrenBuses int = 0,@totalincurrenSPVs int = 0,@totalincurrent int = 0;
				  

				  

				  select @totalincurrenMember  = isnull(totalincurrenMember,0),@totalincurrenEmployee  = isnull(totalincurrenEmployee ,0),@totalincurrenGuest  = isnull(totalincurrenGuest ,0),
				  @totalincurrenCars =  isnull(totalincurrenCars ,0),@totalincurrenBuses = isnull(totalincurrenBuses,0),@totalincurrenSPVs = isnull(totalincurrenSPVs,0),@totalincurrent = isnull(totalincurrent,0)
				  from bt_lotcount_distribution  where lotid = @LotID

				 --select @totalincurrent = @lotcount;
			

			   if(@totalincurrent  !='0')
				     begin

					     select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn 

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut 

						 select @totalincurrent   = @totalincurrent+  @incurrentNum -@outcurrentNum;

						 if(@totalincurrent<0)
						   begin
						      set @totalincurrent = 0
						   end
					 end

			   if(@totalincurrenMember  !='0')
				     begin

					     select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn where  PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Memeber'  and card_endtime>getdate())

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut where  PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Memeber'  and card_endtime>getdate())

						 select @totalincurrenMember   = @totalincurrenMember+  @incurrentNum -@outcurrentNum;

						 if(@totalincurrenMember<0)
						   begin
						      set @totalincurrenMember = 0
						   end
					 end


				
			   if(@totalincurrenEmployee  !='0')
				     begin

					     select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn where  PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee'  and card_endtime>getdate())

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut where  PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee'  and card_endtime>getdate())

						 select @totalincurrenEmployee   = @totalincurrenEmployee + @incurrentNum -@outcurrentNum;

						 if(@totalincurrenEmployee <0)
						   begin
						      set @totalincurrenEmployee = 0
						   end
					 end

				   if(@totalincurrenGuest  !='0')
				     begin
					      --set @totalincurrenGuest =  

					  --   select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn where  PlateNumber  not in ( select car_code from vi_car_vip where isnull(card_status,0) = 0  and card_endtime>getdate()) 

						 --select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut where  PlateNumber  not in ( select car_code from vi_car_vip where isnull(card_status,0) = 0  and card_endtime>getdate()) 

						 --select @totalincurrenGuest   = @totalincurrenGuest + @incurrentNum -@outcurrentNum;

						 --if(@totalincurrenGuest <0)
						 --  begin
						 --     set @totalincurrenGuest = 0
						 --  end

						 set @totalincurrenGuest = @totalincurrent -@totalincurrenMember - @totalincurrenEmployee
					 end

					 -- if(@totalincurrenCars   !='0')
				  --   begin

					 --    select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn  where type in ('0','3') 

						-- select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut 	 where type in ('0','3') 

						-- select @totalincurrenCars   = @totalincurrenCars +  @incurrentNum -@outcurrentNum;

						-- if(@totalincurrenCars <0)
						--   begin
						--      set @totalincurrenCars = 0
						--   end
					 --end

					 
					  if(@totalincurrenBuses   !='0')
				     begin

					     select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn  where type in ('1','10') 

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut 	 where type in ('1','10') 

						 select @totalincurrenBuses   = @totalincurrenBuses + @incurrentNum -@outcurrentNum;

						 if(@totalincurrenBuses <0)
						   begin
						      set @totalincurrenBuses = 0
						   end
					 end


					  if(@totalincurrenSPVs   !='0')
				     begin

					     select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn  where type in ('2','5','7','8','15','16','17','19','20','21','22')

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut 	 where type  in ('2','5','7','8','15','16','17','19','20','21','22') 

						 select @totalincurrenSPVs   = @totalincurrenSPVs+ @incurrentNum -@outcurrentNum;

						 if(@totalincurrenSPVs <0)
						   begin
						      set @totalincurrenSPVs = 0
						   end
					 end


					   if(@totalincurrenCars   !='0')
				     begin  
					      set @totalincurrenCars = @totalincurrent - @totalincurrenBuses - @totalincurrenSPVs;

					  --   select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn  where type in ('0','3') 

						 --select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut 	 where type in ('0','3') 

						 --select @totalincurrenCars   = @totalincurrenCars +  @incurrentNum -@outcurrentNum;

						 --if(@totalincurrenCars <0)
						 --  begin
						 --     set @totalincurrenCars = 0
						 --  end
					 end

	


				   --if(@totalincurrenMember = 0 and @totalincurrenEmployee = 0 and @totalincurrenGuest = 0)
				   --   begin
					  --   set @totalincurrent = 1 ;
						 --set @totalincurrenMember = 1;
						 --set @totalincurrenEmployee=1;
						 --set @totalincurrenGuest = 1;
						 --set @totalincurrenCars =1;
						 --set @totalincurrenBuses =1 ;
						 --set @totalincurrenSPVs =1;
						
						 --    exec sp_GetInParkNum 1,1,null,@LastAmendTime;
		
					  --    	   exec sp_GetInParkNum @lotid,@totalincurrent out,null,@LastAmendTime;

					  --        exec sp_GetInParkNum @lotid,@totalincurrenMember out,null,@LastAmendTime,'Member';

							--	exec sp_GetInParkNum @lotid,@totalincurrenEmployee out,null,@LastAmendTime,'Employee';

							--	exec sp_GetInParkNum @lotid,@totalincurrenGuest out,null,@LastAmendTime,'Guest';

							--	exec sp_GetInParkNum @lotid,@totalincurrenCars out,null,@LastAmendTime,'Cars';

							--	exec sp_GetInParkNum @lotid,@totalincurrenBuses out,null,@LastAmendTime,'Buses';

							--	exec sp_GetInParkNum @lotid,@totalincurrenSPVs out,null,@LastAmendTime,'SPVs';
		
					  --end


					  			

		
				 select @totalincurrenMember =iif(@totalincurrent=0,0, ROUND( convert(decimal(18,2), convert(decimal(18,2),@totalincurrenMember) / @totalincurrent)* @lotcount,0))

				  select @totalincurrenEmployee = iif(@totalincurrent=0,0,ROUND( convert(decimal(18,2), convert(decimal(18,2),@totalincurrenEmployee) / @totalincurrent)* @lotcount,0))

				 select  @totalincurrenGuest = @lotcount - @totalincurrenMember - @totalincurrenEmployee


				  select  @totalincurrenCars =  iif(@totalincurrent=0,0,ROUND( convert(decimal(18,2), convert(decimal(18,2),@totalincurrenCars) / @totalincurrent)* @lotcount,0))

				  select @totalincurrenBuses =  iif(@totalincurrent=0,0,ROUND( convert(decimal(18,2), convert(decimal(18,2),@totalincurrenBuses) / @totalincurrent)* @lotcount,0))

				   select @totalincurrenSPVs =  iif(@totalincurrent=0,0,ROUND( convert(decimal(18,2), convert(decimal(18,2),@totalincurrenSPVs) / @totalincurrent)* @lotcount,0))


				 
				   set @totalincurrenSPVs = @lotcount - @totalincurrenCars - @totalincurrenBuses


				        set @totalincurrent = @lotcount;


				if(not exists (select 1 from bt_lotcount_distribution where lotid = @lotid))
				  begin
				          insert into bt_lotcount_distribution(lotid,totalincurrenMember,totalincurrenEmployee,totalincurrenGuest,totalincurrenCars,totalincurrenBuses,totalincurrenSPVs,totalincurrent)	
						  select @lotid,@totalincurrenMember,@totalincurrenEmployee,@totalincurrenGuest,@totalincurrenCars,@totalincurrenBuses,@totalincurrenSPVs,@totalincurrent

				  end 
				else
				  begin
				        update bt_lotcount_distribution set totalincurrenMember = @totalincurrenMember,totalincurrenEmployee = @totalincurrenEmployee
						,totalincurrenGuest = @totalincurrenGuest,totalincurrenCars = @totalincurrenCars,totalincurrenBuses = @totalincurrenBuses,totalincurrenSPVs = @totalincurrenSPVs,totalincurrent= @totalincurrent
						where lotid = @lotid
				  end


	  --end
END





