# DBI Fix
# require 'dbi'

# DBI.ColumnInfo.class_eval do
#   def initialize(hash=nil)
#     @hash = hash.dup rescue nil
#     @hash ||= Hash.new
# 
#     # coerce all strings to symbols
#     keys = @hash.keys
#     keys.each do |x|
#     # @hash.each_key do |x|
#         if x.kind_of? String
#             sym = x.to_sym
#             if @hash.has_key? sym
#                 raise ::TypeError, 
#                     "#{self.class.name} may construct from a hash keyed with strings or symbols, but not both" 
#             end
#             @hash[sym] = @hash[x]
#             @hash.delete(x)
#         end
#     end
# 
#     super(@hash)    
#   end
# end

# Doesn't work since the class inheritance is wrong?

# module DBI
#   class ColumnInfo < DelegateClass(Hash)
#     def initialize(hash=nil)
#         @hash = hash.dup rescue nil
#         @hash ||= Hash.new
# 
#         # coerce all strings to symbols
#         keys = @hash.keys
#         keys.each do |x|
#         # @hash.each_key do |x|
#             if x.kind_of? String
#                 sym = x.to_sym
#                 if @hash.has_key? sym
#                     raise ::TypeError, 
#                         "#{self.class.name} may construct from a hash keyed with strings or symbols, but not both" 
#                 end
#                 @hash[sym] = @hash[x]
#                 @hash.delete(x)
#             end
#         end
# 
#         super(@hash)
#     end
#   end
# end