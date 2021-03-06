type blocksparse <: SparseFlavour end

############################################################################
immutable blockdata{T<:Number}  
  block::Matrix{T}
  at::(Int,Int)
end
blockdata{T}(block::Matrix{T},at::(Int,Int)) = {T}blockdata(block,at)
eltype{T}(B::blockdata{T}) = T

(+)(A::blockdata,B::blockdata) = 
  A.at==B.at && size(A)==size(B)? blockdata(A.block+B.block,A.at) : error("block mismatch")

(*)(s::Number,data::blockdata) = blockdata(s*data.block,data.at)
(*)(data::blockdata,s::Number) = *(s,data)

transpose(data::blockdata) = blockdata(data.block.',(data.at[2],data.at[1]) )
conj(data::blockdata) = blockdata(conj(data.block),data.at )
ctranspose(data::blockdata) = blockdata(data.block',(data.at[2],data.at[1]) )

function sum(B::blockdata,i::Int)
    if i==1
      blockdata(sum(B.block,i),(1,B.at[2]))  
    elseif i==2
      blockdata(sum(B.block,i),(B.at[1],1))  
    else
      error("bad i")
    end
end
############################################################################

function blocksparse(block::Matrix,at::(Int,Int),sz::(Int,Int)) 
  for i=1:2 assert(1 <= at[i] <= sz[i] - size(block,i) + 1,
    "$(size(block)) block does not fit at $at in $sz matrix") 
    end
  return CustomMatrix(blocksparse,blockdata(block,at),sz...)
end

function update!(d::Number, D::Matrix,S::CustomMatrix{blocksparse})
  assert(size(D)==size(S),"argument dimensions must match")
  i0,j0 = S.data.at
  block = S.data.block
  m,n = size(block) 
  atj = j0
  for j=1:n
    ati = i0
    for i=1:m
      D[ati,atj] = d*D[ati,atj] + block[i,j]
      ati += 1
    end
    atj += 1
  end
  return D  
end


function (+)(A::CustomMatrix{blocksparse},B::CustomMatrix{blocksparse}) 
  assert(size(A)==size(B),"size mismatch")
  return CustomMatrix(blocksparse,A.data+B.data,size(A)...) 
end

transpose(C::CustomMatrix{blocksparse}) = CustomMatrix(blocksparse,C.data.',C.n,C.m)
ctranspose{F,E<:Complex}(C::CustomMatrix{F,E}) = CustomMatrix(blocksparse,C.data',C.n,C.m)

function sum(C::CustomMatrix{blocksparse},i::Int) 
    if i==1
      S = CustomMatrix(blocksparse,sum(C.data,i),1,C.n)
      return full(S)
    elseif i==2
      S = CustomMatrix(blocksparse,sum(C.data,i),C.m,1)
      return full(S)
    else
      return full(C)
    end
end
