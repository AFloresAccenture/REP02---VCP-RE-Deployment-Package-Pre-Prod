create or replace PACKAGE BODY       XXNBTY_MSCREP02_IN_TRANSIT_PKG 
 ---------------------------------------------------------------------------------------------
  /*
  Package Name	: XXNBTY_MSCREP02_IN_TRANSIT_PKG
  Author's Name: Albert John Flores
  Date written: 02-JUN-2015
  RICEFW Object: REP02
  Description: Package that will generate detailed error log for IN TRANSIT using FND_FILE. 
  Program Style:
  Maintenance History:
  Date         Issue#  Name         			    Remarks
  -----------  ------  -------------------		------------------------------------------------
  02-JUN-2015          Albert John Flores	  	Initial Development
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
				|| '","' ||FROM_ORGANIZATION_CODE                    
				|| '","' ||ORDER_NUMBER                      
				|| '","' ||ITEM_NAME                         
				|| '","' ||ORGANIZATION_CODE				
				|| '","' ||PLAN_ID                           
				|| '","' ||TRANSACTION_ID                    
				|| '","' ||INVENTORY_ITEM_ID                 
				|| '","' ||ORGANIZATION_ID                   
				|| '","' ||SCHEDULE_DESIGNATOR_ID            
				|| '","' ||SOURCE_SCHEDULE_NAME              
				|| '","' ||REVISION                          
				|| '","' ||UNIT_NUMBER                       
				|| '","' ||NEW_SCHEDULE_DATE                 
				|| '","' ||OLD_SCHEDULE_DATE                 
				|| '","' ||NEW_WIP_START_DATE                
				|| '","' ||OLD_WIP_START_DATE                
				|| '","' ||FIRST_UNIT_COMPLETION_DATE        
				|| '","' ||LAST_UNIT_COMPLETION_DATE         
				|| '","' ||FIRST_UNIT_START_DATE             
				|| '","' ||LAST_UNIT_START_DATE              
				|| '","' ||DISPOSITION_ID                    
				|| '","' ||DISPOSITION_STATUS_TYPE           
				|| '","' ||ORDER_TYPE                        
				|| '","' ||SUPPLIER_ID                       
				|| '","' ||NEW_ORDER_QUANTITY                
				|| '","' ||OLD_ORDER_QUANTITY                
				|| '","' ||NEW_ORDER_PLACEMENT_DATE          
				|| '","' ||OLD_ORDER_PLACEMENT_DATE          
				|| '","' ||RESCHEDULE_DAYS                   
				|| '","' ||RESCHEDULE_FLAG                   
				|| '","' ||SCHEDULE_COMPRESS_DAYS            
				|| '","' ||NEW_PROCESSING_DAYS               
				|| '","' ||PURCH_LINE_NUM                    
				|| '","' ||QUANTITY_IN_PROCESS               
				|| '","' ||IMPLEMENTED_QUANTITY              
				|| '","' ||FIRM_PLANNED_TYPE                 
				|| '","' ||FIRM_QUANTITY                     
				|| '","' ||FIRM_DATE                         
				|| '","' ||IMPLEMENT_DEMAND_CLASS            
				|| '","' ||IMPLEMENT_DATE                    
				|| '","' ||IMPLEMENT_QUANTITY                
				|| '","' ||IMPLEMENT_FIRM                    
				|| '","' ||IMPLEMENT_WIP_CLASS_CODE          
				|| '","' ||IMPLEMENT_JOB_NAME                
				|| '","' ||IMPLEMENT_DOCK_DATE               
				|| '","' ||IMPLEMENT_STATUS_CODE             
				|| '","' ||IMPLEMENT_UOM_CODE                
				|| '","' ||IMPLEMENT_LOCATION_ID             
				|| '","' ||IMPLEMENT_SOURCE_ORG_ID           
				|| '","' ||IMPLEMENT_SUPPLIER_ID             
				|| '","' ||IMPLEMENT_SUPPLIER_SITE_ID        
				|| '","' ||IMPLEMENT_AS                      
				|| '","' ||RELEASE_STATUS                    
				|| '","' ||LOAD_TYPE                         
				|| '","' ||PROCESS_SEQ_ID                    
				|| '","' ||SCO_SUPPLY_FLAG                   
				|| '","' ||ALTERNATE_BOM_DESIGNATOR          
				|| '","' ||ALTERNATE_ROUTING_DESIGNATOR      
				|| '","' ||OPERATION_SEQ_NUM                 
				|| '","' ||SOURCE                            
				|| '","' ||BY_PRODUCT_USING_ASSY_ID          
				|| '","' ||SOURCE_ORGANIZATION_ID            
				|| '","' ||SOURCE_SR_INSTANCE_ID             
				|| '","' ||SOURCE_SUPPLIER_SITE_ID           
				|| '","' ||SOURCE_SUPPLIER_ID                
				|| '","' ||SHIP_METHOD                       
				|| '","' ||WEIGHT_CAPACITY_USED              
				|| '","' ||VOLUME_CAPACITY_USED              
				|| '","' ||SOURCE_SUPPLY_SCHEDULE_NAME       
				|| '","' ||NEW_SHIP_DATE                     
				|| '","' ||NEW_DOCK_DATE                     
				|| '","' ||LINE_ID                           
				|| '","' ||PROJECT_ID                        
				|| '","' ||TASK_ID                           
				|| '","' ||PLANNING_GROUP                    
				|| '","' ||IMPLEMENT_PROJECT_ID              
				|| '","' ||IMPLEMENT_TASK_ID                 
				|| '","' ||IMPLEMENT_SCHEDULE_GROUP_ID       
				|| '","' ||IMPLEMENT_BUILD_SEQUENCE          
				|| '","' ||IMPLEMENT_ALTERNATE_BOM           
				|| '","' ||IMPLEMENT_ALTERNATE_ROUTING       
				|| '","' ||IMPLEMENT_UNIT_NUMBER             
				|| '","' ||IMPLEMENT_LINE_ID                 
				|| '","' ||RELEASE_ERRORS                    
				|| '","' ||NUMBER1                           
				|| '","' ||SOURCE_ITEM_ID                      
				|| '","' ||SCHEDULE_GROUP_ID                 
				|| '","' ||SCHEDULE_GROUP_NAME               
				|| '","' ||BUILD_SEQUENCE                    
				|| '","' ||WIP_ENTITY_ID                     
				|| '","' ||WIP_ENTITY_NAME                   
				|| '","' ||WO_LATENESS_COST                  
				|| '","' ||IMPLEMENT_PROCESSING_DAYS         
				|| '","' ||DELIVERY_PRICE                    
				|| '","' ||LATE_SUPPLY_DATE                  
				|| '","' ||LATE_SUPPLY_QTY                   
				|| '","' ||SUBINVENTORY_CODE                 
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
				|| '","' ||SR_INSTANCE_ID                    
				|| '","' ||SCHEDULE_DESIGNATOR               
				|| '","' ||VENDOR_ID                         
				|| '","' ||VENDOR_SITE_ID                    
				|| '","' ||SUPPLIER_SITE_ID                  
				|| '","' ||PURCH_ORDER_ID                    
				|| '","' ||EXPECTED_SCRAP_QTY                
				|| '","' ||QTY_SCRAPPED                      
				|| '","' ||QTY_COMPLETED                     
				|| '","' ||LOT_NUMBER                        
				|| '","' ||EXPIRATION_DATE                   
				|| '","' ||WIP_STATUS_CODE                   
				|| '","' ||DAILY_RATE                        
				|| '","' ||LOCATOR_ID                        
				|| '","' ||SERIAL_NUMBER                     
				|| '","' ||REFRESH_ID                        
				|| '","' ||LOCATOR_NAME                      
				|| '","' ||ONHAND_SOURCE_TYPE                
				|| '","' ||SR_MTL_SUPPLY_ID                  
				|| '","' ||DEMAND_CLASS                      
				|| '","' ||FROM_ORGANIZATION_ID              
				|| '","' ||WIP_SUPPLY_TYPE                   
				|| '","' ||PO_LINE_ID                        
				|| '","' ||BILL_SEQUENCE_ID                  
				|| '","' ||ROUTING_SEQUENCE_ID               
				|| '","' ||COPRODUCTS_SUPPLY                 
				|| '","' ||CFM_ROUTING_FLAG                  
				|| '","' ||COMPANY_ID                        
				|| '","' ||COMPANY_NAME            
				|| '","' ||SUPPLIER_NAME                     
				|| '","' ||SOURCE_SR_INSTANCE_CODE           
				|| '","' ||SOURCE_SUPPLIER_SITE_CODE         
				|| '","' ||SOURCE_SUPPLIER_NAME              
				|| '","' ||PROJECT_NUMBER                    
				|| '","' ||TASK_NUMBER                       
				|| '","' ||SR_INSTANCE_CODE                  
				|| '","' ||VENDOR_NAME                       
				|| '","' ||VENDOR_SITE_CODE                  
				|| '","' ||SUPPLIER_SITE_CODE                
				|| '","' ||MESSAGE_ID                        
				|| '","' ||PROCESS_FLAG                      
				|| '","' ||DATA_SOURCE_TYPE                  
				|| '","' ||ST_TRANSACTION_ID                 
				|| '","' ||SCHEDULE_LINE_NUM                                         
				|| '","' ||OPERATION_SEQ_CODE                
				|| '","' ||BATCH_ID                          
				|| '","' ||BILL_NAME                         
				|| '","' ||ROUTING_NAME                      
				|| '","' ||CURR_OP_SEQ_ID                    
				|| '","' ||LINE_CODE                         
				|| '","' ||EFFECTIVITY_DATE                  
				|| '","' ||SHIP_FROM_PARTY_NAME              
				|| '","' ||SHIP_FROM_SITE_CODE               
				|| '","' ||END_ORDER_NUMBER                  
				|| '","' ||END_ORDER_RELEASE_NUMBER          
				|| '","' ||END_ORDER_LINE_NUMBER             
				|| '","' ||ORDER_RELEASE_NUMBER              
				|| '","' ||COMMENTS                          
				|| '","' ||SHIP_TO_PARTY_NAME                
				|| '","' ||SHIP_TO_SITE_CODE                 
				|| '","' ||PLANNING_PARTNER_SITE_ID          
				|| '","' ||PLANNING_TP_TYPE                  
				|| '","' ||OWNING_PARTNER_SITE_ID            
				|| '","' ||OWNING_TP_TYPE                    
				|| '","' ||VMI_FLAG                          
				|| '","' ||NON_NETTABLE_QTY                  
				|| '","' ||ORIGINAL_NEED_BY_DATE             
				|| '","' ||ORIGINAL_QUANTITY                 
				|| '","' ||PROMISED_DATE                     
				|| '","' ||NEED_BY_DATE                      
				|| '","' ||ACCEPTANCE_REQUIRED_FLAG          
				|| '","' ||END_ORDER_SHIPMENT_NUMBER         
				|| '","' ||POSTPROCESSING_LEAD_TIME          
				|| '","' ||WIP_START_QUANTITY                
				|| '","' ||ORDER_LINE_NUMBER                 
				|| '","' ||UOM_CODE                          
				|| '","' ||QUANTITY_PER_ASSEMBLY             
				|| '","' ||QUANTITY_ISSUED                   
				|| '","' ||ACK_REFERENCE_NUMBER              
				|| '","' ||JOB_OP_SEQ_NUM                    
				|| '","' ||JUMP_OP_SEQ_NUM                   
				|| '","' ||JOB_OP_SEQ_CODE                   
				|| '","' ||JUMP_OP_SEQ_CODE                  
				|| '","' ||JUMP_OP_EFFECTIVITY_DATE          
				|| '","' ||SOURCE_ORG_ID                     
				|| '","' ||SOURCE_INVENTORY_ITEM_ID          
				|| '","' ||SOURCE_VENDOR_ID                  
				|| '","' ||SOURCE_VENDOR_SITE_ID             
				|| '","' ||SOURCE_TASK_ID                    
				|| '","' ||SOURCE_PROJECT_ID                 
				|| '","' ||SOURCE_FROM_ORGANIZATION_ID       
				|| '","' ||SOURCE_SR_MTL_SUPPLY_ID           
				|| '","' ||SOURCE_DISPOSITION_ID             
				|| '","' ||SOURCE_BILL_SEQUENCE_ID           
				|| '","' ||SOURCE_ROUTING_SEQUENCE_ID        
				|| '","' ||SOURCE_SCHEDULE_GROUP_ID          
				|| '","' ||SOURCE_WIP_ENTITY_ID              
				|| '","' ||PO_LINE_LOCATION_ID               
				|| '","' ||PO_DISTRIBUTION_ID                
				|| '","' ||REQUESTED_START_DATE              
				|| '","' ||REQUESTED_COMPLETION_DATE         
				|| '","' ||SCHEDULE_PRIORITY                 
				|| '","' ||ASSET_SERIAL_NUMBER               
				|| '","' ||ASSET_ITEM_ID                     
				|| '","' ||ASSET_ITEM_NAME                   
				|| '","' ||PLANNING_PARTNER_SITE_CODE        
				|| '","' ||OWNING_PARTNER_SITE_CODE          
				|| '","' ||ACTUAL_START_DATE                 
				|| '","' ||SCHEDULE_ORIGINATION_TYPE         
				|| '","' ||SR_CUSTOMER_ACCT_ID               
				|| '","' ||ITEM_TYPE_ID                      
				|| '","' ||ITEM_TYPE_VALUE                   
				|| '","' ||CUSTOMER_PRODUCT_ID               
				|| '","' ||RO_STATUS_CODE                    
				|| '","' ||SR_REPAIR_GROUP_ID                
				|| '","' ||SR_REPAIR_TYPE_ID                 
				|| '","' ||RO_CREATION_DATE                  
				|| '","' ||REPAIR_LEAD_TIME                  
				|| '","' ||REQ_LINE_ID                       
				|| '","' ||INTRANSIT_OWNING_ORG_ID           
				|| '","' ||CONDITION_TYPE                    
				|| '","' ||REPAIR_NUMBER                     
				|| '","' ||DESCRIPTION                       
				|| '","' ||MAINTENANCE_OBJECT_SOURCE         
				|| '","' ||PRODUCES_TO_STOCK                 
				|| '","' ||ACTIVITY_TYPE                     
				|| '","' ||CLASS_CODE                        
				|| '","' ||SHUTDOWN_TYPE                     
				|| '","' ||TO_BE_EXPLODED                    
				|| '","' ||ACTIVITY_ITEM_ID                  
				|| '","' ||VISIT_ID                          
				|| '","' ||ASSET_NUMBER                      
				|| '","' ||MAINTENANCE_OBJECT_ID             
				|| '","' ||MAINTENANCE_OBJECT_TYPE           
				|| '","' ||MAINTENANCE_TYPE_CODE             
				|| '","' ||OBJECT_TYPE                       
				|| '","' ||OPERATING_FLEET                   
				|| '","' ||MAINTENANCE_REQUIREMENT           
				|| '","' ||COLL_ORDER_TYPE                   
				|| '","' ||PRODUCT_CLASSIFICATION||'"'  IN_TRANSIT_DATA_TABLE       
				FROM msc_st_supplies 
				WHERE process_flag = 3 AND order_type IN (11,12) AND abs(request_id) >= p_main_request_id;
	 
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
     v_header := v_header || 'ERROR_TEXT,FROM_ORGANIZATION_CODE,ORDER_NUMBER,ITEM_NAME,ORGANIZATION_CODE,PLAN_ID,TRANSACTION_ID,INVENTORY_ITEM_ID,ORGANIZATION_ID,';
     v_header := v_header || 'SCHEDULE_DESIGNATOR_ID,SOURCE_SCHEDULE_NAME,REVISION,UNIT_NUMBER,NEW_SCHEDULE_DATE,OLD_SCHEDULE_DATE,NEW_WIP_START_DATE,OLD_WIP_START_DATE,';
     v_header := v_header || 'FIRST_UNIT_COMPLETION_DATE,LAST_UNIT_COMPLETION_DATE,FIRST_UNIT_START_DATE,LAST_UNIT_START_DATE,DISPOSITION_ID,DISPOSITION_STATUS_TYPE,ORDER_TYPE,';
     v_header := v_header || 'SUPPLIER_ID,NEW_ORDER_QUANTITY,OLD_ORDER_QUANTITY,NEW_ORDER_PLACEMENT_DATE,OLD_ORDER_PLACEMENT_DATE,RESCHEDULE_DAYS,RESCHEDULE_FLAG,';
     v_header := v_header || 'SCHEDULE_COMPRESS_DAYS,NEW_PROCESSING_DAYS,PURCH_LINE_NUM,QUANTITY_IN_PROCESS,IMPLEMENTED_QUANTITY,FIRM_PLANNED_TYPE,FIRM_QUANTITY,FIRM_DATE,';
     v_header := v_header || 'IMPLEMENT_DEMAND_CLASS,IMPLEMENT_DATE,IMPLEMENT_QUANTITY,IMPLEMENT_FIRM,IMPLEMENT_WIP_CLASS_CODE,IMPLEMENT_JOB_NAME,IMPLEMENT_DOCK_DATE,';
     v_header := v_header || 'IMPLEMENT_STATUS_CODE,IMPLEMENT_UOM_CODE,IMPLEMENT_LOCATION_ID,IMPLEMENT_SOURCE_ORG_ID,IMPLEMENT_SUPPLIER_ID,IMPLEMENT_SUPPLIER_SITE_ID,';
     v_header := v_header || 'IMPLEMENT_AS,RELEASE_STATUS,LOAD_TYPE,PROCESS_SEQ_ID,SCO_SUPPLY_FLAG,ALTERNATE_BOM_DESIGNATOR,ALTERNATE_ROUTING_DESIGNATOR,OPERATION_SEQ_NUM,';
     v_header := v_header || 'SOURCE,BY_PRODUCT_USING_ASSY_ID,SOURCE_ORGANIZATION_ID,SOURCE_SR_INSTANCE_ID,SOURCE_SUPPLIER_SITE_ID,SOURCE_SUPPLIER_ID,SHIP_METHOD,';
     v_header := v_header || 'WEIGHT_CAPACITY_USED,VOLUME_CAPACITY_USED,SOURCE_SUPPLY_SCHEDULE_NAME,NEW_SHIP_DATE,NEW_DOCK_DATE,LINE_ID,PROJECT_ID,TASK_ID,PLANNING_GROUP,';
     v_header := v_header || 'IMPLEMENT_PROJECT_ID,IMPLEMENT_TASK_ID,IMPLEMENT_SCHEDULE_GROUP_ID,IMPLEMENT_BUILD_SEQUENCE,IMPLEMENT_ALTERNATE_BOM,IMPLEMENT_ALTERNATE_ROUTING,';
     v_header := v_header || 'IMPLEMENT_UNIT_NUMBER,IMPLEMENT_LINE_ID,RELEASE_ERRORS,NUMBER1,SOURCE_ITEM_ID,SCHEDULE_GROUP_ID,SCHEDULE_GROUP_NAME,BUILD_SEQUENCE,';
     v_header := v_header || 'WIP_ENTITY_ID,WIP_ENTITY_NAME,WO_LATENESS_COST,IMPLEMENT_PROCESSING_DAYS,DELIVERY_PRICE,LATE_SUPPLY_DATE,LATE_SUPPLY_QTY,SUBINVENTORY_CODE,';
     v_header := v_header || 'DELETED_FLAG,LAST_UPDATE_DATE,LAST_UPDATED_BY,CREATION_DATE,CREATED_BY,LAST_UPDATE_LOGIN,REQUEST_ID,PROGRAM_APPLICATION_ID,PROGRAM_ID,';
     v_header := v_header || 'PROGRAM_UPDATE_DATE,SR_INSTANCE_ID,SCHEDULE_DESIGNATOR,VENDOR_ID,VENDOR_SITE_ID,SUPPLIER_SITE_ID,PURCH_ORDER_ID,EXPECTED_SCRAP_QTY,QTY_SCRAPPED,';
     v_header := v_header || 'QTY_COMPLETED,LOT_NUMBER,EXPIRATION_DATE,WIP_STATUS_CODE,DAILY_RATE,LOCATOR_ID,SERIAL_NUMBER,REFRESH_ID,LOCATOR_NAME,ONHAND_SOURCE_TYPE,';
     v_header := v_header || 'SR_MTL_SUPPLY_ID,DEMAND_CLASS,FROM_ORGANIZATION_ID,WIP_SUPPLY_TYPE,PO_LINE_ID,BILL_SEQUENCE_ID,ROUTING_SEQUENCE_ID,COPRODUCTS_SUPPLY,';
     v_header := v_header || 'CFM_ROUTING_FLAG,COMPANY_ID,COMPANY_NAME,SUPPLIER_NAME,SOURCE_SR_INSTANCE_CODE,SOURCE_SUPPLIER_SITE_CODE,SOURCE_SUPPLIER_NAME,';
     v_header := v_header || 'PROJECT_NUMBER,TASK_NUMBER,SR_INSTANCE_CODE,VENDOR_NAME,VENDOR_SITE_CODE,SUPPLIER_SITE_CODE,MESSAGE_ID,PROCESS_FLAG,DATA_SOURCE_TYPE,';
     v_header := v_header || 'ST_TRANSACTION_ID,SCHEDULE_LINE_NUM,OPERATION_SEQ_CODE,BATCH_ID,BILL_NAME,ROUTING_NAME,CURR_OP_SEQ_ID,LINE_CODE,EFFECTIVITY_DATE,';
     v_header := v_header || 'SHIP_FROM_PARTY_NAME,SHIP_FROM_SITE_CODE,END_ORDER_NUMBER,END_ORDER_RELEASE_NUMBER,END_ORDER_LINE_NUMBER,ORDER_RELEASE_NUMBER,COMMENTS,';
     v_header := v_header || 'SHIP_TO_PARTY_NAME,SHIP_TO_SITE_CODE,PLANNING_PARTNER_SITE_ID,PLANNING_TP_TYPE,OWNING_PARTNER_SITE_ID,OWNING_TP_TYPE,VMI_FLAG,NON_NETTABLE_QTY,';
     v_header := v_header || 'ORIGINAL_NEED_BY_DATE,ORIGINAL_QUANTITY,PROMISED_DATE,NEED_BY_DATE,ACCEPTANCE_REQUIRED_FLAG,END_ORDER_SHIPMENT_NUMBER,POSTPROCESSING_LEAD_TIME,';
     v_header := v_header || 'WIP_START_QUANTITY,ORDER_LINE_NUMBER,UOM_CODE,QUANTITY_PER_ASSEMBLY,QUANTITY_ISSUED,ACK_REFERENCE_NUMBER,JOB_OP_SEQ_NUM,JUMP_OP_SEQ_NUM,';
     v_header := v_header || 'JOB_OP_SEQ_CODE,JUMP_OP_SEQ_CODE,JUMP_OP_EFFECTIVITY_DATE,SOURCE_ORG_ID,SOURCE_INVENTORY_ITEM_ID,SOURCE_VENDOR_ID,SOURCE_VENDOR_SITE_ID,';
     v_header := v_header || 'SOURCE_TASK_ID,SOURCE_PROJECT_ID,SOURCE_FROM_ORGANIZATION_ID,SOURCE_SR_MTL_SUPPLY_ID,SOURCE_DISPOSITION_ID,SOURCE_BILL_SEQUENCE_ID,';
     v_header := v_header || 'SOURCE_ROUTING_SEQUENCE_ID,SOURCE_SCHEDULE_GROUP_ID,SOURCE_WIP_ENTITY_ID,PO_LINE_LOCATION_ID,PO_DISTRIBUTION_ID,REQUESTED_START_DATE,';
     v_header := v_header || 'REQUESTED_COMPLETION_DATE,SCHEDULE_PRIORITY,ASSET_SERIAL_NUMBER,ASSET_ITEM_ID,ASSET_ITEM_NAME,PLANNING_PARTNER_SITE_CODE,';
     v_header := v_header || 'OWNING_PARTNER_SITE_CODE,ACTUAL_START_DATE,SCHEDULE_ORIGINATION_TYPE,SR_CUSTOMER_ACCT_ID,ITEM_TYPE_ID,ITEM_TYPE_VALUE,CUSTOMER_PRODUCT_ID,';
     v_header := v_header || 'RO_STATUS_CODE,SR_REPAIR_GROUP_ID,SR_REPAIR_TYPE_ID,RO_CREATION_DATE,REPAIR_LEAD_TIME,REQ_LINE_ID,INTRANSIT_OWNING_ORG_ID,CONDITION_TYPE,';
     v_header := v_header || 'REPAIR_NUMBER,DESCRIPTION,MAINTENANCE_OBJECT_SOURCE,PRODUCES_TO_STOCK,ACTIVITY_TYPE,CLASS_CODE,SHUTDOWN_TYPE,TO_BE_EXPLODED,ACTIVITY_ITEM_ID,';
     v_header := v_header || 'VISIT_ID,ASSET_NUMBER,MAINTENANCE_OBJECT_ID,MAINTENANCE_OBJECT_TYPE,MAINTENANCE_TYPE_CODE,OBJECT_TYPE,OPERATING_FLEET,MAINTENANCE_REQUIREMENT,';
     v_header := v_header || 'COLL_ORDER_TYPE,PRODUCT_CLASSIFICATION';

	 -- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ERROR_TEXT,FROM_ORGANIZATION_CODE,ORDER_NUMBER,ITEM_NAME,....
	 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,v_header);		
     -- drodil 17-july-2015  -- end
		
		OPEN c_gen_error(v_main_request_id);
	v_step := 4;	
		FETCH c_gen_error BULK COLLECT INTO l_detailed_error_tab;
		FOR i in 1..l_detailed_error_tab.COUNT
			LOOP
				FND_FILE.PUT_LINE(FND_FILE.OUTPUT, l_detailed_error_tab(i).IN_TRANSIT_DATA_TABLE );
			END LOOP;
		CLOSE c_gen_error;
	v_step := 5;
	

	
	EXCEPTION
		WHEN OTHERS THEN
		  v_mess := 'At step ['||v_step||'] - SQLCODE [' ||SQLCODE|| '] - ' ||substr(SQLERRM,1,100);
		  x_errbuf  := v_mess;
		  x_retcode := 2; 

   END main_proc;
		
END XXNBTY_MSCREP02_IN_TRANSIT_PKG;
/
show errors;
