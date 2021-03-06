IF(exists(select 1 from sysobjects where id = object_id('sp_getMemeberCode')))
  begin
      drop PROCEDURE sp_getMemeberCode
  end
Go
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-08-04,,>
-- Description:	<自動成員編號,,sp_getMemeberCode '0'>
-- =============================================
CREATE PROCEDURE sp_getMemeberCode
	@memebercode nvarchar(max) output
AS
BEGIN
	
	declare @prefix nvarchar(max)= '',@tempmemebercode nvarchar(max) = @memebercode;
	if(exists(select 1 from BT_SystemParam where ParamName='ZH_OWNER_Member_Code_Need_HandInput' and ParamValue = '0'))
	  begin
	        --自動生成
			select @prefix = ParamValue from  BT_SystemParam where ParamName = 'ZH_OWNER_Member_Code_Prefix'
	     
				select  convert(int, dbo.GET_NUMBER(code)) as code into #zh_members FROM ZH_Members  where deleted = 0

			select @memebercode = @prefix+ convert(nvarchar(max), convert(int,max(CODE)+1)) FROM #zh_members
	  end
	  else 
	  begin
	     set @memebercode = '';
	  end
	  if(@tempmemebercode='0')
	    begin
		   select @memebercode
		end

END
go
