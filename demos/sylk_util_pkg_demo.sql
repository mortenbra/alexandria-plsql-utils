
-- see http://asktom.oracle.com/pls/asktom/f?p=100:11:0::::P11_QUESTION_ID:728625409049

Rem
Rem $Id$
Rem
Rem  Copyright (c) 1991, 1996, 1997 by Oracle Corporation
Rem    NAME
Rem      owasylk.sql - Dump to Spreadsheet with formatting
Rem   DESCRIPTION
Rem     This package provides an API to generate a file in the
Rem     SYLK file format.  This allow for formatting in a 
Rem     spreadsheet with only a ascii text file.  This version 
Rem     of owa_sylk is specific to Oracle8.
Rem   NOTES
Rem
Rem   MODIFIED     (MM/DD/YY)
Rem     clbeck      04/08/98  - Created.
Rem     tkyte       09/10/00  - Made it use UTL_FILE.
Rem
Rem

/*
  This package allows you to send the results of any query to 
  a spreadsheet using UTL_FILE

  parameters:
    p_query        - a text string of the query.  The query 
                     can be parameterized
                     using the :VARAIBLE syntax.  See example 
                     below.

    p_parm_names   - an owaSylkArray of the paramter names 
                     used as bind variables in p_query

    p_parm_values  - an owaSylkArray of the values of the 
                     bind variable names.  The values
                     muse reside in the same index as the 
                     name it corresponds to.

    p_cursor       - an open cursor that has had the query 
                     parsed already.

    p_sum_column   - a owaSylkArray of 'Y's and 'N's 
                     corresponding to the location
                     of the columns selected in p_query.  
                     A value of NYNYY will result
                     in the 2nd, 4th and 5th columns being 
                     summed in the resulting
                     spreadsheet.

    p_max_rows     - the maxium number of row to return.

    p_show_null_as - how to display nulls in the spreadsheet

    p_show_grid    - show/hide the grid in the spreadsheet.

    p_show_col_headers - show/hide the row/column headers 
                         in the spreadsheet.

    p_font_name    - the name of the font

    p_widths       - a owaSylkArray of column widths.  This 
                     will override the default column widths.

    p_headings     - a owaSylkArray of column titles.  
                     This will override the default column 
                     titles.

    p_strip_html   - this will remove the HTML tags from the 
                     results before
                     displaying them in the spreadsheet cells.
                     Useful when the
                     query selects an anchor tag. Only the 
                     text between <a href>
                     and </a> tags will be sent to the 
                     spreadsheet.

*/


--  examples:

--    This example will create a spreadsheet of all the MANAGERS 
--    in the scott.emp table and will sum up the salaries 
--    and commissions for them.  No grid will be in the 
--    spreadsheet.

    

declare
    output utl_file.file_type;
begin
    output := utl_file.fopen( 'DEVTEST_TEMP_DIR', 'emp1.slk', 'w', 32000 );

    sylk_util_pkg.show(
        p_file => output,
        p_query => 'select empno id, ename employee, sal Salary, comm commission from emp where job = :JOB and sal > :SAL',
        p_parm_names => sylk_util_pkg.owaSylkArray( 'JOB', 'SAL'),
        p_parm_values => sylk_util_pkg.owaSylkArray( 'MANAGER', '2000' ),
       p_sum_column => sylk_util_pkg.owaSylkArray( 'N', 'N', 'Y', 'Y'),
        p_show_grid => 'NO' );

    utl_file.fflush ( output );
    utl_file.fclose ( output );
end;



--    This example will create the same spreadsheet but will 
--    send in a pre-parsed cursor instead

declare
    l_cursor number := dbms_sql.open_cursor;
    output utl_file.file_type;
begin
    output := utl_file.fopen( 'DEVTEST_TEMP_DIR', 'emp2.slk', 'w',32000 );

    dbms_sql.parse( l_cursor, 'select empno id, ename employee, sal Salary, comm commission from emp where job = ''MANAGER'' and sal > 2000', dbms_sql.native );

    sylk_util_pkg.show(
        p_file => output ,
        p_cursor => l_cursor,
        p_sum_column => sylk_util_pkg.owaSylkArray( 'N', 'N', 'Y', 'Y' ),
        p_show_grid => 'NO' );

    dbms_sql.close_cursor( l_cursor );
    utl_file.fflush ( output );
    utl_file.fclose ( output );
    
end;
