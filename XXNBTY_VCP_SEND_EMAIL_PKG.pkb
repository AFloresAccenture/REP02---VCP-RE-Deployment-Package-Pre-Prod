create or replace PACKAGE BODY        "XXNBTY_VCP_SEND_EMAIL_PKG"
  --------------------------------------------------------------------------------------------
  /*
  Package Name: XXNBTY_VCP_SEND_EMAIL_PKG
  Author's Name: Mark Anthony Geamoga
  Date written: 19-Dec-2014
  RICEFW Object: N/A
  Description: Package will generate an error output file for all or specific VCP/EBS RICEFW.
				This output file will be sent to identified recipient(s) using UNIX program.
  Program Style:
  Maintenance History:
  Date         Issue#  Name         			    Remarks
  -----------  ------  -------------------		------------------------------------------------
  19-Dec-2014          Mark Anthony Geamoga  	Initial Development
  17-Feb-2015          Erwin Ramos            	Update p_allow_send_if_no_error to UPPER to address case sensitive. 
												Update the tag to UPPER to address case sensitive. 
  3-Mar-2015		   Erwin Ramos				Changed the SQLCODE to 2
  15-Apr-2015	151	   Erwin Ramos				Update the v_message, the message body already included in the XXNBTYVCSENDEMAIL.prog UNIX script. 
  29-Apr-2015	170	   Erwin Ramos				Added the CURSOR c1, v_main_request_id, v_child_request_id in the generate line to fixed defect #170 and INC960237. This will get the parent_request_id of the concurrent program.  
  09-Jun-2015		   Albert John Flores		REP02	
  22-Jul-2015		   Albert John Flores		Removed the creation_date = sysdate in the where clause of the query  
  */
  --------------------------------------------------------------------------------------------
IS
  PROCEDURE send_email_main (x_retcode             OUT VARCHAR2,
                             x_errbuf              OUT VARCHAR2,
                             p_ricefw_name            VARCHAR2,
                             p_allow_send_if_no_error VARCHAR2)
  IS
  
  --------------------------------------------------------------------------------------------
  /*
  Procedure Name: send_email_main
  Author's Name: Mark Anthony Geamoga
  Date written: 19-Dec-2014
  RICEFW Object: N/A
  Description: Procedure for sending email will call another procedure to generate error log. 
  Program Style:
  Maintenance History:
  Date         Issue#  Name         			    Remarks
  -----------  ------  -------------------		------------------------------------------------
  19-Dec-2014          Mark Anthony Geamoga  	Initial Development

  */
  --------------------------------------------------------------------------------------------
  
  
    v_request_id    	   NUMBER := fnd_global.conc_request_id;
	v_onhand_req_id 	   NUMBER; --Request id for on hand detailed error report
	v_intransit_req_id 	   NUMBER; --Request id for in transit detailed error report
	v_wo_req_id 	 	   NUMBER; --Request id for work order detailed error report
	v_wip_req_id		   NUMBER; --Request id for wip detailed error report
	v_sales_orders_req_id  NUMBER; --Request id for sales order detailed error report
	v_item_costs_req_id	   NUMBER; --Request id for item costs detailed error report
    v_max_length    	   NUMBER;
    v_side_length   	   NUMBER;
    v_new_filename  	   VARCHAR2(200);
    v_old_filename  	   VARCHAR2(1000);
    v_lf10_new_filename    VARCHAR2(200);  --6/9/2015 AFlores
    v_lf10_old_filename    VARCHAR2(1000); --6/9/2015 AFlores
    v_lf11_new_filename    VARCHAR2(200);  --6/10/2015 AFlores
    v_lf11_old_filename    VARCHAR2(1000); --6/10/2015 AFlores
    v_lf14_new_filename    VARCHAR2(200);  --6/10/2015 AFlores
    v_lf14_old_filename    VARCHAR2(1000); --6/10/2015 AFlores
    v_lf16_new_filename    VARCHAR2(200);  --6/10/2015 AFlores
    v_lf16_old_filename    VARCHAR2(1000); --6/10/2015 AFlores
	v_lf17_new_filename    VARCHAR2(200);  --6/10/2015 AFlores
    v_lf17_old_filename    VARCHAR2(1000); --6/10/2015 AFlores
	v_lf19_new_filename    VARCHAR2(200);  --6/10/2015 AFlores
    v_lf19_old_filename    VARCHAR2(1000); --6/10/2015 AFlores
    v_query         	   VARCHAR2(4000);
    v_report_title  	   VARCHAR2(200);
    v_report_footer 	   VARCHAR2(200);
    v_lookup_name   	   VARCHAR2(100);
    
	
	CURSOR c_get_file ( p_det_req_id       NUMBER)
	IS
	SELECT outfile_name
      FROM fnd_concurrent_requests
     WHERE request_id = p_det_req_id;
	 
  BEGIN

    IF p_ricefw_name IN ('ALL_VCP_RICEFW', 'ON_HAND_DATA', 'IN_TRANSIT', 'WORK_ORDERS', 'WIP', 'SALES_ORDERS', 'ITEM_COSTS') THEN
      --retrieve width of report for specific or all VCP RICEFW
      v_query := 'SELECT MAX(NVL(maximum_length, 0)) + 16
                    FROM (
                      SELECT MAX(LENGTH(error_text)) maximum_length
                        FROM msc_st_supplies
                       WHERE process_flag = 3 AND order_type = 18 AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_VCP_RICEFW'',1,''ON_HAND_DATA'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_text)) maximum_length
                        FROM msc_st_supplies
                       WHERE process_flag = 3 AND order_type = 11 AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_VCP_RICEFW'',1,''IN_TRANSIT'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_text)) maximum_length
                        FROM msc_st_supplies
                       WHERE process_flag = 3 AND order_type = 3 AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_VCP_RICEFW'',1,''WORK_ORDERS'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_text)) maximum_length
                        FROM msc_st_demands
                       WHERE process_flag = 3 AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_VCP_RICEFW'',1,''WIP'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_text)) maximum_length
                        FROM msc_st_sales_orders
                       WHERE process_flag = 3 AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_VCP_RICEFW'',1,''SALES_ORDERS'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_description)) maximum_length
                        FROM xxnbty_msc_costs_st
                       WHERE status = ''E'' AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_VCP_RICEFW'',1,''ITEM_COSTS'',1,0) = 1
                    )';
      v_lookup_name := 'XXNBTY_VCP_COLL_REP_ADD_LKP';

    ELSIF p_ricefw_name IN ('ALL_EBS_RICEFW', 'BOM', 'FORMULA', 'BATCH', 'CUSTOMER_INTERFACE') THEN
      --retrieve width of report for specific or all EBS RICEFW
      v_query := 'SELECT MAX(NVL(maximum_length, 0)) + 16
                    FROM (
                      SELECT MAX(LENGTH(error_description)) maximum_length
                        FROM xxnbty_bom_st_component
                       WHERE process_flag = 3 AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_EBS_RICEFW'',1,''BOM'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_description)) maximum_length
                        FROM xxnbty_cust_st_bom_int
                       WHERE process_flag = 3 AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_EBS_RICEFW'',1,''BOM'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_text)) maximum_length
                        FROM xxnbty_fm_matl_dtl_stg
                       WHERE status NOT IN (''P'', ''V'')
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_EBS_RICEFW'',1,''FORMULA'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_text)) maximum_length
                        FROM xxnbty_fm_form_mst_b_stg
                       WHERE status NOT IN (''P'', ''V'')
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_EBS_RICEFW'',1,''FORMULA'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(attribute30)) maximum_length
                        FROM xxnbty_frmla_upload
                       WHERE attribute29 NOT IN (''P'', ''V'') AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_EBS_RICEFW'',1,''FORMULA'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_description)) maximum_length
                        FROM xxnbty_batch_int_st
                       WHERE error_description IS NOT NULL AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_EBS_RICEFW'',1,''BATCH'',1,0) = 1
                    UNION
                      SELECT MAX(LENGTH(error_message)) maximum_length
                        FROM xxnbty_cust_stg_tbl
                       WHERE process_flag = ''E'' AND TRUNC(creation_date) = TRUNC(SYSDATE)
                         AND DECODE(''' || p_ricefw_name || ''',''ALL_EBS_RICEFW'',1,''CUSTOMER_INTERFACE'',1,0) = 1
                    )';
      v_lookup_name := 'XXNBTY_EBS_COLL_REP_ADD_LKP';
    END IF;

    --retrive report width
    EXECUTE IMMEDIATE v_query INTO v_max_length;

    --set default width of report to 100
    IF NVL(v_max_length,99) < 100 THEN
      v_max_length := 100;
    END IF;

    --get new filename of the output file
	
    v_new_filename := 'XXNBTY_' || p_ricefw_name || '_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.txt';
	v_lf10_new_filename := 'XXNBTY_ONHAND_ERRORS_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.csv'; --6/9/2015 AFlores
	v_lf11_new_filename := 'XXNBTY_IN_TRANSIT_ERRORS_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.csv'; --6/9/2015 AFlores
	v_lf14_new_filename := 'XXNBTY_WORK_ORDER_ERRORS_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.csv'; --6/9/2015 AFlores
	v_lf16_new_filename := 'XXNBTY_WIP_ERRORS_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.csv'; --6/10/2015 AFlores
	v_lf17_new_filename := 'XXNBTY_SALES_ORDER_ERRORS_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.csv'; --6/10/2015 AFlores
	v_lf19_new_filename := 'XXNBTY_ITEM_COST_ERRORS_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.csv'; --6/10/2015 AFlores
	
    --get report title
    v_report_title := 'SUMMARY REPORT FOR ' || p_ricefw_name;

    v_side_length := TRUNC((v_max_length - LENGTH(v_report_title)) / 2);

    --display header of the output file
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  ' || RPAD(RTRIM(v_new_filename, '.txt'), v_max_length - 17, ' ') || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH:MI:SS AM') || '  ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD(' ', v_side_length + 4, ' ') || v_report_title);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

    IF p_ricefw_name = 'ALL_VCP_RICEFW' THEN --generate output file for all ricefw in VCP
      generate_err_log(x_retcode, x_errbuf, 'ON_HAND_DATA', v_max_length);
      generate_err_log(x_retcode, x_errbuf, 'IN_TRANSIT', v_max_length);
      generate_err_log(x_retcode, x_errbuf, 'WORK_ORDERS', v_max_length);
      generate_err_log(x_retcode, x_errbuf, 'WIP', v_max_length);
      generate_err_log(x_retcode, x_errbuf, 'SALES_ORDERS', v_max_length);
      generate_err_log(x_retcode, x_errbuf, 'ITEM_COSTS', v_max_length);
	  
          --Generate Detailed error log per object
		  --On Hand
          IF g_det_onhand_with_error THEN
              generate_detailed_err_log(x_retcode, x_errbuf, 'ON_HAND_DATA', v_onhand_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling on hand ');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 on hand: ' || v_onhand_req_id); 
          END IF;
		  
		  --In Transit
          IF g_det_intransit_with_error THEN
              generate_detailed_err_log(x_retcode, x_errbuf, 'IN_TRANSIT', v_intransit_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling in transit');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 in transit: ' || v_intransit_req_id); 
          END IF;
		  
		  --Work Orders
          IF g_det_wo_with_error THEN
              generate_detailed_err_log(x_retcode, x_errbuf, 'WORK_ORDERS', v_wo_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling work orders');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 work orders: ' || v_wo_req_id); 
          END IF;
		  
		  --WIP
		  IF g_det_wip_with_error THEN
		      generate_detailed_err_log(x_retcode, x_errbuf, 'WIP', v_wip_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling wip');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 wip: ' || v_wip_req_id); 
          END IF;

		  --Sales Order
		  IF g_det_sales_with_error THEN
		      generate_detailed_err_log(x_retcode, x_errbuf, 'SALES_ORDERS', v_sales_orders_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling sales orders');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 sales orders: ' || v_sales_orders_req_id); 
          END IF;
		  
		  --Item Cost 
		  IF g_det_cost_with_error THEN
		      generate_detailed_err_log(x_retcode, x_errbuf, 'ITEM_COSTS', v_item_costs_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling item costs');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 item costs: ' || v_item_costs_req_id); 
          END IF;
	  
    ELSIF p_ricefw_name = 'ALL_EBS_RICEFW' THEN --generate output file for all ricefw in EBS
      generate_err_log(x_retcode, x_errbuf, 'BOM', v_max_length);
      generate_err_log(x_retcode, x_errbuf, 'FORMULA', v_max_length);
      generate_err_log(x_retcode, x_errbuf, 'BATCH', v_max_length);
      generate_err_log(x_retcode, x_errbuf, 'CUSTOMER_INTERFACE', v_max_length);
    ELSE --generate output file for specific ricefw
      generate_err_log(x_retcode, x_errbuf, p_ricefw_name, v_max_length);
          
          --Generate Detailed error log per object
          --On Hand
          IF g_det_onhand_with_error THEN
              generate_detailed_err_log(x_retcode, x_errbuf, 'ON_HAND_DATA', v_onhand_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling on hand ');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 on hand: ' || v_onhand_req_id); 
          END IF;
		  
		  --In Transit
          IF g_det_intransit_with_error THEN
              generate_detailed_err_log(x_retcode, x_errbuf, 'IN_TRANSIT', v_intransit_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling in transit');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 in transit: ' || v_intransit_req_id); 
          END IF;
		  
		  --Work Orders
          IF g_det_wo_with_error THEN
              generate_detailed_err_log(x_retcode, x_errbuf, 'WORK_ORDERS', v_wo_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling work orders');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 work orders: ' || v_wo_req_id); 
          END IF;
		  
		  --WIP
		  IF g_det_wip_with_error THEN
		      generate_detailed_err_log(x_retcode, x_errbuf, 'WIP', v_wip_req_id); --6/10/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling wip');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 wip: ' || v_wip_req_id); 
          END IF;
		  
		  --Sales Order
		  IF g_det_sales_with_error THEN
		      generate_detailed_err_log(x_retcode, x_errbuf, 'SALES_ORDERS', v_sales_orders_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling sales orders');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 sales orders: ' || v_sales_orders_req_id); 
          END IF;
		  
		  --Item Cost 
		  IF g_det_cost_with_error THEN
		      generate_detailed_err_log(x_retcode, x_errbuf, 'ITEM_COSTS', v_item_costs_req_id); --6/9/2015 AFlores
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered REP02 Calling item costs');
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID for REP02 item costs: ' || v_item_costs_req_id); 
          END IF;
          
    END IF;

    --get report footer
    v_report_footer := 'END OF REPORT';

    v_side_length := TRUNC((v_max_length - LENGTH(v_report_footer)) / 2);

    --display footer of the output file
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  ' || RPAD(LPAD(v_report_footer, v_side_length + LENGTH(v_report_footer), '*'), v_max_length + 6, '*') || '  ');

    --check if generation of output file is successful before sending email.
    IF v_request_id != 0 THEN

     -- IF (p_allow_send_if_no_error = 'Yes' AND NOT g_with_error_msg) --send email though output log has no error messages.
	  IF (UPPER(p_allow_send_if_no_error )= 'YES' AND NOT g_with_error_msg) --send email though output log has no error messages. 
																			--17-Feb-2015: Add the UPPER command to change into not to be case sensitive.
         OR g_with_error_msg THEN
		/*
        SELECT outfile_name
          INTO v_old_filename 					--6/9/2015 AFlores
          FROM fnd_concurrent_requests
         WHERE request_id = v_request_id;
		*/
		--For Error Summary old file name
		OPEN c_get_file (v_request_id);
		FETCH c_get_file INTO v_old_filename;   --6/9/2015 AFlores
		CLOSE c_get_file;		
		
		--For On Hand old file name
		OPEN c_get_file (v_onhand_req_id);		--6/9/2015 AFlores
		FETCH c_get_file INTO v_lf10_old_filename;
		CLOSE c_get_file;
		v_lf10_old_filename := NVL(v_lf10_old_filename , 'NONE');
		
		--For In Transit old file name
		OPEN c_get_file (v_intransit_req_id);		--6/9/2015 AFlores
		FETCH c_get_file INTO v_lf11_old_filename;
		CLOSE c_get_file;
		v_lf11_old_filename := NVL(v_lf11_old_filename , 'NONE');

		--For Work Orders old file name
		OPEN c_get_file (v_wo_req_id);		--6/9/2015 AFlores
		FETCH c_get_file INTO v_lf14_old_filename;
		CLOSE c_get_file;
		v_lf14_old_filename := NVL(v_lf14_old_filename , 'NONE');	

		--For WIP old file name
		OPEN c_get_file (v_wip_req_id);		--6/9/2015 AFlores
		FETCH c_get_file INTO v_lf16_old_filename;
		CLOSE c_get_file;
		v_lf16_old_filename := NVL(v_lf16_old_filename , 'NONE');	

		--For Sales order old file name
		OPEN c_get_file (v_sales_orders_req_id);		--6/9/2015 AFlores
		FETCH c_get_file INTO v_lf17_old_filename;
		CLOSE c_get_file;
		v_lf17_old_filename := NVL(v_lf17_old_filename , 'NONE');

		--For Item Cost old file name
		OPEN c_get_file (v_item_costs_req_id);		--6/9/2015 AFlores
		FETCH c_get_file INTO v_lf19_old_filename;
		CLOSE c_get_file;
		v_lf19_old_filename := NVL(v_lf19_old_filename , 'NONE');		
		
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Sending e-mail in progress...');
        generate_email(x_retcode,
                       x_errbuf,
                       p_ricefw_name,
                       v_new_filename,
                       v_old_filename,
                       v_lookup_name,
					   v_lf10_new_filename,  --Start 6/9/2015 AFlores
					   v_lf10_old_filename,
					   v_lf11_new_filename,
					   v_lf11_old_filename,
					   v_lf14_new_filename,
					   v_lf14_old_filename,
					   v_lf16_new_filename,
					   v_lf16_old_filename,
					   v_lf17_new_filename,
					   v_lf17_old_filename,
					   v_lf19_new_filename,
					   v_lf19_old_filename); --6/9/2015 AFlores

        g_with_error_msg 			:= FALSE; --reset global variable in package
		g_det_onhand_with_error  	:= FALSE; --reset global variable in package --6/10/2015 AFlores
		g_det_intransit_with_error	:= FALSE; --reset global variable in package --6/10/2015 AFlores 
		g_det_wo_with_error  		:= FALSE; --reset global variable in package --6/10/2015 AFlores
		g_det_wip_with_error  		:= FALSE; --reset global variable in package --6/10/2015 AFlores
		g_det_sales_with_error  	:= FALSE; --reset global variable in package --6/10/2015 AFlores
		g_det_cost_with_error  		:= FALSE; --reset global variable in package --6/10/2015 AFlores
		
      ELSE
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Sending e-mail is off.');
      END IF;
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Sending e-mail failed. No error report to be sent.');
    END IF;

  EXCEPTION
   WHEN OTHERS THEN
      x_retcode := 2;
      x_errbuf := SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error message : ' || x_errbuf);
  END send_email_main;

  PROCEDURE generate_email (x_retcode   	 OUT VARCHAR2,
                            x_errbuf    	 OUT VARCHAR2,
                            p_ricefw_name  		 VARCHAR2,
                            p_new_filename 		 VARCHAR2,
                            p_old_filename 		 VARCHAR2,
                            p_lookup_name  		 VARCHAR2,
							p_lf10_new_filename  VARCHAR2, --6/9/2015 AFlores
							p_lf10_old_filename  VARCHAR2,
							p_lf11_new_filename  VARCHAR2,
							p_lf11_old_filename  VARCHAR2,
							p_lf14_new_filename  VARCHAR2,
                            p_lf14_old_filename  VARCHAR2,
							p_lf16_new_filename  VARCHAR2,
                            p_lf16_old_filename  VARCHAR2,
							p_lf17_new_filename	 VARCHAR2,
							p_lf17_old_filename	 VARCHAR2,
							p_lf19_new_filename  VARCHAR2,
							p_lf19_old_filename  VARCHAR2) --6/10/2015 AFlores
  IS
  --------------------------------------------------------------------------------------------
  /*
  Procedure Name: generate_email
  Author's Name: Mark Anthony Geamoga
  Date written: 19-Dec-2014
  RICEFW Object: N/A
  Description: Procedure for generate email procedure that will send access error log file and send it to recipients using lookups. 
  Program Style:
  Maintenance History:
  Date         Issue#  Name         			    Remarks
  -----------  ------  -------------------		------------------------------------------------
  19-Dec-2014          Mark Anthony Geamoga  	Initial Development

  */
  --------------------------------------------------------------------------------------------
    v_request_id    NUMBER;
    v_subject       VARCHAR2(100);
    v_message       VARCHAR2(1000);
    lp_email_to     VARCHAR2(1000);
    lp_email_to_cc  VARCHAR2(1000);
    lp_email_to_bcc VARCHAR2(1000);

    CURSOR cp_lookup_email_ad (p_lookup_name VARCHAR2, p_tag VARCHAR2) --lookup for recipient(s)
    IS
       SELECT meaning
        FROM fnd_lookup_values
       WHERE lookup_type = p_lookup_name
         AND enabled_flag = 'Y'
        -- AND tag = p_tag  -- 17-Feb-2015: Update the tag to UPPER to address case sensitive. 
         AND UPPER(tag) = p_tag
         AND SYSDATE BETWEEN start_date_active AND NVL(end_date_active,SYSDATE);

  BEGIN

    --check all direct recipients in lookup
    FOR rec_send IN cp_lookup_email_ad (p_lookup_name, 'TO')
    LOOP
      lp_email_to := LTRIM(lp_email_to||','||rec_send.meaning,',');
    END LOOP;

    --check all cc recipients in lookup
    FOR rec_send_cc IN cp_lookup_email_ad (p_lookup_name, 'CC')
    LOOP
      lp_email_to_cc := LTRIM(lp_email_to_cc||','||rec_send_cc.meaning,',');
    END LOOP;

    --check all bcc recipients in lookup
    FOR rec_send_bcc IN cp_lookup_email_ad (p_lookup_name, 'BCC')
    LOOP
      lp_email_to_bcc := LTRIM(lp_email_to_bcc||','||rec_send_bcc.meaning,',');
    END LOOP;
	
	IF g_with_error_msg THEN 
	
		-- 15-Apr-2015: Update the subject base on the verbiage provided.
		v_message := 'VCI_NOTIFICATION_ERROR';
		
		IF p_ricefw_name = 'ALL_VCP_RICEFW' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Errors';  --15-Apr-2015: Update the subject base on the verbiage provided. 
		ELSIF p_ricefw_name = 'ON_HAND_DATA' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Errors For On-Hand';
		ELSIF p_ricefw_name = 'IN_TRANSIT' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Errors For In-Transit';
		ELSIF p_ricefw_name = 'WORK_ORDERS' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Errors For Work Orders';
		ELSIF p_ricefw_name = 'WIP' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Errors For WIP Component Demands';
		ELSIF p_ricefw_name = 'SALES_ORDERS' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Errors For Sales Orders';
		ELSIF p_ricefw_name = 'ITEM_COSTS' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Errors For Item Cost';
		ELSE
		   v_subject := 'Supply Planning - VCI Data Collection Errors For ' || p_ricefw_name;
		END IF;

	ELSE --15-Apr-2015: Added this syntax if no error encountered the subject will change to success base on the verbiage provided. 
		v_message := 'VCI_NOTIFICATION_SUCCESS';
		
		IF p_ricefw_name = 'ALL_VCP_RICEFW' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Process Completed Successfully';  
		ELSIF p_ricefw_name = 'ON_HAND_DATA' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Process Completed Successfully For On-Hand';
		ELSIF p_ricefw_name = 'IN_TRANSIT' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Process Completed Successfully For In-Transit';
		ELSIF p_ricefw_name = 'WORK_ORDERS' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Process Completed Successfully For Work Orders';
		ELSIF p_ricefw_name = 'WIP' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Process Completed Successfully For WIP Component Demands';
		ELSIF p_ricefw_name = 'SALES_ORDERS' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Process Completed Successfully For Sales Orders';
		ELSIF p_ricefw_name = 'ITEM_COSTS' THEN
		  v_subject := 'Supply Planning - VCI Data Collection Process Completed Successfully For Item Cost';
		ELSE
		   v_subject := 'Supply Planning - VCI Data Collection Process Completed Successfully For ' || p_ricefw_name;
		END IF;
	END IF;
	
	
    --v_message := 'Hi, \n\nAttached is the ' || v_subject ||'.\n\n*****This is an auto-generated e-mail. Please do not reply.*****';--15-Apr-2015: Comment this message to resolved defect 151. Message already included in the unix script. 
		
    FND_FILE.PUT_LINE(FND_FILE.LOG,'New Filename : ' || p_new_filename);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Old Filename : ' || p_old_filename);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Direct Recipient : ' || lp_email_to);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Carbon Copy Recipient : ' || lp_email_to_cc);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Blind Carbon Copy Recipient : ' || lp_email_to_bcc);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Subject : ' || v_subject);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Content : ' || v_message);

    IF lp_email_to_bcc IS NOT NULL AND lp_email_to_cc IS NULL THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Cannot proceed in sending email due to BCC recipient contains a value and CC recipient is missing.');
    ELSE --send email if recipient is valid.
    --get request id generated after running concurrent program
    v_request_id := FND_REQUEST.SUBMIT_REQUEST(application  => 'XXNBTY'
                                               ,program      => 'XXNBTY_VCP_SEND_EMAIL_LOG'
                                               ,start_time   => TO_CHAR(SYSDATE,'DD-MON-YYYY HH:MI:SS')
                                               ,sub_request  => FALSE
                                               ,argument1    => p_new_filename
                                               ,argument2    => p_old_filename
                                               ,argument3    => lp_email_to
                                               ,argument4    => lp_email_to_cc
                                               ,argument5    => lp_email_to_bcc
                                               ,argument6    => v_subject
                                               ,argument7    => v_message 
											   ,argument8    => p_lf10_new_filename --6/9/2015 AFlores
											   ,argument9    => p_lf10_old_filename
											   ,argument10 	 =>	p_lf11_new_filename
                                               ,argument11 	 =>	p_lf11_old_filename
											   ,argument12 	 =>	p_lf14_new_filename
											   ,argument13 	 =>	p_lf14_old_filename
											   ,argument14	 =>	p_lf16_new_filename
											   ,argument15 	 =>	p_lf16_old_filename
											   ,argument16	 =>	p_lf17_new_filename
											   ,argument17 	 =>	p_lf17_old_filename
											   ,argument18	 =>	p_lf19_new_filename
											   ,argument19 	 =>	p_lf19_old_filename); --6/9/2015 AFlores
    FND_CONCURRENT.AF_COMMIT;
    END IF;

    FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of XXNBTY_SendEmailLog : ' || v_request_id);

    IF v_request_id != 0 THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Sending successful.');
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in sending email.');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      x_retcode := 2;
      x_errbuf := SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error message : ' || x_errbuf);
  END generate_email;

  PROCEDURE generate_err_log (x_retcode   OUT VARCHAR2,
                              x_errbuf    OUT VARCHAR2,
                              p_ricefw_name VARCHAR2,
                              p_width       NUMBER)
  IS
  --------------------------------------------------------------------------------------------
  /*
  Procedure Name: generate_err_log
  Author's Name: Mark Anthony Geamoga
  Date written: 19-Dec-2014
  RICEFW Object: N/A
  Description: Procedure for generate error log procedure to generate error log per ricefw using FND_FILE. 
  Program Style:
  Maintenance History:
  Date         Issue#  Name         			    Remarks
  -----------  ------  -------------------		------------------------------------------------
  19-Dec-2014          Mark Anthony Geamoga  	Initial Development

  */
  --------------------------------------------------------------------------------------------
    TYPE err_type   IS RECORD (error_msg VARCHAR2(4000),
                               ctr       NUMBER);
    TYPE query_type IS RECORD (column_name      VARCHAR2(200),
                               table_name       VARCHAR2(200),
                               table_type       VARCHAR2(200),
                               where_clause     VARCHAR2(200),
                               group_by_clause  VARCHAR2(200));
    TYPE err_tab    IS TABLE OF err_type;
    TYPE query_tab  IS TABLE OF query_type;

    v_err           err_tab;
    v_rec           query_type;
    v_query         query_tab := query_tab();
    v_header        VARCHAR2(1000);
    v_side_length   NUMBER;
    cur             SYS_REFCURSOR;
	v_request_id    NUMBER := fnd_global.conc_request_id; -- 29-Apr-2015:  Added this line to fixed defect #170 and INC960237. This will get the parent_request_id of the concurrent program. 
	v_main_request_id number; 
	v_child_request_id number; 
	
	CURSOR c1 (p_request_id number) 
		IS 
		SELECT a.parent_request_id 
		FROM apps.fnd_concurrent_requests a 
		WHERE a.request_id = p_request_id;

	
  BEGIN
  -- 29-Apr-2015: Added this line to fixed defect #170 and INC960237. This will get the parent_request_id of the concurrent program.  
	 
	v_child_request_id := v_request_id; 
	
	LOOP 
		OPEN c1(v_child_request_id); 
		FETCH c1 INTO v_main_request_id; 
		EXIT WHEN c1%notfound; 
		
		IF v_main_request_id = -1 THEN 
			v_main_request_id := v_child_request_id; 
			EXIT; 
		ELSE 
			v_child_request_id := v_main_request_id; 
		END IF;
		CLOSE c1; 
	END LOOP; 
	IF c1%isopen THEN 
		CLOSE c1; 
	END IF; 
	FND_FILE.PUT_LINE(FND_FILE.LOG,'v_main_request_id : ' || v_main_request_id);
  -- 29-Apr-2015: End of line for defect #170 and INC960237.  
	
    v_query.EXTEND();
    CASE p_ricefw_name
    WHEN 'ON_HAND_DATA' THEN
      v_rec.column_name      := 'error_text, count(*)';
      v_rec.table_name       := 'msc_st_supplies';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'process_flag = 3 AND order_type = 18 AND abs(request_id) >= '||v_main_request_id;
      v_rec.group_by_clause  := 'error_text';
      v_query(1)             := v_rec;
    WHEN 'IN_TRANSIT' THEN
      v_rec.column_name      := 'error_text, count(*)';
      v_rec.table_name       := 'msc_st_supplies';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'process_flag = 3 AND order_type in (11,12) AND abs(request_id) >= '||v_main_request_id;
      v_rec.group_by_clause  := 'error_text';
      v_query(1)             := v_rec;
    WHEN 'WORK_ORDERS' THEN
      v_rec.column_name      := 'error_text, count(*)';
      v_rec.table_name       := 'msc_st_supplies';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'process_flag = 3 AND order_type = 3 AND abs(request_id) >= '||v_main_request_id;
      v_rec.group_by_clause  := 'error_text';
      v_query(1)             := v_rec;
    WHEN 'WIP' THEN
      v_rec.column_name      := 'error_text, count(*)';
      v_rec.table_name       := 'msc_st_demands';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'process_flag = 3 AND abs(request_id) >= '||v_main_request_id;
      v_rec.group_by_clause  := 'error_text';
      v_query(1)             := v_rec;
    WHEN 'SALES_ORDERS' THEN
      v_rec.column_name      := 'error_text, count(*)';
      v_rec.table_name       := 'msc_st_sales_orders';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'process_flag = 3 AND abs(request_id) >= '||v_main_request_id;
      v_rec.group_by_clause  := 'error_text';
      v_query(1)             := v_rec;
    WHEN 'ITEM_COSTS' THEN
      v_rec.column_name      := 'error_description, count(*)';
      v_rec.table_name       := 'xxnbty_msc_costs_st';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'status = ''E'' ';
      v_rec.group_by_clause  := 'error_description';
      v_query(1)             := v_rec;
    WHEN 'BOM' THEN
      v_rec.column_name      := 'error_description, count(*)';
      v_rec.table_name       := 'xxnbty_bom_st_component';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'process_flag = 3 AND TRUNC(creation_date) = TRUNC(SYSDATE)';
      v_rec.group_by_clause  := 'error_description';
      v_query(1)             := v_rec;

      v_query.EXTEND();
      v_rec.column_name      := 'error_description, count(*)';
      v_rec.table_name       := 'xxnbty_cust_st_bom_int';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'process_flag = 3 AND TRUNC(creation_date) = TRUNC(SYSDATE)';
      v_rec.group_by_clause  := 'error_description';
      v_query(2)             := v_rec;

      v_query.EXTEND();
      v_rec.column_name      := 'NULL, count(*)';
      v_rec.table_name       := 'BOM_INVENTORY_COMPS_INTERFACE';
      v_rec.table_type       := 'INTERFACE';
      v_rec.where_clause     := 'process_flag = 3';
      v_rec.group_by_clause  := 1;
      v_query(3)             := v_rec;

      v_query.EXTEND();
      v_rec.column_name      := 'NULL, count(*)';
      v_rec.table_name       := 'BOM_BILL_OF_MTLS_INTERFACE';
      v_rec.table_type       := 'INTERFACE';
      v_rec.where_clause     := 'process_flag = 3';
      v_rec.group_by_clause  := 1;
      v_query(4)             := v_rec;
    WHEN 'FORMULA' THEN
      v_rec.column_name      := 'error_text, NULL';
      v_rec.table_name       := 'xxnbty_fm_matl_dtl_stg';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'status NOT IN (''P'', ''V'')';
      v_rec.group_by_clause  := 'error_text';
      v_query(1)             := v_rec;

      v_query.EXTEND();
      v_rec.column_name      := 'error_text, NULL';
      v_rec.table_name       := 'xxnbty_fm_form_mst_b_stg';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'status NOT IN (''P'', ''V'')';
      v_rec.group_by_clause  := 'error_text';
      v_query(2)             := v_rec;

      v_query.EXTEND();
      v_rec.column_name      := 'attribute30, NULL';
      v_rec.table_name       := 'xxnbty_frmla_upload';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'attribute29 NOT IN (''P'', ''V'') AND TRUNC(creation_date) = TRUNC(SYSDATE)';
      v_rec.group_by_clause  := 'attribute30';
      v_query(3)             := v_rec;
    WHEN 'BATCH' THEN
      v_rec.column_name      := 'error_description, count(*)';
      v_rec.table_name       := 'xxnbty_batch_int_st';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'error_description IS NOT NULL AND TRUNC(creation_date) = TRUNC(SYSDATE)';
      v_rec.group_by_clause  := 'error_description';
      v_query(1)             := v_rec;
    WHEN 'CUSTOMER_INTERFACE' THEN
      v_rec.column_name      := 'error_message, count(*)';
      v_rec.table_name       := 'xxnbty_cust_stg_tbl';
      v_rec.table_type       := 'STAGING';
      v_rec.where_clause     := 'process_flag = ''E'' AND TRUNC(creation_date) = TRUNC(SYSDATE)';
      v_rec.group_by_clause  := 'error_message';
      v_query(1)             := v_rec;

      v_query.EXTEND();
      v_rec.column_name      := 'NULL, count(*)';
      v_rec.table_name       := 'RA_CUSTOMERS_INTERFACE_ALL';
      v_rec.table_type       := 'INTERFACE';
      v_rec.where_clause     := 'interface_status IS NOT NULL';
      v_rec.group_by_clause  := 1;
      v_query(2)             := v_rec;
    END CASE;
		
    FOR i IN 1..v_query.COUNT
    LOOP
      OPEN cur FOR ' SELECT ' || v_query(i).column_name ||
                     ' FROM ' || v_query(i).table_name ||
                    ' WHERE ' || v_query(i).where_clause ||
                 ' GROUP BY ' || v_query(i).group_by_clause;
      LOOP
        FETCH cur BULK COLLECT INTO v_err;

          v_header := v_query(i).table_name ||  '(' || p_ricefw_name || ')';
            v_side_length := TRUNC((p_width - LENGTH(v_header)) / 2);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

            --display header
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'  ' || RPAD(LPAD(v_header, v_side_length + LENGTH(v_header) + 3, '*'), p_width + 6, '*')  || '  ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');

          IF v_err.COUNT = 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     ALL RECORDS FOR ' || v_query(i).table_name || '(' || p_ricefw_name || ') ARE VALID.');
          ELSE
            g_with_error_msg := TRUE; --set global variable if there's an error in RICEFW.
			
			--Start 6/9/2015 AFlores
			--Set global variable to true if there will be errors per object
			--ON_HAND_DATA
			IF p_ricefw_name = 'ON_HAND_DATA' THEN
				g_det_onhand_with_error := TRUE;
			--IN_TRANSIT
			ELSIF p_ricefw_name = 'IN_TRANSIT' THEN
				g_det_intransit_with_error := TRUE;	
			--WORK_ORDERS	
			ELSIF p_ricefw_name = 'WORK_ORDERS' THEN
				g_det_wo_with_error := TRUE;
			--WIP	
			ELSIF p_ricefw_name = 'WIP' THEN
				g_det_wip_with_error := TRUE;	
			--SALES_ORDERS	
			ELSIF p_ricefw_name = 'SALES_ORDERS' THEN
				g_det_sales_with_error := TRUE;
			--ITEM_COSTS	
			ELSIF p_ricefw_name = 'ITEM_COSTS' THEN
				g_det_cost_with_error := TRUE;
			END IF;		
			--End 6/9/2015 AFlores	
			
				--display column header
				IF v_err(1).error_msg IS NOT NULL AND v_err(1).ctr IS NOT NULL THEN --display all columns
				  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     Error Count     Error Message');
				  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     -----------     -------------');
				ELSIF v_err(1).error_msg IS NULL THEN --display error count only if message is null
				  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     Error Count');
				  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     -----------');
				ELSIF v_err(1).ctr IS NULL THEN --display error message only if count is null
				  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     Error Message');
				  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     -------------');
				END IF;
          END IF;

          FOR ii IN 1..v_err.COUNT
          LOOP
            IF v_err(ii).error_msg IS NOT NULL AND v_err(ii).ctr IS NOT NULL THEN --display all columns
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     ' || RPAD(TO_CHAR(v_err(ii).ctr, 'fm999,999,999,999,999'), 16, ' ') || v_err(ii).error_msg);
            ELSIF v_err(ii).error_msg IS NULL THEN --display error count only if message is null
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     ' || TO_CHAR(v_err(ii).ctr, 'fm999,999,999,999,999'));
            ELSIF v_err(ii).ctr IS NULL THEN --display error message only if count is null
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'     ' || v_err(ii).error_msg);
            END IF;
          END LOOP;
          EXIT WHEN cur%NOTFOUND;
      END LOOP;
      CLOSE cur;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      x_retcode := 2;
      x_errbuf := SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error message : ' || x_errbuf);
  END generate_err_log;
  
  PROCEDURE generate_detailed_err_log ( x_retcode     OUT VARCHAR2,
										x_errbuf      OUT VARCHAR2,
										p_det_ricefw_name VARCHAR2,
										p_req_id      OUT  NUMBER)
  IS
  --------------------------------------------------------------------------------------------
  /*
  Procedure Name: generate_detailed_err_log
  Author's Name: Albert John Flores
  Date written: 9-Jun-2015
  RICEFW Object: REP02
  Description: Procedure for generate detailed error log per ricefw using FND_FILE. 
  Program Style:
  Maintenance History:
  Date         Issue#  Name         			    Remarks
  -----------  ------  -------------------		------------------------------------------------
  9-Jun-2015           Albert John Flores	 	Initial Development

  */
  --------------------------------------------------------------------------------------------
  	ln_wait             BOOLEAN;
	lc_phase            VARCHAR2(100)   := NULL;
	lc_status           VARCHAR2(30)    := NULL;
	lc_devphase         VARCHAR2(100)   := NULL;
	lc_devstatus        VARCHAR2(100)   := NULL;
	lc_mesg             VARCHAR2(50)    := NULL;
  
  BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Entered procedure generate_detailed_err_log' );   
  
  CASE p_det_ricefw_name
  WHEN 'ON_HAND_DATA' THEN
		p_req_id := FND_REQUEST.SUBMIT_REQUEST(application  => 'XXNBTY'
													,program      => 'XXNBTY_MSC_LF10_DET_ERR_REP'
													,start_time   => NULL
													,sub_request  => FALSE
													);
													
		FND_CONCURRENT.AF_COMMIT;
				
		ln_wait := fnd_concurrent.wait_for_request( request_id      => p_req_id
												  , interval        => 30
												  , max_wait        => ''
												  , phase           => lc_phase
												  , status          => lc_status
												  , dev_phase       => lc_devphase
												  , dev_status      => lc_devstatus
												  , message         => lc_mesg
												  );
		FND_CONCURRENT.AF_COMMIT;
		
		--check for the report completion
		IF (lc_devphase = 'COMPLETE' AND lc_devstatus = 'NORMAL') THEN 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent program for detailed error report has completed successfully'); 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of XXNBTY On Hand Detailed Error Report is ' || p_req_id); 
		ELSE
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Generating detailed error report for '|| p_det_ricefw_name || ' failed.' );   
		END IF;

  WHEN 'IN_TRANSIT' THEN
		p_req_id := FND_REQUEST.SUBMIT_REQUEST(application  => 'XXNBTY'
													,program      => 'XXNBTY_MSC_LF11_DET_ERR_REP'
													,start_time   => NULL
													,sub_request  => FALSE
													);
													
		FND_CONCURRENT.AF_COMMIT;
				
		ln_wait := fnd_concurrent.wait_for_request( request_id      => p_req_id
												  , interval        => 30
												  , max_wait        => ''
												  , phase           => lc_phase
												  , status          => lc_status
												  , dev_phase       => lc_devphase
												  , dev_status      => lc_devstatus
												  , message         => lc_mesg
												  );
		FND_CONCURRENT.AF_COMMIT;
		
		--check for the report completion
		IF (lc_devphase = 'COMPLETE' AND lc_devstatus = 'NORMAL') THEN 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent program for detailed error report has completed successfully'); 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of XXNBTY In Transit Detailed Error Report is ' || p_req_id); 
		ELSE
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Generating detailed error report for '|| p_det_ricefw_name || ' failed.' );   
		END IF;
		
  WHEN 'WORK_ORDERS' THEN
		p_req_id := FND_REQUEST.SUBMIT_REQUEST(application  => 'XXNBTY'
													,program      => 'XXNBTY_MSC_LF14_DET_ERR_REP'
													,start_time   => NULL
													,sub_request  => FALSE
													);
													
		FND_CONCURRENT.AF_COMMIT;
				
		ln_wait := fnd_concurrent.wait_for_request( request_id      => p_req_id
												  , interval        => 30
												  , max_wait        => ''
												  , phase           => lc_phase
												  , status          => lc_status
												  , dev_phase       => lc_devphase
												  , dev_status      => lc_devstatus
												  , message         => lc_mesg
												  );
		FND_CONCURRENT.AF_COMMIT;
		
		--check for the report completion
		IF (lc_devphase = 'COMPLETE' AND lc_devstatus = 'NORMAL') THEN 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent program for Work orders detailed error report has completed successfully'); 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of XXNBTY Detailed Error Report is ' || p_req_id); 
		ELSE
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Generating detailed error report for '|| p_det_ricefw_name || ' failed.' );   
		END IF;	

  WHEN 'WIP' THEN
		p_req_id := FND_REQUEST.SUBMIT_REQUEST(application  => 'XXNBTY'
													,program      => 'XXNBTY_MSC_LF16_DET_ERR_REP'
													,start_time   => NULL
													,sub_request  => FALSE
													);
													
		FND_CONCURRENT.AF_COMMIT;
				
		ln_wait := fnd_concurrent.wait_for_request( request_id      => p_req_id
												  , interval        => 30
												  , max_wait        => ''
												  , phase           => lc_phase
												  , status          => lc_status
												  , dev_phase       => lc_devphase
												  , dev_status      => lc_devstatus
												  , message         => lc_mesg
												  );
		FND_CONCURRENT.AF_COMMIT;
		
		--check for the report completion
		IF (lc_devphase = 'COMPLETE' AND lc_devstatus = 'NORMAL') THEN 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent program for detailed error report has completed successfully'); 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of XXNBTY WIP Detailed Error Report is ' || p_req_id); 
		ELSE
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Generating detailed error report for '|| p_det_ricefw_name || ' failed.' );   
		END IF;	

  WHEN 'SALES_ORDERS' THEN
		p_req_id := FND_REQUEST.SUBMIT_REQUEST(application  => 'XXNBTY'
													,program      => 'XXNBTY_MSC_LF17_DET_ERR_REP'
													,start_time   => NULL
													,sub_request  => FALSE
													);
													
		FND_CONCURRENT.AF_COMMIT;
				
		ln_wait := fnd_concurrent.wait_for_request( request_id      => p_req_id
												  , interval        => 30
												  , max_wait        => ''
												  , phase           => lc_phase
												  , status          => lc_status
												  , dev_phase       => lc_devphase
												  , dev_status      => lc_devstatus
												  , message         => lc_mesg
												  );
		FND_CONCURRENT.AF_COMMIT;
		
		--check for the report completion
		IF (lc_devphase = 'COMPLETE' AND lc_devstatus = 'NORMAL') THEN 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent program for detailed error report has completed successfully'); 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of XXNBTY Sales orders Detailed Error Report is ' || p_req_id); 
		ELSE
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Generating detailed error report for '|| p_det_ricefw_name || ' failed.' );   
		END IF;	

  WHEN 'ITEM_COSTS' THEN
		p_req_id := FND_REQUEST.SUBMIT_REQUEST(application  => 'XXNBTY'
													,program      => 'XXNBTY_MSC_LF19_DET_ERR_REP'
													,start_time   => NULL
													,sub_request  => FALSE
													);
													
		FND_CONCURRENT.AF_COMMIT;
				
		ln_wait := fnd_concurrent.wait_for_request( request_id      => p_req_id
												  , interval        => 30
												  , max_wait        => ''
												  , phase           => lc_phase
												  , status          => lc_status
												  , dev_phase       => lc_devphase
												  , dev_status      => lc_devstatus
												  , message         => lc_mesg
												  );
		FND_CONCURRENT.AF_COMMIT;
		
		--check for the report completion
		IF (lc_devphase = 'COMPLETE' AND lc_devstatus = 'NORMAL') THEN 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent program for detailed error report has completed successfully'); 
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Request ID of XXNBTY Item costs Detailed Error Report is ' || p_req_id); 
		ELSE
		  FND_FILE.PUT_LINE(FND_FILE.LOG,'Generating detailed error report for '|| p_det_ricefw_name || ' failed.' );   
		END IF;				

  END CASE;
  
    EXCEPTION
    WHEN OTHERS THEN
      x_retcode := 2;
      x_errbuf := SQLERRM;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error message : ' || x_errbuf);
  END generate_detailed_err_log;
  
END XXNBTY_VCP_SEND_EMAIL_PKG;
/
show errors;
