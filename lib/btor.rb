require 'set'
require 'tempfile'

def assert(&blck)
  raise "asser failed" unless blck.call()
end

module BTOR
  class NegatedUse
    def initalize(node)
      assert { node.class == Node }
      @node = node
    end
    def id
      -@node.id
    end
  end

  class ArrayNode
    attr_accessor :id, :type_name, :ptr_size, :elem_size, :args, :builder
    def initialize(builder, id, type_name, elem_size, ptr_size, *args)
      @builder, @id, @type_name, = builder, id, type_name
      @ptr_size, @elem_size, @args = ptr_size, elem_size, args
    end

    def to_btor_s
      args_s = @args.map do |arg|
        case arg
          when Integer then arg.to_s
          else arg.id.to_s
        end
      end
      "#{@id} #{@type_name} #{@elem_size} #{@ptr_size} #{args_s.join(" ")}"
    end
  end

  class Node
    attr_accessor :id, :type_name, :size, :args, :val, :desc, :builder
    attr_accessor :signed

    def initialize(builder, id,type_name, size, *args)
      @builder = builder
      @id = id
      @type_name,@size,@args = type_name,size, args
      @args.each do |arg| assert { arg.id < @id } unless arg.is_a? Integer end
      @signed = false
    end

    def to_btor_s
      args_s = @args.map do |arg|
        case arg
          when Integer then arg.to_s
          else arg.id.to_s
        end
      end
      "#{@id} #{@type_name} #{@size} #{args_s.join(" ")}"
    end

    def +(other) @builder.add(self,other) end
    def -(other) @builder.sub(self,other) end
    def *(other) @builder.mul(self,other) end
    def %(other) @builder.urem(self,other) end
    def &(other) @builder.and(self,other) end
    def |(other) @builder.or(self,other) end
    def ^(other) @builder.xor(self,other) end
    def nand(other) @builder.nand(self,other) end
    def nor(other) @builder.nor(self,other) end
    def xnor(other) @builder.xnor(self,other) end
    def implies(other) @builder.implies(self,other) end
    def iff(other) @builder.iff(self,other) end
    def then_else(then_o, else_o) @builder.cond(self,then_o, else_o) end
    def >>(other) @builder.srl(self,other) end
    def <<(other) @builder.sll(self,other) end
    def rol(other) @builder.rol(self,other) end
    def ror(other) @builder.ror(self,other) end
    def inc() @builder.inc(self) end
    def dec() @builder.dec(self) end
    def redand() @builder.redand(self) end
    def redor() @builder.redor(self) end
    def redxor() @buidler.rexor(self) end
    def bits(range) @builder.slice(self,range.last,range.first) end
    def bit(i) @builder.slice(self,i,i) end
    def not() @builder.not(self) end
    def neg() @builder.neg(self) end
    def ==(other) @builder.eq(self,other) end
    def !=(other) @builder.ne(self,other) end
    def <=(other) @signed ? @builder.slte(self,other) : @builder.ulte(self,other) end
    def <(other) @signed ? @builder.slt(self,other) : @builder.ult(self,other) end
    def >(other) @signed ? @builder.sgt(self,other) : @builder.ugt(self,other) end
    def >=(other) @signed ? @builder.sgte(self,other) : @builder.ugte(self,other) end

    def signed
      res = self.dup
      res.signed = true
    end

    def unsigned
      res = self.dup
      res.signed = false
    end
  end

  class Builder

    def initialize()
      @id_counter = 0
      @nodes = Set.new
    end

    def reg(node)
      @nodes.add(node)
      return node
    end

    def new_array(type_name, *args)
      id = @id_counter += 1
      return reg ArrayNode.new(self, id, type_name, *args)
    end

    def new_slice( node, upper, lower)
      id = @id_counter += 1
      return reg Node.new(self, id,'slice',upper-lower+1, node, upper, lower)
    end

    def new_node(type_name, size, *args)
      id = @id_counter+= 1
      return reg Node.new(self, id,type_name,size,*args)
    end

    def build(&block)
      block.call(self)
    end

    def to_btor_s
      @nodes.sort_by(&:id).map(&:to_btor_s).join("\n")
    end

    def neg_op(node) NegatedUse.new(node) end

    def mon(name,n, size = nil)
      new_node(name,size || n.size, n)
    end

    def bin(name,l,r, size = nil)
      assert {l.is_a? Node }
      if r.is_a? Integer
        r = const(l.size,r)
      end
      assert { l.size == r.size }
      new_node(name, size||l.size, l, r)
    end

    def bit(val)
      assert { val.is_a? Integer }
      const(1,val)
    end

    def byte(val)
      assert { val.is_a? Integer }
      const(8,val)
    end

    def word(val)
      assert { val.is_a? Integer }
      const(16,val)
    end

    def dword(val)
      assert { val.is_a? Integer }
      const(32,val)
    end

    def array(elem_size,ptr_size) new_array("array",elem_size,ptr_size) end
    def read_elem(array,index) new_node("read",array.elem_size,array,index) end
    def write_elem(array,index,elem) new_array("write",array.elem_size, array.ptr_size, array, index, elem) end
    def acond(cond, then_array, else_array)
      assert { then_array.is_a? ArrayNode }
      assert { else_array.is_a? ArrayNode }
      assert { cond.is_a?(Node) && cond.size == 1 }
      assert { then_array.elem_size == else_array.elem_size }
      assert { then_array.ptr_size == else_array.ptr_size }
      new_array("acond",then_array.elem_size, then_array.ptr_size, cond, then_array, else_array)
    end

    def var(size) new_node('var', size) end
    def const(size,val) new_node('constd',size,val) end
    def root(start) new_node('root', 1, start) end
    def neg(n) mon('neg',n) end
    def not(n) mon('not',n) end
    def inc(n) mon('inc',n) end
    def dec(n) mon('dec',n) end

    def redand(op) mon('redand', op, 1) end
    def redor(op) mon('redand', op, 1) end
    def redxor(op) mon('redand', op, 1) end

    def implies(l,r) assert {l.size == r.size && l.size == 1 }; bin('implies', l, r) end
    def iff(l,r) assert {l.size == r.size && l.size == 1 }; bin('iff', l, r) end

    def eq(l,r) bin('eq', l,r,1) end
    def ne(l,r) bin('ne', l,r,1) end
    def ult(l,r) bin('ult', l,r,1) end
    def slt(l,r) bin('slt', l,r,1) end
    def ulte(l,r) bin('ulte', l,r,1) end
    def slte(l,r) bin('slte', l,r,1) end
    def ugt(l,r) bin('ugt', l,r,1) end
    def sgt(l,r) bin('sgt', l,r,1) end
    def ugte(l,r) bin('ugte', l,r,1) end
    def sgte(l,r) bin('sgte', l,r,1) end

    def and( l,r) bin('and', l,r) end
    def or(  l,r) bin('or',  l,r) end
    def xor( l,r) bin('xor', l,r) end
    def nand(l,r) bin('nand',l,r) end
    def nor( l,r) bin('nor', l,r) end
    def xnor(l,r) bin('xnor',l,r) end

    def add(l,r) bin('add',l,r) end
    def sub(l,r) bin('sub',l,r) end
    def mul(l,r) bin('mul',l,r) end
    def urem(l,r) bin('urem',l,r) end
    def srem(l,r) bin('srem',l,r) end
    def sdiv(l,r) bin('sdiv',l,r) end
    def udiv(l,r) bin('udiv',l,r) end
    def smod(l,r) bin('smod',l,r) end

    def log_2(x)
      log = 0
      loop do
        break if x <= 1
        log += 1
        x /= 2
      end
      return log
    end

    def log_bin(name,left,right)
      if right.is_a? Integer
        assert {left.is_a? Node}
        right = const(log_2(left.size), right)
      end
      assert { log_2(left.size) == right.size }
      new_node(name,left.size, left, right)
    end

    def sll(l,r) log_bin('sll', l,r) end
    def srl(l,r) log_bin('srl', l,r) end #shift right logical (always shifts in 0)
    def sra(l,r) log_bin('sra', l,r) end #shift right arithmatic (doens't change sign)
    def ror(l,r) log_bin('ror', l,r) end
    def rol(l,r) log_bin('rol', l,r) end

    def uaddo(l,r) bin('uaddo', l,r,1) end #overflow bits of opertion
    def saddo(l,r) bin('saddo', l,r,1) end
    def usubo(l,r) bin('usubo', l,r,1) end
    def ssubo(l,r) bin('ssubo', l,r,1) end
    def umulo(l,r) bin('usubo', l,r,1) end
    def smulo(l,r) bin('ssubo', l,r,1) end
    def udivo(l,r) bin('usubo', l,r,1) end
    def sdivo(l,r) bin('ssubo', l,r,1) end
    def concat(l,r) new_node('concat',l.size+r.size, l, r) end
    def cond(cond_n, then_n, else_n)
      assert {cond_n.size == 1 }
      assert { then_n.size == else_n.size }
      new_node('cond', then_n.size, cond_n, then_n, else_n)
    end

    def all(arr,&block)
      iter = arr.each
      first = block.call(iter.next)
      if !first
        puts "warning, empty conjunction will always be true"
        return const(1,0)
      end
      second = block.call(iter.next)
        return first if !second
      disjunction = self.and(first,second)
      loop do |nextn|
        nextn = block.call(iter.next) rescue nil
        break unless nextn
        disjunction = self.and(disjunction,nextn)
      end
      return disjunction
    end

    def any(arr,&block)
      iter = arr.each
      first = block.call(iter.next)
      if !first
        puts "warning, empty disjunction will always be false"
        return const(1,0)
      end
      second = block.call(iter.next)
        return first if !second
      disjunction = self.or(first,second)
      loop do |nextn|
        nextn = block.call(iter.next) rescue nil
        break unless nextn
        disjunction = self.or(disjunction,nextn)
      end
      return disjunction
    end

    def slice(n, upper, lower) new_slice(n,upper,lower) end

    def probe(desc,node)
      probe_var = var(node.size)
      probe_var.desc = desc
      root( eq(probe_var,node) )
    end

    def probes
      @nodes.select{|n| n.desc }
    end

    def parse(response)
      sat = false
      mapping = {}
      response.lines.each do |line|
        if line.strip == "sat"
        sat = true
        elsif line =~ /\A(\d+) ([01]+)\Z/
          mapping[$1.to_i] = $2.to_i(2)
        else
          puts "boolector: #{line.strip}"
        end
      end
      @nodes.each do |node|
        node.val = mapping[node.id] if mapping.include? node.id
      end
      return sat
    end

    def dump(filename)
      File.open(filename,"w") do |f|
        f.puts to_btor_s
      end
    end
    def run
      Tempfile.open("smt") do |file|
        file.puts to_btor_s
        file.close
        res = `boolector -m #{file.path}`
        return parse(res)
      end
    end
  end
end

