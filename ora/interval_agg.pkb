/*

Purpose:    Types used by the interval aggregate functions

Remarks:    

Who     Date        Description
------  ----------  -------------------------------------
AJM     14.09.2015  Created

*/

create or replace type body t_sum_dsinterval
as

  static function ODCIAggregateInitialize (actx in out t_sum_dsinterval) return number
  as
  begin

    if actx is null then
      actx := t_sum_dsinterval (interval '0 0:0:0.0' day to second);
    else
      actx.runningsum := interval '0 0:0:0.0' day to second;
    end if;
    return ODCIConst.Success;

  end ODCIAggregateInitialize;

  member function ODCIAggregateIterate (self in out t_sum_dsinterval,
                                        val in dsinterval_unconstrained) return number as
  begin

    self.runningsum := self.runningsum + val;
    return ODCIConst.Success;

  end ODCIAggregateIterate;

  member function ODCIAggregateMerge (self in out t_sum_dsinterval,
                                      ctx2 in t_sum_dsinterval) return number as
  begin

    self.runningsum := self.runningsum + ctx2.runningsum;
    return ODCIConst.Success;

  end ODCIAggregateMerge;

  member function ODCIAggregateTerminate (self in t_sum_dsinterval,
                                          returnvalue out dsinterval_unconstrained,
                                          flags in number) return number as
  begin

    returnvalue := self.runningsum;
    return ODCIConst.Success;

  end ODCIAggregateTerminate;
end;
/

create or replace type body t_avg_dsinterval
as

  static function ODCIAggregateInitialize (actx in out t_avg_dsinterval) return number
  as
  begin

    if actx is null then
      actx := t_avg_dsinterval (interval '0 0:0:0.0' day to second, 0);
    else
      actx.runningsum := interval '0 0:0:0.0' day to second;
      actx.runningcount := 0;
    end if;
    return ODCIConst.Success;

  end ODCIAggregateInitialize;

  member function ODCIAggregateIterate (self in out t_avg_dsinterval,
                                        val in dsinterval_unconstrained) return number as
  begin

    self.runningsum := self.runningsum + val;
    self.runningcount := self.runningcount + 1;
    return ODCIConst.Success;

  end ODCIAggregateIterate;

  member function ODCIAggregateMerge (self in out t_avg_dsinterval,
                                      ctx2 in t_avg_dsinterval) return number as
  begin

    self.runningsum := self.runningsum + ctx2.runningsum;
    self.runningcount := self.runningcount + ctx2.runningcount;
    return ODCIConst.Success;

  end ODCIAggregateMerge;

  member function ODCIAggregateTerminate (self in t_avg_dsinterval,
                                          returnvalue out dsinterval_unconstrained,
                                          flags in number) return number as
  begin

    if self.runningcount <> 0 then
      returnvalue := self.runningsum / self.runningcount;
    else
      returnvalue := self.runningsum;
    end if;
    return ODCIConst.Success;

  end ODCIAggregateTerminate;
end;
/

create or replace type body t_sum_yminterval
as

  static function ODCIAggregateInitialize (actx in out t_sum_yminterval) return number
  as
  begin

    if actx is null then
      actx := t_sum_yminterval (interval '0-00' year to month);
    else
      actx.runningsum := interval '0-00' year to month;
    end if;
    return ODCIConst.Success;

  end ODCIAggregateInitialize;

  member function ODCIAggregateIterate (self in out t_sum_yminterval,
                                        val in yminterval_unconstrained) return number as
  begin

    self.runningsum := self.runningsum + val;
    return ODCIConst.Success;

  end ODCIAggregateIterate;

  member function ODCIAggregateMerge (self in out t_sum_yminterval,
                                      ctx2 in t_sum_yminterval) return number as
  begin

    self.runningsum := self.runningsum + ctx2.runningsum;
    return ODCIConst.Success;

  end ODCIAggregateMerge;

  member function ODCIAggregateTerminate (self in t_sum_yminterval,
                                          returnvalue out yminterval_unconstrained,
                                          flags in number) return number as
  begin

    returnvalue := self.runningsum;
    return ODCIConst.Success;

  end ODCIAggregateTerminate;
end;
/

create or replace type body t_avg_yminterval
as

  static function ODCIAggregateInitialize (actx in out t_avg_yminterval) return number
  as
  begin

    if actx is null then
      actx := t_avg_yminterval (interval '0-00' year to month, 0);
    else
      actx.runningsum := interval '0-00' year to month;
      actx.runningcount := 0;
    end if;
    return ODCIConst.Success;

  end ODCIAggregateInitialize;

  member function ODCIAggregateIterate (self in out t_avg_yminterval,
                                        val in yminterval_unconstrained) return number as
  begin

    self.runningsum := self.runningsum + val;
    self.runningcount := self.runningcount + 1;
    return ODCIConst.Success;

  end ODCIAggregateIterate;

  member function ODCIAggregateMerge (self in out t_avg_yminterval,
                                      ctx2 in t_avg_yminterval) return number as
  begin

    self.runningsum := self.runningsum + ctx2.runningsum;
    self.runningcount := self.runningcount + ctx2.runningcount;
    return ODCIConst.Success;

  end ODCIAggregateMerge;

  member function ODCIAggregateTerminate (self in t_avg_yminterval,
                                          returnvalue out yminterval_unconstrained,
                                          flags in number) return number as
  begin

    if self.runningcount <> 0 then
      returnvalue := self.runningsum / self.runningcount;
    else
      returnvalue := self.runningsum;
    end if;
    return ODCIConst.Success;

  end ODCIAggregateTerminate;
end;
/
