

####  update!(d,D,S) ####
#########################
# Does D = d*D + S, in-place in D if types allow, else returns new D (of promoted type).  
#
# D can be Vector or Matrix; d is scalar
# S can be Matrix, Vector, scalar, or a custom type (see below). 
# For (standard) S <: VecOrMat, broadcasting over D is done where appropriate.
#
# Note: "types allow" means: accepts(D,promote_type(map(typeof,(d,D,S))...)) 
#   This means elements of the RHS can be assigned to elements of D without
#   throwing InexactError, or similar. 
#
# For custom S, S must be provided with the following methods:
#   size(S), ndims(S),
#   custom_update!(d,D,S), which performs the update in-place.
# Note: custom_update!(d,D,S): 
# -- does not have to check sizes and 
# -- does not have to check types, but should succeed if "types allow".
#

size2(A) = size(A,1), size(A,2)

update!(d::Number,D::Number,S::Number) = d*D+S
function update!{E<:Number,F<:Number}(d::E,D::Array{F},S)
    # Check size and do conversions here, 
    # Then defer to specific implementations 
    G = eltype(S)
    T = promote_type(E,F,G)
    if !accepts(D,T)
      D = convert(Array{T},D)
      d = convert(T,d)
    else
      d = convert(F,d)
    end
    if size2(S) == size2(D)
        if isa(S,Array) return full_update!(d,D,S) end
        return custom_update!(d,D,S)
    end
    if ndims(S)==0 return update_broadcast_scalar!(d,D,S) end
    if length(S)==1 return update_broadcast_scalar!(d,D,S[1]) end
    if ndims(D)==2
      if size2(S) == (size(D,1),1) return update_broadcast_col!(d,D,S) end
      if size2(S) == (1,size(D,2)) return update_broadcast_row!(d,D,S) end
    end
    error("cannot update $(size(S)) into $(size(D))")
end



function full_update!(d::Number, D::Array, S::Array)
    @assert length(S) == length(D)
    for i=1:length(D)
      D[i] = d*D[i] + S[i]
    end
    return D
end

function update_broadcast_scalar!(d::Number, D::Array, s::Number)
    for i=1:length(D)
      D[i] = d*D[i] + s
    end
    return D
end

function update_broadcast_col!(d::Number, D::Matrix, s::Array)
    M,N = size(D)
    @assert size(s,1) == length(s) == M
    for j=1:N, i=1:M
      D[i,j] = d*D[i,j] + s[i]
    end
    return D
end


function update_broadcast_row!(d::Number, D::Matrix, s::Array)
    M,N = size(D)
    @assert size(s,2) == length(s) == N
    for j=1:N
      sj = s[j]
      for i=1:M
          D[i,j] = d*D[i,j] + sj
      end
    end
    return D
end



##############################
## procrustean_update! #######
##############################
# Does D = D + S, in-place of possible.
# Behaves like update!(), but also sums S down to size 1 in directions where D has size 1.
#
# S must be VecOrMat, or custom type provided as described above, with:
#  ndims(), size(), custom_update!() and also sum(S), sum(S,i).
procrustean_update!(d::Number,s::Number) = d + s  
procrustean_update!(d::Number,S) = d + sum(S)  
function procrustean_update!(D::Array,S)
    # sum if necessary
    for k=1:ndims(S)
        szD = size(D,k) ; szS = size(S,k)
      if szS > szD
        if szD != 1 error("cannot reduce size(S,$k)==$szS to $szD") end
        S = sum(S,k) # this changes size(S,k), but not ndims(S)
      end
    end
    # update, with broadcast
    return update!(one(eltype(D)),D,S)      
end

# In Greek mythology, Procrustes was a rogue smith and bandit who attacked people by stretching them,
# or cutting off their legs, so as to force them to fit the size of an iron bed.




