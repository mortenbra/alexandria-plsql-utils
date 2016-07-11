/*

Purpose:    Types used by the interval aggregate functions

Remarks:    

Who     Date        Description
------  ----------  -------------------------------------
AJM     14.09.2015  Created

*/

create or replace type t_sum_dsinterval as object (
  runningsum interval day(9) to second(9),

  static function ODCIAggregateInitialize (actx in out t_sum_dsinterval) return number,

  member function ODCIAggregateIterate (self in out t_sum_dsinterval,
                                        val in dsinterval_unconstrained) return number,

  member function ODCIAggregateMerge (self in out t_sum_dsinterval,
                                      ctx2 in t_sum_dsinterval) return number,

  member function ODCIAggregateTerminate (self in t_sum_dsinterval,
                                          returnvalue out dsinterval_unconstrained,
                                          flags in number) return number
);
/

create or replace type t_avg_dsinterval as object (
  runningsum interval day(9) to second(9),
  runningcount number,

  static function ODCIAggregateInitialize (actx in out t_avg_dsinterval) return number,

  member function ODCIAggregateIterate (self in out t_avg_dsinterval,
                                        val in dsinterval_unconstrained) return number,

  member function ODCIAggregateMerge (self in out t_avg_dsinterval,
                                      ctx2 in t_avg_dsinterval) return number,

  member function ODCIAggregateTerminate (self in t_avg_dsinterval,
                                          returnvalue out dsinterval_unconstrained,
                                          flags in number) return number
);
/

create or replace type t_sum_yminterval as object (
  runningsum interval year(9) to month,

  static function ODCIAggregateInitialize (actx in out t_sum_yminterval) return number,

  member function ODCIAggregateIterate (self in out t_sum_yminterval,
                                        val in yminterval_unconstrained) return number,

  member function ODCIAggregateMerge (self in out t_sum_yminterval,
                                      ctx2 in t_sum_yminterval) return number,

  member function ODCIAggregateTerminate (self in t_sum_yminterval,
                                          returnvalue out yminterval_unconstrained,
                                          flags in number) return number
);
/

create or replace type t_avg_yminterval as object (
  runningsum interval year(9) to month,
  runningcount number,

  static function ODCIAggregateInitialize (actx in out t_avg_yminterval) return number,

  member function ODCIAggregateIterate (self in out t_avg_yminterval,
                                        val in yminterval_unconstrained) return number,

  member function ODCIAggregateMerge (self in out t_avg_yminterval,
                                      ctx2 in t_avg_yminterval) return number,

  member function ODCIAggregateTerminate (self in t_avg_yminterval,
                                          returnvalue out yminterval_unconstrained,
                                          flags in number) return number
);
/
