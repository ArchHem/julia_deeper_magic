#large credit goes to Peter554 at https://discourse.julialang.org/t/dual-number-magic/11238
module DualNumbers

import Base: +, -, *, /, ^, log, exp, sin, cos, show, convert, ==, isapprox, promote_rule

struct DualNumber{T<:Real} <: Number
    a::T
    b::T
end

DualNumber(x::Real, y::Real) = DualNumber(promote(x,y)...)

#converts
convert(::Type{DualNumber{T}},x::DualNumber{T}) where {T<:Real} = x
convert(::Type{DualNumber{T}},x::DualNumber) where {T<:Real} = DualNumber{T}(convert(T,x.a),convert(T,x.b))
convert(::Type{DualNumber{T}},x::Real) where {T<:Real} = DualNumber{T}(convert(T,x),convert(T,0))
#cant convert non-zero dual part
convert(::Type{T},x::DualNumber) where {T<:Real} = x.b == 0.0 ? convert(T,x.a) : throw(InexactError(:convert,T,x))

#promotions
promote_rule(::Type{T},::Type{DualNumber{U}}) where {T<:Real, U<:Real} = DualNumber{promote_type(T,U)}
promote_rule(::Type{DualNumber{T}},::Type{DualNumber{U}}) where {T<:Real, U<:Real} = DualNumber{promote_type(T,U)}

#fundamental algebra

#identities and nulls
zero(::DualNumber{T}) where {T<:Real}= DualNumber{T}(0,0)
zero(::Type{DualNumber{T}}) where {T<:Real} = DualNumber{T}(0,0)

one(::DualNumber{T}) where {T<:Real} = DualNumber{T}(1,0)
one(::Type{DualNumber{T}}) where {T<:Real}= DualNumber{T}(1,0)

#since we cant overload === we do the next best thing
==(x::DualNumber{T},y::DualNumber{U}) where {T<:Real, U<:Real} = x.a == y.a && x.b == y.b
==(x::DualNumber{T},y::U) where {T<:Real, U<:Real} = x.a == y && x.b == 0
==(y::U,x::DualNumber{T}) where {T<:Real, U<:Real} = x.a == y && x.b == 0

#define approx. relations under the system st. ϵ = 0
isapprox(x::DualNumber{T},y::DualNumber{U}) where {T<:Real, U<:Real} = x.a == y.a 
isapprox(x::DualNumber{T},y::U) where {T<:Real, U<:Real} = x.a == y 
isapprox(y::U,x::DualNumber{T}) where {T<:Real, U<:Real} = x.a == y


#arithmetics
+(x::DualNumber, y::DualNumber) = DualNumber(x.a + y.a, x.b + y.b)
-(x::DualNumber, y::DualNumber) = DualNumber(x.a - y.a, x.b - y.b)
*(x::DualNumber, y::DualNumber) = DualNumber(x.a * y.a, x.a * y.b + x.b * y.a)
/(x::DualNumber, y::DualNumber) = DualNumber(x.a / y.a, (x.b * y.a - x.a * y.b) / y.a^2)
#this is a deliberate, if ill-advised taking of the limit 
^(x::DualNumber, y::DualNumber) = begin
    if x.a == 0
        DualNumber(x.a^y.a, 0.0)
    else
        DualNumber(x.a^y.a, (x.a^y.a) * (y.b*log(x.a) + x.b*y.a/x.a))
    end
end

realpart(x::DualNumber) = x.a
hyperpart(x::DualNumber) = x.b


#single arg functions - maybe U declaration can be discarded?
exp(x::DualNumber{U}) where {U<:Real} = DualNumber{U}(exp(x.a),exp(x.a)*x.b)
log(x::DualNumber{U}) where {U<:Real} = DualNumber{U}(log(x.a), x.b/x.a)
cos(x::DualNumber{U}) where {U<:Real} = DualNumber{U}(cos(x.a),-x.b*sin(x.a))
sin(x::DualNumber{U}) where {U<:Real} = DualNumber{U}(sin(x.a),x.b*cos(x.a))

#abuse promote until we cant
+(x::DualNumber,y::U) where {U<:Real} = +(promote(x,y)...)
-(x::DualNumber,y::U) where {U<:Real} = -(promote(x,y)...)
*(x::DualNumber,y::U) where {U<:Real} = *(promote(x,y)...)
/(x::DualNumber,y::U) where {U<:Real} = /(promote(x,y)...)
#need to remove ambigbiouty
^(x::DualNumber,y::U) where {U<:Int} = ^(promote(x,y)...)
^(x::DualNumber,y::U) where {U<:AbstractFloat} = ^(promote(x,y)...)


#the infamous 'epsilon'
const ϵ = DualNumber(0.0,1.0)

#printing
show(io::IO,X::DualNumber) = print(io,"$(X.a) + $(X.b)ϵ")

export DualNumber, ϵ, realpart, hyperpart

end

#TESTS

#=
using .DualNumbers
X = DualNumber(1, 2)
Y = DualNumber(4/3, 4)
Z = DualNumber(4/3, 3)
Q = DualNumber(5.0, 1)
N = 5
R = 6.0
=#



