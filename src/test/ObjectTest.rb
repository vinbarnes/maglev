require File.expand_path('simple', File.dirname(__FILE__))

#     BEGIN TEST CASES

test(''.class == String, true, "''.class == String")

test(String.class == Class, true, "String.class == Class")
test(String.class.eql?(Class), true, "String.class.eql? Class")
test(String.class.equal?(Class), true, "String.class.equal? Class")

test(String.class == Fixnum.class, true, "String.class == Fixnum.class")

begin
  class ClsOne < Hash
    def setBb(a)
      @bb = a
    end
    def setCc(a)
      @cc = a
    end
  end
  o = ClsOne.new
  x = o.instance_variables
  test(x , [ '@bb', '@cc' ] , "instance_variables fixed")
  class ClsOne
    def setDd(a)
      @dd = a
    end
    def to_a
      res = [ @bb , @cc , @dd ]
    end
  end
  x = o.instance_variables
  test(x , [ '@bb', '@cc' ] , "instance_variables fixed 2")
  o.setDd(20)
  x = o.instance_variables
  test(x , [ '@bb', '@cc' , '@dd' ] , "ivs3")
  o.setBb(9) ;   o.setCc(15)
  x = o.to_a
  test(x , [ 9, 15, 20 ] , "ivs4")
  p = ClsOne.new
  p.setCc(8) ;
  x = p.to_a
  test(x , [ nil, 8, nil ] , "ivs5")
  test(o.instance_variable_get( :'@bb' )  , 9 , "ivs6")
  test(o.instance_variable_get( :'@dd' )  , 20 , "ivs6")
  test(p.instance_variable_get( :'@dd' ), nil, "ivs7")
  o.instance_variable_set( :'@dd' , 30)
  p.instance_variable_set( :'@dd' , 35)
  test(o.to_a, [ 9, 15, 30 ], "ivs7")
  test(p.to_a, [ nil, 8, 35 ], "ivs8")
end

report
