| type | size | hex_count | rows | intersections | paths |
| hex  | 2    | 4         | 3    | 16            | 19    |
| hex  | 3    | 14        | 7    | 42            | 55    |
| hex  | 4    | 30        | 11   | 80            | 109   |



# Hex-type Map
# rows = 3+4*(size-2)
# hexes = 2* (size..(size+(size-2))).inject do |sum,n| sum + n end
# 
# intersections = (2..(2*size)).inject(0) { |sum, n| 
#   if (n%2).zero?
#     if n == 2*size
#       sum + (2*size-1)*2*size 
#     else
#       sum + (2*n)
#     end
#   else
#     sum
#   end
# }
#
# paths = (2 * (6*size - 2) + 3 * (intersections - (6*size - 2)))/2
