# Start of a KD Tree library.  Right now, only 2D trees are supported, but
# the general algorithm should work for higher dimensions.  There are a few
# optimizations for 2D trees (basically, instead of iterating through the
# axis by using Point[], we access with x() and y(), which cuts down the
# running time by quite a bit.

# The points
# given to a tree must have the following methods: cmp(axis, other)
#
#
# TODO: Instead of checking axis all the time, make subclasses for each axis?
require 'bestk'

module KDTree

  # Tree2D is a KD-Tree of dimension 2.
  #
  # TODO:
  # * Add insert_node and remove_node methods (make them (functionally)
  #   persistent).
  #
  # * Rebalance is hard for KD Trees.  Need to implement a re-generate
  #   which just completely rebuilds the tree
  #
  class Tree2D
    attr_reader :left, :right, :value

    class << self
      attr_reader :counts
      def inc_counter(name)
        @counts[name] += 1
      end
      def counter(name)
        @counts[name]
      end
      def reset_counts
        puts "#{self}.reset_counts"
        @counts = Hash.new(0)
      end

      def report_counts(msg=nil)
        puts "====== #{self}.counts"
        puts msg if msg
        @counts.each {|k,v|  puts "#{k} => #{v}" }
      end
    end
    reset_counts

    # Creates a new Tree2D for the given points.  If points is nil or
    # empty, will return an empty tree.  #left and #right may return nil,
    # if there is no data on that side of the tree.  The points passed to
    # the initialize method must respond to the following methods:
    # * x     Return the x coordinate
    # * y     Return the y coordinate
    # * eql?  (and hash)
    # * dist_sq
    #
    # TODO: Should we replace nil with an empty tree?
    def initialize(points, depth=0)
      @axis = depth % 2
      return if points.nil? or points.empty?

      #sorted = points.sort {|a,b| a[@axis] <=> b[@axis] }
      if @axis == 0
        sorted = points.sort {|a,b| a.x <=> b.x }
      else
        sorted = points.sort {|a,b| a.y <=> b.y }
      end
      pivot = sorted.size / 2
      left_points = sorted[0...pivot]
      right_points = sorted[pivot+1..-1]
      @left = Tree2D.new(left_points, depth+1) unless left_points.nil? or left_points.empty?
      @right = Tree2D.new(right_points, depth+1) unless right_points.nil? or right_points.empty?
      @value = sorted[pivot]
    end

    # Does an in-order traversal of the tree, but yields only the values
    def each(&block)
      @left.each(&block) unless @left.nil?
      block.call(@value) if @value and block
      @right.each(&block) unless @right.nil?
    end

    # Does an pre-order traversal of the tree, yields the whole node
    def pre_order(&block)
      block.call(self) if block
      @left.pre_order(&block) unless @left.nil?
      @right.pre_order(&block) unless @right.nil?
    end

    # Does an post-order traversal of the tree, yields the whole node
    def post_order(&block)
      @left.post_order(&block) unless @left.nil?
      @right.post_order(&block) unless @right.nil?
      block.call(self) if block
    end

    # Does an in-order traversal of the tree, yields the whole node
    def in_order(&block)
      @left.in_order(&block) unless @left.nil?
      block.call(self) if block
      @right.in_order(&block) unless @right.nil?
    end

    def leaf?
      @left.nil? and @right.nil?
    end

    def nearest_lat_lon(lat, lon)
      nearest(Point2D.new(lat, lon))
    end

    # Returns an array of [value, dist] which represents the value of the
    # nearest point to the target_point in this subtree, along with the
    # distance squared from the point to the target_point. If this tree
    # contains several points at the same distance, only one of those values
    # is returned.
    #
    # It is about 20% (maglev) - 40% (mri) faster to not use MinMetric in
    # this method...
    def nearest(target_point)
      my_dist = target_point.dist_sq(@value)
      best_v = @value
      best_d = my_dist

      return [best_v, best_d] if self.leaf?

      # cmp = target_point[@axis] <=> @value[@axis]
      if @axis == 0
        cmp = target_point.x <=> @value.x
      else
        cmp = target_point.y <=> @value.y
      end
      # But best_v is not set if the search side is nil...
      case cmp
      when -1
        unsearched = @right
        best_v, best_d = @left.nearest(target_point) unless @left.nil?
      when 1
        unsearched = @left
        best_v, best_d = @right.nearest(target_point) unless @right.nil?
      when 0
        if @left
          unsearched = @right
          best_v, best_d = @left.nearest(target_point)
        else
          unsearched = @left
          best_v, best_d = @right.nearest(target_point)
        end
      end

      # Am I better than the best in my sub-tree?
      if my_dist < best_d
        best_v = @value
        best_d = my_dist
      end

      # Check if the other side of the splitting plane is close enough for
      # possibilities.  This will be the case if the best distance so far is
      # larger than the distance from target node to the axis (i.e., does a
      # hypersphere of radius best_d cross the splitting axis or not).
      #    target_to_axis_d = @value[@axis] - best_v[@axis]
      #target_to_axis_d = @value[@axis] - target_point[@axis]
      if @axis == 0
        target_to_axis_d = @value.x - target_point.x
      else
        target_to_axis_d = @value.y - target_point.y
      end
      target_to_axis_d_sq = target_to_axis_d * target_to_axis_d
      if best_d >= target_to_axis_d_sq and not unsearched.nil?
        v, d = unsearched.nearest(target_point)
        if d < best_d
          best_v = v
          best_d = d
        end
        #      else
        #        Tree2D.inc_counter :skip
      end
      [best_v, best_d]
    end

    # Returns an array of [value, dist] which represents the value of the
    # nearest point to the target_point in this subtree, along with the
    # distance squared from the point to the target_point. If this tree
    # contains several points at the same distance, only one of those values
    # is returned.
    def nearest_k(target_point, k=1)
#       bestk = BestK.new(k) do |a,b|
#         # a is better than b if the metric is smaller
#         a
#       end
#       _nearest_k(target_point, bestk)
#     end

#     def _nearest_k(target_point, bestk)
      #      Tree2D.inc_counter :nearest
      my_dist = target_point.dist_sq(@value)
      best = MinMetric.new(@value, my_dist)

      return best if self.leaf?

      cmp = if @axis == 0
              target_point.x <=> @value.x
            else
              target_point.y <=> @value.y
            end
      # But best_v is not set if the search side is nil...
      case cmp
      when -1
        unsearched = @right
        best.update_metric(@left.nearest_k(target_point, k)) unless @left.nil?
      when 1
        unsearched = @left
        best.update_metric(@right.nearest_k(target_point, k)) unless @right.nil?
      when 0
        if @left
          unsearched = @right
          best.update_metric(@left.nearest_k(target_point, k))
        else
          unsearched = @left
          best.update_metric(@right.nearest_k(target_point, k))
        end
      end

      # Am I better than the best in my sub-tree?
      best.update(@value, my_dist)

      # Check if the other side of the splitting plane is close enough for
      # possibilities.  This will be the case if the best distance so far
      # is larger than the distance from target node to my splitting axis
      # (i.e., does a hypersphere of radius best_d cross the splitting axis
      # or not).
      target_to_axis_d = if @axis == 0
                           @value.x - target_point.x
                         else
                           @value.y - target_point.y
                         end
      target_to_axis_d_sq = target_to_axis_d * target_to_axis_d
      if best.metric >= target_to_axis_d_sq and not unsearched.nil?
        best.update_metric(unsearched.nearest_k(target_point, k))
      end
      best
    end

    def eql?(other)
      @value.eql?(other.value) and
        @left.eql?(other.left) and
        @right.eql?(other.y)
    end

    def inspect
      "Tree2D (inspect): value #{value.inspect} LEFT #{@left.to_s} RIGHT: #{@right.to_s}"
    end

    def to_s
      "Tree2D (to_s): value #{value.inspect} LEFT #{@left.__id__} RIGHT: #{@right.__id__}"
    end

    def stats(depth=0, stats=TreeStats.new)
      stats.node
      stats.depth(depth)
      stats.children(@left, @right)
      @left.stats(depth+1, stats) if @left
      @right.stats(depth+1, stats) if @right
      stats
    end
  end

  # Maintains a value / metric pair.  Updated data can be sent to the
  # object, but it will only be remembered if the metric is better than the
  # current one.
  class MinMetric
    attr_reader :value, :metric

    def initialize(value=nil, metric=nil)
      @value = value
      @metric = metric
    end

    def update_metric(metric)
      if @metric.nil? || metric.metric < @metric
        @value = metric.value
        @metric = metric.metric
      end
    end

    def update(value, metric)
      if @metric.nil? || metric < @metric
        @value = value
        @metric = metric
      end
    end

    def eql?(other)
      other and @metric.eql?(other.metric) and @value.eql?(other.value)
    end

    def hash
      @metric.hash ^ @value.hash
    end
  end

  class SearchResult
    attr_reader :value, :distance
    def initialize(value, dist)
      @value = value
      @distance = dist
    end
    def >(other)
      # a is greater (better) than b if its distance from the target is
      # smaller
      other.distance > @distance
    end
  end

  # A Point2D contains two coordinates, x and y, and may have some data
  # associated with it.
  class Point2D
    attr_reader :x, :y, :data

    def initialize(x, y, data=nil)
      @x, @y, @data = x, y, data
    end

    def to_s
      "Point[#{@x}, #{@y}] #{@data}"
    end

    # Return the coordinate along the given axis (0 or 1)
    # This is much slower than using the x() and y() readers...
    def [](index)
      if index.equal? 0
        @x
      elsif index.equal? 1
        @y
      else
        raise ArgumentError, "#{index} is out of range.  Should be 0 or 1"
      end
    end

    def eql?(other)
      @x.eql?(other.x) and @y.eql?(other.y) and @data.eql?(other.data)
    end

    def hash
      @x.hash ^ @y.hash ^ @data.hash
    end

    # Returns the distance squared from the other point
    def dist_sq(other)
      dx = @x - other.x
      dy = @y - other.y
      (dx * dx) + (dy * dy)
    end
  end

  class TreeStats
    def initialize
      @counts = Hash.new(0)
      @depth  = Hash.new(0)
      @children = [0, 0, 0]
    end

    def node
      @counts[:node] += 1
    end

    def depth(depth)
      @depth[depth] += 1
    end

    def children(left, right)
      count = 0
      count += 1 if left
      count += 1 if right
      @children[count] += 1
    end

    def report
      puts "=== Tree Stats"
      @counts.each {|k,v| puts "    #{k} => #{v}"}
      puts "  Depths:  #{@depth.size}"
      @depth.keys.sort.each {|k| puts "    #{k} => #{@depth[k]}" }
      puts "  Child counts"
      @depth.each_with_index {|v,i|"    #{i} => #{v}" }
    end
  end
end
