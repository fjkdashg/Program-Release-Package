USE [Test1]
GO

/****** Object:  StoredProcedure [dbo].[CopySaleBillM]    Script Date: 08/24/2016 11:45:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[CopySaleBillM]
(
   @Vchcode BIGINT,   --被复制的单据
   @Vchtype INT,      --被复制的单据类型
   @VchcodeNew BIGINT, --复制新生成的单据
   @OperID VARCHAR(50) = '',--当前操作员ＩＤ
   @isnewnumber BIT=1	,
   @BtypeID VARCHAR(50)
)
AS
--*******************************************************
--老罗
--createdate：2013-01-25
--销售类单据的复制操作成功返回0，失败返回 <0 的数
--2014-03-24增加货运管理
--*******************************************************
BEGIN
	DECLARE @Ret int=0
	BEGIN TRY
	BEGIN
		 
		IF NOT EXISTS(SELECT 1 FROM Salebill WHERE vchcode=@vchcode ) 
		BEGIN
			SELECT 'A' AS ErrorType,'单据复制失败！<此单据已不存在>' AS ErrorMessage
			RETURN -100
		END
		ELSE IF exists(SELECT 1 FROM Salebill WHERE Redold='T' AND RedWord='T' AND vchcode=@vchcode)
		BEGIN
			SELECT 'A' AS ErrorType,'单据复制失败！<红单不能复制>' AS ErrorMessage
			RETURN -1
		END
		ELSE
		BEGIN
				--得到单据Number
		DECLARE @Billdate VARCHAR(10)='',@branchid VARCHAR(50)='',@Number VARCHAR(50)=''
		SET @BillDate=CONVERT(varchar(10),GETDATE(),120)
		SELECT TOP 1 @branchid=branchid,@Billdate=CASE WHEN @isnewnumber=0 THEN [date] ELSE @Billdate END,
       		@Number=CASE WHEN @isnewnumber=0 THEN [number] ELSE @Number END
       	FROM dbo.SaleBill WHERE vchcode=@Vchcode
        
        IF @isnewnumber=1
        Begin
			EXEC FN_VchNumber_Get @VchType, @BillDate, @Branchid,
            '127.0.0.1', 1, @Number OUTPUT
        END    
 		DECLARE @Time DATETIME
 		SELECT @Time=GETDATE()
 		DECLARE @sysUseGoodNumber INT,@sysUseGoodValidDate INT--系统配置是否启用批次管理、保质期管理
 		SELECT @sysUseGoodNumber=0,@sysUseGoodValidDate=0
 		SELECT @sysUseGoodNumber=ISNULL(SubValue,0) FROM dbo.SysData WHERE SubName='UseGoodNumber'
 		SELECT @sysUseGoodValidDate=ISNULL(SubValue,0) FROM dbo.SysData WHERE SubName='UseGoodValidDate'
 		INSERT	INTO Salebill( BillType       , VchType                  , Vchcode 
			  , Draft                  , Redold                   , [Date] 
			  , Number                 , BtypeId                  , BranchId 
			  , BranchId2              , EtypeId                  , KtypeId 
			  , KtypeId2               , IfCheck                  , Checke 
			  , Period                 , RedWord                  , Account 
			  , InputNo                , Qty                      , Total 
			  , InvoiceTag             , InvoiceTotal             , Dtypeid 
			  , VipCardID              , VipDiscount              , BarterType 
			  , InputNO1               , InputNO2                 , InputNO3 
			  , InputNO4               , InputNO5    			  , CheckAndAccept         
			  , IfTally 		       , LimitTime   
              , DlyVchcode             , ZdDiscount 			  , ZdDiscountprice        
              , Preferential           , AcceptState 			  , AtypeId                
              , AtypeTotal             , ExpandId 			      , BackMoney         
              , IsExported             , Flag 			          , YSYFTotal     
              , ForeignVchcode         , AccountTime 	          , SiteId 
              , RetailBackFlag         , CurrUnDoIntegral         
              , LastUnDoIntegral       
              , VerifyFlow             , LJYSYFTotal 	          , ForeVIPBalance         
              , OrderList              , Summary 		          , SkipFlag               
              , Comment                , Xw_Vsf1 		          , Xw_Vsf2                
              , Xw_Vsf3                , Xw_Vsf4 		          , Xw_Vsf5                
              , BranchId3              , PHID 			          , PrintNum               
              , checkdate              , TypeItem 		          , SourceVchType          
              , BillSource             , OgnVchCode 		      , NtfList                
              , Transit                , [Address] 		          , LinkMan                
              , LinkTel	               , CreateDate
					)
			SELECT	s.billtype       , s.VchType                  , @VchcodeNew 
			  , 1                      , 'F'                   , @BillDate 
			  , @Number                 , @BtypeID                  , s.BranchId 
			  , BranchId2              , EtypeId                  , KtypeId 
			  , KtypeId2               , IfCheck                  ,'' Checke 
			  , Period                 , 'F'                      , '' AS Account 
			  , @OperID                 , qty                      , Total
			  , InvoiceTag             , InvoiceTotal             , Dtypeid 
			  , 0 AS VipCardID         ,100 VipDiscount           , BarterType 
			  , InputNO1               , InputNO2                 , InputNO3 
			  , InputNO4               , InputNO5    			  , s.CheckAndAccept         
			  , 0 		               , LimitTime   
              , 0                      , ZdDiscount 			  , ZdDiscountprice        
              , Preferential           , AcceptState 			  , AtypeId                
              , AtypeTotal             , ExpandId 			      , BackMoney         
              , IsExported             , Flag 			          ,0 AS  YSYFTotal     
              , ForeignVchcode         , @Time 	          , SiteId 
              , RetailBackFlag         ,0 AS  CurrUnDoIntegral         
              , 0 AS LastUnDoIntegral       
              , VerifyFlow             ,0 AS  LJYSYFTotal 	      , ForeVIPBalance         
              , '' OrderList           , '批量'+Summary 		          , SkipFlag               
              , s.Comment                , Xw_Vsf1 		          , Xw_Vsf2                
              , Xw_Vsf3                , Xw_Vsf4 		          , Xw_Vsf5                
              , BranchId3              , PHID 			          , PrintNum               
              , checkdate              , TypeItem 		          ,0 AS SourceVchType          
              , '' AS BillSource       , 0 AS OgnVchCode 		  ,'' NtfList                
              , Transit                , b.[Address] 		          , b.Person                
              , b.Tel1                ,@Time
              	 
			  FROM Salebill s left join [Btype] b on b.TypeId=@BtypeID WHERE s.Vchcode=@Vchcode
		--添加送过地址等信息关联更新
		--写二级明细--2014-01-07 启华和余姐一致同意复制时将Costmode值强制写为0，这会导致复制单据过账时会按取价原则重新取价
		SET @Ret=-2
		INSERT INTO dbo.SaleBillData(
					BillType       , Vchcode        , Vchtype 
				  , Draft                  , RedOld 
				  , RedWord          , AtypeId        , BtypeId 
				  , BranchId         , EtypeId        , KtypeId 
				  , PtypeId          , Qty            , Discount 
				  , DiscountPrice    , CostPrice      , CostTotal 
				  , Retailprice      , Price          , Total 
				  , TaxPrice         , TaxTotal       , [Date] 
				  , Usedtype         , Period         , Tax_total 
				  , Tax              , DiscountTotal  , CostMode 
				  , Unit             , WLDZGroup      , PDetail 
				  , Dtypeid          , InvoiceTag     , InvoiceTotal 
				  , ZdDiscount       , ZdDiscountPrice, Colorid 
				  , BargainTotal     , VipCardID      , VipDiscount 
				  , IfSupply         , [Convert]        , JoinCostPrice 
				  , JoinCostTotal    , MarketDiscount , MarketDiscount1 
				  , SaleMoney        , PackCode       , PackRate 
				  , PackQty          , ForeignDlyOrder, Comment 
				  , SiteId           , RowOrder       , SaleMode 
				  , CustValue1       , CustValue2     , CustValue3 
				  , CustValue4       , CustValue5     , CustValue6 
				  , OpID             , PHRows         , UnitRate  
				  , SingleUnit       , Tax_price      
				  , OrdDlyorder      , NtfDlyOrder    , OrdVchcode 
				  , NtfVchcode		 ,DUQty)
		SELECT  BillType                    , @VchcodeNew          , Vchtype 
				  , 1                       , 'F' 
				  , 'F'                 , AtypeId              , BtypeId 
				  , BranchId                , EtypeId              , KtypeId 
				  , PtypeId                 , Qty                  , Discount 
				  , DiscountPrice           ,0 AS CostPrice        ,0 AS CostTotal 
				  , Retailprice             , Price                , Total 
				  , TaxPrice                , TaxTotal             , @BillDate 
				  , Usedtype                , Period               , Tax_total 
				  , Tax                     , DiscountTotal        ,0 AS CostMode 
				  , Unit                    , WLDZGroup            , PDetail 
				  , Dtypeid                 , InvoiceTag           , InvoiceTotal 
				  , ZdDiscount              , ZdDiscountPrice      , Colorid 
				  , BargainTotal            ,0 AS VipCardID        ,100 VipDiscount 
				  , IfSupply                , [Convert]            , JoinCostPrice 
				  , JoinCostTotal           , MarketDiscount       , MarketDiscount1 
				  , SaleMoney               , PackCode             , PackRate 
				  , PackQty                 , ForeignDlyOrder      , Comment 
				  , SiteId                  , RowOrder             , SaleMode 
				  , CustValue1              , CustValue2           , CustValue3 
				  , CustValue4              , CustValue5           , CustValue6 
				  , OpID                    , PHRows               , UnitRate  
				  , SingleUnit              , Tax_price      
				  ,0 as OrdDlyorder         ,0 AS NtfDlyOrder      ,0 AS OrdVchcode 
				  ,0 AS NtfVchcode			,DUQty
        FROM SalebillData WHERE vchcode=@vchcode
		--写三级明细
		SET @Ret=-3	
		
		INSERT INTO dbo.SaleBillDataDetail(
					DlyOrder             ,  Draft                    ,  SizeID 
				  ,  ColorID                ,  Qty                    ,  Total 
				  ,  TaxTotal               ,  Tax_Total              ,  BargainTotal 
				  ,  [Convert]              ,  DiscountTotal          ,  CostTotal 
				  ,  SaleMoney              ,  JoinCostTotal          ,  Usedtype 
				  ,  PHRows                 ,  Vchcode                
				  ,  OrdDlyorder            ,  NtfDlyOrder            ,  GoodsNumber 
				  ,  ProduceDate            ,  ValidDate              ,  NumberOrder
				  ,  Vchtype				,  DUQty)
		SELECT b.DlyOrder                   , 1                       , a.SizeID 
				  , a.ColorID               , a.Qty                   , a.Total 
				  , a.TaxTotal              , a.Tax_Total             , a.BargainTotal 
				  , a.[Convert]             , a.DiscountTotal         , 0 AS CostTotal 
				  , a.SaleMoney             , a.JoinCostTotal         , a.Usedtype 
				  , a.PHRows                , @VchCodeNew                
				  ,0 AS OrdDlyorder         ,0 AS NtfDlyOrder         
				  ,(CASE WHEN @sysUseGoodNumber=1 AND ISNULL(p. UseGoodNumber,0)=1 THEN a.GoodsNumber ELSE  '' END) AS GoodsNumber
				  ,(CASE WHEN @sysUseGoodValidDate=1 AND ISNULL(p. UseGoodValidDate,0)=1 THEN a.ProduceDate ELSE  '' END) AS ProduceDate
				  ,(CASE WHEN @sysUseGoodValidDate=1 AND ISNULL(p. UseGoodValidDate,0)=1 THEN a.ValidDate ELSE  '' END) AS ValidDate
				  ,(CASE WHEN @sysUseGoodNumber=1 AND ISNULL(p. UseGoodNumber,0)=1 THEN a.NumberOrder ELSE  0 END) AS NumberOrder
				  , a.Vchtype				,a.DUQty
		FROM SaleBillDataDetail a INNER JOIN dbo.SaleBillData b 
			   ON a.vchcode=@vchcode AND a.phRows=b.phRows AND a.UsedType=b.usedtype AND b.vchcode=@VchcodeNew
			   INNER JOIN dbo.Ptype p ON p.TypeID=b.PtypeId
			   
		/*
		-- 写科目表
		SET @Ret=-4	
		IF EXISTS(SELECT 1 FROM SaleBillA WHERE vchcode=@Vchcode)
		BEGIN
			INSERT INTO dbo.SaleBillA (
				BillType        , VchType       , VchCode 
			  , Draft					 , AtypeId       , BtypeId 
			  , BranchId                 , EtypeId       , KtypeId 
			  , Total                    , [Date]          , Period 
			  , UsedType                 , Comment       , WLDZGroup 
			                             , Dtypeid       , InvoiceTag 
			  , InvoiceTotal             , RedOld        , RedWord 
			  , VipCardID)
			SELECT BillType       , VchType       , @VchCodeNew 
			  , 1    					 , AtypeId       , BtypeId 
			  , BranchId                 , EtypeId       , KtypeId 
			  , Total                    , @BillDate          , Period 
			  , UsedType                 , Comment       , WLDZGroup 
			                             , Dtypeid       , InvoiceTag 
			  , InvoiceTotal             , 'F'        , 'F'
			  ,0 AS VipCardID 
		    FROM SalebillA WHERE vchcode=@Vchcode AND Comment<>'System-'
		END
		*/
		/*
		--写商品唯一码
		IF EXISTS(SELECT 1 FROM PtypeUniqueCode WHERE Vchcode=@Vchcode)
		BEGIN
			SET @ret=-5
			
			INSERT INTO dbo.PtypeUniqueCode
			        ( VchCode ,			PtypeID ,         ColorID ,
			          SizeID ,          UniqueCode ,       dlyorder ,
			          TracePrice ,      TraceDisCount,     Tax,
			          Taxprice
			        )
			SELECT    @VchCodeNew ,         PtypeID ,         ColorID ,
			          SizeID ,          UniqueCode ,      dlyorder ,
			          TracePrice ,      TraceDisCount,     Tax,
			          Taxprice
			FROM PtypeUniqueCode WHERE Vchcode=@Vchcode
		END	
		*/
		--写货运信息
		IF EXISTS(SELECT 1 FROM CarriageBill WHERE Vchcode=@Vchcode)
		BEGIN
			SET @ret=-6
			INSERT INTO dbo.CarriageBill
			        ( Vchcode ,	        PayMode ,		  IsDSK ,
			          CarriageTotal ,   BtypeID ,		  TrackNumber ,
			          Atypeid ,		    AtypeTotal,			dskTotal	
			         )
			SELECT    @VchCodeNew ,	        PayMode ,		  IsDSK ,
			          CarriageTotal ,   BtypeID ,		  TrackNumber ,
			          Atypeid ,	        AtypeTotal,		dskTotal
			FROM CarriageBill WHERE vchcode =@vchcode
		END
		--处理虚拟库存.
		DECLARE @tvpBillDataTemp AS tvpBillDataGoods,@tvpBillDataDetailTemp AS tvpBillDataDetailGoods
		INSERT INTO @tvpBillDataTemp
			  (Vchcode  ,dlyorder ,KtypeId,PtypeId,Qty,CostTotal ,Usedtype ,PHRows)
		SELECT Vchcode  ,dlyorder ,KtypeId,PtypeId,Qty,CostTotal ,Usedtype ,PHRows
		FROM Salebilldata WHERE vchcode=@Vchcode
		
		INSERT INTO @tvpBillDataDetailTemp
		      (DlyOrder , SizeID   ,ColorID ,Qty   ,CostTotal,Usedtype,PHRows,Vchcode,GoodsNumber,ValidDate,NumberOrder)
		SELECT DlyOrder , SizeID   ,ColorID ,Qty   ,CostTotal,Usedtype,PHRows,Vchcode,GoodsNumber,ValidDate,NumberOrder
		FROM SalebilldataDetail WHERE vchcode=@Vchcode
		IF EXISTS(SELECT TOP 1 1 FROM Salebill WHERE vchcode=@vchcode) 
			AND exists(SELECT TOP 1 1 FROM dbo.VchType WHERE Vchtype=@vchtype AND VirtualFlag=1 )--先判断有没有记录，有则重新增加
		BEGIN
			
			EXEC @Ret=dbo.BillUpdateGoodsVirtualQty @tvpBillDataGoods = @tvpBillDataTemp, -- tvpBillData
			    @tvpBillDataDetailGoods = @tvpBillDataDetailTemp ,@sign=1-- tvpBillDataDetail
			IF @Ret<0 
			BEGIN
				SELECT 'A' AS ErrorType,'处理虚拟库存失败！' AS ErrorMessage
				RETURN @Ret     
			END     
		END	
		 --判断负库存
	    EXEC @Ret=dbo.BillCheckNegativeQty @tvpBillDataGoods = @tvpBillDataTemp, -- tvpBillData
	      @tvpBillDataDetailGoods = @tvpBillDataDetailTemp, -- tvpBillDataDetail
	      @CheckType =0 -- tinyint
	    IF @Ret <0 RETURN @Ret	
		--更新单据编号数
		EXEC dbo.FZModifyVchnumber @nVchtype = @Vchtype , @Date = @BillDate
		
		SET @Ret=0 --不能删除，表示前面的语句都执行成功
		END
		
	END
	END TRY
	BEGIN CATCH
		IF @Ret=-1 SELECT 'A' AS ErrorType,'单据复制失败！<处理主单>' AS ErrorMessage
		IF @Ret=-2 SELECT 'A' AS ErrorType,'单据复制失败！<处理二级明细>' AS ErrorMessage
		IF @Ret=-3 SELECT 'A' AS ErrorType,'单据复制失败！<处理三级明细>' AS ErrorMessage
		--IF @Ret=-4 SELECT 'A' AS ErrorType,'单据复制失败！<处理科目>' AS ErrorMessage
		--IF @Ret=-5 SELECT 'A' AS ErrorType,'单据复制失败！<处理商品唯一码>' AS ErrorMessage
		IF @Ret=-6 SELECT 'A' AS ErrorType,'单据保存失败！<处理单据货运信息>' AS ErrorMessage
		RETURN @Ret
	END CATCH
    RETURN @ret
END



GO


