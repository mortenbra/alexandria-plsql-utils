-- see http://technology.amis.nl/blog/10995/create-an-excel-file-with-plsql

begin
  xlsx_builder_pkg.new_sheet;
  xlsx_builder_pkg.cell( 5, 1, 5 );
  xlsx_builder_pkg.cell( 3, 1, 3 );
  xlsx_builder_pkg.cell( 2, 2, 45 );
  xlsx_builder_pkg.cell( 3, 2, 'Anton Scheffer', p_alignment => xlsx_builder_pkg.get_alignment( p_wraptext => true ) );
  xlsx_builder_pkg.cell( 1, 4, sysdate );
  xlsx_builder_pkg.cell( 2, 4, sysdate, p_numFmtId => xlsx_builder_pkg.get_numFmt( 'dd/mm/yyyy h:mm' ) );
  xlsx_builder_pkg.cell( 3, 4, sysdate, p_numFmtId => xlsx_builder_pkg.get_numFmt( xlsx_builder_pkg.orafmt2excel( 'dd/mon/yyyy' ) ) );
  xlsx_builder_pkg.cell( 5, 5, 75, p_borderId => xlsx_builder_pkg.get_border( 'double', 'double', 'double', 'double' ) );
  xlsx_builder_pkg.cell( 2, 3, 33 );
  xlsx_builder_pkg.hyperlink( 1, 6, 'http://www.amis.nl', 'Amis site' );
  xlsx_builder_pkg.cell( 1, 7, 'Some merged cells', p_alignment => xlsx_builder_pkg.get_alignment( p_horizontal => 'center' ) );
  xlsx_builder_pkg.mergecells( 1, 7, 3, 7 );
  for i in 1 .. 5
  loop
    xlsx_builder_pkg.comment( 3, i + 3, 'Row ' || (i+3), 'Anton' );
  end loop;
  xlsx_builder_pkg.new_sheet;
  xlsx_builder_pkg.set_row( 1, p_fillId => xlsx_builder_pkg.get_fill( 'solid', 'FFFF0000' ) ) ;
  for i in 1 .. 5
  loop
    xlsx_builder_pkg.cell( 1, i, i );
    xlsx_builder_pkg.cell( 2, i, i * 3 );
    xlsx_builder_pkg.cell( 3, i, 'x ' || i * 3 );
  end loop;
  xlsx_builder_pkg.query2sheet( 'select rownum, x.*
, case when mod( rownum, 2 ) = 0 then rownum * 3 end demo
, case when mod( rownum, 2 ) = 1 then ''demo '' || rownum end demo2 from dual x connect by rownum <= 5' );
  xlsx_builder_pkg.save( 'MY_DIR', 'my.xlsx' );
end;
/



