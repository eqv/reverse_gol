p=<<P
_____________________________________
___o_o__o_o______o____o__o__o_o_o____
___o_o______o_oo___o__o_____o_o_o____
___o__oo_ooo______o____oo_oo___o_o_o_
__ooo_o_o__oo_oo____o____o_o_ooo_____
__oo____o_o_o_oo___oo____o_oo______o_
___oo_o_o____oo__oo__o_____oo__o_o___
_o_____oo__o__ooo___oo__oo______o____
__oo_o___oooo_o__oo_oo__o_o_o_ooo____
_oo__o_o___o___oo__o__o__o_o____oo___
_oo_oo__oooooo__o_____oo_oooo_o____o_
_o___o___o___oooo__o___o__o___o_oo_o_
_oo_ooo__oo___o_o__o_oo__o_o_o_______
_ooooo____oo__o____ooo__o___oo_oooo__
__o___oo____o__ooo_ooo_____o_o_ooo___
__o_____o__o___oo__o___o_o________o__
____oo__o_________o________oo____o___
_____________________________________
P
#i={};m=[-1,0,1];11.times{|x|24.times{|y|i[[x,y]]=((p[x*25+y]=="o")?1 :nil)}}
#3.times{n=m.product(m)-[[0,0]];r=i.dup;r.map{|(x,y),c|s=n.count{|v,w|r[[v+x,w+y]]}
#i[[x,y]]=s==3||s==2&&c ?1:nil};5.times{|x|24.times{|y|print(i[[x+3,y]] ? "o":" ")}
#puts""};puts""}

i={};
m=[-1,0,1];
w = p.lines.first.length
h = p.lines.to_a.length
h.times{|x|
  w.times{|y|
    i[[x,y]]=((p[x*w+y]=="o")?1 :nil)
  }
}
5.times{ |g|
  puts "[generation #{g}]"
  n=m.product(m)-[[0,0]];r=i.dup;
  r.map{|(x,y),c|
    s=n.count{|v,w|r[[v+x,w+y]]}
    i[[x,y]]=s==3||s==2&&c ?1:nil
  }
  10.times{|x|
    w.times{|y|
      print(i[[x+3,y]] ? "o":" ")}
puts""};
puts""
}
