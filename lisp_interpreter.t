--use c library
local c = terralib.includec("stdio.h")

-- replace any "(" or ")" with spaces before and after
function replace(str)
  local newstr = ""
  for i in string.gmatch(str, "%C") do
    if (i == "(") then 
      i = " ( "
    elseif (i == ")") then
      i = " ) "
    end
    newstr = newstr..i
  end
  return newstr
end

--scans the expressing and turns it into tokens
function scan(str)
  local str = replace(str)
  local sep, fields = " ", {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

--parse the tokens
function parse(program)
  local tokenized = read_tokens(scan(program))
  --use parsedprint to printout the tokens
  --parsedprint(tokenized)
  return tokenized
end

-- use this if you want to print the tokens 
function parsedprint(tokenized)
  for i,line in ipairs(tokenized) do
    if type(line) == "table" then
      parsedprint(line)
    else
      print(line, type(line))
    end
  end
end

--tokens are in a table
--turns the tokens into number or string, and put them into a table
function read_tokens(tokens)
  if (table.getn(tokens) == 0) then
    error("unexpected EOF while readin")
  end
  local token = table.remove(tokens,1)
  if (tonumber(token) ~= nil) then
    token = tonumber(token)
  end
  if "(" == token then
    local L = {}
    while tokens[1] ~= ")" do
      table.insert(L, read_tokens(tokens))
    end
    local token1 = table.remove(tokens,1)
    return L
  elseif ")" == token then
    return error("unexpected )")
  else
    return token
  end
end

--environment
function env()
  env = {
   '+', '-', '*', '/', 'quote', 'cons', 'car', '<', '>'}
end
local globalenv = env()

--if it is a primitive
function contains(element, env)
  for _, value in pairs(env) do
    if value == element then
      return true
    end
  end
  return false
end 

--add function
terra add(a : double, b: double) : double
  return a + b
end

--minus function
terra minus(a : double, b: double) : double
  return a - b
end

--multiply function
terra multiply(a : double, b: double) : double
  return a * b
end

--divide function
terra divide(a : double, b: double) : double
  return a / b
end

--less than
terra lessthan(a : double, b: double) : bool
  return a < b
end

--greater than
terra greaterthan(a : double, b: double) : bool
  return a > b
end

--cons
function cons(a,b)
  return {a,b}
end

--car
function car(list)
  --if (type(list) ~= "table") then 
  print(eval(list[1], globalenv), "this is the first thing")
    return list[1]
  --else
   -- return list
  --end
end

--quote 
function evalquote(exp)
  for _, value in pairs(exp) do
    io.write(value, " ")
  end
end

-- eval expression
local evalexp = {}
function eval(exp, globalenv)
    if type(exp[1]) == "table" then
      --print("we should never get here")
      evalexp = eval(table.remove(exp,1 ), globalenv)
    else
      --print("I believe we got here twice...?")
      evalexp = table.remove(exp, 1)
    end
    
    --arithmetics/ primitives
    if contains(evalexp, globalenv) then
      if (evalexp == "+") then
        local arg1 = eval(exp, globalenv)
        local arg2 = eval(exp, globalenv)
        return add(arg1,arg2)
      elseif (evalexp == "-") then
        local arg1 = eval(exp, globalenv)
        local arg2 = eval(exp, globalenv)
        return minus(arg1,arg2)
      elseif (evalexp == "*") then
        local arg1 = eval(exp, globalenv)
        local arg2 = eval(exp, globalenv)
        return multiply(arg1,arg2)
      elseif (evalexp == "/") then
        local arg1 = eval(exp, globalenv)
        local arg2 = eval(exp, globalenv)
        return divide(arg1,arg2)
      elseif (evalexp == "<") then
        local arg1 = eval(exp, globalenv)
        local arg2 = eval(exp, globalenv)
        return lessthan(arg1,arg2) 
      elseif (evalexp == ">") then
        local arg1 = eval(exp, globalenv)
        local arg2 = eval(exp, globalenv)
        return greaterthan(arg1,arg2) 
      elseif (evalexp == "quote") then
        return quote(exp) end
      elseif(evalexp == "cons") then
        local arg1 = eval(exp, globalenv)
        local arg2 = eval(exp, globalenv)
        return cons(arg1,arg2)
      elseif(evalexp == "car") then
        local t = eval(exp[1], globalenv)
        return t[1]
      end
    end
      
    --a number
    if type(evalexp) == "number" then 
      --print("I want to get here")
      return evalexp

    --define
    elseif evalexp == "define" then
      local a = table.remove(exp, 1)
      globalenv[a] = eval(exp, globalenv)
    
    --and
    elseif evalexp == "and" then
      local a = table.remove(exp, 1)
      if a == nil then
        print("var is null")
        return true
      else
        if eval(a, globalenv) == false or eval(table.remove(exp,1), globalenv) == false then
          return false
        else
          return true 
        end
      end

    --or
    elseif evalexp == "or" then 
      local a = table.remove(exp, 1)
        if a == nil then
          print("var is null")
          return false
        else
          if eval(a, globalenv) == true or eval(table.remove(exp,1), globalenv) == true then
            return true
          else
            return false
          end
        end

    --lambda
    elseif evalexp == "lambda" then
      local envi = globalenv
      local a = tostring(table.remove(exp, 1))
      local body = table.remove(exp, 1)
      envi[a] = eval(exp, globalenv)
      table.insert(envi, globalenv )
      return eval(body, envi)

    -- if
    elseif evalexp == "if" then
      local test = table.remove(exp, 1)
      local action1 = table.remove(exp,1)
      if eval(test, globalenv) then
        return eval(action1, globalenv)
      else
        local action2 = table.remove(exp, 1)
        return eval(action2, globalenv)
      end

    --let
    elseif evalexp == "let" then
      local value = table.remove(exp, 1)
      local a = tostring(table.remove(value, 1))
      local arg = table.remove(value, 1)
      globalenv[a] = arg
      local body = table.remove(exp, 1)
      return eval(body, globalenv)
    
    --a string
    elseif type(evalexp) == "string" then
      return globalenv[evalexp]

    end
  end

function repl()
  local controlvar = true 
  while controlvar do
    local line = io.read()
    if line == "quit" then
      controlvar = false
    else 
      print(eval(parse(line), env))
    end
  end
end

repl()