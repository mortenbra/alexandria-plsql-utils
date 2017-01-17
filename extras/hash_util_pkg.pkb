create or replace package body hash_util_pkg
as
  
  type ta_number is table of number index by binary_integer;

  type tr_ctx is record (
    h ta_number,
    total_length number,
    leftover_buffer raw(256),
    leftover_buffer_length number,
    words_array ta_number
  );
  
  m_ctx tr_ctx;
  m_k ta_number;
  m_result ta_number;
  
  -- Constants for message padding
  c_bits_00 raw(1) := hextoraw('00');
  c_bits_80 raw(1) := hextoraw('80');

  -- Constant for 32bit bitwise operations
  c_bits_80000000 number := to_number('80000000','xxxxxxxx');
  c_bits_ffffffc0 number := to_number('FFFFFFC0','xxxxxxxx');
  c_bits_ffffffff number := to_number('FFFFFFFF','xxxxxxxx');
  
  -- Constant for 64bit bitwise operations
  c_bits_8000000000000000 number := to_number('8000000000000000','xxxxxxxxxxxxxxxx');
  c_bits_ffffffffffffff80 number := to_number('FFFFFFFFFFFFFF80','xxxxxxxxxxxxxxxx');
  c_bits_ffffffffffffffff number := to_number('FFFFFFFFFFFFFFFF','xxxxxxxxxxxxxxxx');

  ---
  --- Bitwise operators
  ---
  
  function bitor(x in number, y in number) return number as
  begin
    return (x + y - bitand(x, y));
  end;
  
  function bitxor(x in number, y in number) return number as
  begin
    return bitor(x, y) - bitand(x, y);
  end;
  
  function bitnot32(x in number) return number as
  begin
    return c_bits_ffffffff - x;
  end;
  
  function leftshift32(x in number, y in number) return number as
    tmp number := x;
  begin
    for idx in 1..y
    loop
      tmp := tmp * 2;
    end loop;
    return bitand(tmp, c_bits_ffffffff);
  end;
  
  function rightshift32(x in number, y in number) return number as
    tmp number := x;
  begin
    for idx in 1..y
    loop
      tmp := trunc(tmp / 2);
    end loop;
    return bitand(tmp, c_bits_ffffffff);
  end;
  
  function cyclic32(x in number, y in number) return number as
  begin
    return bitor(rightshift32(x, y), leftshift32(x, 32-y));
  end;

  function bitnot64(x in number) return number as
  begin
    return c_bits_ffffffffffffffff - x;
  end;
  
  function leftshift64(x in number, y in number) return number as
    tmp number := x;
  begin
    for idx in 1..y
    loop
      tmp := tmp * 2;
    end loop;
    return bitand(tmp, c_bits_ffffffffffffffff);
  end;
  
  function rightshift64(x in number, y in number) return number as
    tmp number := x;
  begin
    for idx in 1..y
    loop
      tmp := trunc(tmp / 2);
    end loop;
    return bitand(tmp, c_bits_ffffffffffffffff);
  end;
  
  function cyclic64(x in number, y in number) return number as
  begin
    return bitor(rightshift64(x, y), leftshift64(x, 64-y));
  end;

  ---
  --- Operators defined in FIPS 180-2:4.1.2.
  ---
  
  function op_maj(x in number, y in number, z in number) return number as
  begin
    return bitxor(bitxor(bitand(x,y), bitand(x,z)), bitand(y,z));
  end;
  
  function op_ch_32(x in number, y in number, z in number) return number as
  begin
    return bitxor(bitand(x, y), bitand(bitnot32(x), z));
  end;
  
  function op_s0_32(x in number) return number as 
  begin
    return bitxor(bitxor(cyclic32(x, 2), cyclic32(x, 13)), cyclic32(x, 22));
  end;
  
  function op_s1_32(x in number) return number as
  begin
    return bitxor(bitxor(cyclic32(x, 6), cyclic32(x, 11)), cyclic32(x, 25));
  end;
  
  function op_r0_32(x in number) return number as
  begin
    return bitxor(bitxor(cyclic32(x, 7), cyclic32(x, 18)), rightshift32(x, 3));
  end;
  
  function op_r1_32(x in number) return number as
  begin
    return bitxor(bitxor(cyclic32(x, 17), cyclic32(x, 19)), rightshift32(x, 10));
  end;

  function op_ch_64(x in number, y in number, z in number) return number as
  begin
    return bitxor(bitand(x, y), bitand(bitnot64(x), z));
  end;
  
  function op_s0_64(x in number) return number as 
  begin
    return bitxor(bitxor(cyclic64(x, 28), cyclic64(x, 34)), cyclic64(x, 39));
  end;
  
  function op_s1_64(x in number) return number as
  begin
    return bitxor(bitxor(cyclic64(x, 14), cyclic64(x, 18)), cyclic64(x, 41));
  end;
  
  function op_r0_64(x in number) return number as
  begin
    return bitxor(bitxor(cyclic64(x, 1), cyclic64(x, 8)), rightshift64(x, 7));
  end;
  
  function op_r1_64(x in number) return number as
  begin
    return bitxor(bitxor(cyclic64(x, 19), cyclic64(x, 61)), rightshift64(x, 6));
  end;
  
  --
  -- SHA-1
  --

  procedure sha1_init_ctx 
  as
  begin
    m_ctx.h(0) := to_number('67452301', 'xxxxxxxx');
    m_ctx.h(1) := to_number('efcdab89', 'xxxxxxxx');
    m_ctx.h(2) := to_number('98badcfe', 'xxxxxxxx');
    m_ctx.h(3) := to_number('10325476', 'xxxxxxxx');
    m_ctx.h(4) := to_number('c3d2e1f0', 'xxxxxxxx');
    m_ctx.total_length := 0;
    m_ctx.leftover_buffer := null;
    m_ctx.leftover_buffer_length := 0;
    for idx in 0..15 loop
      m_ctx.words_array(idx) := 0;
    end loop;
  end sha1_init_ctx;

  procedure sha1_process_block(p_words_array in ta_number,
                               p_words_count in number) 
  as
    l_words_array ta_number := p_words_array;
    l_words_count number := p_words_count;
    l_words_idx number;
    t number;
    a number := m_ctx.h(0);
    b number := m_ctx.h(1);
    c number := m_ctx.h(2);
    d number := m_ctx.h(3);
    e number := m_ctx.h(4);
    w ta_number; 
    a_save number;
    b_save number;
    c_save number;
    d_save number;
    e_save number;
    f number;
    k number;
    temp number;
  begin
    -- Process all bytes in the buffer with 64 bytes in each round of the loop. 
    l_words_idx := 0;
    while (l_words_count > 0) loop
      a_save := a;
      b_save := b;
      c_save := c;
      d_save := d;
      e_save := e;
      for t in 0..15 loop
        w(t) := l_words_array(l_words_idx);
        l_words_idx := l_words_idx + 1;
      end loop;
      for t in 16..79 loop
        w(t) := cyclic32(bitxor(bitxor(bitxor(w(t-3), w(t-8)), w(t-14)), w(t-16)), 32-1);
      end loop;
      for t in 0..79 loop
        if t between 0 and 19 then
          f := bitor(bitand(b, c), bitand(bitnot32(b), d));
          k := to_number('5a827999', 'xxxxxxxx');
        elsif t between 20 and 39 then
          f := bitxor(bitxor(b, c), d);
          k := to_number('6ed9eba1', 'xxxxxxxx');
        elsif t between 40 and 59 then
          f := bitor(bitor(bitand(b, c), bitand(b, d)), bitand(c, d));
          k := to_number('8f1bbcdc', 'xxxxxxxx');
        elsif t between 60 and 79 then
          f := bitxor(bitxor(b, c), d);
          k := to_number('ca62c1d6', 'xxxxxxxx');
        end if;
        temp := bitand(cyclic32(a, 32-5) + f + e + k + w(t), c_bits_ffffffff);
        e := d;
        d := c;
        c := cyclic32(b, 32-30);
        b := a;
        a := temp;
      end loop;
      a := bitand(a + a_save, c_bits_ffffffff);
      b := bitand(b + b_save, c_bits_ffffffff);
      c := bitand(c + c_save, c_bits_ffffffff);
      d := bitand(d + d_save, c_bits_ffffffff);
      e := bitand(e + e_save, c_bits_ffffffff);
      -- Prepare for the next round. 
      l_words_count := l_words_count - 16;
    end loop;
    -- Put checksum in context given as argument.
    m_ctx.h(0) := a;
    m_ctx.h(1) := b;
    m_ctx.h(2) := c;
    m_ctx.h(3) := d;
    m_ctx.h(4) := e;
  end sha1_process_block;

  procedure sha1_process_bytes(p_buffer in raw,
                               p_buffer_length in number)
  as
    l_buffer raw(16640);
    l_buffer_length number;
    l_words_array ta_number;
  begin
    -- First increment the byte count.  FIPS 180-2 specifies the possible
    -- length of the file up to 2^64 bits. Here we only compute the number of
    -- bytes. 
    m_ctx.total_length := m_ctx.total_length + nvl(p_buffer_length, 0);
    -- When we already have some bits in our internal buffer concatenate both inputs first.
    if (m_ctx.leftover_buffer_length = 0) then
      l_buffer := p_buffer;
      l_buffer_length := nvl(p_buffer_length, 0);
    else
      l_buffer := m_ctx.leftover_buffer || p_buffer;
      l_buffer_length := m_ctx.leftover_buffer_length + nvl(p_buffer_length, 0);
    end if;
    -- Process available complete blocks.
    if (l_buffer_length >= 64) then
      declare
        l_words_count number := bitand(l_buffer_length, c_bits_ffffffc0) / 4;
        l_max_idx number := l_words_count - 1;
        l_numberraw raw(4);
        l_numberhex varchar(8);
        l_number number;
      begin
        for idx in 0..l_max_idx loop
          l_numberraw := sys.utl_raw.substr(l_buffer, idx * 4 + 1, 4);
          l_numberhex := rawtohex(l_numberraw);
          l_number := to_number(l_numberhex, 'xxxxxxxx');
          l_words_array(idx) := l_number;
        end loop;
        sha1_process_block(l_words_array, l_words_count);
        l_buffer_length := bitand(l_buffer_length, 63);
        if (l_buffer_length > 0) then
          l_buffer := sys.utl_raw.substr(l_buffer, l_words_count * 4 + 1, l_buffer_length);
        end if;
      end;
    end if;
    -- Move remaining bytes into internal buffer. 
    if (l_buffer_length > 0) then
      m_ctx.leftover_buffer := l_buffer;
      m_ctx.leftover_buffer_length := l_buffer_length;
    end if;
  end sha1_process_bytes;
  
  procedure sha1_finish_ctx(p_resultbuf out nocopy ta_number)
  as
    l_filesizeraw raw(8);
  begin
    m_ctx.leftover_buffer := m_ctx.leftover_buffer || c_bits_80;
    m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 1;
    while ((m_ctx.leftover_buffer_length mod 64) <> 56) loop
      m_ctx.leftover_buffer := m_ctx.leftover_buffer || c_bits_00;
      m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 1;
    end loop;
    l_filesizeraw := hextoraw(to_char(m_ctx.total_length * 8, 'FM0xxxxxxxxxxxxxxx'));
    m_ctx.leftover_buffer := m_ctx.leftover_buffer || l_filesizeraw;
    m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 8;
    sha1_process_bytes(null, 0);
    for idx in 0..4 loop
      p_resultbuf(idx) := m_ctx.h(idx);
    end loop;
  end sha1_finish_ctx;

  function sha1(p_buffer in raw) return sha1_checksum_raw
  as
    l_result sha1_checksum_raw;
  begin
    sha1_init_ctx;
    sha1_process_bytes(p_buffer, sys.utl_raw.length(p_buffer));
    sha1_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0), 'FM0xxxxxxx') || 
      to_char(m_result(1), 'FM0xxxxxxx') || 
      to_char(m_result(2), 'FM0xxxxxxx') || 
      to_char(m_result(3), 'FM0xxxxxxx') || 
      to_char(m_result(4), 'FM0xxxxxxx')
    );
    return l_result;
  end sha1;
  
  function sha1(p_buffer in blob) return sha1_checksum_raw
  as
    l_result sha1_checksum_raw;
    l_buffer raw(16384);
    l_amount number := 16384;
    l_offset number := 1;
  begin
    sha1_init_ctx;
    begin
      loop
        sys.dbms_lob.read(p_buffer, l_amount, l_offset, l_buffer);
        sha1_process_bytes(l_buffer, l_amount);
        l_offset := l_offset + l_amount;
        l_amount := 16384;
      end loop;
    exception
      when no_data_found then
        null;
    end;
    sha1_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0), 'FM0xxxxxxx') || 
      to_char(m_result(1), 'FM0xxxxxxx') || 
      to_char(m_result(2), 'FM0xxxxxxx') || 
      to_char(m_result(3), 'FM0xxxxxxx') || 
      to_char(m_result(4), 'FM0xxxxxxx')
    );
    return l_result;
  end sha1;
  
  --
  -- SHA-256
  --

  procedure sha256_init_k
  as
  begin
    m_k(0) := to_number('428a2f98', 'xxxxxxxx');
    m_k(1) := to_number('71374491', 'xxxxxxxx');
    m_k(2) := to_number('b5c0fbcf', 'xxxxxxxx');
    m_k(3) := to_number('e9b5dba5', 'xxxxxxxx');
    m_k(4) := to_number('3956c25b', 'xxxxxxxx');
    m_k(5) := to_number('59f111f1', 'xxxxxxxx');
    m_k(6) := to_number('923f82a4', 'xxxxxxxx');
    m_k(7) := to_number('ab1c5ed5', 'xxxxxxxx');
    m_k(8) := to_number('d807aa98', 'xxxxxxxx');
    m_k(9) := to_number('12835b01', 'xxxxxxxx');
    m_k(10) := to_number('243185be', 'xxxxxxxx');
    m_k(11) := to_number('550c7dc3', 'xxxxxxxx');
    m_k(12) := to_number('72be5d74', 'xxxxxxxx');
    m_k(13) := to_number('80deb1fe', 'xxxxxxxx');
    m_k(14) := to_number('9bdc06a7', 'xxxxxxxx');
    m_k(15) := to_number('c19bf174', 'xxxxxxxx');
    m_k(16) := to_number('e49b69c1', 'xxxxxxxx');
    m_k(17) := to_number('efbe4786', 'xxxxxxxx');
    m_k(18) := to_number('0fc19dc6', 'xxxxxxxx');
    m_k(19) := to_number('240ca1cc', 'xxxxxxxx');
    m_k(20) := to_number('2de92c6f', 'xxxxxxxx');
    m_k(21) := to_number('4a7484aa', 'xxxxxxxx');
    m_k(22) := to_number('5cb0a9dc', 'xxxxxxxx');
    m_k(23) := to_number('76f988da', 'xxxxxxxx');
    m_k(24) := to_number('983e5152', 'xxxxxxxx');
    m_k(25) := to_number('a831c66d', 'xxxxxxxx');
    m_k(26) := to_number('b00327c8', 'xxxxxxxx');
    m_k(27) := to_number('bf597fc7', 'xxxxxxxx');
    m_k(28) := to_number('c6e00bf3', 'xxxxxxxx');
    m_k(29) := to_number('d5a79147', 'xxxxxxxx');
    m_k(30) := to_number('06ca6351', 'xxxxxxxx');
    m_k(31) := to_number('14292967', 'xxxxxxxx');
    m_k(32) := to_number('27b70a85', 'xxxxxxxx');
    m_k(33) := to_number('2e1b2138', 'xxxxxxxx');
    m_k(34) := to_number('4d2c6dfc', 'xxxxxxxx');
    m_k(35) := to_number('53380d13', 'xxxxxxxx');
    m_k(36) := to_number('650a7354', 'xxxxxxxx');
    m_k(37) := to_number('766a0abb', 'xxxxxxxx');
    m_k(38) := to_number('81c2c92e', 'xxxxxxxx');
    m_k(39) := to_number('92722c85', 'xxxxxxxx');
    m_k(40) := to_number('a2bfe8a1', 'xxxxxxxx');
    m_k(41) := to_number('a81a664b', 'xxxxxxxx');
    m_k(42) := to_number('c24b8b70', 'xxxxxxxx');
    m_k(43) := to_number('c76c51a3', 'xxxxxxxx');
    m_k(44) := to_number('d192e819', 'xxxxxxxx');
    m_k(45) := to_number('d6990624', 'xxxxxxxx');
    m_k(46) := to_number('f40e3585', 'xxxxxxxx');
    m_k(47) := to_number('106aa070', 'xxxxxxxx');
    m_k(48) := to_number('19a4c116', 'xxxxxxxx');
    m_k(49) := to_number('1e376c08', 'xxxxxxxx');
    m_k(50) := to_number('2748774c', 'xxxxxxxx');
    m_k(51) := to_number('34b0bcb5', 'xxxxxxxx');
    m_k(52) := to_number('391c0cb3', 'xxxxxxxx');
    m_k(53) := to_number('4ed8aa4a', 'xxxxxxxx');
    m_k(54) := to_number('5b9cca4f', 'xxxxxxxx');
    m_k(55) := to_number('682e6ff3', 'xxxxxxxx');
    m_k(56) := to_number('748f82ee', 'xxxxxxxx');
    m_k(57) := to_number('78a5636f', 'xxxxxxxx');
    m_k(58) := to_number('84c87814', 'xxxxxxxx');
    m_k(59) := to_number('8cc70208', 'xxxxxxxx');
    m_k(60) := to_number('90befffa', 'xxxxxxxx');
    m_k(61) := to_number('a4506ceb', 'xxxxxxxx');
    m_k(62) := to_number('bef9a3f7', 'xxxxxxxx');
    m_k(63) := to_number('c67178f2', 'xxxxxxxx');
  end sha256_init_k;

  procedure sha256_init_ctx
  as
  begin
    m_ctx.h(0) := to_number('6a09e667', 'xxxxxxxx');
    m_ctx.h(1) := to_number('bb67ae85', 'xxxxxxxx');
    m_ctx.h(2) := to_number('3c6ef372', 'xxxxxxxx');
    m_ctx.h(3) := to_number('a54ff53a', 'xxxxxxxx');
    m_ctx.h(4) := to_number('510e527f', 'xxxxxxxx');
    m_ctx.h(5) := to_number('9b05688c', 'xxxxxxxx');
    m_ctx.h(6) := to_number('1f83d9ab', 'xxxxxxxx');
    m_ctx.h(7) := to_number('5be0cd19', 'xxxxxxxx');
    m_ctx.total_length := 0;
    m_ctx.leftover_buffer := null;
    m_ctx.leftover_buffer_length := 0;
    for idx in 0..15 loop
      m_ctx.words_array(idx) := 0;
    end loop;
  end sha256_init_ctx;

  procedure sha256_process_block(p_words_array in ta_number,
                                 p_words_count in number)
  as
    l_words_array ta_number := p_words_array;
    l_words_count number := p_words_count;
    l_words_idx number;
    t number;
    a number := m_ctx.h(0);
    b number := m_ctx.h(1);
    c number := m_ctx.h(2);
    d number := m_ctx.h(3);
    e number := m_ctx.h(4);
    f number := m_ctx.h(5);
    g number := m_ctx.h(6);
    h number := m_ctx.h(7);
    w ta_number;
    a_save number;
    b_save number;
    c_save number;
    d_save number;
    e_save number;
    f_save number;
    g_save number;
    h_save number;
    t1 number;
    t2 number;
  begin
    -- Process all bytes in the buffer with 64 bytes in each round of the loop.
    l_words_idx := 0;
    while (l_words_count > 0) loop
      a_save := a;
      b_save := b;
      c_save := c;
      d_save := d;
      e_save := e;
      f_save := f;
      g_save := g;
      h_save := h;
      -- Compute the message schedule according to FIPS 180-2:6.2.2 step 2.
      for t in 0..15 loop
        w(t) := l_words_array(l_words_idx);
        l_words_idx := l_words_idx + 1;
      end loop;
      for t in 16..63 loop
        w(t) := bitand(op_r1_32(w(t - 2)) + w(t - 7) + op_r0_32(w(t - 15)) + w(t - 16), c_bits_ffffffff);
      end loop;
      -- The actual computation according to FIPS 180-2:6.2.2 step 3.
      for t in 0..63 loop
        t1 := bitand(h + op_s1_32(e) + op_ch_32(e, f, g) + m_k(t) + w(t), c_bits_ffffffff);
        t2 := bitand(op_s0_32(a) + op_maj(a, b, c), c_bits_ffffffff);
        h := g;
        g := f;
        f := e;
        e := bitand(d + t1, c_bits_ffffffff);
        d := c;
        c := b;
        b := a;
        a := bitand(t1 + t2, c_bits_ffffffff);
      end loop;
      -- Add the starting values of the context according to FIPS 180-2:6.2.2 step 4.
      a := bitand(a + a_save, c_bits_ffffffff);
      b := bitand(b + b_save, c_bits_ffffffff);
      c := bitand(c + c_save, c_bits_ffffffff);
      d := bitand(d + d_save, c_bits_ffffffff);
      e := bitand(e + e_save, c_bits_ffffffff);
      f := bitand(f + f_save, c_bits_ffffffff);
      g := bitand(g + g_save, c_bits_ffffffff);
      h := bitand(h + h_save, c_bits_ffffffff);
      -- Prepare for the next round.
      l_words_count := l_words_count - 16;
    end loop;
    -- Put checksum in context given as argument.
    m_ctx.h(0) := a;
    m_ctx.h(1) := b;
    m_ctx.h(2) := c;
    m_ctx.h(3) := d;
    m_ctx.h(4) := e;
    m_ctx.h(5) := f;
    m_ctx.h(6) := g;
    m_ctx.h(7) := h;
  end sha256_process_block;

  procedure sha256_process_bytes(p_buffer in raw,
                                 p_buffer_length in number)
  as
    l_buffer raw(16640);
    l_buffer_length number;
    l_words_array ta_number;
  begin
    -- First increment the byte count.  FIPS 180-2 specifies the possible
    -- length of the file up to 2^64 bits. Here we only compute the number of
    -- bytes. 
    m_ctx.total_length := m_ctx.total_length + nvl(p_buffer_length, 0);
    -- When we already have some bits in our internal buffer concatenate both inputs first.
    if (m_ctx.leftover_buffer_length = 0) then
      l_buffer := p_buffer;
      l_buffer_length := nvl(p_buffer_length, 0);
    else
      l_buffer := m_ctx.leftover_buffer || p_buffer;
      l_buffer_length := m_ctx.leftover_buffer_length + nvl(p_buffer_length, 0);
    end if;
    -- Process available complete blocks.
    if (l_buffer_length >= 64) then
      declare
        l_words_count number := bitand(l_buffer_length, c_bits_ffffffc0) / 4;
        l_max_idx number := l_words_count - 1;
        l_numberraw raw(4);
        l_numberhex varchar2(8);
        l_number number;
      begin
        for idx in 0..l_max_idx loop
          l_numberraw := sys.utl_raw.substr(l_buffer, idx * 4 + 1, 4);
          l_numberhex := rawtohex(l_numberraw);
          l_number := to_number(l_numberhex,'xxxxxxxx');
          l_words_array(idx) := l_number;
        end loop;
        sha256_process_block(l_words_array, l_words_count);
        l_buffer_length := bitand(l_buffer_length, 63);
        if (l_buffer_length > 0) then
          l_buffer := sys.utl_raw.substr(l_buffer, l_words_count * 4 + 1, l_buffer_length);
        end if;
      end;
    end if;
    -- Move remaining bytes into internal buffer. 
    if (l_buffer_length > 0) then
      m_ctx.leftover_buffer := l_buffer;
      m_ctx.leftover_buffer_length := l_buffer_length;
    end if;
  end sha256_process_bytes;
  
  procedure sha256_finish_ctx(p_resultbuf out nocopy ta_number)
  as
    l_filesizeraw raw(8);
  begin
    m_ctx.leftover_buffer := m_ctx.leftover_buffer || c_bits_80;
    m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 1;
    while ((m_ctx.leftover_buffer_length mod 64) <> 56) loop
      m_ctx.leftover_buffer := m_ctx.leftover_buffer || c_bits_00;
      m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 1;
    end loop;
    l_filesizeraw := hextoraw(to_char(m_ctx.total_length * 8, 'FM0xxxxxxxxxxxxxxx'));
    m_ctx.leftover_buffer := m_ctx.leftover_buffer || l_filesizeraw;
    m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 8;
    sha256_process_bytes(null, 0);
    for idx in 0..7 loop
      p_resultbuf(idx) := m_ctx.h(idx);
    end loop;
  end sha256_finish_ctx;

  function sha256(p_buffer in raw) return sha256_checksum_raw
  as
    l_result sha256_checksum_raw;
  begin
    sha256_init_k;
    sha256_init_ctx;
    sha256_process_bytes(p_buffer, sys.utl_raw.length(p_buffer));
    sha256_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxx') || 
      to_char(m_result(4),'FM0xxxxxxx') || 
      to_char(m_result(5),'FM0xxxxxxx') || 
      to_char(m_result(6),'FM0xxxxxxx') || 
      to_char(m_result(7),'FM0xxxxxxx')
    );
    return l_result;
  end sha256;
  
  function sha256(p_buffer in blob) return sha256_checksum_raw
  as
    l_result sha256_checksum_raw;
    l_buffer raw(16384);
    l_amount number := 16384;
    l_offset number := 1;
  begin
    sha256_init_k;
    sha256_init_ctx;
    begin
      loop
        sys.dbms_lob.read(p_buffer, l_amount, l_offset, l_buffer);
        sha256_process_bytes(l_buffer, l_amount);
        l_offset := l_offset + l_amount;
        l_amount := 16384;
      end loop;
    exception
      when no_data_found then
        null;
    end;
    sha256_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxx') || 
      to_char(m_result(4),'FM0xxxxxxx') || 
      to_char(m_result(5),'FM0xxxxxxx') || 
      to_char(m_result(6),'FM0xxxxxxx') || 
      to_char(m_result(7),'FM0xxxxxxx')
    );
    return l_result;
  end sha256;
  
  --
  -- SHA-224
  --

  procedure sha224_init_ctx
  as
  begin
    m_ctx.h(0) := to_number('c1059ed8', 'xxxxxxxx');
    m_ctx.h(1) := to_number('367cd507', 'xxxxxxxx');
    m_ctx.h(2) := to_number('3070dd17', 'xxxxxxxx');
    m_ctx.h(3) := to_number('f70e5939', 'xxxxxxxx');
    m_ctx.h(4) := to_number('ffc00b31', 'xxxxxxxx');
    m_ctx.h(5) := to_number('68581511', 'xxxxxxxx');
    m_ctx.h(6) := to_number('64f98fa7', 'xxxxxxxx');
    m_ctx.h(7) := to_number('befa4fa4', 'xxxxxxxx');
    m_ctx.total_length := 0;
    m_ctx.leftover_buffer := null;
    m_ctx.leftover_buffer_length := 0;
    for idx in 0..15 loop
      m_ctx.words_array(idx) := 0;
    end loop;
  end sha224_init_ctx;

  function sha224(p_buffer in raw) return sha224_checksum_raw
  as
    l_result sha224_checksum_raw;
  begin
    sha256_init_k;
    sha224_init_ctx;
    sha256_process_bytes(p_buffer, sys.utl_raw.length(p_buffer));
    sha256_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxx') || 
      to_char(m_result(4),'FM0xxxxxxx') || 
      to_char(m_result(5),'FM0xxxxxxx') || 
      to_char(m_result(6),'FM0xxxxxxx')
    );
    return l_result;
  end sha224;
  
  function sha224(p_buffer in blob) return sha224_checksum_raw
  as
    l_result sha224_checksum_raw;
    l_buffer raw(16384);
    l_amount number := 16384;
    l_offset number := 1;
  begin
    sha256_init_k;
    sha224_init_ctx;
    begin
      loop
        sys.dbms_lob.read(p_buffer, l_amount, l_offset, l_buffer);
        sha256_process_bytes(l_buffer, l_amount);
        l_offset := l_offset + l_amount;
        l_amount := 16384;
      end loop;
    exception
      when no_data_found then
        null;
    end;
    sha256_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxx') || 
      to_char(m_result(4),'FM0xxxxxxx') || 
      to_char(m_result(5),'FM0xxxxxxx') || 
      to_char(m_result(6),'FM0xxxxxxx')
    );
    return l_result;
  end sha224;
  
  --
  -- SHA-512
  --

  procedure sha512_init_k
  as
  begin
    m_k(0) := to_number('428a2f98d728ae22', 'xxxxxxxxxxxxxxxx');
    m_k(1) := to_number('7137449123ef65cd', 'xxxxxxxxxxxxxxxx');
    m_k(2) := to_number('b5c0fbcfec4d3b2f', 'xxxxxxxxxxxxxxxx');
    m_k(3) := to_number('e9b5dba58189dbbc', 'xxxxxxxxxxxxxxxx');
    m_k(4) := to_number('3956c25bf348b538', 'xxxxxxxxxxxxxxxx');
    m_k(5) := to_number('59f111f1b605d019', 'xxxxxxxxxxxxxxxx');
    m_k(6) := to_number('923f82a4af194f9b', 'xxxxxxxxxxxxxxxx');
    m_k(7) := to_number('ab1c5ed5da6d8118', 'xxxxxxxxxxxxxxxx');
    m_k(8) := to_number('d807aa98a3030242', 'xxxxxxxxxxxxxxxx');
    m_k(9) := to_number('12835b0145706fbe', 'xxxxxxxxxxxxxxxx');
    m_k(10) := to_number('243185be4ee4b28c', 'xxxxxxxxxxxxxxxx');
    m_k(11) := to_number('550c7dc3d5ffb4e2', 'xxxxxxxxxxxxxxxx');
    m_k(12) := to_number('72be5d74f27b896f', 'xxxxxxxxxxxxxxxx');
    m_k(13) := to_number('80deb1fe3b1696b1', 'xxxxxxxxxxxxxxxx');
    m_k(14) := to_number('9bdc06a725c71235', 'xxxxxxxxxxxxxxxx');
    m_k(15) := to_number('c19bf174cf692694', 'xxxxxxxxxxxxxxxx');
    m_k(16) := to_number('e49b69c19ef14ad2', 'xxxxxxxxxxxxxxxx');
    m_k(17) := to_number('efbe4786384f25e3', 'xxxxxxxxxxxxxxxx');
    m_k(18) := to_number('0fc19dc68b8cd5b5', 'xxxxxxxxxxxxxxxx');
    m_k(19) := to_number('240ca1cc77ac9c65', 'xxxxxxxxxxxxxxxx');
    m_k(20) := to_number('2de92c6f592b0275', 'xxxxxxxxxxxxxxxx');
    m_k(21) := to_number('4a7484aa6ea6e483', 'xxxxxxxxxxxxxxxx');
    m_k(22) := to_number('5cb0a9dcbd41fbd4', 'xxxxxxxxxxxxxxxx');
    m_k(23) := to_number('76f988da831153b5', 'xxxxxxxxxxxxxxxx');
    m_k(24) := to_number('983e5152ee66dfab', 'xxxxxxxxxxxxxxxx');
    m_k(25) := to_number('a831c66d2db43210', 'xxxxxxxxxxxxxxxx');
    m_k(26) := to_number('b00327c898fb213f', 'xxxxxxxxxxxxxxxx');
    m_k(27) := to_number('bf597fc7beef0ee4', 'xxxxxxxxxxxxxxxx');
    m_k(28) := to_number('c6e00bf33da88fc2', 'xxxxxxxxxxxxxxxx');
    m_k(29) := to_number('d5a79147930aa725', 'xxxxxxxxxxxxxxxx');
    m_k(30) := to_number('06ca6351e003826f', 'xxxxxxxxxxxxxxxx');
    m_k(31) := to_number('142929670a0e6e70', 'xxxxxxxxxxxxxxxx');
    m_k(32) := to_number('27b70a8546d22ffc', 'xxxxxxxxxxxxxxxx');
    m_k(33) := to_number('2e1b21385c26c926', 'xxxxxxxxxxxxxxxx');
    m_k(34) := to_number('4d2c6dfc5ac42aed', 'xxxxxxxxxxxxxxxx');
    m_k(35) := to_number('53380d139d95b3df', 'xxxxxxxxxxxxxxxx');
    m_k(36) := to_number('650a73548baf63de', 'xxxxxxxxxxxxxxxx');
    m_k(37) := to_number('766a0abb3c77b2a8', 'xxxxxxxxxxxxxxxx');
    m_k(38) := to_number('81c2c92e47edaee6', 'xxxxxxxxxxxxxxxx');
    m_k(39) := to_number('92722c851482353b', 'xxxxxxxxxxxxxxxx');
    m_k(40) := to_number('a2bfe8a14cf10364', 'xxxxxxxxxxxxxxxx');
    m_k(41) := to_number('a81a664bbc423001', 'xxxxxxxxxxxxxxxx');
    m_k(42) := to_number('c24b8b70d0f89791', 'xxxxxxxxxxxxxxxx');
    m_k(43) := to_number('c76c51a30654be30', 'xxxxxxxxxxxxxxxx');
    m_k(44) := to_number('d192e819d6ef5218', 'xxxxxxxxxxxxxxxx');
    m_k(45) := to_number('d69906245565a910', 'xxxxxxxxxxxxxxxx');
    m_k(46) := to_number('f40e35855771202a', 'xxxxxxxxxxxxxxxx');
    m_k(47) := to_number('106aa07032bbd1b8', 'xxxxxxxxxxxxxxxx');
    m_k(48) := to_number('19a4c116b8d2d0c8', 'xxxxxxxxxxxxxxxx');
    m_k(49) := to_number('1e376c085141ab53', 'xxxxxxxxxxxxxxxx');
    m_k(50) := to_number('2748774cdf8eeb99', 'xxxxxxxxxxxxxxxx');
    m_k(51) := to_number('34b0bcb5e19b48a8', 'xxxxxxxxxxxxxxxx');
    m_k(52) := to_number('391c0cb3c5c95a63', 'xxxxxxxxxxxxxxxx');
    m_k(53) := to_number('4ed8aa4ae3418acb', 'xxxxxxxxxxxxxxxx');
    m_k(54) := to_number('5b9cca4f7763e373', 'xxxxxxxxxxxxxxxx');
    m_k(55) := to_number('682e6ff3d6b2b8a3', 'xxxxxxxxxxxxxxxx');
    m_k(56) := to_number('748f82ee5defb2fc', 'xxxxxxxxxxxxxxxx');
    m_k(57) := to_number('78a5636f43172f60', 'xxxxxxxxxxxxxxxx');
    m_k(58) := to_number('84c87814a1f0ab72', 'xxxxxxxxxxxxxxxx');
    m_k(59) := to_number('8cc702081a6439ec', 'xxxxxxxxxxxxxxxx');
    m_k(60) := to_number('90befffa23631e28', 'xxxxxxxxxxxxxxxx');
    m_k(61) := to_number('a4506cebde82bde9', 'xxxxxxxxxxxxxxxx');
    m_k(62) := to_number('bef9a3f7b2c67915', 'xxxxxxxxxxxxxxxx');
    m_k(63) := to_number('c67178f2e372532b', 'xxxxxxxxxxxxxxxx');
    m_k(64) := to_number('ca273eceea26619c', 'xxxxxxxxxxxxxxxx');
    m_k(65) := to_number('d186b8c721c0c207', 'xxxxxxxxxxxxxxxx');
    m_k(66) := to_number('eada7dd6cde0eb1e', 'xxxxxxxxxxxxxxxx');
    m_k(67) := to_number('f57d4f7fee6ed178', 'xxxxxxxxxxxxxxxx');
    m_k(68) := to_number('06f067aa72176fba', 'xxxxxxxxxxxxxxxx');
    m_k(69) := to_number('0a637dc5a2c898a6', 'xxxxxxxxxxxxxxxx');
    m_k(70) := to_number('113f9804bef90dae', 'xxxxxxxxxxxxxxxx');
    m_k(71) := to_number('1b710b35131c471b', 'xxxxxxxxxxxxxxxx');
    m_k(72) := to_number('28db77f523047d84', 'xxxxxxxxxxxxxxxx');
    m_k(73) := to_number('32caab7b40c72493', 'xxxxxxxxxxxxxxxx');
    m_k(74) := to_number('3c9ebe0a15c9bebc', 'xxxxxxxxxxxxxxxx');
    m_k(75) := to_number('431d67c49c100d4c', 'xxxxxxxxxxxxxxxx');
    m_k(76) := to_number('4cc5d4becb3e42b6', 'xxxxxxxxxxxxxxxx');
    m_k(77) := to_number('597f299cfc657e2a', 'xxxxxxxxxxxxxxxx');
    m_k(78) := to_number('5fcb6fab3ad6faec', 'xxxxxxxxxxxxxxxx');
    m_k(79) := to_number('6c44198c4a475817', 'xxxxxxxxxxxxxxxx');
  end sha512_init_k;

  procedure sha512_init_ctx
  as
  begin
    m_ctx.h(0) := to_number('6a09e667f3bcc908', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(1) := to_number('bb67ae8584caa73b', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(2) := to_number('3c6ef372fe94f82b', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(3) := to_number('a54ff53a5f1d36f1', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(4) := to_number('510e527fade682d1', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(5) := to_number('9b05688c2b3e6c1f', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(6) := to_number('1f83d9abfb41bd6b', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(7) := to_number('5be0cd19137e2179', 'xxxxxxxxxxxxxxxx');
    m_ctx.total_length := 0;
    m_ctx.leftover_buffer := null;
    m_ctx.leftover_buffer_length := 0;
    for idx in 0..15 loop
      m_ctx.words_array(idx) := 0;
    end loop;
  end sha512_init_ctx;

  procedure sha512_process_block(p_words_array in ta_number,
                                 p_words_count in number)
  as
    l_words_array ta_number := p_words_array;
    l_words_count number := p_words_count;
    l_words_idx number;
    t number;
    a number := m_ctx.h(0);
    b number := m_ctx.h(1);
    c number := m_ctx.h(2);
    d number := m_ctx.h(3);
    e number := m_ctx.h(4);
    f number := m_ctx.h(5);
    g number := m_ctx.h(6);
    h number := m_ctx.h(7);
    w ta_number;
    a_save number;
    b_save number;
    c_save number;
    d_save number;
    e_save number;
    f_save number;
    g_save number;
    h_save number;
    t1 number;
    t2 number;
  begin
    -- Process all bytes in the buffer with 64 bytes in each round of the loop.
    l_words_idx := 0;
    while (l_words_count > 0) loop
      a_save := a;
      b_save := b;
      c_save := c;
      d_save := d;
      e_save := e;
      f_save := f;
      g_save := g;
      h_save := h;
      -- Compute the message schedule according to FIPS 180-2:6.2.2 step 2.
      for t in 0..15 loop
        w(t) := l_words_array(l_words_idx);
        l_words_idx := l_words_idx + 1;
      end loop;
      for t in 16..79 loop
        w(t) := bitand(op_r1_64(w(t - 2)) + w(t - 7) + op_r0_64(w(t - 15)) + w(t - 16), c_bits_ffffffffffffffff);
      end loop;
      -- The actual computation according to FIPS 180-2:6.2.2 step 3.
      for t in 0..79 loop
        t1 := bitand(h + op_s1_64(e) + op_ch_64(e, f, g) + m_k(t) + w(t), c_bits_ffffffffffffffff);
        t2 := bitand(op_s0_64(a) + op_maj(a, b, c), c_bits_ffffffffffffffff);
        h := g;
        g := f;
        f := e;
        e := bitand(d + t1, c_bits_ffffffffffffffff);
        d := c;
        c := b;
        b := a;
        a := bitand(t1 + t2, c_bits_ffffffffffffffff);
      end loop;
      -- Add the starting values of the context according to FIPS 180-2:6.2.2 step 4.
      a := bitand(a + a_save, c_bits_ffffffffffffffff);
      b := bitand(b + b_save, c_bits_ffffffffffffffff);
      c := bitand(c + c_save, c_bits_ffffffffffffffff);
      d := bitand(d + d_save, c_bits_ffffffffffffffff);
      e := bitand(e + e_save, c_bits_ffffffffffffffff);
      f := bitand(f + f_save, c_bits_ffffffffffffffff);
      g := bitand(g + g_save, c_bits_ffffffffffffffff);
      h := bitand(h + h_save, c_bits_ffffffffffffffff);
      -- Prepare for the next round.
      l_words_count := l_words_count - 16;
    end loop;
    -- Put checksum in context given as argument.
    m_ctx.h(0) := a;
    m_ctx.h(1) := b;
    m_ctx.h(2) := c;
    m_ctx.h(3) := d;
    m_ctx.h(4) := e;
    m_ctx.h(5) := f;
    m_ctx.h(6) := g;
    m_ctx.h(7) := h;
  end sha512_process_block;

  procedure sha512_process_bytes(p_buffer in raw,
                                 p_buffer_length in number)
  as
    l_buffer raw(16640);
    l_buffer_length number;
    l_words_array ta_number;
  begin
    m_ctx.total_length := m_ctx.total_length + nvl(p_buffer_length, 0);
    -- When we already have some bits in our internal buffer concatenate both inputs first.
    if (m_ctx.leftover_buffer_length = 0) then
      l_buffer := p_buffer;
      l_buffer_length := nvl(p_buffer_length, 0);
    else
      l_buffer := m_ctx.leftover_buffer || p_buffer;
      l_buffer_length := m_ctx.leftover_buffer_length + nvl(p_buffer_length, 0);
    end if;
    -- Process available complete blocks.
    if (l_buffer_length >= 128) then
      declare
        l_words_count number := bitand(l_buffer_length, c_bits_ffffffffffffff80) / 8;
        l_max_idx number := l_words_count - 1;
        l_numberraw raw(8);
        l_numberhex varchar2(16);
        l_number number;
      begin
        for idx in 0..l_max_idx loop
          l_numberraw := sys.utl_raw.substr(l_buffer, idx * 8 + 1, 8);
          l_numberhex := rawtohex(l_numberraw);
          l_number := to_number(l_numberhex,'xxxxxxxxxxxxxxxx');
          l_words_array(idx) := l_number;
        end loop;
        sha512_process_block(l_words_array, l_words_count);
        l_buffer_length := bitand(l_buffer_length, 127);
        if (l_buffer_length > 0) then
          l_buffer := sys.utl_raw.substr(l_buffer, l_words_count * 8 + 1, l_buffer_length);
        end if;
      end;
    end if;
    -- Move remaining bytes into internal buffer. 
    if (l_buffer_length > 0) then
      m_ctx.leftover_buffer := l_buffer;
      m_ctx.leftover_buffer_length := l_buffer_length;
    end if;
  end sha512_process_bytes;
  
  procedure sha512_finish_ctx(p_resultbuf out nocopy ta_number)
  as
    l_filesizeraw raw(16);
  begin
    m_ctx.leftover_buffer := m_ctx.leftover_buffer || c_bits_80;
    m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 1;
    while ((m_ctx.leftover_buffer_length mod 128) <> 112) loop
      m_ctx.leftover_buffer := m_ctx.leftover_buffer || c_bits_00;
      m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 1;
    end loop;
    l_filesizeraw := hextoraw(to_char(m_ctx.total_length * 8, 'FM0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'));
    m_ctx.leftover_buffer := m_ctx.leftover_buffer || l_filesizeraw;
    m_ctx.leftover_buffer_length := m_ctx.leftover_buffer_length + 16;
    sha512_process_bytes(null, 0);
    for idx in 0..7 loop
      p_resultbuf(idx) := m_ctx.h(idx);
    end loop;
  end sha512_finish_ctx;

  function sha512(p_buffer in raw) return sha512_checksum_raw
  as
    l_result sha512_checksum_raw;
  begin
    sha512_init_k;
    sha512_init_ctx;
    sha512_process_bytes(p_buffer, sys.utl_raw.length(p_buffer));
    sha512_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(4),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(5),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(6),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(7),'FM0xxxxxxxxxxxxxxx')
    );
    return l_result;
  end sha512;
  
  function sha512(p_buffer in blob) return sha512_checksum_raw
  as
    l_result sha512_checksum_raw;
    l_buffer raw(16384);
    l_amount number := 16384;
    l_offset number := 1;
  begin
    sha512_init_k;
    sha512_init_ctx;
    begin
      loop
        sys.dbms_lob.read(p_buffer, l_amount, l_offset, l_buffer);
        sha512_process_bytes(l_buffer, l_amount);
        l_offset := l_offset + l_amount;
        l_amount := 16384;
      end loop;
    exception
      when no_data_found then
        null;
    end;
    sha512_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(4),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(5),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(6),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(7),'FM0xxxxxxxxxxxxxxx')
    );
    return l_result;
  end sha512;
  
  --
  -- SHA-384
  --

  procedure sha384_init_ctx
  as
  begin
    m_ctx.h(0) := to_number('CBBB9D5DC1059ED8', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(1) := to_number('629A292A367CD507', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(2) := to_number('9159015A3070DD17', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(3) := to_number('152FECD8F70E5939', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(4) := to_number('67332667FFC00B31', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(5) := to_number('8EB44A8768581511', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(6) := to_number('DB0C2E0D64F98FA7', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(7) := to_number('47B5481DBEFA4FA4', 'xxxxxxxxxxxxxxxx');
    m_ctx.total_length := 0;
    m_ctx.leftover_buffer := null;
    m_ctx.leftover_buffer_length := 0;
    for idx in 0..15 loop
      m_ctx.words_array(idx) := 0;
    end loop;
  end sha384_init_ctx;

  function sha384(p_buffer in raw) return sha384_checksum_raw
  as
    l_result sha384_checksum_raw;
  begin
    sha512_init_k;
    sha384_init_ctx;
    sha512_process_bytes(p_buffer, sys.utl_raw.length(p_buffer));
    sha512_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(4),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(5),'FM0xxxxxxxxxxxxxxx') 
    );
    return l_result;
  end sha384;
  
  function sha384(p_buffer in blob) return sha384_checksum_raw
  as
    l_result sha384_checksum_raw;
    l_buffer raw(16384);
    l_amount number := 16384;
    l_offset number := 1;
  begin
    sha512_init_k;
    sha384_init_ctx;
    begin
      loop
        sys.dbms_lob.read(p_buffer, l_amount, l_offset, l_buffer);
        sha512_process_bytes(l_buffer, l_amount);
        l_offset := l_offset + l_amount;
        l_amount := 16384;
      end loop;
    exception
      when no_data_found then
        null;
    end;
    sha512_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(4),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(5),'FM0xxxxxxxxxxxxxxx') 
    );
    return l_result;
  end sha384;
  
  --
  -- SHA-512/224
  --

  procedure sha512_224_init_ctx
  as
  begin
    m_ctx.h(0) := to_number('8C3D37C819544DA2', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(1) := to_number('73E1996689DCD4D6', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(2) := to_number('1DFAB7AE32FF9C82', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(3) := to_number('679DD514582F9FCF', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(4) := to_number('0F6D2B697BD44DA8', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(5) := to_number('77E36F7304C48942', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(6) := to_number('3F9D85A86A1D36C8', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(7) := to_number('1112E6AD91D692A1', 'xxxxxxxxxxxxxxxx');
    m_ctx.total_length := 0;
    m_ctx.leftover_buffer := null;
    m_ctx.leftover_buffer_length := 0;
    for idx in 0..15 loop
      m_ctx.words_array(idx) := 0;
    end loop;
  end sha512_224_init_ctx;

  function sha512_224(p_buffer in raw) return sha224_checksum_raw
  as
    l_result sha224_checksum_raw;
  begin
    sha512_init_k;
    sha512_224_init_ctx;
    sha512_process_bytes(p_buffer, sys.utl_raw.length(p_buffer));
    sha512_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxxxxxxxxxx') || 
      substr(to_char(m_result(3),'FM0xxxxxxxxxxxxxxx'), 1, 8)
    );
    return l_result;
  end sha512_224;
  
  function sha512_224(p_buffer in blob) return sha224_checksum_raw
  as
    l_result sha224_checksum_raw;
    l_buffer raw(16384);
    l_amount number := 16384;
    l_offset number := 1;
  begin
    sha512_init_k;
    sha512_224_init_ctx;
    begin
      loop
        sys.dbms_lob.read(p_buffer, l_amount, l_offset, l_buffer);
        sha512_process_bytes(l_buffer, l_amount);
        l_offset := l_offset + l_amount;
        l_amount := 16384;
      end loop;
    exception
      when no_data_found then
        null;
    end;
    sha512_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxxxxxxxxxx') || 
      substr(to_char(m_result(3),'FM0xxxxxxxxxxxxxxx'), 1, 8)
    );
    return l_result;
  end sha512_224;
  
  --
  -- SHA-512/256
  --

  procedure sha512_256_init_ctx
  as
  begin
    m_ctx.h(0) := to_number('22312194FC2BF72C', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(1) := to_number('9F555FA3C84C64C2', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(2) := to_number('2393B86B6F53B151', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(3) := to_number('963877195940EABD', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(4) := to_number('96283EE2A88EFFE3', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(5) := to_number('BE5E1E2553863992', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(6) := to_number('2B0199FC2C85B8AA', 'xxxxxxxxxxxxxxxx');
    m_ctx.h(7) := to_number('0EB72DDC81C52CA2', 'xxxxxxxxxxxxxxxx');
    m_ctx.total_length := 0;
    m_ctx.leftover_buffer := null;
    m_ctx.leftover_buffer_length := 0;
    for idx in 0..15 loop
      m_ctx.words_array(idx) := 0;
    end loop;
  end sha512_256_init_ctx;

  function sha512_256(p_buffer in raw) return sha256_checksum_raw
  as
    l_result sha256_checksum_raw;
  begin
    sha512_init_k;
    sha512_256_init_ctx;
    sha512_process_bytes(p_buffer, sys.utl_raw.length(p_buffer));
    sha512_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxxxxxxxxxx') 
    );
    return l_result;
  end sha512_256;
  
  function sha512_256(p_buffer in blob) return sha256_checksum_raw
  as
    l_result sha256_checksum_raw;
    l_buffer raw(16384);
    l_amount number := 16384;
    l_offset number := 1;
  begin
    sha512_init_k;
    sha512_256_init_ctx;
    begin
      loop
        sys.dbms_lob.read(p_buffer, l_amount, l_offset, l_buffer);
        sha512_process_bytes(l_buffer, l_amount);
        l_offset := l_offset + l_amount;
        l_amount := 16384;
      end loop;
    exception
      when no_data_found then
        null;
    end;
    sha512_finish_ctx(m_result);
    l_result := hextoraw(
      to_char(m_result(0),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(1),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(2),'FM0xxxxxxxxxxxxxxx') || 
      to_char(m_result(3),'FM0xxxxxxxxxxxxxxx') 
    );
    return l_result;
  end sha512_256;
  
  ---
  --- Unittest
  ---
  
  procedure unittest 
  as
    l_blob blob;
    l_raw raw(100);
  begin

    dbms_lob.createtemporary(l_blob, true);
    l_raw := sys.utl_raw.cast_to_raw('The quick brown fox jumps over the lazy dog' || chr(13) || chr(10));
    for i in 1..1000 loop
      dbms_lob.writeappend(l_blob, sys.utl_raw.length(l_raw), l_raw);
    end loop;
    
    if lower(rawtohex(sha1(sys.utl_raw.cast_to_raw('')))) = 'da39a3ee5e6b4b0d3255bfef95601890afd80709' then
      dbms_output.put_line('SHA-1. Test 1 passed');
    else
      dbms_output.put_line('SHA-1. Test 1 failed');
    end if;
    if lower(rawtohex(sha1(sys.utl_raw.cast_to_raw('The quick brown fox jumps over the lazy dog')))) = '2fd4e1c67a2d28fced849ee1bb76e7391b93eb12' then
      dbms_output.put_line('SHA-1. Test 2 passed');
    else
      dbms_output.put_line('SHA-1. Test 2 failed');
    end if;
    if lower(rawtohex(sha1(l_blob))) = '65d489cb70cae1cd7661a3043dc6ee51e41efb01' then
      dbms_output.put_line('SHA-1. Test 3 passed');
    else
      dbms_output.put_line('SHA-1. Test 3 failed');
    end if;
    
    if lower(rawtohex(sha224(sys.utl_raw.cast_to_raw('')))) = 'd14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f' then
      dbms_output.put_line('SHA-224. Test 1 passed');
    else
      dbms_output.put_line('SHA-224. Test 1 failed');
    end if;
    if lower(rawtohex(sha224(sys.utl_raw.cast_to_raw('The quick brown fox jumps over the lazy dog')))) = '730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525' then
      dbms_output.put_line('SHA-224. Test 2 passed');
    else
      dbms_output.put_line('SHA-224. Test 2 failed');
    end if;
    if lower(rawtohex(sha224(l_blob))) = 'daa4ac7e3d679550368d98cbf59e0805fbccbdd9c88b41c879a3ad6c' then
      dbms_output.put_line('SHA-224. Test 3 passed');
    else
      dbms_output.put_line('SHA-224. Test 3 failed');
    end if;
    
    if lower(rawtohex(sha256(sys.utl_raw.cast_to_raw('')))) = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' then
      dbms_output.put_line('SHA-256. Test 1 passed');
    else
      dbms_output.put_line('SHA-256. Test 1 failed');
    end if;
    if lower(rawtohex(sha256(sys.utl_raw.cast_to_raw('The quick brown fox jumps over the lazy dog')))) = 'd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592' then
      dbms_output.put_line('SHA-256. Test 2 passed');
    else
      dbms_output.put_line('SHA-256. Test 2 failed');
    end if;
    if lower(rawtohex(sha256(l_blob))) = '6a8fd57827ee3c24359730e5c64b6badc41da43758990964ff1b20e5d62ea5f0' then
      dbms_output.put_line('SHA-256. Test 3 passed');
    else
      dbms_output.put_line('SHA-256. Test 3 failed');
    end if;
    
    if lower(rawtohex(sha384(sys.utl_raw.cast_to_raw('')))) = '38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b' then
      dbms_output.put_line('SHA-384. Test 1 passed');
    else
      dbms_output.put_line('SHA-384. Test 1 failed');
    end if;
    if lower(rawtohex(sha384(sys.utl_raw.cast_to_raw('The quick brown fox jumps over the lazy dog')))) = 'ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1' then
      dbms_output.put_line('SHA-384. Test 2 passed');
    else
      dbms_output.put_line('SHA-384. Test 2 failed');
    end if;
    if lower(rawtohex(sha384(l_blob))) = '0f35cb80adadaede011868e4cb79d760ca5bc80a7e84075b1b3e703ca12cc13366bd60b42e699e2d3d1744a617ab50da' then
      dbms_output.put_line('SHA-384. Test 3 passed');
    else
      dbms_output.put_line('SHA-384. Test 3 failed');
    end if;
    
    if lower(rawtohex(sha512(sys.utl_raw.cast_to_raw('')))) = 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e' then
      dbms_output.put_line('SHA-512. Test 1 passed');
    else
      dbms_output.put_line('SHA-512. Test 1 failed');
    end if;
    if lower(rawtohex(sha512(sys.utl_raw.cast_to_raw('The quick brown fox jumps over the lazy dog')))) = '07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6' then
      dbms_output.put_line('SHA-512. Test 2 passed');
    else
      dbms_output.put_line('SHA-512. Test 2 failed');
    end if;
    if lower(rawtohex(sha512(l_blob))) = '3211cc7c5868f4f14878f93ab5dc82a12d5e8b9dbdc65eb7c7793a368cc93fbb5d9c130333b87db538a1cf86911aa60e1da4248ab8c6bb5bc14d381f556b99f4' then
      dbms_output.put_line('SHA-512. Test 3 passed');
    else
      dbms_output.put_line('SHA-512. Test 3 failed');
    end if;
    
    if lower(rawtohex(sha512_224(sys.utl_raw.cast_to_raw('')))) = '6ed0dd02806fa89e25de060c19d3ac86cabb87d6a0ddd05c333b84f4' then
      dbms_output.put_line('SHA-512/224. Test 1 passed');
    else
      dbms_output.put_line('SHA-512/224. Test 1 failed');
    end if;
    if lower(rawtohex(sha512_224(sys.utl_raw.cast_to_raw('The quick brown fox jumps over the lazy dog')))) = '944cd2847fb54558d4775db0485a50003111c8e5daa63fe722c6aa37' then
      dbms_output.put_line('SHA-512/224. Test 2 passed');
    else
      dbms_output.put_line('SHA-512/224. Test 2 failed');
    end if;

    if lower(rawtohex(sha512_256(sys.utl_raw.cast_to_raw('')))) = 'c672b8d1ef56ed28ab87c3622c5114069bdd3ad7b8f9737498d0c01ecef0967a' then
      dbms_output.put_line('SHA-512/256. Test 1 passed');
    else
      dbms_output.put_line('SHA-512/256. Test 1 failed');
    end if;
    if lower(rawtohex(sha512_256(sys.utl_raw.cast_to_raw('The quick brown fox jumps over the lazy dog')))) = 'dd9d67b371519c339ed8dbd25af90e976a1eeefd4ad3d889005e532fc5bef04d' then
      dbms_output.put_line('SHA-512/256. Test 2 passed');
    else
      dbms_output.put_line('SHA-512/256. Test 2 failed');
    end if;

  end unittest; 
  
end hash_util_pkg;
/

