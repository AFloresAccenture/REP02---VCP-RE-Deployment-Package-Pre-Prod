create or replace PACKAGE BODY       XXNBTY_MSCREP02_SALES_ORDR_PKG 
 ---------------------------------------------------------------------------------------------
  /*
  Package Name	: XXNBTY_MSCREP02_SALES_ORDR_PKG
  Author's Name: Albert John Flores
  Date written: 10-Jun-2015
  RICEFW Object: REP02
  Description: Package that will generate detailed error log for SALES ORDER using FND_FILE. 
  Program Style:
  Maintenance History:
  Date         Issue#  Name         			    Remarks
  -----------  ------  -------------------		------------------------------------------------
  10-Jun-2015          Albert John Flores	  	Initial Development
  17-Jul-2015          Daniel Rodil             modified output due to limitation in SQL*Plus when compiling 
                                                  encountered SP2-0027: Input is too long (> 2499 characters) - line ignored 
												  use v_header
  22-Jul-2015		   Albert John Flores		Removed the creation_date = sysdate in the where clause of the query												  
  */
  ----------------------------------------------------------------------------------------------
 IS 
  PROCEDURE main_proc ( x_retcode   OUT VARCHAR2
					   ,x_errbuf    OUT VARCHAR2)
  IS
   v_request_id    		NUMBER := fnd_global.conc_request_id;  
   v_main_request_id 	NUMBER; 
   v_child_request_id 	NUMBER; 
   v_header  VARCHAR2(32000);  -- drodil 17-july-2015
	
		CURSOR c_req_id (p_request_id NUMBER) 
		IS 
		SELECT a.parent_request_id 
		FROM apps.fnd_concurrent_requests a 
		WHERE a.request_id = p_request_id;
		
		CURSOR c_gen_error (p_main_request_id NUMBER)
		IS
		SELECT '"'||ERROR_TEXT                      
				|| '","' ||ITEM_NAME                 
				|| '","' ||ORGANIZATION_CODE                 
				|| '","' ||SR_INSTANCE_CODE                 
				|| '","' ||CUSTOMER_NAME
				|| '","' ||INVENTORY_ITEM_ID                 
				|| '","' ||ORGANIZATION_ID                   
				|| '","' ||DEMAND_ID                         
				|| '","' ||PRIMARY_UOM_QUANTITY              
				|| '","' ||RESERVATION_TYPE                  
				|| '","' ||RESERVATION_QUANTITY              
				|| '","' ||DEMAND_SOURCE_TYPE                
				|| '","' ||DEMAND_SOURCE_HEADER_ID           
				|| '","' ||COMPLETED_QUANTITY                
				|| '","' ||SUBINVENTORY                      
				|| '","' ||DEMAND_CLASS                      
				|| '","' ||REQUIREMENT_DATE                  
				|| '","' ||DEMAND_SOURCE_LINE                
				|| '","' ||DEMAND_SOURCE_DELIVERY            
				|| '","' ||DEMAND_SOURCE_NAME                
				|| '","' ||PARENT_DEMAND_ID                  
				|| '","' ||DELETED_FLAG                      
				|| '","' ||LAST_UPDATE_DATE                  
				|| '","' ||LAST_UPDATED_BY                   
				|| '","' ||CREATION_DATE                     
				|| '","' ||CREATED_BY                        
				|| '","' ||LAST_UPDATE_LOGIN                 
				|| '","' ||REQUEST_ID                        
				|| '","' ||PROGRAM_APPLICATION_ID            
				|| '","' ||PROGRAM_ID                        
				|| '","' ||PROGRAM_UPDATE_DATE               
				|| '","' ||REFRESH_ID                        
				|| '","' ||SR_INSTANCE_ID                    
				|| '","' ||SALES_ORDER_NUMBER                
				|| '","' ||SALESREP_CONTACT                  
				|| '","' ||ORDERED_ITEM_ID                   
				|| '","' ||AVAILABLE_TO_MRP                  
				|| '","' ||CUSTOMER_ID                       
				|| '","' ||SHIP_TO_SITE_USE_ID               
				|| '","' ||BILL_TO_SITE_USE_ID               
				|| '","' ||LINE_NUM                          
				|| '","' ||TERRITORY_ID                      
				|| '","' ||UPDATE_SEQ_NUM                    
				|| '","' ||DEMAND_TYPE                       
				|| '","' ||PROJECT_ID                        
				|| '","' ||TASK_ID                           
				|| '","' ||PLANNING_GROUP                    
				|| '","' ||END_ITEM_UNIT_NUMBER              
				|| '","' ||DEMAND_PRIORITY                   
				|| '","' ||ATP_REFRESH_NUMBER                
				|| '","' ||REQUEST_DATE                      
				|| '","' ||SELLING_PRICE                     
				|| '","' ||DEMAND_VISIBLE                    
				|| '","' ||FORECAST_VISIBLE                  
				|| '","' ||CTO_FLAG                          
				|| '","' ||ORIGINAL_SYSTEM_REFERENCE         
				|| '","' ||ORIGINAL_SYSTEM_LINE_REFERENCE    
				|| '","' ||COMPANY_ID                        
				|| '","' ||COMPANY_NAME                         
				|| '","' ||ORDERED_ITEM_NAME                     
				|| '","' ||SHIP_TO_SITE_CODE                 
				|| '","' ||BILL_TO_SITE_CODE                  
				|| '","' ||PROJECT_NUMBER                    
				|| '","' ||TASK_NUMBER                       
				|| '","' ||MESSAGE_ID                        
				|| '","' ||PROCESS_FLAG                      
				|| '","' ||BATCH_ID                          
				|| '","' ||DATA_SOURCE_TYPE                  
				|| '","' ||ST_TRANSACTION_ID                        
				|| '","' ||COMMENTS                          
				|| '","' ||ORDER_RELEASE_NUMBER              
				|| '","' ||END_ORDER_NUMBER                  
				|| '","' ||END_ORDER_RELEASE_NUMBER          
				|| '","' ||END_ORDER_LINE_NUMBER             
				|| '","' ||END_ORDER_TYPE                    
				|| '","' ||NEW_ORDER_PLACEMENT_DATE          
				|| '","' ||ORIGINAL_ITEM_ID                  
				|| '","' ||PROMISE_DATE                      
				|| '","' ||ORIGINAL_ITEM_NAME                
				|| '","' ||LINK_TO_LINE_ID                   
				|| '","' ||CUST_PO_NUMBER                    
				|| '","' ||CUSTOMER_LINE_NUMBER              
				|| '","' ||MFG_LEAD_TIME                     
				|| '","' ||ORDER_DATE_TYPE_CODE              
				|| '","' ||LATEST_ACCEPTABLE_DATE            
				|| '","' ||SHIPPING_METHOD_CODE              
				|| '","' ||SCHEDULE_ARRIVAL_DATE             
				|| '","' ||ORG_FIRM_FLAG                     
				|| '","' ||SHIP_SET_ID                       
				|| '","' ||ARRIVAL_SET_ID                    
				|| '","' ||SOURCE_DEMAND_SOURCE_HEADER_ID    
				|| '","' ||SOURCE_ORGANIZATION_ID            
				|| '","' ||SOURCE_ORIGINAL_ITEM_ID           
				|| '","' ||SOURCE_DEMAND_ID                  
				|| '","' ||SOURCE_INVENTORY_ITEM_ID          
				|| '","' ||SOURCE_CUSTOMER_ID                
				|| '","' ||SOURCE_BILL_TO_SITE_USE_ID        
				|| '","' ||SOURCE_SHIP_TO_SITE_USE_ID        
				|| '","' ||ATO_LINE_ID                       
				|| '","' ||SHIP_SET_NAME                     
				|| '","' ||ARRIVAL_SET_NAME                  
				|| '","' ||SALESREP_ID                       
				|| '","' ||INTRANSIT_LEAD_TIME               
				|| '","' ||SOURCE_DEMAND_SOURCE_LINE         
				|| '","' ||ROW_TYPE                          
				|| '","' ||REVISED_DMD_DATE                  
				|| '","' ||REVISED_DMD_PRIORITY              
				|| '","' ||ITEM_TYPE_ID                      
				|| '","' ||ITEM_TYPE_VALUE||'"' SALES_ORDER_DATA_TABLE       
				FROM msc_st_sales_orders 
				WHERE process_flag = 3 AND abs(request_id) >= p_main_request_id;
						 
	TYPE err_tab_type		   IS TABLE OF c_gen_error%ROWTYPE;
	  
	l_detailed_error_tab	   err_tab_type; 
	v_step          		   NUMBER;
	v_mess          		   VARCHAR2(500);
	
   BEGIN
	v_step := 1;
		v_child_request_id := v_request_id; 
		
		LOOP 
			OPEN c_req_id(v_child_request_id); 
			FETCH c_req_id INTO v_main_request_id; 
			EXIT WHEN c_req_id%notfound; 
			
			IF v_main_request_id = -1 THEN 
				v_main_request_id := v_child_request_id; 
				EXIT; 
			ELSE 
				v_child_request_id := v_main_request_id; 
			END IF;
			CLOSE c_req_id; 
		END LOOP;
	v_step := 2;		
		IF c_req_id%isopen THEN 
			CLOSE c_req_id; 
		END IF; 
	v_step := 3;	
		FND_FILE.PUT_LINE(FND_FILE.LOG,'v_main_request_id : ' || v_main_request_id);
		
     -- drodil 17-july-2015 start
     v_header := null;
     v_header := v_header || 'ERROR_TEXT ,ITEM_NAME ,ORGANIZATION_CODE ,SR_INSTANCE_CODE ,CUSTOMER_NAME ,INVENTORY_ITEM_ID ,ORGANIZATION_ID ,';
	 v_header := v_header || 'DEMAND_ID ,PRIMARY_UOM_QUANTITY ,RESERVATION_TYPE ,RESERVATION_QUANTITY ,DEMAND_SOURCE_TYPE ,DEMAND_SOURCE_HEADER_ID ,';
	 v_header := v_header || 'COMPLETED_QUANTITY ,SUBINVENTORY ,DEMAND_CLASS ,REQUIREMENT_DATE ,DEMAND_SOURCE_LINE ,DEMAND_SOURCE_DELIVERY ,';
	 v_header := v_header || 'DEMAND_SOURCE_NAME ,PARENT_DEMAND_ID ,DELETED_FLAG ,LAST_UPDATE_DATE ,LAST_UPDATED_BY ,CREATION_DATE ,CREATED_BY ,';
	 v_header := v_header || 'LAST_UPDATE_LOGIN ,REQUEST_ID ,PROGRAM_APPLICATION_ID ,PROGRAM_ID ,PROGRAM_UPDATE_DATE ,REFRESH_ID ,SR_INSTANCE_ID ,';
	 v_header := v_header || 'SALES_ORDER_NUMBER ,SALESREP_CONTACT ,ORDERED_ITEM_ID ,AVAILABLE_TO_MRP ,CUSTOMER_ID ,SHIP_TO_SITE_USE_ID ,';
	 v_header := v_header || 'BILL_TO_SITE_USE_ID ,LINE_NUM ,TERRITORY_ID ,UPDATE_SEQ_NUM ,DEMAND_TYPE ,PROJECT_ID ,TASK_ID ,PLANNING_GROUP ,';
	 v_header := v_header || 'END_ITEM_UNIT_NUMBER ,DEMAND_PRIORITY ,ATP_REFRESH_NUMBER ,REQUEST_DATE ,SELLING_PRICE ,DEMAND_VISIBLE ,';
	 v_header := v_header || 'FORECAST_VISIBLE ,CTO_FLAG ,ORIGINAL_SYSTEM_REFERENCE ,ORIGINAL_SYSTEM_LINE_REFERENCE ,COMPANY_ID ,COMPANY_NAME ,';
	 v_header := v_header || 'ORDERED_ITEM_NAME ,SHIP_TO_SITE_CODE ,BILL_TO_SITE_CODE ,PROJECT_NUMBER ,TASK_NUMBER ,MESSAGE_ID ,PROCESS_FLAG ,';
	 v_header := v_header || 'BATCH_ID ,DATA_SOURCE_TYPE ,ST_TRANSACTION_ID ,COMMENTS ,ORDER_RELEASE_NUMBER ,END_ORDER_NUMBER ,';
	 v_header := v_header || 'END_ORDER_RELEASE_NUMBER ,END_ORDER_LINE_NUMBER ,END_ORDER_TYPE ,NEW_ORDER_PLACEMENT_DATE ,ORIGINAL_ITEM_ID ,';
	 v_header := v_header || 'PROMISE_DATE ,ORIGINAL_ITEM_NAME ,LINK_TO_LINE_ID ,CUST_PO_NUMBER ,CUSTOMER_LINE_NUMBER ,MFG_LEAD_TIME ,';
	 v_header := v_header || 'ORDER_DATE_TYPE_CODE ,LATEST_ACCEPTABLE_DATE ,SHIPPING_METHOD_CODE ,SCHEDULE_ARRIVAL_DATE ,ORG_FIRM_FLAG ,';
	 v_header := v_header || 'SHIP_SET_ID ,ARRIVAL_SET_ID ,SOURCE_DEMAND_SOURCE_HEADER_ID ,SOURCE_ORGANIZATION_ID ,SOURCE_ORIGINAL_ITEM_ID ,';
	 v_header := v_header || 'SOURCE_DEMAND_ID ,SOURCE_INVENTORY_ITEM_ID ,SOURCE_CUSTOMER_ID ,SOURCE_BILL_TO_SITE_USE_ID ,SOURCE_SHIP_TO_SITE_USE_ID ,';
	 v_header := v_header || 'ATO_LINE_ID ,SHIP_SET_NAME ,ARRIVAL_SET_NAME ,SALESREP_ID ,INTRANSIT_LEAD_TIME ,SOURCE_DEMAND_SOURCE_LINE ,';
	 v_header := v_header || 'ROW_TYPE ,REVISED_DMD_DATE ,REVISED_DMD_PRIORITY ,ITEM_TYPE_ID ,ITEM_TYPE_VALUE ';
		
	--	FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ERROR_TEXT ,ITEM_NAME ,ORGANIZATION_CODE ,SR_INSTANCE_CODE ,....
	 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_header);		
     -- drodil 17-july-2015  -- end
		
		OPEN c_gen_error(v_main_request_id);
	v_step := 4;	
		FETCH c_gen_error BULK COLLECT INTO l_detailed_error_tab;
		FOR i in 1..l_detailed_error_tab.COUNT
			LOOP
				FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_detailed_error_tab(i).SALES_ORDER_DATA_TABLE );
			END LOOP;
		CLOSE c_gen_error;
	v_step := 5;
	
	EXCEPTION
		WHEN OTHERS THEN
		  v_mess := 'At step ['||v_step||'] - SQLCODE [' ||SQLCODE|| '] - ' ||substr(SQLERRM,1,100);
		  x_errbuf  := v_mess;
		  x_retcode := 2; 

   END main_proc;
		
END XXNBTY_MSCREP02_SALES_ORDR_PKG;
/
show errors;
