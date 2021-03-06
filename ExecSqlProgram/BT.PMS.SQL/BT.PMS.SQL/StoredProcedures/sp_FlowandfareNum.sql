if(exists(select 1 from sysobjects where id = object_id('sp_FlowandfareNum')))
   begin
      drop PROCEDURE [dbo].[sp_FlowandfareNum]
   end
/****** Object:  StoredProcedure [dbo].[sp_FlowandfareNum]    Script Date: 7/8/2021 9:31:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-01-26,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[sp_FlowandfareNum]
	-- Add the parameters for the stored procedure here
  @begindate datetime,
  @enddate datetime,
  @laseAmend datetime,
  @totalparkedvehicles int out,
  @totalparkedvechiclescars int out,
  @totalparkedvechiclesbuses int out,
  @totalparkedvechiclesspvs int out,
  @totalexitedvehicles int out,
  @totalexitedvehiclesMembers int out,
  @totalexitedvehiclesEmp int out,
  @totalexitedvehiclesGuests int out,
  @inpeople int out,
  @totalPaidAmount decimal(18,2) out,
  @totalparkedvehiclesMembers int out,
  @totalparkedvehiclesEmp int out,
  @totalparkedvehiclesGuests int out,
  @totalexitedvehiclesCars int out,
  @totalexitedvehiclesBuses int out,
  @totalexitedvehiclesSpvs int out,
  @totalincurrent  int out,
  @totalincurrenMember  int out,
  @totalincurrenEmployee  int out,
  @totalincurrenGuest  int out,
  @totalincurrenCars  int out,
  @totalincurrenBuses  int out,
  @totalincurrenSPVs  int out,
  @lotid int=0
AS
BEGIN

         declare @mindate datetime =getdate();

		 if(datediff(second,@begindate,@laseAmend)>0)
		    begin
			   set @mindate = @begindate;
			end
		 else 
		   begin
		      set @mindate = @laseAmend;
		   end 

		   declare @tempenddate datetime;

		   if(@totalincurrent = -1)
		     begin
			    set @tempenddate = @enddate;
			 end
			else
			 begin
			    set @tempenddate = getdate();
			 end

			   select platenumber,time, iif(ISNUMERIC(type) = 1,type,0) as type,a.enter as PassType into #temppass　
			 from tb_deviceusereventinfo_top as a
				inner join tb_deviceuser as b on a.deviceid = b.deviceid and b.isdelete = 0 and b.isMain = 1
					 inner join tb_LotPass as c on c.id = a.LotID
				where  time>=@mindate  and time <=@tempenddate and c.lotid = @lotid and autoadd !=2


			  if( datediff(day,@begindate,getdate())>30 )
					 begin
						     insert into #temppass
						     select platenumber,time,iif(ISNUMERIC(type) = 1,type,1) as  type,enter as PassType 　
							  from　tb_DeviceUserEventInfo_Top_old  as a with (nolock)
							   inner join tb_LotPass as c on c.id = a.LotID

							  where (isnull(isMain,0) = 1 or enter !=1  ) and time>=@mindate  and time <= @tempenddate and c.lotid = @lotid and autoadd !=2
				 end
		
         


			  select  distinct platenumber,time,[Type],PassType
				into #temptotal
				from #temppass as a
				 where time>=@begindate and time <=@enddate



				  /*当前车位使用*/
				select  distinct platenumber,time,[Type],PassType
				into #temptotalcurrent
				from #temppass as a
				 where time>=@laseAmend







			  	select distinct platenumber,time,[Type] 
				into #tempinpark
				from #temptotal 
				 where PassType = 1 
	


				  	select distinct platenumber,time,[Type] 
				into #tempoutpark
				from #temptotal 
				 where PassType != 1


				select  distinct platenumber,time,[Type],PassType
				into #temptotalcurrentIn
				from #temptotalcurrent as a
				 where  PassType = 1 


				select  distinct platenumber,time,[Type],PassType
				into #temptotalcurrentOut
				from #temptotalcurrent as a
				 where  PassType != 1 



				 /*若果查会员 用isMain=1 查重算后的表*/	
				create table #tempmemeber
				(
					 platenumber varchar(max) collate Chinese_PRC_CI_AS,
					 time datetime ,
					 type int,
					 PassType int
				)


				if(@totalexitedvehiclesMembers!=-1)
				   begin
				  
				
						  insert into #tempmemeber
						  select platenumber,time,iif(ISNUMERIC(type) = 1,type,1) as  type,enter as PassType 　
						  from　V_DeviceUserEventInfo_top_Golf with (nolock) 
						  where time>=@mindate  and time <= @tempenddate and lotid = @lotid and autoadd !=2


						if( datediff(day,@begindate,getdate())>30 )
						 begin
						     insert into #tempmemeber
						     select platenumber,time,iif(ISNUMERIC(type) = 1,type,1) as  type,enter as PassType 　
							  from　tb_DeviceUserEventInfo_Top_old  as a with (nolock)
							   inner join tb_LotPass as c on c.id = a.LotID

							  where  (isnull(isMain,0) = 1 or enter !=1 ) and time>=@mindate  and time <= @tempenddate and c.lotid = @lotid and autoadd !=2
						 end

				   end
				   /*end*/


				--CREATE NONCLUSTERED INDEX  #tempoutpark_Time_platenumber
				--ON #tempoutpark ([PlateNumber])
				--INCLUDE ([Time])

				--CREATE NONCLUSTERED INDEX  #tempinpark_Time_platenumber
				--ON #tempinpark ([PlateNumber])
				--INCLUDE ([Time])


				--CREATE NONCLUSTERED INDEX  #temptotalcurrentIn_Time_platenumber
				--ON #temptotalcurrentIn ([PlateNumber])
				--INCLUDE ([Time])

				--CREATE NONCLUSTERED INDEX #temptotalcurrentOut_Time_platenumber
				--ON #temptotalcurrentOut ([PlateNumber])
				--INCLUDE ([Time])

			   SELECT  @totalparkedvehicles =  isnull( count(1),0)  from (
					select 1 as [counts] from #tempinpark

					--and lotid = @lotid
				) as a

			

				--SELECT  @totalparkedvechiclescars =  REPLACE(CONVERT(VARCHAR(20),CAST(count(1) AS MONEY),1),'.00','')  from (
				--			select 1 as [counts] from #tempinpark where [type] in ('3','0')

				--) as a
				if(@totalparkedvechiclesbuses!=-1)
				   begin
					  declare  @totalparkedvechiclesbusescount int = 0;	  
				
					SELECT  @totalparkedvechiclesbuses  =isnull( count(1),0) from (
							  select 1 as [counts] from #tempinpark where [type] in ('1','10')
					) as a

				  end

				if(@totalparkedvechiclesspvs!=-1)
				   begin
						declare  @totalparkedvechiclesspvscount int = 0;	 
						SELECT  @totalparkedvechiclesspvs = isnull( count(1),0)  from (
								  select 1 as [counts] from #tempinpark where [type]  in ('2','5','7','8','15','16','17','19','20','21','22')
						) as a

				  end

				  if(@totalparkedvechiclescars!=-1)
				   begin
						
						SELECT  @totalparkedvechiclescars =isnull( count(1),0)  from (
								  select 1 as [counts] from #tempinpark where [type] not in ('1','10','2','5','7','8','15','16','17','19','20','21','22')
						) as a

				  end

				
				 declare  @totalparkedvehiclesMemberscount int = 0
				if(@totalparkedvehiclesMembers!=-1)
				  begin


					SELECT  @totalparkedvehiclesMembers  = isnull( count(1),0)  from (
					    select 1 as [counts] from #tempmemeber where PassType = 1 and time>=@begindate and time <=@enddate and  PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Member' and card_endtime>getdate())
					) as a
				  end

			
			declare  @totalparkedvehiclesEmpcount int = 0
				if(@totalparkedvehiclesEmp!=-1)
				   begin
					SELECT  @totalparkedvehiclesEmp = isnull( count(1),0) from (
							 select 1 as [counts] from #tempmemeber where  PassType = 1 and time>=@begindate and time <=@enddate and PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee'  and card_endtime>getdate())
			
					) as a
				  end


				  --SELECT  @totalparkedvehiclesGuests =  REPLACE(CONVERT(VARCHAR(20),CAST(@totalparkedvehiclescount - @totalparkedvehiclesMemberscount -@totalparkedvehiclesEmpcount AS MONEY),1),'.00','')  
				  	  	
		     declare  @totalparkedvehiclesGuestscount int = 0
				  if(@totalparkedvehiclesGuests!=-1)
				   begin

					SELECT  @totalparkedvehiclesGuests = isnull( count(1),0)  from (
						 	 select 1 as [counts] from #tempmemeber where   PassType = 1 and time>=@begindate and time <=@enddate and  PlateNumber   not in ( select car_code from vi_car_vip where isnull(card_status,0) = 0  and card_endtime>getdate())  
					) as a
				   end

				 declare  @totalexitedvehiclescount int = 0
				 SELECT  @totalexitedvehicles =  isnull( count(1),0)  from (
				           select 1 as [counts] from #tempoutpark

					 --and lotid = @lotid
				) as a

				 if(@totalexitedvehiclesMembers!=-1)
				   begin
					declare  @totalexitedvehiclesMemberscount int = 0
					 SELECT  @totalexitedvehiclesMembers =  isnull(count(1),0)  from (
						   select 1 as [counts] from #tempmemeber  
									where PassType != 1 and time>=@begindate and time <=@enddate and   PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Member'  and card_endtime>getdate())
					 
					) as a
				 end

				  if(@totalexitedvehiclesEmp!=-1)
				   begin
						declare  @totalexitedvehiclesEmpcount int = 0
						 SELECT  @totalexitedvehiclesEmp = isnull( count(1),0)  from (
								 select 1 as [counts] from #tempmemeber  
										 where  PassType != 1 and time>=@begindate and time <=@enddate and  PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee'  and card_endtime>getdate())
					
						) as a
				 end

				  --SELECT  @totalexitedvehiclesGuests =  REPLACE(CONVERT(VARCHAR(20),CAST(@totalexitedvehiclescount - @totalexitedvehiclesMemberscount -@totalexitedvehiclesEmpcount AS MONEY),1),'.00','')  
				  	  	
				 if(@totalexitedvehiclesGuests!=-1)
				   begin
						 SELECT  @totalexitedvehiclesGuests = isnull( count(1),0)  from (
									  select 1 as [counts] from #tempmemeber  
										where PassType != 1 and time>=@begindate and time <=@enddate and  PlateNumber not in ( select car_code from vi_car_vip where isnull(card_status,0) = 0  and card_endtime>getdate()) 
						) as a
				  end

				
			

			--declare  @totalexitedvehiclesCarscount int = 0
			--	if(@totalexitedvehiclesCars!='0')
			--	  begin
			--		SELECT  @totalexitedvehiclesCars =  REPLACE(CONVERT(VARCHAR(20),CAST(count(1) AS MONEY),1),'.00',''),@totalexitedvehiclesCars = count(1)  from (
			--			      select 1 as [counts] from #tempoutpark  
			--					 where type in ('0','3') 
			--		) as a
			--	  end

			declare  @totalexitedvehiclesBusescount int = 0



				if(@totalexitedvehiclesBuses!=-1)
				   begin
					SELECT  @totalexitedvehiclesBuses = isnull( count(1),0)  from (
						  	    select 1 as [counts] from #tempoutpark
								 where type in ('1','10')
					) as a

				
				  end

				  	
		   declare  @totalexitedvehiclesSpvscount int = 0

				  if(@totalexitedvehiclesSpvs!=-1)
				   begin

					SELECT  @totalexitedvehiclesSpvs = isnull( count(1),0)  from (
								select 1 as [counts] from #tempoutpark where type in ('2','5','7','8','15','16','17','19','20','21','22')
					) as a
 
				   end

				   --if(@totalexitedvehiclesCars != -1)
				   --   begin
					  --    select @totalexitedvehiclesCars = @totalexitedvehiclescount - @totalexitedvehiclesBusescount - @totalexitedvehiclesSpvscount
					  --end


				declare  @totalexitedvehiclesCarscount int = 0
				if(@totalexitedvehiclesCars!=-1)
				  begin
					SELECT  @totalexitedvehiclesCars = isnull( count(1),0)  from (
						      select 1 as [counts] from #tempoutpark  
								 where type not in ('1','10','2','5','7','8','15','16','17','19','20','21','22') 
					) as a
				  end
			



				   declare @incurrentNum int,@outcurrentNum int = 0;
				   if(@totalincurrent!=-1)
				     begin

					     select @incurrentNum =isnull( count(1),0) from #temptotalcurrentIn

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut



						 select @totalincurrent = @totalincurrent +  @incurrentNum -@outcurrentNum;



						 if(@totalincurrent<0)
						   begin
						      set @totalincurrent = 0
						   end
					 end
			



		
		    declare @totalincurreTempEmployee int = 0;
			 declare @totalincurreTempGuest int = 0;
			 declare @totalincurrenTempMember int = 0;
				
			   if(@totalincurrenEmployee  !=-1)
				     begin

					     select @incurrentNum = isnull( count(1),0) from #tempmemeber where time >= @laseAmend  and PassType = 1 and PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee'  and card_endtime>getdate())

						 select @outcurrentNum = isnull( count(1),0) from #tempmemeber where time >= @laseAmend  and PassType != 1 and PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee'  and card_endtime>getdate())

						 select @totalincurrenEmployee   = convert(int,@totalincurrenEmployee) + convert(int,@incurrentNum) -convert(int,@outcurrentNum);

						 if(@totalincurrenEmployee <0)
						   begin
						      set @totalincurreTempEmployee = @totalincurrenEmployee;
						      set @totalincurrenEmployee = 0
						   end
					 end

				   if(@totalincurrenGuest  !=-1)
				     begin
					      --select @totalincurrenGuest = convert(int,@totalincurrent) - convert(int,@totalincurrenEmployee) - convert(int,@totalincurrenMember);
					     select @incurrentNum = isnull( count(1),0) from #tempmemeber where time >= @laseAmend and PassType = 1 and PlateNumber  not in ( select car_code from vi_car_vip where isnull(card_status,0) = 0  and card_endtime>getdate()) 

						 select @outcurrentNum = isnull( count(1),0) from #tempmemeber where time >= @laseAmend and PassType != 1 and PlateNumber  not in ( select car_code from vi_car_vip where isnull(card_status,0) = 0  and card_endtime>getdate()) 

						 select @totalincurrenGuest   = @totalincurrenGuest + @incurrentNum -@outcurrentNum;

						 if(@totalincurrenGuest <0)
						   begin
						       set @totalincurreTempGuest = @totalincurrenGuest;
						      set @totalincurrenGuest = 0
						   end

						 	 --if(@totalincurrenGuest<0)
						   --begin
						   --   set @totalincurrenGuest = 0
						   --end
					 end


					
					if(@totalincurrenMember  !=-1)
				     begin

					     select @incurrentNum = isnull( count(1),0) from #tempmemeber where time >= @laseAmend and PassType = 1 and PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Member'  and card_endtime>getdate())

						 select @outcurrentNum = isnull( count(1),0) from #tempmemeber where  time >= @laseAmend and PassType != 1 and PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Member'  and card_endtime>getdate())

						 select @totalincurrenMember   = @totalincurrenMember + @incurrentNum -@outcurrentNum;

						 if(@totalincurrenMember<0)
						   begin
						      set @totalincurrenTempMember = @totalincurrenMember;
						      set @totalincurrenMember = 0
						   end
					 end

					 /*访客为负数,从会员里扣*/
					 if(@totalincurreTempGuest!=0)
					   begin
					       set @totalincurrenMember = @totalincurrenMember + @totalincurreTempGuest
						   if(@totalincurrenMember<0)
						     begin
							    set @totalincurrenMember = 0;
							 end 
					   end


					 /*会员或员工为负数,从访客里扣*/
					 if(@totalincurrenTempMember!=0)
					   begin

					       set @totalincurrenGuest = @totalincurrenGuest + @totalincurrenTempMember;
						   if(@totalincurrenGuest<0)
						     begin
							    set @totalincurrenGuest = 0;
							 end
					   end


					    if(@totalincurrenTempMember!=0)
					   begin

					       set @totalincurrenGuest = @totalincurrenGuest + @totalincurrenTempMember;

						   if(@totalincurrenGuest<0)
						     begin
							    set @totalincurrenGuest = 0;
							 end
					   end
					
					/* end*/
					

					 declare @totalincurreTempBuses int = 0;
					 declare @totalincurreTempSPVs int = 0;
					 declare @totalincurrenTempCars int = 0;
				
					 
					  if(@totalincurrenBuses   !=-1)
				     begin

					     select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn  where type in ('1','10') 

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut 	 where type in ('1','10') 

						 select @totalincurrenBuses   = @totalincurrenBuses + @incurrentNum -@outcurrentNum;


						 if(@totalincurrenBuses <0)
						   begin
						      set @totalincurreTempBuses =@totalincurrenBuses;
						      set @totalincurrenBuses = 0
						   end
					 end


					  if(@totalincurrenSPVs   !=-1)
				     begin

					     select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn  where type in ('2','5','7','8','15','16','17','19','20','21','22')

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut 	 where type in ('2','5','7','8','15','16','17','19','20','21','22')

						 select @totalincurrenSPVs   = @totalincurrenSPVs + @incurrentNum -@outcurrentNum;

						 if(@totalincurrenSPVs <0)
						   begin
						      set @totalincurreTempSPVs =@totalincurrenSPVs;
						      set @totalincurrenSPVs = 0
						   end
					 end


					   if(@totalincurrenCars   !=-1)
				     begin
					  --   select @totalincurrenCars = convert(int,@totalincurrent) - convert(int,@totalincurrenBuses) - convert(int,@totalincurrenSPVs);

						 --if(@totalincurrenCars<0)
						 --  begin
						 --     set @totalincurrenCars = 0
						 --  end

						   select @incurrentNum = isnull( count(1),0) from #temptotalcurrentIn  where type not in ('1','10','2','5','7','8','15','16','17','19','20','21','22')

						 select @outcurrentNum = isnull( count(1),0) from #temptotalcurrentOut 	 where type not  in ('1','10','2','5','7','8','15','16','17','19','20','21','22')

						 select @totalincurrenCars   = @totalincurrenCars + @incurrentNum -@outcurrentNum;

						 if(@totalincurrenCars <0)
						   begin
						      set @totalincurrenTempCars =@totalincurrenCars;
						      set @totalincurrenCars = 0
						   end
				
					
					 end
				

				 /*巴士为负数,从私家车里扣*/
				  if(@totalincurreTempBuses!=0)
				    begin
					   set @totalincurrenCars = @totalincurrenCars + @totalincurreTempBuses;
					   if(@totalincurrenCars<0)
					     begin
						  set @totalincurrenCars = 0 ;
						 end
					end
				/*其它为负数,从私家车里扣*/
				if(@totalincurreTempSPVs!=0)
				   begin
				       set @totalincurrenCars = @totalincurrenCars + @totalincurreTempSPVs;

					    if(@totalincurrenCars<0)
					     begin
						  set @totalincurrenCars = 0 ;
						 end
				   end
				


				 select  @inpeople = isnull(sum(isnull(incount,0)),0) from [dbo].[BT_FlowData] where StartTime>=@begindate and endtime <=@enddate

				 select @totalPaidAmount =  isnull( sum(isnull(PaidAmount,0)),0) from tb_Transaction where [TransactionTime] between @begindate and @enddate
		
END

