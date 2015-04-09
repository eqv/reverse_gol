require './lib/btor.rb'
b = BTOR::Builder.new
pattern = <<EOF
...........................
.oooo..oooooo..oooo..ooooo.
.o.....o....o..o.....o...o.
.o.....o....o..o.....o...o.
.o.....o....o..o.....o...o.
.o.....o....o..o.....o...o.
.oooo..oooooo..oooo..ooooo.
...........................
EOF

pattern = <<EOF
_____________________________
_o______o_____________o__o___
____oo___o__oo__oo__o____o___
_o_oo___o_oo_o___oo_o_oo__o__
___oo____oo_o_____oooo_____o_
____oo___ooo_o__ooooo____o___
_o_oo_o_o__oo___oo__ooo__o___
___oo____o__o______o__o____o_
_________o____o__o__o___oo___
_____________________________
EOF

pattern = <<EOF
_______________________________
_o_______o_ooooooo_o__o________
_____oo___oooo_oooo____o_o_o___
_o_o_____o___o___o___o_oo__o___
______o_____o________ooo_______
_o__oo___ooo_oo___ooo______ooo_
___o________o__________________
_____o_o_____o__oo___oo___oo___
_oo__oooooo__ooooo_o__oo__oooo_
____o___oo_____o__o__o__o_o____
______o__________o____o____o___
_______________________________
EOF

pattern =<<EOF
_________________________________
_o_______________o___o___oo______
___oo____o_o_o__o__o___o____o_oo_
_o____oo__o__oo_o__o__ooo_oo_____
__ooo_oo_oo___o_o__oooo__oo_o_oo_
___oo__ooo____o____oo______o_____
__o__o____ooo___o___o_o_ooo_oooo_
___oo__oo____oo__o_____ooooo_____
__oo________o________oo____o__oo_
__oo__oo__o___o__oo______o__o____
______oo_oo__oo_oo_o_ooo_o_o_o___
_____o_o___ooooo__o______o_o_____
__o_____o_o_ooo_o______o_________
_________________________________
EOF

pattern=<<EOF
___________________________________
_oo_o_oo_________o___o_ooo_o_o_oo__
_____ooooo________o___ooooo________
___ooo_o___o_oo____o____o___oooo_o_
_______o___o___o_oooo_________oo___
__oo___o__oo____oo__o__oo_oo___o___
____oooo__o____o_____o_ooo_ooo__o__
__oo__o_o__ooo__oo___ooo_oo________
____o________ooo_ooo_o_______o_oo__
__ooo__oo_o_o___o____oo_o__oo______
_______________oo__oo_o______oo__o_
_____o__o_o____o_oo_ooooooo_o______
______o_ooo_oo__o________oo_o_o__o_
___oooo__o_o_o__o___oo_o____o_o____
__o_oo_o______o___o______oo______o_
___________________________________
EOF

pattern <<EOF
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
EOF

w = pattern.lines.to_a.first.strip.length
h = pattern.lines.to_a.length
puts [w,h].inspect
out = {}
pattern.lines.each.with_index do |l,x|
  l.strip.each_char.with_index do |c,y|
    if c== 'o'
    out[[x,y]] = true
    else
    out[[x,y]] = false
    end
  end
end

border_vars = []
b.build do |b|
  vars = {}
  (0...h+2).each do |x|
    (0...w+2).each do |y|
      v= b.var(4)
      vars[[x,y]] = v
      b.root((v <= b.const(4,1)) & (v >= b.const(4,0)))
      border_vars << v if x==0 || x==h+1 || y == 0 || y == w+1
      #border_vars << v if y == 0 || y == w+1
    end
  end

  border_vars.each do |v|
    b.root(v == b.const(4,0))
  end

  out.each_pair do |(x,y),life|
    x+=1
    y+=1
    n = [-1,0,1].product([-1,0,1])-[[0,0]]
    s = n.map{|(ox,oy)| vars[[x+ox,y+oy]]}.inject(&:+)
    c = vars[[x,y]]
    if life
      b.root(((c == b.const(4,1)) & (s==b.const(4,2))) | (s==b.const(4,3)))
    else
      b.root(((s==b.const(4,2)) & (c == b.const(4,0))) | (s<b.const(4,2)) | (s >b.const(4,3)))
    end
  end

  puts "running"
  ok = b.run
  puts "done #{ok.inspect}"
  if ok
    puts "satisfied"
    (0...h+2).each do |x|
      (0...w+2).each do |y|
        v = vars[[x,y]].val
        if v == 0
          print "_"
        elsif v == 1
          print "o"
        else
          printf "[#{v}]"
        end
      end
    print "\n"
    end
  else
    puts "unsatisfiable"
  end
end
